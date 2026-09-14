# TLLM-P0-002 paged/contiguous synthetic oracle（2026-09-14）

## 交接压缩格式

```yaml
task_id: TLLM-P0-002
status: complete
repository: open-infra-ai/tiny-llm
base_branch: master
base_commit: 2b15fb2b6e16671a91c648a5e1b3cf0666099b3f   # = backlog 审查参考 commit
current_branch: tllm-p0-002-paged-oracle
current_commit: bff2af6
dirty: false
complexity: L3
dependencies: none
changed_files:
  - tests/paged_attention_oracle.h        # 新增：纯 host 独立参考 + 冻结 contract
  - tests/test_paged_oracle.cpp           # 新增：kernel 级 / layer 级 / contract 测试
  - src/transformer.cpp                   # +12 行：forwardPaged 块表长度校验
  - src/kv_cache.cpp                      # +9 行：create() 清零 append_pos_
  - CHANGELOG.md
decisions:
  - 只做设计包 §4.5 的第 1 步 Oracle PR（reference / layout tests / invalid tests）；
    不写 direct kernel，不改 FFI/C ABI。
  - test seam 使用既有 kernels/*.cuh（测试目标已 include kernels/），不新增 public API。
  - layer 级强门禁改为「按冻结公式读回 pool，与连续 KV cache 逐层位级比较 K/V」：
    先前的最终 hidden 比对受 fp16 输出量化 + 残差主导影响，对真实 bug 不敏感
    （实测会把注入的 scatter/layer 步长 bug 判为通过），已废弃该做法。
  - 块表长度 contract 下移到 forwardPaged 入口：这是「invalid table length」验收项在
    无 GPU/无 GGUF 条件下唯一可安全测试的方式（否则只能测未定义行为）。
  - append_pos_ 清零属根因修复，而非修改既有测试来掩盖。
verified:
  - ./build/tiny_llm_tests：195 passed / 11 skipped / 0 failed
  - ./build/tiny_llm_tests --gtest_filter='PagedOracle*'：8 passed
  - compute-sanitizer --tool memcheck --gtest_filter='PagedOracle*'：0 errors
  - clang-format 18.1.8（CI 同版本）--dry-run --Werror 全仓：0 violation
  - CI Format job：pass
  - 变异检验：scatter 忽略 position 被 kernel 级增量测试捕获；
    attentionPaged 层步长丢 max_num_blocks 被 layer 级逐层 K/V 门禁捕获（报 layer 1）
failed: []
not_run:
  - 11 项需要真实 GGUF 模型的既有测试（本机未提供 TLLM_GGUF_TEST_MODEL）；
    未运行项不作通过声明
  - 任何 benchmark / profiler / serving 实验：本任务不产生性能证据
artifacts:
  - PR open-infra-ai/tiny-llm#4
open_questions:
  - forwardPaged 与 ffi.cpp 各自算一遍 required_blocks，重复口径；TLLM-P0-004 的
    direct kernel 是否应把 table_length 显式作为参数并只保留一处校验？
  - PagedKVCacheView 的 visible_blocks 目前仅用于校验，gather 长度实际由
    position/num_tokens 推导；设计包 §4.2 需决定 table_length 与 visible_tokens 的关系。
next_task_id: TLLM-P0-004 PR-5（三路 kernel benchmark；通过后把 TLLM_PAGED_ATTENTION 默认值改为 auto）
next_exact_command: |
  # 设计包已批准（tiny-llm#5 §12），8 项决议全部关闭，实现不再被阻塞。
  # PR-1 是唯一有真实爆炸半径的 PR（改现有热路径 kernel），先做它并请第二方复核。
  cd tiny-llm && git fetch origin
  git checkout master && git pull --ff-only            # 先合并 #4（oracle）与 #6（C ABI 校验）
  git checkout -b tllm-dpa-pr1-tile-loop
  # 改动范围仅 kernels/attention.cu：把 decode 的 tile loop 抽成 __device__ 模板
  # + 寻址策略（连续版改用它，行为不变）
  cmake -S . -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_TESTS=ON
  cmake --build build -j"$(nproc)"
  ./build/tiny_llm_tests --gtest_filter='PagedOracle*'   # 必须与重构前逐元素一致
  ./build/tiny_llm_tests                                 # 全量不得减少通过数
  ./build/tiny_llm_kernel_bench                          # PR-1 必须附前后对比证明无回归
```

## 同日追加：TLLM-P0-004 设计包已批准 + C ABI 边界缺陷已修

### 1. 设计包（`open-infra-ai/tiny-llm#5`）

- 文件 `docs/architecture/direct-paged-decode-attention-design.md`（base `2b15fb2`）。
  按 `L3_L4_DESIGN_REVIEW_PACKAGES.md` §3 模板填充，覆盖 G0–G8 与 §4（TLLM-DPA）
  的全部必答项；已冻结地址公式、stride、整数宽度、`visible_tokens = position + 1`
  不变量、`visible_tokens = 0`、非法块 id 的零行语义。
- **Decision: `approved`（2026-09-14）**，8 项待决议题全部关闭（Q1 flat 参数 /
  Q2 抽取共享 tile loop + 强制性能不回归检查 / Q3 冻结零行语义 / Q4 逐元素严格相等 /
  Q5 校验位置改到 C ABI 边界 / Q6 收益不得外推 TTFT-TPOT / Q7 scratch 保留 + follow-up /
  Q8 取消不可达的几何回落）。
- **独立性缺陷已记录在 §12**：本包由作者编写、也由作者汇总决议，不满足
  「实现 Agent 不应成为唯一 reviewer」。**PR-1 是唯一有真实爆炸半径的决定**
  （改现有热路径 kernel），合并前应由第二方复核其 diff 与前后性能数据。

### 2. 本轮新发现：C ABI 模型几何越界读（`open-infra-ai/tiny-llm#6`）

- 现象：`num_heads` 不被 `num_kv_heads` 整除时，attention kernel 的
  `kv_head = q_head / (num_heads / num_kv_heads)` 越界，最后一个 token 的 K/V 读
  越过缓冲末尾。最小复现 + Compute Sanitizer 证实（`Hq=14/Hkv=3`，13 errors，
  `cudaDeviceSynchronize -> unknown error`，CUDA 上下文被毒化）。
- 范围：`validateModelConfig` 早已实现该校验，但全仓只有 `InferenceEngine::Load`
  调用；C ABI 路径 `tinyllm_load`（分页/策略 1 与 paged-serving 走的那条）不调用，
  且 `extractModelConfig` 对异常元数据是补默认值而非报错。
- 修复：在 `tinyllm_load` 的 `extractModelConfig()` 之后、`loadGGUF()` 之前调用
  `Validator::validateModelConfig`；一处覆盖整条 C ABI 路径，对合法模型零行为变化。
- 新增 `tests/test_validator.cpp`（纯 host，无 GPU 也运行；`Validator` 此前零覆盖）。
  变异检验：移除校验调用后边界测试失败。
- 该修复与 TLLM-P0-004 解耦，可独立合并。

### 3. TLLM-P0-004 实现：门禁先否决，后按 issue #8 翻转

- **PR-1（抽取共享 decode tile loop）先被它自己的门禁否决**。设计包 §10 预先写明
  "出现可测回归则退回复制实现"，而抽取实测给生产 kernel `attention_decode` 带来
  **+1.4~2.3% 的可复现回归**（两轮独立重复分别 7/8 与 6/8 几何为正，D=128/S=512 达
  +4.9%）。完整证据与三次测量方法修正见设计包 §10.1。
  - 测量陷阱（后人勿重蹈）：GPU 空闲时 SM 时钟停在 900/3090 MHz，小 kernel 拉不动
    boost，逐次差异可达 50%；scratch 程序误编到 sm_75 而非生产的 sm_120；现成 harness
    的 host-int 重载每次调用带一次 4 字节 H2D memcpy。
  - 可信方法：时钟预热 + `-arch=native` + device-int 重载 + 大 S + 顺序平衡交替 +
    **新旧 kernel 编入同一进程交替调用**（消除跨二进制代码布局混淆）。
  - 两种规避写法（策略按值/按引用、无效行返回零行以消分支）均未改变结论。
- **随后按 issue #8 翻转该取舍：接受回归，改回共享循环**（设计包 §10.2）。理由是
  复制方案唯一的风险（两份实现漂移）已由"逐位相同"门禁自动覆盖——**安全来自门禁，
  不来自副本数量**；+1.4~2.3% 落在单 kernel，端到端约 0.1~0.3%，不划算。
  最终形态：`decode_online_softmax` 模板 + `ContiguousRows` / `PagedRows` 取址策略，
  无效行返回共享内存零行（循环内无分支）。
- **PR-2 已提交**：`open-infra-ai/tiny-llm#7`（base = #4，堆叠），含两个 commit。
  - 主门禁：direct 与 legacy 在同一 pool/块表/输入下输出**逐位相同**（12 组几何 × 3 seed），
    另对照 TLLM-P0-002 的独立 oracle；sanitizer 0 error。
  - 连续路径数值**逐位不变**（10 组几何的 fp16 位模式指纹，抽取前后一致）。
  - **变异检验三项**：① 块内偏移写错 → 逐位门禁捕获；② 去掉 `table_len` 防护 → 短块表
    用例捕获；③ **在共享循环里丢掉 online rescale（两条路径同等出错）→ 逐位门禁通过、
    独立 oracle 捕获**。第三项证明"共享归约必须配独立参考"，否则该类错误整体漏过。
  - 边界：只加 kernel 与 kernel 级测试，**未**接入 Transformer dispatch（PR-3），
    生产 decode 路径行为不变；不产生性能数字。
  - **CI**：`ci.yml` 的 `pull_request.branches` 匹配的是 base 分支，堆叠 PR 不会自动
    触发 CI。已用 `workflow_dispatch` 在分支 head 手动跑（翻转前的 bb0f124 与翻转后的
    commit 各一次）。#4 合并后 base 会自动重定向到 master。

### 4. PR-3（runtime dispatch）已提交

- **`open-infra-ai/tiny-llm#9`**（base = #7，堆叠）。`attentionPaged` 的 decode 分支按
  `TLLM_PAGED_ATTENTION` 分发：`direct` 时直接调用 `attention_decode_paged` 并**跳过
  gather**；`legacy` 保留原路径；`auto` 当前等价于 `direct`。
  - **默认（未设置）= legacy ⇒ 不改变生产默认行为**（设计包 §11）。PR-5 通过后才改 `auto`。
  - 非法取值显式报错，不静默回退；显式 legacy 打一次 `TLLM_WARN`（便于结果包区分路径）。
  - 开关**不做进程级缓存**：每次调用解析（约 20 ns、无堆分配），使 `setenv` 在测试中
    即时生效 → 不需要为测试暴露 reset seam。只影响 strategy 1 的 decode。
- 测试手法值得复用：把共享 `k_scratch`/`v_scratch` 预填哨兵值，跑一次 decode 后检查
  scratch 是否被写——**直接观测走了哪条路径**，比比对输出更不容易自欺。
- 变异检验 3 项全被捕获：忽略开关一律 direct（3 项失败）；dispatch 处 `table_len`
  传 0（层级逐位比对失败，max|diff| 0.011）；非法取值静默回退（对应用例失败）。
- 全量 208 passed / 11 skipped；sanitizer 0 error；clang-format 0 violation；
  CI 手动 dispatch 通过。

### 5. 当前 PR 依赖

| PR | 内容 | 阻塞关系 |
|----|------|----------|
| tiny-llm#4 | TLLM-P0-002 oracle | #7 的 base |
| tiny-llm#5 | TLLM-P0-004 设计包（已批准；§10.1 门禁否决、§10.2 翻转、§11 开关语义） | 无 |
| tiny-llm#6 | C ABI 几何校验 | 无，可独立合并 |
| tiny-llm#7 | TLLM-P0-004 PR-2 direct kernel（含共享归约抽取） | 依赖 #4 |
| tiny-llm#9 | TLLM-P0-004 PR-3 dispatch + 开关 | 依赖 #7 |
| tiny-llm#10 | TLLM-P0-004 PR-5 三路 kernel benchmark（**结论：不改默认值**） | 依赖 #9 |
| ai-infra-interview-prep#9 | 本交接记录 | 无 |

合并顺序：**#4 → #7 → #9 → #10**（#6 可任意时刻独立合并）。

### 6. 下一步

**PR-5 已完成并给出否定结论（见 §7），`TLLM_PAGED_ATTENTION` 默认值保持 `legacy`。**

下一个有价值的任务不是继续推 direct，而是消除它和 legacy 共同的真实瓶颈：
`kernels/attention.cu::decode_online_softmax` 第 4 步（每个线程固定一个 `d`、遍历整个
tile）对 V 的访问——ncu 显示两条 attention kernel 的 SM throughput 都 < 1%、
long-scoreboard stall 40%–46%。修掉它之后再重测三路，direct 的取舍才有意义。

在此之前若要收口能力边界文档（设计包 §10 的 PR-6），只能引用
`docs/performance/results/2026-09-14-rtx5070ti-dpa.md` 的已归档证据。

### 7. PR-5（三路 kernel benchmark）已提交 —— 结论：不改默认值（2026-09-14）

```yaml
task_id: TLLM-P0-004 PR-5
status: complete            # 交付完成；但「改默认值」的门禁未通过
repository: open-infra-ai/tiny-llm
base_branch: tllm-dpa-pr3-dispatch   # PR #9 head（堆叠）
base_commit: ce93564
current_branch: tllm-dpa-pr5-benchmark
current_commit: 4fc897e
dirty: false
complexity: L3
change: 仅 src/kernel_bench.cpp + docs/performance/**；未改 kernel / FFI / transformer.cpp
changed_files:
  - src/kernel_bench.cpp                              # +601：--dpa-bench 三路 harness
  - docs/performance/index.md
  - docs/performance/benchmark-methodology.md         # §8 修正 ncu 可用性 + --dpa-bench
  - docs/performance/results/2026-09-14-rtx5070ti-dpa.md
  - docs/performance/results/data/2026-09-14-rtx5070ti-dpa.{raw.jsonl,summary.json}
decisions:
  - 默认值**不改**（仍 legacy）。设计包 §10/§11 规定只在 PR-5 通过后改 auto；实测未通过，
    因此 src/transformer.cpp 未改，无生产行为变化。
  - 采样用「每样本 100 次调用」（而非 §9 字面值 implied 的 10 次）：reps=200 + 每样本 10 次
    时 32/32 shape 全部 CV>10%；收敛阈值未改，反例保留在报告 §1.1。
  - 收敛门禁只约束三条对比路径（legacy/contiguous/direct）；gather_k/gather_v 是 §9 规定的
    辅助诊断，单独报告 CV 但不参与 shape 级判定。
verified:
  - legacy vs direct 逐位相等 32/32（max|diff| = 0），且先于计时
  - 全量 tiny_llm_tests：208 passed / 11 skipped（skip 均为需真实 GGUF 的既有用例）
  - compute-sanitizer --tool memcheck：paged 三 suite 0 error；新 harness 在 S=8/512/2048 亦 0 error
  - clang-format 18.1.8（CI 同版本）全仓 --dry-run --Werror：0 violation
  - docs npm run build：exit 0
  - 构建 -DCMAKE_CUDA_ARCHITECTURES=native；cuobjdump --list-elf 实测 cubin = sm_120
  - CI workflow_dispatch 已触发：run 34834253209
failed: []
not_run:
  - CUDA Graph 下的三路复测（报告已明确不外推小窗口收益）
  - nsys timeline；prefill / batched decode / 非本机硬件
artifacts:
  - PR open-infra-ai/tiny-llm#10
  - docs/performance/results/data/2026-09-14-rtx5070ti-dpa.raw.jsonl（5025 行，dirty_files=0）
  - .ncu-rep（按 TEMPLATE 要求放在仓库外）
open_questions:
  - decode_online_softmax 第 4 步的 V 访问是两条路径共同瓶颈；先修它再评估 direct
  - 是否保留 direct 路径与冗余 K/V scratch（设计包 §5 follow-up）
next_exact_command: |
  cd tiny-llm && git fetch origin
  git checkout tllm-dpa-pr5-benchmark && git log --oneline -3 && gh pr view 10
  # 复现三路基准（约 2 分钟；先确认 GPU 空闲）
  ./build/tiny_llm_kernel_bench --dpa-bench --warmup 20 --reps 1000 --batch 100 \
    --repeats 3 --clock-warmup 4 --seed 20260914 --out /tmp/dpa.raw.jsonl
```

**结果摘要**（RTX 5070 Ti / sm_120；clean commit `b6f6138`；被测 kernel `ce93564`）：

| visible (bs=16) | legacy (ms) | direct (ms) | leg/dir |
|---|---|---|---|
| 8 | 0.0170 | 0.0068 | **2.504** |
| 128 | 0.0189 | 0.0144 | 1.316 |
| 512 | 0.0436 | 0.0450 | **0.969** |
| 1024 | 0.0817 | 0.0881 | **0.927** |
| 2048 | 0.1510 | 0.1734 | **0.871** |

- 3 个 repeat 方向一致；交叉点在 **S≈129–512**。小窗口的正收益主要来自「3 次 launch → 1 次」。
- `legacy ≈ gather_k + gather_v + contiguous`（差 3%–9%）；gather 在 S=2048 只占 legacy 的
  8.3%，**省掉它不可能给出两位数百分比收益**。
- ncu：direct 316 µs / contiguous 280 µs（分页寻址在归约内层循环里多约 13%），gather 仅
  4.42 µs；两条 attention 的 SM throughput 均 < 1%、long-scoreboard stall 40%–46%
  ⇒ 真正的瓶颈是第 4 步的 V 访问，既不是 gather，也不是 DRAM 带宽。
- **本项目自己记录的测量陷阱再次生效**：本机 `build/CMakeCache.txt` 里缓存着
  `CMAKE_CUDA_ARCHITECTURES=75`，直接沿用会编到 sm_75 而设备是 sm_120（§10.1 陷阱 2）。
  已用 `-DCMAKE_CUDA_ARCHITECTURES=native` 重建并以 `cuobjdump --list-elf` 验证 cubin = sm_120。
- ncu 在本机**已可用**（2026-08-23 的 `ERR_NVGPUCTRPERM` 不再复现）；但
  `dram__bytes_read.sum` 返回 n/a，需改用 `dram__bytes.sum`。

### 8. TLLM-ATTN-SPLITKV（split-KV decode attention）—— PR-A/B/C 已提交（2026-09-14/15）

```yaml
task_id: TLLM-ATTN-SPLITKV
status: partial      # PR-A/B/C 完成且 CI 绿；PR-D（benchmark）未做；另发现一个更该优先的既有隐患
repository: open-infra-ai/tiny-llm
base_branch: tllm-dpa-pr5-benchmark   # 堆叠链 #4 → #7 → #9 → #10 → #11 → #12 → #13
current_branch: tllm-attn-splitkv-wiring
current_commit: 743119b
dirty: false
complexity: L4
artifacts:
  - "PR #11 设计记录（docs/architecture/decode-attention-splitkv-design.md），CI 绿"
  - "PR #12  kernel（decode_online_softmax_range + partial/combine + 两个 _splitkv 入口），CI 绿"
  - "PR #13  接线（LayerWorkspace.attn_partial + TLLM_ATTN_SPLITKV + transformer 路由），CI 绿"
verified:
  - "逐位锚点：num_splits == 1 与单遍路径逐位相同（连续 + 分页）"
  - "num_splits ∈ {2,4,8,16} 落在独立 oracle 的 2e-3 容差内；split 连续 vs 分页逐位相同"
  - "CUDA Graph：捕获后可见长度 1→96 增长并 replay，与 eager 逐位相同"
  - "全量 225 passed / 11 skipped；sanitizer 0 error；clang-format 18.1.8 clean"
  - "CI：PR #11/#12/#13 各一次 workflow_dispatch 全绿（CUDA 11.8）"
mutation_testing:
  - "combine 丢 l_i 权重 → 6 项 oracle 用例抓到，而 num_splits=1 锚点照常通过（说明必须有独立 oracle）"
  - "段范围 off-by-one → 7 项抓到，含两条锚点"
  - "去掉 m==M→1.0f → 未抓到且本就不该抓到：探针证实 __expf(0)==1.0f 精确成立"
  - "丢掉在线 rescale → **初版矩阵漏掉**（随机数据+短序列时全局 max 总在第一个 tile，old_rescale 恒为 1）；"
  - "  已补 LateMaxForcesOnlineRescaleToMatter（确定性构造后置 max）后被抓到"
not_run:
  - "PR-D：三路 benchmark + num_splits 扫描 + 结果包（本任务尚**未产生任何性能数字**）"
  - "CUDA Graph 下的生产级复测"
next_task_id: 优先修 §9 的既有隐患，其次 PR-D
next_exact_command: |
  cd tiny-llm && git fetch origin
  git log --oneline -1 tllm-attn-splitkv-wiring   # 743119b
  # 复现 PR-C 的开关语义
  TLLM_ATTN_SPLITKV=4 ./build/tiny_llm_tests --gtest_filter='PagedDispatchTest.SplitKv*'
```

设计要点（详见 PR #11）：decode 的并行度原本只有 `num_q_heads` 一个轴，`visible=2048`
时 `grid=(14,1,1)×128`、**occupancy 8.33%**，且无资源饱和（DRAM 0.44%、SM 0.72%、
L2 0.96%）。修法是加 block：`grid=(Hq, num_splits)` 切可见窗口 + combine kernel。
段范围由 device 端 `visible_tokens` 现场派生、`num_splits` 是 host 参数，因此
**grid 固定、CUDA Graph 仍可捕获**。

**注意：PR-5 收尾时"修归约第 4 步的 V 访问"的说法已被 profiler 数据推翻**——那是
"只有 4 个 warp"的症状，不是原因。

### 9. ⚠️ 一个比 split-KV 更该优先的既有隐患（未修，仅定位）

开发 PR-C 时，只要那次额外 device 分配存在，全量测试就**确定性失败**（16 项，首个是
`attention_decode_kernel` 的非法读）。证据链：

1. 读地址在 **KV pool 末尾之后 4 字节**（`pool=0x717c72800`、`fault=pool+32772`，而
   slot 只有 32768 字节）⇒ kernel 用了一个**远大于本步实际（`visible=21`）的可见长度**（约 64）；
2. 发生在**既有的连续路径**（`tests/test_paged_oracle.cpp:673` → `forward` → `attention`），
   **与 split-KV 无关**；
3. **决定性对照**：在 **PR-B 状态**（完全没有 split-KV 代码）下，只在
   `LayerWorkspace::allocate` 里注入一次独立的 8 KiB `cudaMalloc`/`cudaFree`，复现**完全相同**的失败；
4. **对构建敏感**：失败二进制连续 4/4 失败；revert + 重新应用后重建，同源码连续 6/6 通过。
   CI（CUDA 11.8）本次也是绿的。

**为什么重要**：split-KV 会增加一次 device 分配，从而扰动同一布局。也就是说这个隐患
不修，split-KV 就没有可信基础（本机绿 ≠ 可信）。它属于本项目已经修过两次的同一类
问题（`KVCacheManager::append_pos_` 未初始化、FFI `decode_len`），建议按同样的方式
单独立一个 bug 任务：最小复现 + Compute Sanitizer + 根因修复，**不要靠调整分配大小绕过**。

**现状**：本机与 CI 现在都是绿的（所以没有阻塞交付），但**隐患仍在**，只是当前构建
布局下不显形。


- 环境（当前机器，不是历史上的 RTX 3060 Laptop）：RTX 5070 Ti 16GB（sm_120）、
  CUDA 13.3.73 / driver 615.65.06、GCC 13.3、CMake 3.28.3。
- 构建：`cmake -S . -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_TESTS=ON`
  然后 `cmake --build build -j12`（exit 0）。
- 基线（同 commit 未改动时）：198 项，187 passed / 11 skipped。
  本 PR 后：206 项，195 passed / 11 skipped。11 项 skip 全部是真实 GGUF 模型门控。

## 变异检验（证明 oracle 不是恒真测试）

| 注入的 bug | 被谁捕获 | 结果 |
|---|---|---|
| `paged_scatter_blocks` 忽略 `position`（`abs = t`） | `PagedOracleKernelTest.IncrementalScatterAtNonZeroPositionsMatchesOracle` | FAILED |
| `attentionPaged` 层步长丢掉 `max_num_blocks` | `PagedOracleLayerTest.ForwardPagedKVMatchesContiguousKVPerLayer` | FAILED，精确报 layer 1 |

两处变异均已还原，`git diff` 中不含变异代码。

## 本 PR 暴露并修复的两处既有缺陷

1. `TransformerLayer::forwardPaged` 不校验块表长度。`visible_blocks` 不足时
   `paged_gather_blocks` 会越界读 `block_table`（未定义行为）。`src/ffi.cpp` 早有
   等价检查（`nb < need_blocks`），但与 kernel/层入口不同源。
2. `KVCacheManager::create` 未初始化 `append_pos_`。同一函数内 `memory_pool_` 有
   `cudaMemset`，`append_pos_` 漏了。调用方（`inference_engine.cpp`、`ffi.cpp`）
   都会先 `setAppendPos`，所以生产路径此前未暴露；但既有的
   `TransformerTest.KeyProjectionUsesItsOwnGroupSize` 依赖它恰好为 0——在本 PR 的
   测试污染分配器后该测试稳定失败，根因是未初始化 device 内存。

## 限制与不得越级的声明

- 被测路径仍是 scatter → gather → continuous attention，**不是** direct
  PagedAttention。本 PR 不改变这一点，也不改变任何能力边界文档。
- 未产生任何性能数字、profiler 结论或 serving 证据。
- layer 级最终 hidden 比对在本文件里只是次要检查：合成权重下残差主导，fp16 输出
  量化会吞掉 attention 的微小差异，因此不作为门禁依据。
