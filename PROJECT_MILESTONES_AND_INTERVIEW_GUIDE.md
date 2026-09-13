# 七仓详细改进、阶段成果与面试使用手册

更新时间：2026-09-13。

这不是新的路线图，也不替代已有任务单。它把以下三类材料连接起来：

- 具体实现任务：[`P0_P1_AGENT_BACKLOG.md`](P0_P1_AGENT_BACKLOG.md)；
- L3/L4 设计：[`L3_L4_DESIGN_REVIEW_PACKAGES.md`](L3_L4_DESIGN_REVIEW_PACKAGES.md)；
- 跨仓系统关系：
  [`system-integration-and-interview-map.md`](https://github.com/open-infra-ai/open-infra-ai/blob/master/docs/system-integration-and-interview-map.md)。

用途：

1. 本人知道每个仓下一阶段具体做什么；
2. Agent 知道任务前置、产物、验收和停止条件；
3. 面试时能按阶段说明“已经完成什么、证据是什么、还没有完成什么”；
4. 七仓最终被讲成两个旗舰故事，而不是七个互不相关的练习。

---

## 1. 全局阶段模型

每个技术仓都使用同一套阶段名称，但不同仓的具体产物不同。

| 阶段 | 目标 | 必须有的证据 | 面试状态 |
|------|------|-------------|---------|
| M0 定位 | 当前实现、边界、依赖、风险可定位 | symbol/file/commit/dirty、现状图、限制 | 可以讲设计理解，不能讲完成 |
| M1 可信 | build/test/skip/错误语义可信 | clean build、CPU/static tests、负向测试、环境 metadata | 可以写“可构建/有测试” |
| M2 正确 | 真实 GPU 或独立 reference 证明语义 | non-skip GPU、reference differential、sanitizer | 可以写正确性范围 |
| M3 深改造 | 完成一个有系统价值的技术改造 | design review、实现、fallback、回归 | 可以讲技术 ownership |
| M4 性能 | 性能结果可复现和归因 | raw samples、manifest、A/B、profile、收敛 | 可以写有限定的性能数字 |
| M5 集成 | 进入真实请求/框架/上游链路 | end-to-end、failure path、资源回收、公平 baseline | 可以作为旗舰项目 |
| M6 外部 | 有上游或第三方反馈 | issue/PR/review/reproduction | 可以证明协作和外部验证 |

### 1.1 “阶段完成”不是 checkbox

只有同时满足以下条件才可以晋级：

```text
实现存在
  + 验收命令成功
  + 失败/skip 可见
  + artifact 可定位
  + exact commit 可复现
  + limitations/prohibited claims 已记录
```

只有代码、README 或 Agent 的“完成”回复，不算阶段成果。

### 1.2 当前总体判断

现有项目已经普遍拥有 M0/M1 的部分基础，但深改造和系统证据仍不均衡：

| 仓库 | 当前可利用基础 | 当前主要缺口 | 目标阶段 |
|------|---------------|-------------|---------|
| `cuda-foundations` | CUDA/SGEMM 优化阶梯和测试 | GPU gate、sanitizer、Nsight 归因与公平计时 | M4 教学证据 |
| `trifuse` | Triton 算子与 `torch.library` 基础 | fake/meta/export、timing/provenance、framework contract | M5 框架集成证据 |
| `cuflash` | FlashAttention/FlashDecoding 算法实现 | workspace/stream safety、GPU gate、profile/baseline | M4 Kernel 深挖 |
| `tiny-llm` | 模型加载、量化、KV、decode、C ABI | independent paged oracle、direct paged path、长上下文 A/B | M5 旗舰数据面 |
| `paged-serving` | Rust 调度、BlockPool、HTTP/SSE | cancel/backpressure、真实 backend gate、容量/尾延迟 | M5 旗舰控制面 |
| `kvtier` | SGLang HiCache 研究脚手架 | pinned upstream、schema、回载 correctness、真实单卡矩阵 | M4 研究证据 |
| `open-infra-ai` | 组织导航、契约和审计路线 | 持续 evidence lifecycle、stale/revoked 和 demo 索引 | M5 治理入口 |

表中只是路线判断。开始任务前仍要按
[`NEXT_AGENT_START_HERE.md`](NEXT_AGENT_START_HERE.md) 重新检查当前 HEAD、PR、CI 和结果状态。

---

## 2. 项目一：`cuda-foundations`

### 2.1 最终定位

一句话：

> 用 SGEMM 优化阶梯证明我理解 CUDA execution/memory model，能够建立正确 benchmark，
> 并用 profiler 解释优化、负优化和硬件边界。

它不是：

- 生产 BLAS；
- 完整推理引擎；
- “所有 shape 都快于 cuBLAS”的项目。

### 2.2 M0：实现与测量盘点

关联任务：`CUDA-P0-001`、`CUDA-P1-002`、`CUDA-P1-004`。

具体工作：

1. 列出 naive、coalesced、shared-memory、register tiling、WMMA 等实际可调用变体；
2. 对每个变体记录 public API、shape/layout/dtype 和 dispatch 条件；
3. 标记“实现存在但未接入”“只用于教学”“已有实测”“理论目标”；
4. 审计 timer 是否包含 H2D/D2H、allocation、conversion、warmup；
5. 审计无 GPU 环境是 fail、skip 还是误报 pass；
6. 删除或降级无法由源码/结果支持的 README 声明。

交付：

- variant inventory；
- timing boundary 表；
- current evidence map；
- unsupported/placeholder 清单。

停止条件：

- 无法从 public API 到实际 kernel 建立调用链；
- benchmark 的同步边界不明确；
- 现有结果找不到 exact commit 或硬件。

阶段成果：

> 可以准确解释每个 SGEMM 版本的优化意图和调用状态，但此阶段不宣传性能。

### 2.3 M1：可信 correctness 与 GPU gate

关联任务：`CUDA-P0-001..003`。

具体工作：

1. CPU/reference 使用独立矩阵乘法逻辑；
2. 覆盖 M/N/K 非 tile 整除、极小矩阵、skinny/wide、错误 leading dimension；
3. dtype/tolerance 写入测试参数，不用单一绝对误差；
4. GPU test 输出 device、driver/runtime 和实际执行数量；
5. 无 GPU 时明确 `skipped`，不能显示与 GPU pass 相同的成功文本；
6. Compute Sanitizer 检查 memcheck，必要时增加 racecheck/initcheck；
7. CI 将 CPU/build 与 GPU correctness 分成不同 job/status。

验收：

- reference differential 通过；
- 非整除 shape 通过；
- invalid launch/config 返回明确错误；
- GPU job 有 non-zero executed test count；
- sanitizer 无非法访问；
- skip 原因可见。

阶段成果：

> 可以声明“在记录的 shape/dtype/tolerance 和 GPU 上与独立 reference 对齐，并通过
> 指定 sanitizer”，不能声明 production-grade。

### 2.4 M2/M3：Nsight 驱动优化解释

关联任务：`CUDA-P0-004`、`CUDA-P1-001`、`CUDA-P1-003`。

固定 4 类 shape：

1. square compute-heavy；
2. M=1 decode-like；
3. skinny matrix；
4. tile 非整除。

对每个 shape 记录：

- warmup、iterations、独立进程数；
- kernel-only 与 end-to-end 两种 timing；
- achieved bandwidth/throughput；
- occupancy、register、shared-memory；
- memory coalescing、bank conflict、warp stall；
- WMMA conversion/padding 成本；
- 失败、OOM 或负优化。

必须回答：

- shared memory 为什么可能更慢？
- tile 增大后 occupancy 为什么下降？
- WMMA kernel 快时，端到端为什么可能不快？
- M=1 为什么与大矩阵的优化策略不同？
- 哪个结果受 RTX 3060 Laptop 功耗/频率影响？

阶段成果：

> 一份“假设 → profiler → 修改 → A/B → 解释”的教学案例，比堆更多 kernel 更有价值。

### 2.5 面试展示

首选材料：

- 一张优化阶梯表；
- 一个负优化案例；
- 一张 Nsight Compute 指标对比；
- 一份 raw benchmark manifest。

常见追问：

- global/shared/register 的访问代价；
- coalescing 与 bank conflict；
- arithmetic intensity/roofline；
- occupancy 是否越高越好；
- Tensor Core 数据布局和累加精度；
- CUDA event 与 wall-clock timing 差异。

简历安全表述模板：

> 构建 SGEMM CUDA 优化阶梯，在固定 GPU/shape/计时边界下使用独立 reference、
> Compute Sanitizer 和 Nsight 分析访存、occupancy 与 WMMA conversion；保留负优化
> 和 raw samples。

---

## 3. 项目二：`trifuse`

### 3.1 最终定位

一句话：

> 用 Triton 实现 Transformer 融合算子，并把它作为正规的 PyTorch custom op 接入
> eager、fake/meta、export/compile 工作流。

它不是：

- 完整 Triton compiler；
- CUDA kernel 的性能结果副本；
- 只要 eager 正确就算框架集成完成。

### 3.2 M0/M1：冻结 custom-op contract

关联任务：`TRI-P0-001`、`TRI-P0-002`、`TRI-P1-005`。

每个 op 必须定义：

- namespace 和 schema；
- tensor rank/shape；
- dtype/device；
- contiguity/stride；
- in-place/aliasing；
- optional 参数和默认值；
- output shape/dtype/device；
- unsupported input 的错误类型；
- fake/meta 是否访问真实数据；
- autograd 支持或明确不支持。

验证矩阵：

```text
eager CPU reference
eager CUDA
FakeTensorMode
torch.export
torch.compile（若纳入支持范围）
dynamic/non-contiguous/invalid input
```

阶段成果：

> 可以解释“写一个 Triton kernel”和“交付一个 PyTorch operator”之间的差别。

### 3.3 M2：独立 correctness

关联任务：`TRI-P1-005`、`TRI-P1-008`。

具体工作：

1. reference 使用 PyTorch primitives/SDPA，不复制 Triton indexing；
2. 覆盖 causal/non-causal、非 2 的幂、非整除、短/长 sequence；
3. 覆盖 FP32/FP16/BF16 能力范围；
4. 对 softmax/attention 使用合理的 atol/rtol；
5. invalid device/dtype/shape 必须报错；
6. GPU test 显示实际 executed 数量和 skip 原因；
7. fake/export 与 eager 共用同一 contract 测试表。

阶段成果：

> 可以声明具体 op 在列出的 eager/fake/export 场景与 reference 一致。

### 3.4 M3/M4：benchmark 与 framework evidence

关联任务：`TRI-P0-003/004`、`TRI-P1-006/007`。

benchmark 必须固定：

- input shape/dtype/layout；
- warmup/repetitions；
- 同步方式；
- compile/autotune 是否计入；
- forward-only 或 end-to-end；
- Triton/PyTorch/CUDA baseline 版本；
- raw samples；
- commit/dirty/GPU/toolchain。

至少报告：

- eager first-run；
- warmed steady-state；
- compile/autotune cost；
- 代表 shape 的 win/loss；
- dynamic shape/recompile 行为；
- peak memory 或 workspace（能可靠测量时）。

阶段成果：

> 不只是“比 PyTorch 快”，而是能解释在哪些 shape、哪个 timing boundary、什么 compilation
> 状态下更快或更慢。

### 3.5 面试展示

首选故事：

1. 一个 fused op 的 contract；
2. fake/meta 的必要性；
3. export/compile 失败过的边界；
4. Triton 与 CUDA 的性能和维护性取舍。

常见追问：

- program id 如何映射数据 tile；
- masking 如何处理非整除 shape；
- autotune key 选错会怎样；
- fake implementation 为什么不能读 tensor data；
- custom op alias/mutation 为什么影响编译；
- dynamic shape 如何导致重新编译。

简历安全表述模板：

> 为 Transformer 融合算子实现 Triton + `torch.library` 集成，覆盖 eager、fake/meta、
> export 和输入契约测试，并在固定 compile/timing 边界下与 PyTorch reference 做差分和
> 可复现 benchmark。

---

## 4. 项目三：`cuflash`

### 4.1 最终定位

一句话：

> 从零实现并验证 FlashAttention/FlashDecoding，重点证明 online softmax、tiling、
> 数值稳定性、workspace/stream 生命周期和真实性能归因。

它不是：

- 官方 FlashAttention 的替代品；
- 已经接入 `tiny-llm` 的生产 kernel；
- 所有 GPU/shape 都更快的通用库。

### 4.2 M0/M1：workspace 与 stream contract

关联任务：`CUF-P0-001`、`CUF-P0-002`。

必须先冻结：

- workspace owner；
- 分配、增长、复用和释放时机；
- device 变化如何处理；
- stream 由 caller 还是 library 拥有；
- 同一 handle 是否允许并发 stream；
- OOM、invalid argument、launch error 如何映射；
- asynchronous error 何时可见；
- destruction 前是否需要同步；
- thread safety；
- fallback。

推荐结果不是简单把 function-static pointer 包一层 mutex，而是选择明确模型：

```text
caller-owned workspace
或
explicit context/handle-owned workspace
```

必须测试：

- 两个 stream 交错；
- workspace grow；
- repeated create/destroy；
- device mismatch；
- OOM/error injection（可控时）；
- launch failure propagation。

阶段成果：

> 可以讨论 CUDA library API 的 ownership、reentrancy 和 asynchronous error，而不只会写
> kernel body。

### 4.3 M2：数值与边界

关联任务：`CUF-P0-003/004`。

矩阵至少覆盖：

- batch/head/sequence/head_dim 边界；
- causal 与非 causal；
- 非整除 tile；
- chunk 数不是 sequence 因子的情况；
- FP32/FP16/BF16 支持范围；
- extreme logits；
- empty/invalid 参数；
- 多 stream；
- scalar/WMMA dispatch。

reference：

- 使用独立 SDPA/显式 stable softmax；
- 不复用 production online-softmax helper；
- 比较 output 和 LSE（如果 API 暴露）；
- 记录 tolerance 与最大误差分布。

阶段成果：

> 可以声明当前 HEAD 在指定 GPU/shape/dtype 下通过 non-skip correctness 和 sanitizer。

### 4.4 M3/M4：dispatch 和性能归因

关联任务：`CUF-P1-001..003`。

代表 workload：

- prefill：中等/较长 sequence；
- decode：query length=1、不同 KV length；
- GQA/MQA-like head mapping（若 API 支持）；
- 非整除和小 shape；
- workspace reallocation 与 steady-state 分开。

必须保留：

- dispatch observability；
- scalar/WMMA/其他 path 的实际命中；
- raw latency；
- PyTorch SDPA/可安装的官方 baseline；
- Nsight Systems timeline；
- Nsight Compute 的 memory/compute/stall 指标；
- 更慢的 shape。

阶段成果：

> 面试重点是解释“为什么某个 shape 赢、另一个 shape 输”，而不是只给最佳加速比。

### 4.5 面试展示

白板顺序：

1. naive attention 的中间矩阵和 IO；
2. online softmax 的 running max/sum 更新；
3. tile 和 shared memory；
4. causal/edge mask；
5. decode 分 chunk 和 reduction；
6. workspace/stream 生命周期；
7. profiler 证据和 fallback。

常见追问：

- online softmax 为什么数值稳定？
- 为什么 FlashAttention 减少 HBM IO？
- decode 与 prefill 的瓶颈为何不同？
- LSE 有什么作用？
- stream-safe API 如何设计？
- WMMA 为什么不一定端到端更快？

简历安全表述模板：

> 实现 CUDA FlashAttention/FlashDecoding，补齐 workspace/stream 生命周期、独立 reference、
> 非整除/数值/并发矩阵和 GPU sanitizer，并用 Nsight 解释代表 shape 的性能边界。

---

## 5. 项目四：`tiny-llm`

### 5.1 最终定位

一句话：

> 一个可加载真实 GGUF 权重、执行量化 Transformer decode、管理连续/分页 KV，并通过
> C ABI 提供 Serving 数据面的单 GPU C++/CUDA runtime。

这是旗舰项目，优先级高于继续扩展辅助仓。

### 5.2 当前关键边界

必须持续区分：

```text
paged KV storage/scatter/gather
≠ direct paged attention

CUDA Graph on/off
≠ 所有 decode 路径都有同等收益

W8A16
≠ Tensor Core INT8

真实模型能生成
≠ 与外部引擎同量化、公平性能对照
```

### 5.3 M1：模型与独立 oracle

关联任务：`TLLM-P0-001..003`。

`TLLM-P0-001`：

- 固定至少两个受支持模型/变体的 identity、revision、hash；
- 明确 GGUF tensor、quantization type、tokenizer/chat template 支持；
- unsupported architecture/tensor 返回明确错误；
- 模型文件不提交仓库；
- 真实模型 test 与 synthetic test 分离。

`TLLM-P0-002`：

- 建立 paged/contiguous synthetic KV；
- reference 直接从逻辑 K/V 序列计算，不调用 production scatter/gather；
- 覆盖 layer/request/kv_head/position/dim；
- 覆盖 block boundary、last partial block、非连续 block id、复用后清零；
- 比较 logits/attention output/token，而不只比较 copied bytes。

`TLLM-P0-003`：

- CUDA Graph correctness 不依赖下载模型；
- eager/graph 使用同一 deterministic synthetic inputs；
- 覆盖 capture、replay、shape/capacity 变化和 fallback；
- graph failure 不得静默切换后仍报告 graph success。

阶段成果：

> 建立 direct paged 改造前的独立 correctness 防线。

### 5.4 M2/M3：direct paged decode

关联任务：`TLLM-P0-004/005`，设计入口为 TLLM-DPA 和 TLLM-PSRV-ABI。

设计必须冻结：

- kernel signature；
- Q/K/V/output layout；
- block table layout 和 stride；
- physical block address 公式；
- max blocks、block size、context length；
- GQA/MQA head mapping；
- causal/valid-position mask；
- accumulation precision；
- workspace；
- stream；
- fallback 和 error。

建议拆分：

1. header/contract/reference；
2. standalone direct paged kernel；
3. differential tests；
4. Transformer dispatch；
5. C ABI additive change；
6. `paged-serving` dual-compatible integration；
7. default switch；
8. compatibility cleanup。

验收：

- 不 gather K/V 到完整 contiguous scratch；
- output 与 independent oracle 对齐；
- profiler 证明命中 direct path；
- unsupported shape 使用明确 fallback；
- old continuous strategy 不回退；
- FFI size/alignment/field order tests 通过；
- allocation/step/free 生命周期通过。

阶段成果：

> 可以讲一个真实数据布局与 kernel/runtime/ABI 联动的深改造，而不是只讲 isolated kernel。

### 5.5 M4：长上下文 A/B 和归因

关联任务：`TLLM-P1-001`。

固定：

- model/revision/hash；
- prompt/output token；
- sampling/seed；
- continuous 与 paged 的 capacity；
- block size；
- eager/graph；
- warmup、独立进程、交错顺序；
- GPU power/clock 条件（能控制时）；
- raw samples 和 exact commit。

指标：

- TTFT；
- TPOT；
- decode tok/s；
- peak/steady memory；
- scatter/gather/direct kernel time；
- HBM traffic；
- occupancy/stall；
- correctness/token divergence。

必须允许结果为：

- direct 更快；
- 基本持平；
- 某些短 context 更慢；
- 不收敛。

阶段成果：

> 性能结论绑定 workload，不把 direct addressing 自动等同于加速。

### 5.6 M5：Serving 数据面

与 `paged-serving` 集成时必须证明：

- C ABI 双源一致；
- request/block table 参数来自真实 scheduler；
- cancel/timeout 后 runtime state 可回收；
- max capacity 与 buffer size 不越界；
- token/result/error 能稳定返回；
- real backend test 不是 mock；
- 失败时资源和 metric 一致。

### 5.7 面试展示

建议主故事：

> 原实现已经有分页 KV 存储，但 decode 会 gather 回连续 scratch。我先建立不依赖 production
> scatter/gather 的 oracle，再冻结 block table 和 GQA 地址公式，实现 direct paged kernel，
> 分阶段接入 Transformer 与 C ABI，最后用 profiler 判断减少 copy 是否转化为 TPOT 和显存收益。

常见追问：

- GGUF/量化如何加载？
- KV shape 和生命周期？
- PagedAttention 与分页 allocator 的区别？
- block size 权衡？
- direct addressing 的性能代价？
- CUDA Graph 捕获限制？
- C ABI 如何演进不破坏下游？
- 为什么外部 baseline 不一定公平？

简历安全表述模板：

> 构建单 GPU C++/CUDA LLM runtime，覆盖 GGUF/W8A16、Transformer decode、KV 和 C ABI；
> 使用独立 synthetic oracle 将分页 KV 从 gather-to-contiguous 路径升级为 direct paged
> decode，并在固定模型/硬件/workload 下报告 correctness、TPOT、显存和 Nsight 归因。

只有 direct path 和正式证据真实完成后，才能使用模板后半句。

---

## 6. 项目五：`paged-serving`

### 6.1 最终定位

一句话：

> Rust Serving 控制面，负责 OpenAI-compatible HTTP/SSE、admission、continuous-batching
> scheduler、Paged KV ownership、取消、背压、可观测性和真实后端评测。

它不是：

- GPU kernel 项目；
- 仅靠 scheduler vector 就证明 fused batch compute；
- 三个并发请求通过就等于生产容量。

### 6.2 M1/M2：请求生命周期

关联任务：`PSRV-P0-001..004`。

请求状态机至少包含：

```text
admitted
  → queued
  → running/prefill
  → running/decode
  → completed

任意未终态
  → cancelled | timed_out | failed
```

所有权清单：

- request record；
- input/output tokens；
- BlockPool blocks；
- backend sequence/runtime handle；
- scheduler queue slot；
- SSE/fan-in channel；
- metrics span。

取消触发：

- client disconnect；
- explicit cancel；
- timeout/deadline；
- server shutdown；
- backend error；
- receiver/channel closed。

完成条件：

- scheduler 不再选择 cancelled request；
- block/backend/channel 被释放；
- active/queued/allocation 指标回基线；
- duplicate cancel 幂等；
- late backend token 不泄露到新 request；
- error code/HTTP status/SSE termination 可解释。

### 6.3 M2/M3：bounded backpressure

关联任务：`PSRV-P0-002`。

必须冻结：

- 每 request channel capacity；
- fan-in/global queue capacity；
- send 满时 wait/drop/cancel 的策略；
- slow client 的 deadline；
- scheduler 是否允许被网络发送阻塞；
- token buffer memory 上限；
- fairness/HOL 指标。

测试：

- 一个慢客户端 + 多个正常客户端；
- receiver 不读取；
- receiver 中途断开；
- backend 突发产生 token；
- channel 满；
- server shutdown；
- 内存/blocks/active requests 回基线。

阶段成果：

> 可以解释 backpressure 是资源和调度问题，不只是把 channel 改成 bounded。

### 6.4 M3：指标契约

关联任务：`PSRV-P0-003/004`、`PSRV-P1-001`。

必须定义：

- arrival/admission/queue/prefill-first/decode-token/flush/complete 时间戳；
- TTFT 是否到 server first token 或 client received first event；
- TPOT 与 ITL 的关系；
- token count 覆盖率；
- cancelled/failed request 是否进入 latency 分位数；
- 429、timeout、5xx、disconnect 的独立计数；
- queue depth、active requests、allocated/free blocks；
- request id 与 raw record。

禁止：

- 用 SSE chunk 间隔直接命名 token-level ITL，除非一 chunk 一 token 且已验证；
- 丢弃失败请求后只报告成功延迟；
- 用平均值替代 p95/p99；
- 用 mock backend 生成 GPU throughput。

### 6.5 M4/M5：真实后端和容量曲线

关联任务：`PSRV-P1-002..004`。

执行顺序：

1. build/link `tiny-llm`；
2. ABI layout/size/alignment test；
3. 单请求 deterministic e2e；
4. 多请求并发 correctness；
5. cancel/disconnect/timeout；
6. closed-loop concurrency sweep；
7. Poisson/open-loop arrival-rate sweep；
8. fairness/HOL；
9. external baseline；
10. profiler 与 bottleneck 解释。

矩阵至少包含：

- prompt length；
- output length；
- concurrency；
- arrival rate；
- block size/KV strategy；
- backend；
- sampling；
- model/quantization；
- stream mode；
- success/failure/cancel。

输出：

- TTFT p50/p95/p99；
- TPOT/ITL（按契约）；
- request/s、token/s；
- error/429/cancel/timeout；
- queue wait；
- GPU utilization；
- memory/BlockPool；
- convergence；
- raw request rows。

阶段成果：

> 可以画出系统从低负载到饱和的容量曲线，并解释瓶颈位于 scheduler、CPU、ABI、GPU、
> KV、网络还是慢客户端。

### 6.6 面试展示

主故事：

> 我把 Rust 作为控制面，C++/CUDA runtime 作为数据面。优化不是从 QPS 开始，而是先冻结
> request ownership、cancel 和 backpressure，再定义 TTFT/TPOT 的时间戳，最后在真实 backend
> 上做到达率和并发矩阵，保留失败请求并追踪 BlockPool/runtime 是否回到基线。

常见追问：

- continuous batching 如何工作？
- scheduler batching 是否等于 GPU batch？
- slow client 如何影响其他请求？
- cancellation 如何跨 FFI？
- 429 和排队如何取舍？
- open-loop 与 closed-loop 压测差异？
- TTFT/TPOT/p99 如何定义？
- 如何检测 head-of-line blocking？

简历安全表述模板：

> 构建 Rust LLM Serving 控制面，通过 C ABI 接入 `tiny-llm`，实现请求生命周期、分页 KV
> ownership、主动取消和 bounded backpressure；在真实后端上采集并发/到达率对应的
> TTFT/TPOT/p99/吞吐/错误率/显存曲线并验证资源回收。

只有真实 backend 和正式矩阵完成后，才能使用模板最后一句。

---

## 7. 项目六：`kvtier`

### 7.1 最终定位

一句话：

> 对 SGLang HiCache/KV tiering 做 pinned-upstream、可审计的 correctness 和性能实验，
> 用于讨论 GPU/host/storage 层级、回载路径和未来 disaggregation。

它不是：

- 自研生产 KV tiering engine；
- `tiny-llm` 或 `paged-serving` 的当前依赖；
- 没有多机实测时的 disaggregated serving 性能项目。

### 7.2 M0：固定上游事实

关联任务：`KVT-P0-001`。

记录：

- SGLang repository URL、commit、dirty；
- HiCache 相关 symbols 和调用链；
- issue/PR 状态及复核日期；
- backend/config/env names；
- 当前仓是 wrapper、patch、workload 还是 report；
- 与上游默认行为的差异。

上游更新后不得沿用旧 symbol/claim，先判断结果是否 stale。

阶段成果：

> 可以准确区分“上游已实现”“本仓配置调用”“本仓新增”“设计建议”。

### 7.3 M1：schema 与 CPU-only gate

关联任务：`KVT-P0-002/004`。

结果至少记录：

- commit/dirty；
- Python/SGLang/CUDA/driver；
- GPU；
- model identity/hash；
- server/client/config；
- warmup/iterations；
- workload；
- IO backend；
- KV dtype；
- W/E/R/P 分解；
- failure/OOM/not-converged；
- raw artifact hash；
- limitations/claims。

CPU-only CI 只验证：

- schema；
- parser；
- aggregation；
- report generation；
- invalid/missing fields；
- audit links。

不能把它称为 GPU correctness。

### 7.4 M2：host DRAM 回载 correctness

关联任务：`KVT-P0-003`。

测试思想：

1. 构造可识别 KV pattern；
2. GPU/host 层之间 write/evict/reload；
3. 验证 position/head/dim 未错位；
4. 验证 dtype conversion；
5. 覆盖 partial block、reuse、capacity pressure；
6. 与不 offload 的 reference 比较输出/token；
7. 错误和资源回收可见。

阶段成果：

> 可以证明回载语义，而不只是 server 能启动。

### 7.5 M3/M4：单卡实验矩阵

关联任务：`KVT-P1-001/002`。

固定：

- model、prompt/output；
- GPU/host memory；
- upstream commit；
- KV dtype；
- IO backend；
- cache capacity；
- concurrency；
- warmup/repetition；
- raw records。

报告：

- write/evict/reload/prefetch 时间；
- hit/miss；
- token/TTFT/TPOT；
- GPU/host memory；
- IO bytes/bandwidth；
- correctness；
- failure/OOM；
- 不收敛。

阶段成果：

> 可以讨论 W/E/R/P 中哪个阶段主导、dtype/IO backend 如何影响回载，而不是宣传生产吞吐。

### 7.6 面试展示

常见追问：

- 为什么 KV cache 适合分层？
- offload 与 recompute 如何权衡？
- eviction/prefetch 如何避免 stall？
- host bandwidth/PCIe 如何影响 TPOT？
- prefix reuse 与 tiering 的关系？
- disaggregated prefill/decode 需要哪些网络和 ownership 契约？

简历安全表述模板：

> 基于 pinned SGLang HiCache 构建可审计 KV tiering 实验，验证 host DRAM 回载的
> position/head/dtype 正确性，并按 W/E/R/P 分解单卡 IO backend、KV dtype、延迟和显存。

---

## 8. 项目七：`open-infra-ai`

### 8.1 最终定位

一句话：

> 作品集控制面：维护七仓边界、跨仓契约、证据生命周期、公开索引和面试导航。

它不作为简历中的独立技术项目，不产生 kernel 或 Serving 性能数字。

### 8.2 M0/M1：事实和边界

必须维护：

- repository status registry；
- 两条旗舰主线；
- C ABI 双源；
- cross-repo semantic contracts；
- current vs archive；
- live repo URL；
- limitations；
- 每个 claim 的证据入口。

阶段成果：

> 面试官能够在 90 秒内找到 flagship、code、benchmark、profile 和 limitations。

### 8.3 M2/M3：evidence lifecycle

新正式结果使用：

```text
manifest.json
raw/
derived/
checks/
README.md
```

状态：

```text
draft → candidate → verified → published
                         ↓
                       stale

任意状态 → revoked
资源不足 → blocked
统计失败 → not_converged
```

组织仓只链接：

- exact commit；
- raw artifact；
- verified/published result；
- allowed/prohibited claims；
- stale/revoked 原因；
- reviewer。

阶段成果：

> 可以证明你不仅会跑 benchmark，还会治理结果、回归和失效。

### 8.4 M4/M5：跨仓 demo

维护三条入口：

1. 90 秒作品集入口；
2. `HTTP → scheduler → KV → ABI → CUDA → SSE` 旗舰证据链；
3. `reference → cuflash/trifuse → benchmark → profiler` Kernel 对照链。

每个链接失效、仓库更名或结果 stale 时同步修复。

### 8.5 面试展示

不要说“我写了很多文档”，而要说：

> 我为跨仓实验建立了 manifest、raw artifact hash、状态晋级和 stale/revoked 规则，确保
> 简历数字可以定位到 exact commit、硬件、workload、correctness 和 profiler。

常见追问：

- 如何避免 benchmark cherry-picking？
- 代码变更后旧结果怎么办？
- raw 和 derived 如何管理？
- 外部 baseline 如何定义公平？
- failed/OOM/not-converged 是否保留？

---

## 9. 七仓阶段性成果总表

### 9.1 第一阶段：可信基础

完成内容：

- 各仓 build/test/skip 语义；
- independent reference；
- CPU/GPU 证据分离；
- exact commit/environment；
- 文档不夸大。

面试可讲：

> 我先审计并修复测试和证据边界，避免把 CPU build、GPU correctness、microbenchmark
> 和 end-to-end serving 混为一谈。

还不能讲：

- direct PagedAttention；
- 生产 Serving；
- 全面性能领先。

### 9.2 第二阶段：Kernel 与 runtime 正确性

完成内容：

- SGEMM/attention/paged KV/custom op correctness；
- sanitizer；
- workspace/stream；
- fake/export；
- ABI layout。

面试可讲：

> 我能定义 kernel、framework op 和 FFI 的输入/输出/布局/生命周期，并用独立 oracle
> 和 sanitizer 验证。

### 9.3 第三阶段：一个旗舰深改造

默认：

```text
tiny-llm direct paged decode
```

替代（只在 Kernel 岗优先且时间不足时）：

```text
cuflash reentrant workspace + Nsight
```

面试可讲：

> 我完成了一个跨 contract、实现、测试、fallback 和性能归因的深改造。

### 9.4 第四阶段：真实 Serving

完成内容：

- cancel/backpressure；
- real backend；
- failure regression；
- capacity curve；
- telemetry；
- external baseline。

面试可讲：

> 我能把一个请求从 HTTP 追到 GPU，并验证取消、慢客户端、饱和和失败时的资源与指标。

### 9.5 第五阶段：外部验证

完成内容：

- 一个上游 issue reproduction、review 或 PR；
- 第三方可运行的 evidence package；
- 公开 demo/文章/面试录像（脱敏）。

面试可讲：

> 除了自有仓库，我还把复现或修复带到真实社区上下文，并处理外部 review。

---

## 10. 面试中的搭建关系

### 10.1 面试官问“为什么做这么多仓？”

回答结构：

```text
不是七个产品
  → 两个旗舰主线
  → 每仓只负责一类可验证能力
  → 只有 tiny-llm/paged-serving 有运行时依赖
  → 其余是基础、横向对照、上游研究和证据治理
```

### 10.2 面试官问“系统怎么跑？”

回答：

```text
client
  → paged-serving HTTP/SSE
  → admission/scheduler/BlockPool
  → C ABI
  → tiny-llm model/KV/decode
  → CUDA kernels
  → token
  → bounded streaming
```

再补：

- `cuflash` 用于解释 attention 深度；
- `trifuse` 用于解释 PyTorch/Triton 集成；
- `cuda-foundations` 用于解释 GPU 基础和 measurement；
- `kvtier` 用于讨论更大模型的 KV 层级；
- `open-infra-ai` 用于定位证据。

### 10.3 面试官问“这些项目之间复用了什么？”

只说真实复用：

- `tiny-llm` / `paged-serving`：C ABI 和 runtime data；
- 所有仓：证据 manifest/measurement methodology；
- attention/KV 概念、shape 命名和语义 contract。

不要声称当前不存在的代码复用：

- `cuflash` 直接链接 `tiny-llm`；
- `trifuse` 进入 Rust Serving；
- `kvtier` 被 `paged-serving` 调用。

### 10.4 面试官问“你个人做了什么？”

按四列回答：

| 类别 | 回答 |
|------|------|
| 决策 | 你定义的 contract、取舍和停止规则 |
| 实现 | 你实际修改的 symbols/paths/PR |
| 验证 | 你亲自运行并理解的 correctness/profile/benchmark |
| 限制 | 未运行、失败、硬件边界和不支持项 |

Agent 生成代码不等于你的个人理解。你必须能够白板解释核心数据布局、状态机、profile 和
失败路径。

---

## 11. 每次里程碑结束的成果包

```yaml
project:
milestone: M0 | M1 | M2 | M3 | M4 | M5 | M6
repository:
commit:
dirty:
task_ids:
design_decisions:
  - <decision>
correctness:
  status: passed | failed | blocked | not_run
  commands:
    - <command + exit code>
gpu:
  device:
  tests_executed:
sanitizer:
  status:
performance:
  status: verified | not_converged | not_run
  comparison_key:
  raw_artifacts:
profiling:
  tools:
  findings:
integration:
  upstream_downstream:
failure_paths:
  - <case + result>
allowed_claims:
  - <claim>
prohibited_claims:
  - <claim>
limitations:
  - <limitation>
next_task_id:
```

任何一栏缺失，都不能用一句“项目已完成”代替。

---

## 12. 推荐执行顺序

### 12.1 默认 Runtime/Serving 路线

```text
TLLM-P0-002
  → TLLM-P0-004
  → TLLM-P0-005
  → TLLM-P1-001
  → PSRV-P0-001
  → PSRV-P0-002
  → PSRV-P0-003/004
  → PSRV-P1-002
  → PSRV-P1-003/004
  → upstream contribution
```

### 12.2 Kernel 路线

```text
CUF-P0-001
  → CUF-P0-002/003
  → CUF-P0-004
  → CUF-P1-001/002
  → CUDA-P1-001/003
  → TRI-P0-001/002
  → TRI-P1-005/007
  → upstream kernel issue/PR
```

### 12.3 CPU-only 等待路线

```text
TLLM-P0-002 oracle preparation
  + PSRV-P0-001..004 lifecycle tests
  + TRI-P0-001/002 fake/export
  + KVT-P0-001/002/004 audit/schema
  + evidence manifest validation
```

以下保持 `blocked`：

- GPU correctness；
- sanitizer；
- Nsight；
- 正式性能数字；
- 多 GPU/NCCL/RDMA；
- FP8/FP4 hardware claims。

---

## 13. 最终面试材料清单

### 必须

- 一张七仓架构图；
- 一条旗舰请求生命周期；
- 一个 direct paged 或 workspace 深改造；
- 一份 independent correctness matrix；
- 一份 profiler 报告；
- 一份端到端 serving matrix；
- 一个失败/取消/资源回收案例；
- 一张 limitations/prohibited claims；
- 一个上游协作链接。

### 加分

- Triton/PyTorch export；
- KV tiering W/E/R/P 分解；
- 性能回退 RCA；
- stale/revoked 结果示例；
- 公平 baseline 的配置 diff；
- 第三方复现。

### 不需要

- 第八个练习仓；
- 没有真实设备的 FP4/RDMA 数字；
- 七个项目各写一条同权重简历 bullet；
- 所有热门技术各做一个浅 demo；
- 为看起来复杂而加入 Kubernetes、Ray、NCCL。

---

## 14. 最终判断

项目改进的目标不是让每个仓库都“功能更多”，而是形成以下可防守链路：

```text
CUDA 基础
  → Attention/Triton correctness
  → LLM runtime direct paged deep change
  → Rust Serving lifecycle and capacity
  → KV tiering research boundary
  → evidence provenance and external review
```

做到这一点后，面试官看到的不是“转行者做了七个练习”，而是：

> 一个能跨 Kernel、Runtime、Serving 和性能证据工作的系统工程师；知道哪些结果是真的，
> 哪些只是理论，能够解释数据布局、生命周期、故障路径、性能归因和工程取舍。
