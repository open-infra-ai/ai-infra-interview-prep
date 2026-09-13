# AI Infra L3/L4 设计评审与 Agent 编排包

> 用途：在实现 direct paged attention、CUDA/Triton public op、GPU workspace、并发
> cancellation/backpressure、跨仓 FFI 或正式性能矩阵之前，先冻结不可由低成本 Agent
> 自行决定的设计。

本文定义的是评审协议，不代表对应功能已经实现或验证。没有批准的设计包时，L3/L4 Agent
只能阅读代码、复现基线、列方案和风险，不能修改生产实现。

## 1. 为什么 L3/L4 不能直接写代码

以下决策一旦错误，通常不会表现为简单编译失败：

- CUDA kernel 可能在漂亮 shape 正确、在 ragged/tail 越界；
- shared workspace 可能在单 stream 正确、并发时互相覆盖；
- C ABI 两侧可以分别编译，但 size/alignment 或 ownership 不一致；
- cancellation 可能返回了 HTTP 终态，但 KV block 或 backend sequence 仍泄漏；
- fake/meta implementation 可能能 export shape，却与 eager 错误语义不同；
- benchmark 可能计时稳定，但比较的不是同一工作量；
- schema 可能格式合法，却无法证明 commit、模型和 raw log 的来源。

因此统一顺序是：

```text
现状证据
  → 设计方案比较
  → 接口/布局/生命周期冻结
  → correctness 与失败矩阵
  → benchmark baseline
  → rollback/fallback
  → reviewer 批准
  → 实现
```

## 2. G0-G8 通用评审门禁

### G0：事实与范围

设计包必须列出：

- exact repository、base branch、40 位 commit、dirty state；
- 当前已实现、证据不足、未来目标；
- 本任务解决的问题和明确不解决的问题；
- 代码锚点、现有 tests、CI、benchmark 和文档声明；
- GPU、模型、外部依赖和 profiler 的可用状态。

拒绝条件：

- 把 roadmap、注释或 symbol 存在当成已验证能力；
- 用历史结果代替当前 commit；
- 将 Paged KV bookkeeping 写成 direct PagedAttention；
- 将 mock/CPU test 写成 GPU correctness。

### G1：API/ABI

必须冻结：

- public/internal API 选择；
- 参数顺序、类型、整数宽度、nullability；
- input/output shape、dtype、stride、device；
- workspace/context/config 的创建、复用和销毁接口；
- 兼容策略、versioning 和调用方迁移；
- C ABI 的 size/alignment/field order/error code。

拒绝条件：

- public API 仍存在未决参数；
- 两个仓分别维护不同契约；
- 通过隐式全局状态绕过 API ownership；
- 对 unsupported 输入静默 fallback 且没有可观察状态。

### G2：数据布局与数值

必须冻结：

- 每个 buffer 的逻辑 shape 和线性地址公式；
- batch/layer/head/kv_head/token/block/dim 的排列；
- block table 的元素语义和合法范围；
- GQA/MQA 的 query-head 到 kv-head 映射；
- accumulation dtype、softmax、scale、mask 和容差；
- ragged/tail、空输入、最大输入和 overflow 行为。

拒绝条件：

- 使用“contiguous”“paged”“standard layout”等模糊词而没有公式；
- reference 与生产实现共享关键寻址/归约函数；
- 只覆盖对齐 shape；
- NaN/Inf、非法 block id 或整数乘法溢出未定义。

### G3：所有权与生命周期

必须冻结：

- 谁分配、谁释放、何时扩容；
- workspace 是否 request/handle/stream/device scoped；
- request、sequence、KV block、backend slot 的映射；
- success、cancel、timeout、disconnect、OOM、launch error 的清理；
- 重复释放、部分初始化、destructor 和 shutdown 行为。

拒绝条件：

- 使用函数级 static/raw pointer 且没有并发协议；
- 只描述 happy path；
- owner 销毁时仍可能有 in-flight GPU work；
- cleanup 依赖未来某次成功事件。

### G4：stream 与 concurrency

必须冻结：

- caller stream、internal stream 和 default stream 的关系；
- event/stream ordering；
- 同 handle 多 stream、不同 handle 同 stream、不同 request 并发；
- host mutex 是否只保护 metadata，是否错误地序列化 GPU；
- reallocation 与 in-flight kernel 的同步；
- cancellation 与正在执行 step 的线性化点。

拒绝条件：

- 默认 stream 假设未声明；
- 用 `cudaDeviceSynchronize` 作为普通路径修复；
- 使用 unbounded channel；
- 宣称 thread-safe/stream-safe 却没有并发测试。

### G5：错误语义

必须冻结：

- validation error、unsupported、OOM、launch failure、runtime failure；
- exception/error-code/HTTP/SSE terminal 的映射；
- partial success 和 `n>1` fan-out/fan-in；
- 是否允许 fallback，fallback 如何记录；
- 错误后 output、workspace 和资源状态。

拒绝条件：

- 吞掉错误或只写日志；
- 将 protocol failure 算成功；
- fallback 后仍把结果记为目标 fast path；
- malformed/timeout/disconnect 不进入指标或审计记录。

### G6：correctness

设计阶段必须先给出测试矩阵：

- independent reference；
- deterministic seed；
- normal、ragged、tail、boundary、invalid、failure；
- 多 dtype、shape、layout、stream、sequence lifecycle；
- CPU/build 与 GPU correctness 分开；
- Compute Sanitizer 或等价 memory-safety gate；
- 跨仓/端到端 canary。

拒绝条件：

- correctness 计划晚于 benchmark；
- 只比较最终 token，无法定位 kernel/layer/FFI；
- GPU tests 可 skip 后仍标 pass；
- 测试 oracle 复用同一生产寻址或归约逻辑。

### G7：性能 baseline

必须冻结：

- 被比较实现和语义等价依据；
- kernel、operator、runtime、serving 的测量层级；
- 输入、seed、warmup、repetitions、interleaving；
- raw samples、统计量和收敛标准；
- profiler 问题和具体指标；
- GPU/driver/CUDA/toolchain/model/hash/commit/dirty/limitations。

拒绝条件：

- correctness 未过就正式计时；
- 单次运行；
- 无 raw data；
- CV 或 spread >10% 却不标 `not_converged`；
- 不同量化、工作量或输出语义直接计算 speedup；
- 把 kernel latency 写成 TTFT/TPOT。

### G8：合并、fallback 与回滚

必须冻结：

- PR 拆分和文件 owner；
- feature flag/config/fallback；
- 新旧实现差分期；
- artifact 保留位置；
- 回滚触发条件和恢复步骤；
- shared file 与跨仓合并顺序。

拒绝条件：

- 一个 PR 同时改 contract、实现、benchmark 和最终性能文档；
- 没有 legacy fallback 的高风险替换；
- benchmark Agent 同时优化算法；
- 一个仓先合并破坏另一个仓的 ABI。

## 3. 标准设计包模板

将以下模板复制到任务 PR 或独立设计文档。所有 `unknown` 必须在实现前关闭，或者明确由
reviewer 接受为受限范围。

```markdown
# <task-id> 设计包

## 1. Decision summary
- Chosen design:
- Why:
- Rejected alternatives:
- Explicit non-goals:

## 2. Base evidence
- Repository:
- Base branch:
- Commit:
- Dirty state:
- Existing code anchors:
- Existing tests:
- Existing GPU/performance evidence:
- Unknown:

## 3. API / ABI
- Public or internal:
- Signature:
- Parameter order and types:
- Shape/dtype/stride/device:
- Size/alignment/field order:
- Compatibility/versioning:

## 4. Data layout and numerics
- Logical shape:
- Linear address formula:
- Head/block/page mapping:
- Accumulation dtype:
- Mask/scale:
- Boundary and overflow behavior:

## 5. Ownership and lifecycle
- Allocator:
- Owner:
- Reuse scope:
- Reallocation:
- Destruction:
- Success cleanup:
- Cancel/timeout/error cleanup:

## 6. Stream and concurrency
- Caller stream:
- Internal stream/event:
- Supported concurrency:
- Synchronization:
- Unsafe combinations:

## 7. Error and fallback
- Validation errors:
- OOM:
- Launch/runtime errors:
- Partial success:
- Fallback:
- Observability:

## 8. Correctness matrix
| Case | Reference | Expected | GPU required | Sanitizer |
|------|-----------|----------|--------------|-----------|

## 9. Benchmark plan
- Measurement layer:
- Baseline:
- Shapes/workload:
- Warmup/repetitions:
- Raw artifact:
- Convergence:
- Profiler question:

## 10. PR and ownership plan
- Contract PR:
- Tests/reference PR:
- Implementation PR:
- Integration PR:
- Benchmark/profiling PR:
- Docs PR:
- Shared-file owner:

## 11. Rollback
- Trigger:
- Procedure:
- Preserved legacy path:

## 12. Approval
- G0:
- G1:
- G2:
- G3:
- G4:
- G5:
- G6:
- G7:
- G8:
- Reviewer:
- Decision: approved / changes_requested / rejected
```

## 4. TLLM-DPA：direct paged decode attention 设计包

对应任务：TLLM-P0-002、TLLM-P0-004、TLLM-P0-005、TLLM-P1-001。

### 4.1 当前事实

- `kernels/attention.cu::attention_decode` 消费连续 K/V。
- `kernels/paged_kv.cu` 实现 scatter/gather。
- `src/transformer.cpp::attentionPaged` 每层 scatter 到 physical pool，再 gather 到
  `k_scratch/v_scratch`，最后调用连续 attention。
- `src/ffi.cpp` 维护 pool、scratch、block table 和 strategy 1/2。
- 因此当前实现可称“paged KV storage/control path”，不能称 direct PagedAttention。

### 4.2 必须冻结的 kernel API

设计至少比较：

1. 直接传 raw pool + table + geometry；
2. 传只读 `PagedKVView`；
3. 在 Transformer 内隐藏 kernel，不增加 public C++ API。

候选内部接口必须显式包含：

```cpp
attention_decode_paged(
    query,
    k_pool,
    v_pool,
    block_table,
    output,
    scale,
    num_q_heads,
    num_kv_heads,
    head_dim,
    visible_tokens,
    block_size,
    max_num_blocks,
    layer_pool_offset,
    stream);
```

这只是设计字段清单，不是已批准 signature。评审必须决定：

- `block_table` 是 per-request 还是 batch-flattened；
- layer offset 由 caller 计算还是 kernel 计算；
- table length 是否显式传入；
- `visible_tokens` 和 current position 的关系；
- 是否第一阶段只支持 batch=1、query_len=1；
- head_dim 和 block_size 的支持集合；
- output/logsumexp 是否都需要；
- unsupported 输入是 error 还是 legacy fallback。

### 4.3 地址公式

设计文档必须用变量写出：

```text
logical_token = t
logical_block = t / block_size
block_offset = t % block_size
physical_block = block_table[logical_block]
kv_head = query_head / (num_q_heads / num_kv_heads)
pool[layer, physical_block, block_offset, kv_head, dim]
```

如果真实布局不同，必须给出实际线性地址公式，包括：

- layer stride；
- physical block stride；
- token stride；
- kv-head stride；
- dim stride；
- pool element dtype；
- 乘法使用的整数宽度和 overflow 检查。

### 4.4 correctness 矩阵

最低矩阵：

| 维度 | 必测值 |
|------|--------|
| block size | 1、16、32 或仓库正式支持集合 |
| visible tokens | 1、block-1、block、block+1、2*block+尾部 |
| q/kv heads | MHA、GQA、MQA |
| head dim | 32、64、128 或正式支持集合 |
| table | 顺序块、非连续物理块、复用顺序、非法/不足长度 |
| values | 随机、全零、大正/负 score、重复 K |
| lifecycle | allocate→prefill→多次 decode→free→reuse |
| streams | default、non-default、批准的并发组合 |

reference 必须独立构造连续逻辑 K/V，不能调用 `paged_gather_blocks`。先比较 kernel output，
再比较 Transformer layer，最后比较 FFI token/logit。

### 4.5 PR 拆分

1. **Oracle PR**：synthetic reference、layout tests、invalid tests。
2. **Kernel PR**：header/kernel 和专用 tests；不改 FFI。
3. **Runtime PR**：Transformer dispatch + legacy fallback。
4. **ABI/Integration PR**：若 C ABI 变化，与 paged-serving 成对提交。
5. **Benchmark PR**：legacy gather、direct paged、contiguous 三路。
6. **Docs PR**：只有证据完成后更新能力边界。

### 4.6 回滚

- 保留 runtime flag 或内部 dispatch 选择 legacy gather path；
- 任一 unsupported geometry 自动 fallback 时必须增加 counter/log，benchmark 不得把
  fallback 记为 direct；
- correctness、sanitizer 或真实 backend 回归时默认关闭 direct path；
- 不删除 legacy path，直到固定观察期和结果矩阵完成。

## 5. TLLM-PSRV-ABI：跨仓 C ABI 设计包

对应任务：TLLM-P0-005、PSRV-P1-002。

### 5.1 双源文件

- `tiny-llm/include/tiny_llm/ffi.h`
- `paged-serving/src/tiny_llm_ffi.rs`

设计 reviewer 必须同时查看两个文件，不能分别批准。

### 5.2 ABI 表

为每个 struct/function 建表：

| 项 | C/C++ | Rust | 验证 |
|----|-------|------|------|
| size | `sizeof` | `size_of` | equality |
| alignment | `alignof` | `align_of` | equality |
| field offset | `offsetof` | offset assertion | equality |
| integer width | exact type | exact FFI type | equality |
| pointer | const/mutable/null | `*const/*mut` | contract |
| ownership | caller/backend | caller/backend | lifecycle test |
| error | enum/int | mapped enum | exhaustive |

至少冻结：

- load/config 的 `max_num_blocks`、`block_size`；
- allocate/free 的 sequence/request identity；
- step 中 tokens、positions、seq_lens、flattened block tables、num_blocks；
- 每个 buffer 的 capacity 和写入范围；
- `max_num_blocks == 0` 的连续策略；
- partial failure 后哪些 sequence 已分配、谁负责回滚。

### 5.3 兼容和合并顺序

优先选择：

1. 不改变 ABI，仅改变 tiny-llm 内部 dispatch；
2. 如必须扩展，新增 versioned function/struct size；
3. 最后才考虑破坏性替换。

合并顺序：

```text
两仓 ABI 设计批准
  → 两侧 layout tests
  → tiny-llm 提供兼容实现
  → paged-serving 切换调用
  → 固定双 commit integration
  → 删除旧接口（另一个任务）
```

禁止在中间状态使 main 分支只能与未合并的另一个仓配合。

## 6. CUF-WORKSPACE：decode workspace/stream 设计包

对应任务：CUF-P0-001、CUF-P0-002、CUF-P0-003。

### 6.1 当前风险

`src/forward/flash_decoding.cu::launch_flash_decoding_typed` 使用函数级 static scratch，
按最大需要扩容。风险包括：

- 两个 host thread 同时扩容；
- 两个 stream 同时写同一 partial buffers；
- reallocation/free 与另一个 in-flight kernel 竞争；
- handle 不存在，无法表达 owner/destructor；
- OOM 和 launch error 的状态不完整。

### 6.2 必须比较的方案

| 方案 | 优点 | 必须回答的风险 |
|------|------|----------------|
| caller-owned workspace | ownership 明确、无隐藏 allocation | workspace bytes API、调用复杂度、ABI |
| handle-owned workspace | 可复用、可集中销毁 | handle/thread safety、stream ordering |
| per-stream pool | 易支持多 stream | stream key 生命周期、缓存增长、销毁 |
| per-call async allocation | 简单隔离 | CUDA 版本、allocator 可用性、性能 |

不接受“用全局 mutex 包住整个函数”作为最终方案，除非明确降级为单流 API 并修改能力声明。

### 6.3 workspace contract

必须给出：

- `required_bytes(batch, heads, seq, head_dim, chunks, dtype)`；
- alignment；
- partial `m/l/O` 的 offset 和 size；
- overflow-safe size 计算；
- grow-only 还是 exact allocation；
- stream event 如何保护复用；
- destruction 是否等待 in-flight work；
- OOM 后旧 workspace 是否仍有效。

### 6.4 并发矩阵

| 场景 | 必须定义 |
|------|----------|
| 同 thread、同 stream、连续调用 | 支持 |
| 同 thread、不同 stream | 支持/拒绝及行为 |
| 不同 thread、同 handle | 支持/拒绝及行为 |
| 不同 handle、不同 stream | 支持 |
| 调用中扩容 | ordering 和旧 buffer 生命周期 |
| handle 销毁且有 in-flight work | error/wait/precondition |

### 6.5 错误返回

分别定义 validation、workspace-too-small、OOM、partial launch、combine launch 和 async
runtime failure。若 API 只做异步 launch，必须说明哪些错误能同步返回，哪些由调用方在
stream sync 时发现，不能声称同步捕获所有 device runtime error。

## 7. PSRV-CANCEL-BP：取消与背压设计包

对应任务：PSRV-P0-001、PSRV-P0-002、PSRV-P0-003。

### 7.1 request 状态机

设计必须覆盖：

```text
received
  → admitted
  → pending
  → prefill
  → decode
  → completed | failed | cancelled
```

每个状态列出：

- HTTP handler owner；
- response/SSE consumer owner；
- scheduler sequence；
- KV blocks；
- tiny-llm backend sequence；
- event channel sender/receiver；
- cancellation signal；
- terminal event；
- cleanup owner。

核心 invariant：

```text
每个已准入 request 恰好一个 terminal state
每个 sequence 恰好一次 release
terminal 后不再产生 chunk
cancel/timeout/disconnect 后资源最终回到基线
```

### 7.2 cancellation 触发

必须定义：

- client 在首 token 前断开；
- HF decoder 暂无安全文本 chunk 时断开；
- client 在多个 chunk 后断开；
- unary handler future 被 abort；
- `n>1` 第 k 个候选准入失败；
- server shutdown；
- engine/backend error；
- request timeout；
- channel overflow/receiver close。

设计应优先使用 request ownership guard/token，把 cancel 送到 engine；不能只依赖
`tx.send(...).is_err()` 的偶然时点。

### 7.3 bounded channel 策略

必须分别冻结：

- engine → single-request response；
- `n>1` child → fan-in aggregator；
- submission queue；
- metrics sampler。

每条 channel 记录 capacity、element size 上界、producer 是否可 await、overflow 行为和
全局影响。可选策略：

1. producer await，但必须证明不阻塞整个 engine loop；
2. per-request forwarding task，engine 只写有界 mailbox；
3. overflow 即 cancel slow consumer，并发送/记录稳定终态；
4. coalesce 只可用于 metrics，不可静默合并文本 token/chunk。

### 7.4 指标语义

冻结以下问题：

- `inflight` 是 HTTP handler lifetime、response body lifetime 还是 generation lifetime；
- `requests_total` 对 `n` 是一个 API request 还是 n 个 generation；
- 429、malformed JSON、admission failure、SSE terminal error 是否进入 errors；
- cancelled 与 failed 是否独立；
- active sequences、KV utilization 的采样时点；
- HELP 文本是否精确描述单位。

### 7.5 测试方式

不能只靠 sleep。优先使用：

- barrier/oneshot 控制 engine 进入 pending/prefill/decode；
- 有界 channel 填满信号；
- abort handler task；
- drop response body/receiver；
- backend probe 记录 allocate/step/free；
- BlockPool/metrics baseline 前后比较；
- property test 验证 exactly-once terminal/release。

## 8. TRI-CUSTOM-OP：FlashAttention custom op 设计包

对应任务：TRI-P0-001、TRI-P0-002、TRI-P1-005。

### 8.1 先做“注册或不注册”决策

注册不是必然更好。设计必须比较：

- Python function 保持实验 API；
- 注册 `torch.library.custom_op`，只支持 inference forward；
- 注册 forward + autograd；
- 等待动态 shape/fake 约束稳定后再注册。

如果选择不注册，README 要解释它与现有三个 custom op 的边界。如果注册，以下 contract
必须完整。

### 8.2 schema

冻结：

- Q/K/V layout，例如 `[B,H,S,D]`；
- self/cross attention；
- causal；
- scale 默认值；
- FP16/BF16/FP32；
- contiguous 或 stride policy；
- MHA/GQA/MQA；
- output 和可选 LSE；
- forward-only 还是 autograd；
- mutation/aliasing；
- dynamic `S` 和 fake output shape。

### 8.3 eager/fake/export

相同静态错误必须在 eager/fake 一致：

- rank；
- shape compatibility；
- dtype；
- device；
- head mapping；
- head_dim；
- stride。

fake implementation 只做 metadata 推导，不读 storage、不调用 CUDA。`torch.export` 测试
必须使用仓库声明支持的最小/最大 torch 版本；上游不支持时降级声明并保留最小复现。

### 8.4 correctness

- independent reference 使用 PyTorch SDPA 或显式 softmax/matmul；
- 覆盖 causal/non-causal、ragged length、极端 logits、dtype 和 head geometry；
- output/LSE 分别比较；
- 如果没有 backward，不得在文档暗示 training support；
- compile/export graph 中确认 op 边界符合设计。

## 9. CUDA-SGEMM-API：变体和 WMMA 设计包

对应任务：CUDA-P1-002、CUDA-P1-003。

### 9.1 变体 inventory

对每个 launcher 建表：

| Variant | Input dtype | Accumulation | Output | Shape constraints | Status |
|---------|-------------|--------------|--------|-------------------|--------|
| naive | | | | | |
| tiled | | | | | |
| bank-conflict-free | | | | | |
| double-buffer | | | | | |
| tensor-core FP32 wrapper | | | | | |
| tensor-core FP16 input | | | | | |
| scaled | | | | | |
| transposed | | | | | |
| register-tiled | | | | | |

status 只能是 supported、experimental、internal、broken 或 future。supported 必须有
correctness、sanitizer 和 benchmark。

### 9.2 WMMA 两层 API

必须把以下成本分开：

1. pure kernel：输入已是批准 dtype/layout；
2. convenience wrapper：FP32 input conversion、allocation、kernel、conversion/output、
   synchronization 和 free。

设计必须决定 workspace 是否 caller-owned、conversion 是否可预计算、timing 的起止点、
cuBLAS baseline 的对应 API，以及 FP32/TF32/FP16 是否具有相同数值目标。

### 9.3 不可接受的性能归因

- “Tensor Core 文件被调用，所以 Tensor Core 已利用充分”；
- 把 wrapper allocation/conversion 全部时间称 kernel latency；
- 用不同输入 dtype 与 cuBLAS FP32 直接比较后称同精度 speedup；
- 用一次 `ncu` 截图代替 raw report；
- 从一个方阵外推所有矩形/ragged shape。

## 10. KVT-SCHEMA-V2：HiCache 结果包设计

对应任务：KVT-P0-002、KVT-P0-003、KVT-P1-001、KVT-P1-002。

### 10.1 状态模型

顶层必须有：

```text
complete      所有必填 provenance、correctness、path 和 raw evidence 通过
partial       有真实运行，但缺少指定证据或只有部分矩阵
blocked       前置条件不可用，未产生可解释实验结果
not_measured  harness 完成，但未运行真实性能
invalid       结果包内部不一致或审计失败
```

validator 不得把缺字段的旧 v1 自动升级为 complete。

### 10.2 最小字段

```yaml
schema_version: 2
status:
scope:
timestamps:
repository:
  kvtier_commit:
  kvtier_dirty:
upstream:
  repository:
  sglang_commit:
  dirty:
environment:
  os:
  python:
  gpu:
  vram:
  driver:
  cuda:
  framework:
model:
  path_or_id:
  revision:
  file_hashes:
  weight_dtype:
  kv_cache_dtype:
server:
  command:
  config_snapshot:
workload:
  command:
  seed:
  W_E_R_P_parameters:
correctness:
  output_oracle:
  cache_path_evidence:
  counter_evidence:
results:
  raw_requests:
  raw_metrics:
  summary:
artifacts:
  stdout_hash:
  stderr_hash:
  result_hash:
limitations:
```

模型绝对路径可能包含本机信息；公开包应保存脱敏 identifier 和 hash，私有本地记录可保存
完整路径。不能把 secret、token 或个人路径原样发布。

### 10.3 W/E/R/P 归因

每个 phase 必须有独立 timestamp、request id、input token hash、cache details 和 counter
snapshot/delta。R 的 host hit 不能仅由整轮结束时全局 counter 正增量推断。

最低 oracle：

- R 与对应 P 使用相同输入和 generation config；
- 比较输出 token ids 或可稳定获取的文本；
- W backup 完成使用可观察条件或有界 polling；
- E 确认 device eviction；
- R 确认 host load-back；
- namespace 不被其他 request 污染。

如果上游 API 只能提供 run-level counter，状态应为 partial，并在 limitations 说明无法完成
per-request 因果归因。

## 11. PERF-MATRIX：正式 benchmark/profiling 设计包

适用于 CUDA-P1-001/003、TRI-P1-007、CUF-P1-002、TLLM-P1-001、
PSRV-P1-004、KVT-P1-001/002。

### 11.1 correctness-first gate

正式性能任务开始前，输入 commit 必须满足：

- build/lint/typecheck 通过；
- 目标 GPU correctness 非 skip；
- memory-safety gate 通过；
- baseline 与目标实现输出等价；
- fallback/dispatch 可观察；
- benchmark harness 自测通过。

否则只允许采集 debugging profile，不得发布性能结论。

### 11.2 实验清单

每个 run 至少记录：

- exact commit 和 dirty state；
- GPU、VRAM、power/clock policy；
- driver、CUDA、compiler/framework；
- 模型/tokenizer/revision/hash；
- dtype、quantization、layout；
- shape/workload、seed；
- warmup、repetitions、运行顺序；
- raw JSON/JSONL/CSV/stdout；
- profiler 原始文件；
- failure/OOM/skip；
- limitations；
- CV/spread 和 convergence。

### 11.3 A/B 原则

- 相同机器和尽可能相同时间窗口；
- 交错 `A B B A` 或随机化顺序，避免热漂移；
- 独立进程重复；
- 固定 clock/power 只能在合法且已记录时使用；
- warmup 与 measurement 分开；
- 失败和 OOM 也是结果；
- 比较层级一致：kernel 对 kernel、operator 对 operator、server 对 server。

### 11.4 结论格式

允许：

```text
在 <commit/GPU/model/shape> 下，A 的 median 为 X，B 为 Y；
差值 Z%，3 次独立重复的 CV 为 C。该观察只适用于上述条件。
```

不允许：

```text
全面提升 2x
显著降低显存
达到生产级
等价于 vLLM/FA2/FA3
```

除非矩阵和证据确实支持这些更广结论。

## 12. 多 Agent 编排

### 12.1 推荐角色

| 角色 | 输入 | 输出 | 禁止 |
|------|------|------|------|
| evidence Agent | 固定 commit | 现状、anchors、unknown | 改生产代码 |
| design Agent | evidence + 本文 | 完整设计包 | 未批准先实现 |
| oracle Agent | 批准 contract | independent reference/tests | 复用生产核心逻辑 |
| implementation Agent | contract + failing tests | 最小实现 | 改 benchmark 结论 |
| integration Agent | 两仓/多模块 contract | ABI/E2E | 单方面改兼容语义 |
| benchmark Agent | correctness-passed commit | raw results | 优化算法、删失败 |
| profiling Agent | 收敛 benchmark | raw profiler + 归因 | 根据源码猜指标 |
| reviewer | 全部 artifact | approve/changes/reject | 只看最终平均值 |

### 12.2 文件 owner

在任务开始前建表：

```yaml
owners:
  public_api: <one owner>
  build_config: <one owner>
  workflow: <one owner>
  production_source_a: <one owner>
  tests_reference: <one owner>
  benchmark_schema: <one owner>
  docs_evidence_index: <one owner>
```

一个文件同一批次只能有一个 owner。特别注意：

- paged-serving cancellation/backpressure 都会修改 `src/server.rs`，必须串行；
- tiny-llm ABI 与 paged-serving Rust mirror 必须由 integration owner 协调；
- README、workflow、CMake/Cargo/pyproject 和 schema validator 都属于 shared files；
- benchmark/profiling Agent 不拥有生产 kernel。

### 12.3 交接包

每个 Agent 完成后必须提供：

```markdown
## Status
complete / partial / blocked / failed

## Base
repository, branch, commit, dirty state

## Decision or changes
设计决定，或修改的 symbols/files

## Validation
CPU/build:
GPU correctness:
Sanitizer:
Performance:

## Evidence
命令、退出码、raw artifact、环境 metadata

## Not run
未运行项和原因

## Risks
剩余风险、fallback、rollback

## Handoff
下一任务 ID、所需输入、禁止重新决定的 contract
```

下游 Agent 必须读取交接包，不得仅根据 PR 标题猜测 contract。

## 13. Reviewer 最终决策

### Approved

只有在 G0-G8 全部关闭、unknown 已解决或被明确接受、测试和回滚计划可执行时使用。

### Changes requested

适用于：

- 缺少一个或多个必填 contract；
- reference 不独立；
- 并发/错误/cleanup 未覆盖；
- baseline 不公平；
- PR 拆分会产生不可合并中间状态。

### Rejected

适用于：

- 设计依赖伪造/不可获得的证据；
- 通过关闭安全检查、吞错误、无限缓冲或全局同步掩盖问题；
- 目标超出仓库定位且没有用户批准；
- 方案会让两个 main 分支永久 ABI 不兼容；
- 性能结论无法在可接受资源内被证伪或复现。

评审通过只意味着“允许实现”，不意味着功能已完成。最终完成仍需独立 correctness、
GPU/sanitizer、集成、benchmark 和文档证据。
