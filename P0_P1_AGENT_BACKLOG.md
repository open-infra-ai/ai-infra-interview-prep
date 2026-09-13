# AI Infra 六仓 P0/P1 Agent 执行 Backlog

> 用途：把作品集路线图继续拆成可直接委托给其他 AI Agent 的单任务包。
> 本文只定义未来工作，不代表任务已经完成，也不代表已经获得新的 GPU、性能或
> profiler 证据。

## 1. 使用方法

每次只选择一个任务 ID，并把以下“公共执行头”与该任务卡一起发送给 Agent。禁止把整份
backlog 直接交给一个低成本模型并要求一次完成。

```yaml
repository: <任务卡指定仓库>
task_id: <唯一任务 ID>
base_branch: <执行时重新确认>
base_commit: <执行时 git rev-parse HEAD>
working_tree: <clean 或列出已有改动>
complexity: <L0-L4>

execution_rules:
  - 先读取仓库 README、AGENTS.md、构建配置和任务卡列出的代码位置。
  - 先验证任务卡中的 current_evidence；若当前代码已变化，停止并报告差异。
  - 只修改 allowed_scope；发现需要越界时停止，不得顺手重构。
  - 不修改测试来掩盖实现错误，不删除失败样本，不降低安全或 CI 策略。
  - L3/L4 任务必须先提交设计包并通过评审，未批准前不得修改生产实现。
  - CPU/build、GPU correctness、performance benchmark 分开报告。
  - 缺 GPU、模型、依赖或 profiler 时写 blocked/not_run/not_measured。
  - 最终报告必须包含 diff、命令、退出码、原始证据、未运行项和剩余风险。
```

复杂度分工：

| 级别 | 默认执行者 | 合并要求 |
|------|------------|----------|
| L0-L1 | 低成本 Agent | 常规代码审查 |
| L2 | 低成本或中等模型 | 独立 reviewer 检查测试 oracle 和边界 |
| L3 | 强模型 | 先完成 `L3_L4_DESIGN_REVIEW_PACKAGES.md` 的设计门禁 |
| L4 | 强模型 + 人工/第二强模型 | 设计、实现、correctness、benchmark 分派给不同 owner |

审查参考提交如下；它们不是未来执行时可以跳过重新核对的固定基线。

| 仓库 | 审查参考提交 |
|------|--------------|
| `open-infra-ai/cuda-foundations` | `e95bcd3ca2f9928dfa75d3994fb5b91ae29f1b53` |
| `open-infra-ai/trifuse` | `2f7f46e599db7423f425b70fd131347087e53fd7` |
| `open-infra-ai/cuflash` | `55ca53b4cdb6fbed6c7ac6d2cd656eb3730ab515` |
| `open-infra-ai/tiny-llm` | `2b15fb2b6e16671a91c648a5e1b3cf0666099b3f` |
| `open-infra-ai/paged-serving` | `496611d3f9bbacdfc63a8cc92037d4e382247cf0` |
| `open-infra-ai/kvtier` | `8965148b0be98c3fcae8137b2e5edcd901b4bde5` |

## 2. 推荐执行批次

| 批次 | 目标 | 可并行内容 |
|------|------|------------|
| Batch 0 | 冻结事实、接口和设计，不改生产实现 | 所有 L3/L4 设计任务可按仓并行 |
| Batch 1 | 契约、独立 reference、负向测试 | 不修改同一文件的任务可并行 |
| Batch 2 | GPU gate、provenance、结果 schema | 六仓基础设施可并行 |
| Batch 3 | 局部实现 | 每仓一个实现 owner；shared file 串行 |
| Batch 4 | 跨仓和深实现 | `tiny-llm` 与 `paged-serving` 必须联合评审 |
| Batch 5 | benchmark 与 profiling | 只消费 correctness 已通过的固定 commit |
| Batch 6 | 文档、证据索引和简历声明 | 只能引用已归档证据 |

默认优先顺序：

```text
事实边界
  → API/ABI/数据布局/生命周期设计
  → 契约测试与独立 reference
  → CPU/build gate
  → 真实 GPU correctness 与 sanitizer
  → 最小实现和 fallback
  → benchmark harness
  → 正式 benchmark / Nsight
  → 文档与简历声明
```

## 3. `cuda-foundations`

当前边界：仓库已经包含 SGEMM 优化阶梯、cuBLAS 对照、CPU-only build smoke 和 opt-in
GPU workflow；但是“测试命令退出 0”仍可能包含 GPU case skip，ragged shape、sanitizer、
可复现 raw benchmark 和部分变体的支持边界尚不完整。

### CUDA-P0-001：消除无 GPU 环境下的测试假绿

- **复杂度**：L2。
- **目标**：GPU lane 在 CUDA runtime 不可用、必测 case 被跳过或零 GPU case 执行时失败；
  CPU lane 则明确报告 skipped/blocked，不能冒充 GPU correctness。
- **当前证据**：`.github/workflows/ci.yml`、`.github/workflows/gpu-tests.yml`、
  `01-sgemm-tutorial/tests/test_sgemm.cu`、`02-tensorcraft-core/tests/test_main.cpp`。
- **前置与范围**：允许修改上述 workflow、测试入口和最小统计脚本；禁止要求 CPU runner
  运行 GPU kernel、禁止把 skip 改名为 pass。
- **验收**：CPU lane 显式输出 GPU case 数与 skip 原因；GPU lane 断言 NVIDIA device、
  至少一个 GPU test 执行且零 unexpected skip；故意屏蔽 GPU 时 GPU lane 非零退出。
- **命令**：`cmake --preset default && cmake --build --preset default`；
  `ctest --preset default --output-on-failure`；GPU runner 重复同一命令并检查 summary。
- **证据/停止**：保存两类 lane 日志与测试计数；若 CI 提供者无法暴露可靠 skip 统计，
  先提交 runner 方案，不得通过日志字符串脆弱匹配伪造门禁。
- **下游**：CUDA-P0-003、CUDA-P1-002、CUDA-P1-003。

### CUDA-P0-002：建立 SGEMM correctness 契约与非对齐矩阵

- **复杂度**：L2。
- **目标**：统一 verifier 的绝对/相对容差、NaN/Inf 和 alpha/beta 语义，并覆盖 ragged
  `M/N/K`、矩形 shape、尾块和 scaled launcher。
- **当前证据**：`01-sgemm-tutorial/tests/test_sgemm.cu`、
  `01-sgemm-tutorial/src/utils/verify.cuh`、`01-sgemm-tutorial/src/kernels/*.cuh`。
- **前置与范围**：先写矩阵和 oracle；允许改 verifier 与该模块测试；禁止改 kernel
  只为绕过测试，禁止只测 32 的倍数。
- **验收**：至少覆盖 `1/17/31/33/65` 类尾部尺寸、矩形矩阵、非零 beta、零尺寸或非法
  参数的冻结行为；与 cuBLAS/reference 对照；NaN/Inf 必须显式失败。
- **命令**：`cmake --preset default && cmake --build --preset default`；
  `ctest --preset default -R sgemm --output-on-failure`；GPU 上运行新增参数化测试。
- **证据/停止**：附 shape 表、容差依据、失败样例和随机 seed；若现有 public launcher
  不支持 alpha/beta 或任意尺寸，先升级 API 设计，不得在测试中隐式假定。
- **下游**：CUDA-P0-003、CUDA-P1-002、CUDA-P1-003。

### CUDA-P0-003：建立 Compute Sanitizer GPU gate

- **复杂度**：L1。
- **目标**：对 P0 correctness 矩阵运行 `compute-sanitizer --tool memcheck`，将非法访问与
  数值正确性分开门禁。
- **当前证据**：`.github/workflows/gpu-tests.yml` 和仓库故障排查文档已有零散命令，
  但没有稳定的 sanitizer artifact。
- **前置与范围**：依赖 CUDA-P0-001/002；允许新增最小脚本、workflow step 和文档；
  禁止把全仓超长 sanitizer 当作每次 PR 的唯一 gate。
- **验收**：精选 ragged、WMMA 和尾块 case；sanitizer error count 为零；工具不可用时
  状态为 blocked，不得继续报告 passed。
- **命令**：`compute-sanitizer --tool memcheck --error-exitcode=1 <sgemm-test-binary>
  --gtest_filter=<p0-cases>`。
- **证据/停止**：归档命令、GPU、driver、CUDA、完整日志；若单 case 超时，先缩小矩阵并
  记录覆盖差异，不得关闭错误检查。
- **下游**：所有 CUDA-P1 实现和性能任务。

### CUDA-P0-004：生成可复现 SGEMM benchmark 证据包

- **复杂度**：L2。
- **目标**：让一次 benchmark 生成 metadata、raw stdout/stderr、CSV/JSON 和 limitations，
  并要求显式传入 GPU architecture。
- **当前证据**：`scripts/run_benchmarks.sh`、
  `01-sgemm-tutorial/src/main.cu`、`01-sgemm-tutorial/src/utils/benchmark.cuh`、
  `01-sgemm-tutorial/Makefile`。
- **前置与范围**：correctness 先通过；允许改 benchmark 脚本、报告 schema 和文档；
  禁止覆盖历史 raw data，禁止自动抄写“最佳数字”。
- **验收**：记录 commit/dirty、GPU、driver、CUDA、compiler、arch、shape、seed、warmup、
  repetitions、每次 raw sample、cuBLAS baseline 和限制；输出目录不可静默覆盖。
- **命令**：`GPU_ARCH=<sm_xx> scripts/run_benchmarks.sh <output-dir>`；运行后用新增
  validator 检查必填字段。
- **证据/停止**：提交 synthetic fixture 和 validator 测试；无 GPU 时只完成 harness，
  性能状态写 not_measured。
- **下游**：CUDA-P1-001、CUDA-P1-003、CUDA-P1-004。

### CUDA-P1-001：用 Nsight 解释三种 shared-memory 变体

- **复杂度**：L2。
- **目标**：在相同输入和计时口径下比较 Tiled、Bank Conflict Free、Double Buffer，
  解释实测为何不一定单调加速。
- **当前证据**：三个 kernel 位于 `01-sgemm-tutorial/src/kernels/`，现有 RTX 3060
  报告不能单凭名称证明 bank conflict 消失或 load/compute 重叠。
- **前置与范围**：依赖 CUDA-P0-002/003/004；默认只新增 profiler 命令、raw artifact
  和分析文档；禁止 profiler Agent 修改 kernel。
- **验收**：同一固定 commit/shape 至少采集 launch timeline、achieved occupancy、
  shared-memory conflict 相关指标、memory throughput 与 stall 指标；结论区分观察和推断。
- **命令**：先运行 benchmark canary，再运行 `nsys profile` 与定点 `ncu --kernel-name`
  命令；具体 metric set 按本机 Nsight 版本记录。
- **证据/停止**：保存 `.nsys-rep`、`.ncu-rep`、导出表和 limitations；缺 profiler 权限
  或指标不支持时写 blocked/unknown，不得用源码注释代替测量。
- **下游**：CUDA-P1-004。

### CUDA-P1-002：关闭未接入 SGEMM 变体的支持边界缺口

- **复杂度**：L3。
- **目标**：对 scaled、transposed、register-tiled、FP16-input 变体逐一决定“纳入受支持
  实验面”或“明确为内部/未完成”，被纳入者必须有完整证据。
- **当前证据**：相关 symbols 分散于 `01-sgemm-tutorial/src/kernels/`，主 benchmark、
  tests 与文档没有形成一致清单。
- **前置与范围**：先提交 design inventory；允许改 01 模块的 public launcher、测试、
  benchmark 和对应文档；禁止借机重写其他模块。
- **验收**：每个 symbol 有 owner/status/input contract；受支持项通过 correctness、
  sanitizer 和 benchmark；不支持项不再被文档画入已完成优化阶梯。
- **命令**：CUDA-P0-002/003/004 的同口径命令，加每个变体的精确 filter。
- **证据/停止**：若 register-tiled 默认模板本身不可实例化，先给出最小 API 修正设计；
  不得通过隐藏 symbol 或删除测试来完成。
- **下游**：CUDA-P1-004。

### CUDA-P1-003：拆分 WMMA 纯 kernel 与端到端 conversion 成本

- **复杂度**：L3。
- **目标**：分别验证和计时“预转换 FP16 输入的 WMMA kernel”与“FP32 输入、内部转换的
  wrapper”，禁止合并为一个 Tensor Core 数字。
- **当前证据**：`01-sgemm-tutorial/src/kernels/tensor_core_sgemm.cuh` 中 wrapper 包含
  allocation、conversion、sync/free；FP16 launcher 尚缺完整测试与 benchmark。
- **前置与范围**：先冻结两个 API 和 ownership；允许改 tensor-core launcher、测试与
  benchmark；禁止把 W8A16、FP16 输入和 FP32 SGEMM 写成同一精度语义。
- **验收**：两条路径均有 correctness、sanitizer 和 raw timing；报告分别列 conversion、
  allocation 与 kernel 时间；不支持的 shape/arch 有稳定错误。
- **命令**：运行专用 GTest filter、sanitizer 和两种 benchmark mode。
- **证据/停止**：记录输入 dtype、累加 dtype、输出 dtype、arch 和 cuBLAS 对照；若 public
  API 无法表达 workspace ownership，先停在设计评审。
- **下游**：CUDA-P1-004。

### CUDA-P1-004：清理实现、实测、占位和未来目标文档

- **复杂度**：L1。
- **目标**：给每个 SGEMM stage 和性能数字标明 code-proven、GPU-verified、
  measured、experimental 或 future。
- **当前证据**：根 README、01 模块 README、`docs/en|zh/modules/01-*`、
  `docs/en|zh/benchmarks/` 存在多处不同口径。
- **前置与范围**：只能在相应证据任务完成后更新结论；允许改上述文档和 evidence index；
  禁止新增没有 raw artifact 的数字。
- **验收**：中英文关键结论一致；每个数字链接到 commit-bound evidence；失败和负结果
  保留；未完成变体不再显示为已验证能力。
- **命令**：仓库文档检查、`git diff --check`，并运行文档测试。
- **证据/停止**：若历史数字找不到原始数据，删除具体性能声明或明确标注 historical/
  unverified，不能推测补齐。
- **下游**：作品集最终展示。

## 4. `trifuse`

当前边界：仓库已有 Triton kernels、CPU/PyTorch reference、`torch.library.custom_op`、
`register_fake`、benchmark suite 和 opt-in GPU tests。主要缺口是 custom-op 错误契约、
`torch.export` 证据、raw timing/provenance、公平 baseline 和 FlashAttention 是否进入
`torch.ops.trifuse` 的明确决策。

### TRI-P0-001：冻结 custom op 的错误和 fake/meta 契约

- **复杂度**：L2。
- **目标**：三个现有 op 对非法 shape/dtype/device/stride/activation/block size 具有
  eager 与 fake 一致的错误语义，并补齐 SGEMM block-size 校验。
- **当前证据**：`trifuse/ops.py`、`trifuse/kernels/sgemm.py`、
  `tests/test_torch_library.py`、`tests/test_edge_cases.py`。
- **前置与范围**：先列输入 contract；允许改 ops、validation 和相关测试；禁止在 fake
  路径访问真实 data pointer 或触发 CUDA。
- **验收**：每个非法维度都有 exact exception class/关键消息；eager/fake 对相同静态
  错误一致；合法非 contiguous 行为明确为支持或拒绝。
- **命令**：`pytest -q tests/test_torch_library.py tests/test_edge_cases.py`；
  GPU 环境另跑对应 CUDA cases。
- **证据/停止**：附契约矩阵；若 PyTorch 版本差异改变 fake API，先冻结支持版本矩阵。
- **下游**：TRI-P0-002、TRI-P1-005。

### TRI-P0-002：补齐 `torch.export` 与 fake tensor 证据

- **复杂度**：L2。
- **目标**：用可执行测试证明 README 中的 export 能力；若支持版本无法成功，则把声明
  降级为仅 `torch.compile` 已验证。
- **当前证据**：`trifuse/ops.py` docstring、`tests/test_torch_library.py` 和 README。
- **前置与范围**：依赖 TRI-P0-001；允许改 custom-op 测试、兼容性文档和最小 fake impl；
  禁止捕获异常后把测试标绿。
- **验收**：固定 torch 版本运行 export、保存 graph/signature，并比较 eager 与 exported
  输出；动态 shape 不支持时明确列边界。
- **命令**：`pytest -q tests/test_torch_library.py -k 'export or fake or compile'`。
- **证据/停止**：记录 torch/Triton/Python 版本；若 export 是上游限制，保留最小复现并
  修改声明，不得声称已支持。
- **下游**：TRI-P1-006。

### TRI-P0-003：统一 timing 口径并保留 raw samples

- **复杂度**：L2。
- **目标**：`measure_latency`/`measure_metrics` 保留 per-iteration samples，明确 mean、
  median/p50、p95 和同步边界，消除文档与实现不一致。
- **当前证据**：`trifuse/performance.py` 当前按整段 wall clock 求平均；
  `trifuse/benchmark/report.py` 和 README 使用的统计描述不完全一致。
- **前置与范围**：先冻结计时 schema；允许改 performance、benchmark report 和测试；
  禁止只保存聚合值，禁止混用 CPU wall clock 与 CUDA event 后不标注。
- **验收**：warmup 不进入 samples；每次测量有明确同步；JSON 包含 raw、count、mean、
  median、p95；单测覆盖空/非法 repetitions。
- **命令**：`pytest -q tests/test_runtime_surface.py tests/test_benchmark.py`。
- **证据/停止**：CPU-only 可验证 schema；真实性能数字必须在 GPU 上重新采集，不能沿用
  旧聚合值反推 raw samples。
- **下游**：TRI-P0-004、TRI-P1-007。

### TRI-P0-004：建立 benchmark provenance

- **复杂度**：L3。
- **目标**：使 `python -m tests.benchmarks.bench_*` 生成自包含、可复现的结果包。
- **当前证据**：`trifuse/benchmark/`、`tests/benchmarks/` 当前能够生成 text/JSON，
  但环境、dirty state、seed、raw samples 和 limitations 不完整。
- **前置与范围**：依赖 TRI-P0-003；允许改 benchmark/report/CLI、测试和文档；
  禁止自动读取并泄露环境 secret。
- **验收**：记录 commit/dirty、GPU/CC、driver、CUDA、PyTorch、Triton、numpy、输入构造、
  seed、dtype/shape、warmup、repetitions、raw samples、command 和 limitations。
- **命令**：CPU-only 运行 report schema tests；GPU 上运行两个现有 benchmark module
  并通过 validator。
- **证据/停止**：无 GPU 时只完成 harness；性能状态 not_measured；依赖版本无法固定时
  不发布正式数字。
- **下游**：TRI-P1-007、TRI-P1-006。

### TRI-P1-005：决定并实现 FlashAttention custom-op 边界

- **复杂度**：L3。
- **目标**：要么注册 `trifuse::flash_attention` 并提供 fake/差分测试，要么明确说明
  其被故意排除以及原因。
- **当前证据**：`trifuse/kernels/flash_attention.py` 有 Python API，
  `trifuse/ops.py` 的 `torch.ops.trifuse` 命名空间未包含该 op。
- **前置与范围**：先完成 design package；允许改 `ops.py`、flash kernel、对应测试和
  README；禁止在没有 backward contract 时暗示完整训练支持。
- **验收**：输入 layout、causal、scale、dtype、stride、GQA/MQA 范围和输出 shape 冻结；
  eager/fake/compile 或明确不支持的状态可测试；与独立 PyTorch SDPA reference 差分。
- **命令**：新增专用 op tests，加 `pytest -q tests/test_flash_attention.py
  tests/test_torch_library.py`。
- **证据/停止**：若动态 shape、autograd 或 fake 语义未决，停在设计评审；不得仅为接口
  对称性注册不安全 op。
- **下游**：TRI-P1-006、TRI-P1-007。

### TRI-P1-006：建立文档和元数据一致性门禁

- **复杂度**：L1。
- **目标**：校验状态、版本、测试统计、计时口径和未实测数字，防止 README 漂移。
- **当前证据**：README、`pyproject.toml`、benchmark report 和测试数量存在可漂移字段。
- **前置与范围**：依赖已冻结的 P0 schema；允许新增小型 validator/test；禁止硬编码
  容易变化但无单一事实来源的总测试数。
- **验收**：CI 能发现版本/能力/统计描述冲突；文档数字必须链接 raw artifact；
  GPU skip 不算 GPU pass。
- **命令**：`pytest -q` 中新增文档/元数据检查；`git diff --check`。
- **证据/停止**：自动检查只能覆盖机器可判定字段；技术能力边界仍需 reviewer，不得用
  简单字符串匹配替代设计审查。
- **下游**：作品集最终展示。

### TRI-P1-007：建立公平 Triton baseline

- **复杂度**：L3。
- **目标**：默认输出 Triton 与 PyTorch/cuBLAS/SDPA 的同输入、同 warmup、同 repetitions、
  同统计口径对比。
- **当前证据**：benchmark suite 已有 reference hooks，但不同脚本的 baseline 命名、
  输入构造和报告字段未形成强契约。
- **前置与范围**：依赖 TRI-P0-003/004；允许改 benchmark suite、脚本和结果 schema；
  禁止把 fusion 与非 fusion 工作量直接写成 kernel speedup。
- **验收**：每条结果包含 baseline implementation、工作量、dtype/layout/shape、raw
  samples、speedup 分布和 correctness 状态；correctness 失败时不输出正式 speedup。
- **命令**：运行两个现有 benchmark module和新增 FlashAttention benchmark；
  validator 检查同组参数一致性。
- **证据/停止**：CV 或 spread 超门槛时标 `not_converged`；找不到语义等价 baseline 时
  只报告绝对 timing，不构造不公平 speedup。
- **下游**：TriFuse 性能报告。

### TRI-P1-008：让 GPU 测试与 skip 语义可见

- **复杂度**：L2。
- **目标**：CPU CI 汇总 skip 并声明未覆盖 GPU；GPU workflow 归档环境和测试 artifact。
- **当前证据**：大量测试使用 `pytest.mark.skipif(not torch.cuda.is_available())`，
  `.github/workflows/gpu-tests.yml` 已检查 CUDA，但证据留存不足。
- **前置与范围**：允许改 pytest 配置、workflow 和报告脚本；禁止强迫普通 runner 安装
  GPU stack 后声称 GPU 验证。
- **验收**：CPU/GPU 两类 summary 独立；GPU lane 要求指定 GPU tests 非零执行且无
  unexpected skip；artifact 包含环境 metadata。
- **命令**：`pytest -q -ra`；GPU lane 运行完整 GPU marker/filter 并导出 JUnit。
- **证据/停止**：runner 不可用时状态 blocked；不能以本地历史日志代替当前 HEAD。
- **下游**：TRI-P1-007 和正式能力声明。

## 5. `cuflash`

当前边界：forward/backward/decode、FP32/FP16/BF16、PyTorch comparison 与 GPU workflow
已有实现；最高风险位于 `src/forward/flash_decoding.cu` 的函数级 static scratch，其注释
明确依赖单流假设。现有证据不足以证明多 stream 并发安全和当前 HEAD 的完整 GPU 门禁。

### CUF-P0-001：冻结 decode workspace 与 stream lifecycle

- **复杂度**：L3。
- **目标**：在改代码前冻结 workspace ownership、lifetime、reallocation、destruction、
  stream ordering、并发、OOM 和错误映射。
- **当前证据**：`src/forward/flash_decoding.cu::launch_flash_decoding_typed` 使用共享
  `static float* scratch`；public decode API 仅接收 stream，没有 workspace/context。
- **前置与范围**：只提交设计文档、API 草案和测试矩阵；禁止先把 static 换成另一个
  未审查的全局 allocator。
- **验收**：设计必须比较 caller-owned、handle-owned、stream-keyed pool 至少三种方案；
  写清 ABI 兼容、并发矩阵、释放时机和 fallback。
- **命令**：只运行现有 build/tests 验证基线；不采集新性能结论。
- **证据/停止**：使用 `L3_L4_DESIGN_REVIEW_PACKAGES.md` 的 CUF 包；API/ABI、所有权或
  stream ordering 未批准则停止。
- **下游**：CUF-P0-002、CUF-P0-003、CUF-P1-002。

### CUF-P0-002：修复 workspace/stream safety 和 launch error

- **复杂度**：L3。
- **目标**：按批准设计消除 shared static scratch 竞争，并让 partial/combine launch
  failures 以稳定错误返回。
- **当前证据**：`src/forward/flash_decoding.cu` 包含 resize/free/malloc 和两个 kernel
  launch；当前 API path 未形成并发 ownership。
- **前置与范围**：依赖 CUF-P0-001；允许改 decode implementation、public header/API
  adapter、最小 build/test；禁止同步整个 device 作为默认修复。
- **验收**：同 stream 顺序正确；两个非默认 stream 并发结果稳定；resize 与 destruction
  无 use-after-free；OOM、unsupported head dim、launch failure 有固定错误。
- **命令**：专用 decode unit tests、并发 stress、`compute-sanitizer`；完整受影响 GPU
  suite。
- **证据/停止**：若兼容 API 需要隐式全局同步或无法安全判断 workspace 生命周期，
  回到设计评审，不得用 mutex 包住全部 GPU 执行后宣称 stream-safe。
- **下游**：CUF-P0-003、CUF-P0-004。

### CUF-P0-003：补齐 decode 数值、参数和并发矩阵

- **复杂度**：L2。
- **目标**：覆盖 BF16、head_dim 32/64/128、chunk 边界、极端 score、invalid scale、
  null/shape 和多 stream。
- **当前证据**：`tests/unit/test_flash_decoding.cu` 已有 FP32/FP16、chunk=1/16 和部分
  invalid 参数；BF16、边界和多 stream 不完整。
- **前置与范围**：数值测试可与 CUF-P0-002 并行准备；允许改 decode tests/reference；
  禁止让 reference 复用生产 combine 逻辑。
- **验收**：独立 CPU/PyTorch reference；每个 dtype 有容差依据；测试跨 chunk 尾部、
  `seq_len < num_chunks`、大负 logits、并发和错误路径。
- **命令**：运行 `test_flash_decoding` filter；GPU 上加 sanitizer。
- **证据/停止**：BF16 需要 sm_80+；无相应 GPU 时标 blocked，不得用 FP16 结果代替。
- **下游**：CUF-P0-004、CUF-P1-002。

### CUF-P0-004：建立当前 HEAD 的 GPU correctness 与 sanitizer 门禁

- **复杂度**：L2。
- **目标**：把 numerical tests、PyTorch comparison、stress 和 Compute Sanitizer
  归档成当前 commit 的可审计证据。
- **当前证据**：`.github/workflows/gpu.yml`、`scripts/run_compute_sanitizer.sh`、
  `tests/integration/test_pytorch_comparison.py` 已存在，但 hosted skip 与 GPU pass
  仍需明确分层。
- **前置与范围**：依赖 CUF-P0-002/003；允许改 GPU workflow、脚本和报告；
  禁止把 build-only lane 算 GPU correctness。
- **验收**：指定 GPU tests 非零执行；FP32/FP16/BF16 支持矩阵透明；sanitizer 零错误；
  artifact 绑定 commit/dirty/GPU/driver/CUDA。
- **命令**：仓库 GPU workflow 的等价本地命令、PyTorch comparison、sanitizer 脚本。
- **证据/停止**：缺 GPU 或 PyTorch CUDA 依赖时 blocked；不得保留空 artifact 后标绿。
- **下游**：CUF-P1-001、CUF-P1-002、CUF-P1-003。

### CUF-P1-001：验证 WMMA/scalar dispatch 和数值归因

- **复杂度**：L3。
- **目标**：证明 FP16/BF16 forward 在各 arch 的实际 dispatch、fallback 和 tolerance，
  并明确 backward 是否仍为 scalar path。
- **当前证据**：`src/forward/flash_attention_forward_wmma.cu`、
  `src/forward/flash_attention_forward_typed.cu`、
  `src/backward/flash_attention_backward_typed.cu`。
- **前置与范围**：依赖 CUF-P0-004；允许加可关闭的 dispatch observability、测试和
  profiler harness；禁止仅凭文件名声明 Tensor Core 已使用。
- **验收**：sm_70 与 sm_80+ 支持矩阵、实际 kernel symbol/trace、fallback 条件、数值
  容差和失败行为均有证据。
- **命令**：GPU tests 加定点 `nsys/ncu`；BF16 仅在支持硬件运行。
- **证据/停止**：无法取得硬件时对应格 blocked；不外推到未测 arch。
- **下游**：CUF-P1-003。

### CUF-P1-002：固化可复现 benchmark 与 baseline

- **复杂度**：L3。
- **目标**：覆盖 forward/backward/decode 的 correctness-first benchmark artifact，
  并使用语义等价 baseline。
- **当前证据**：`benchmarks/bench_flash_attention.cu` 和
  `docs/performance/benchmarks.md` 已有基础，但 metadata/raw/limitations 不完整。
- **前置与范围**：依赖 CUF-P0-004；允许改 benchmark、schema、validator 和性能文档；
  禁止将单 kernel 数字写成端到端 serving 性能。
- **验收**：commit/dirty、GPU/driver/CUDA/compiler、dtype/layout/shape、causal、head
  geometry、warmup/repetitions/raw、baseline、correctness 和 limitations 完整。
- **命令**：先 correctness canary，再运行 benchmark；正式数据至少 3 repetitions，
  validator 检查 CV/参数一致性。
- **证据/停止**：不公平 baseline 或 CV>10% 时标 not_converged；不得筛掉慢/失败 run。
- **下游**：CUF-P1-003 和跨仓对照。

### CUF-P1-003：收敛文档状态和 evidence map

- **复杂度**：L2。
- **目标**：将 README/API/design/performance 中的 code-proven、GPU-verified、
  measured、experimental、future 明确分层。
- **当前证据**：`README.md`、`docs/design/flash-decoding.md`、
  `docs/performance/benchmarks.md`、public header。
- **前置与范围**：设计边界可先写；验证/性能结论必须等待对应证据；禁止写“完整 FA2/FA3”
  或生产级结论。
- **验收**：每项能力链接到 test/artifact；decode 的 workspace 假设已移除或显式保留；
  backward、BF16、WMMA 和 split-KV 范围准确。
- **命令**：文档检查、`git diff --check`、必要的 API smoke tests。
- **证据/停止**：缺 raw evidence 的数字降级或删除；不能根据代码存在推断已测性能。
- **下游**：作品集最终展示。

## 6. `tiny-llm`

当前边界：已有 GGUF/量化、Tokenizer、Transformer、连续与 paged KV、CUDA Graph、
W8A16 和 C ABI。strategy 1 当前每层先 scatter 到物理 pool，再 gather 到连续 scratch，
最后调用连续 attention；因此它是分页 KV 控制面，不是 direct PagedAttention。

### TLLM-P0-001：建立 GGUF/量化兼容性和第二模型 evidence

- **复杂度**：L2。
- **目标**：区分“parser/loader 代码支持”和“真实模型已验证”，补 Q4_0/Q8_0 synthetic
  reference，并运行第二种模型几何。
- **当前证据**：`src/gguf_parser.cpp`、`src/model_loader.cpp`、
  `src/quantization.cpp`、`tests/test_gguf_*`、`tests/test_quantization.cpp`。
- **前置与范围**：允许改 loader/quant tests、模型矩阵文档和显式 GPU lane；
  禁止提交模型，禁止无许可自动下载，禁止把测试 skip 算验证。
- **验收**：每种量化列 parser/load/dequant/matmul/e2e 状态；至少两个固定 SHA 模型或
  两种 GQA 几何通过真实门控；失败模型保留日志。
- **命令**：CPU parser/quant tests；GPU 上运行 `TLLM_GGUF_TEST_MODEL` 与第二模型变量
  对应的专用 tests。
- **证据/停止**：缺第二模型或显存不足时 blocked；不得用同一文件复制重命名充当第二模型。
- **下游**：TLLM-P0-005 和真实 serving lane。

### TLLM-P0-002：建立 paged 与 contiguous 的 synthetic oracle

- **复杂度**：L3。
- **目标**：新增不依赖外部 GGUF 的 layer/kernel 差分，冻结 direct paged attention 的
  不可变 correctness oracle。
- **当前证据**：`kernels/paged_kv.cu` 主要证明 scatter/gather；`src/transformer.cpp`
  的 `attentionPaged` 再调用连续 attention；端到端 FFI 差分依赖真实模型。
- **前置与范围**：只做独立 reference、fixture、测试 API 最小 seam；禁止先写 direct
  kernel，禁止 reference 调用生产 paged helper。
- **验收**：覆盖 block_size、跨块尾部、GQA/MQA、RoPE position、visible length、
  多 layer pool offset、invalid block id/table length 和随机 seed。
- **命令**：构建后运行新增 `test_transformer`/`test_kernels` filter；GPU sanitizer。
- **证据/停止**：如果内部接口不可测，先评审最小 test seam；不得暴露不稳定 public API
  只为测试。
- **下游**：TLLM-P0-004、TLLM-P0-005。

### TLLM-P0-003：将 CUDA Graph correctness 与外部模型解耦

- **复杂度**：L3。
- **目标**：用微型 synthetic 权重验证 Graph off、capture、replay、多次 generate 复用和
  fallback，不依赖私有 GGUF。
- **当前证据**：Graph 实现在 inference/transformer/KV 路径；现有 generate 差分测试
  依赖 `TLLM_GGUF_TEST_MODEL`。
- **前置与范围**：先冻结 capture/replay 状态机和可测 seam；允许改 graph 相关实现、
  synthetic fixture 和测试；禁止把 graph benchmark 当 correctness。
- **验收**：固定 seed 下 graph on/off token/logit 一致；地址变化、decode length、
  append position、多次 request、capture 失败 fallback 和清理均覆盖。
- **命令**：专用 CUDA Graph tests、sanitizer、受影响 inference tests。
- **证据/停止**：若 synthetic model 与真实执行路径不相同，设计必须说明差异并保留真实
  canary；不得用 mock 完全替代 GPU graph。
- **下游**：Graph 能力声明和 serving 集成稳定性。

### TLLM-P0-004：实现 direct paged decode attention kernel

- **复杂度**：L4。
- **目标**：kernel 直接读取物理 K/V pool 与 block table，单 token decode 不再 gather
  完整可见 KV 到连续 scratch。
- **当前证据**：`kernels/attention.cu::attention_decode` 只接连续 K/V；
  `kernels/paged_kv.cu` 只负责 scatter/gather。
- **前置与范围**：必须先通过 direct-paged design package 和 TLLM-P0-002；第一 PR
  只允许 kernel/header/tests/benchmark seam，禁止同时改 FFI 与 serving。
- **验收**：API、layout、GQA 映射、block lookup、tail、online softmax、dtype/accumulation、
  invalid geometry 和 stream 语义冻结；与独立 contiguous/reference 差分；sanitizer 通过。
- **命令**：专用 kernel tests、Compute Sanitizer；正确性通过后才运行 microbenchmark。
- **证据/停止**：任一 layout/ABI/ownership 未批准，或只能通过 gather helper 才正确，
  停止；无 GPU 时只能完成设计/编译，不能完成任务。
- **下游**：TLLM-P0-005、TLLM-P1-001。

### TLLM-P0-005：将 direct decode 接入 Transformer 与 FFI

- **复杂度**：L3。
- **目标**：strategy 1 decode 调用 direct kernel；prefill 暂保留 scatter/gather；
  提供 feature/config fallback 到 legacy path。
- **当前证据**：`src/transformer.cpp::attentionPaged` 负责 pool offset、scatter、gather
  和 decode；`src/ffi.cpp` 复制 block table、维护 pool/scratch 和策略 1/2。
- **前置与范围**：依赖 TLLM-P0-001/002/004；允许改 transformer、FFI、C header、
  tests 和最小 config；`paged-serving` 镜像 ABI 必须联合评审。
- **验收**：单/跨块、GQA、长上下文、allocate/step/free、失败后资源恢复；direct、
  legacy paged、contiguous 三路差分；`max_num_blocks == 0` 语义不变。
- **命令**：`test_transformer`、`test_ffi`、真实模型 canary 和 sanitizer；随后运行
  paged-serving ABI tests。
- **证据/停止**：任何 C struct/参数变化必须先更新双仓 ABI package；禁止独立合并一个
  破坏兼容的版本。
- **下游**：TLLM-P1-001、PSRV-P1-002/004。

### TLLM-P1-001：运行 direct paged 长上下文 A/B

- **复杂度**：L3。
- **目标**：比较 legacy gather+continuous attention、direct paged 和 contiguous，
  分别报告 kernel、scratch bytes 和可行的 FFI/serving 影响。
- **当前证据**：`src/kernel_bench.cpp` 目前以连续 attention 和较短 sequence 为主；
  CUDA Graph 历史数据不能回答 direct paged 收益。
- **前置与范围**：依赖 TLLM-P0-005 和 GPU gate；默认只改 benchmark/schema/docs；
  禁止 benchmark Agent 修改 kernel。
- **验收**：shape 覆盖 block boundary 和长上下文；三路同输入/同输出 contract；
  raw samples、显存口径、warmup/repetitions 和 CV 完整；不把 kernel 结果写成 TTFT/TPOT。
- **命令**：先 correctness canary，再运行 kernel benchmark；若接 serving，使用固定
  paged-serving commit 的独立实验。
- **证据/停止**：6 GB GPU OOM 要保留负结果并缩小矩阵；不得删除失败 shape 或外推大卡。
- **下游**：最终性能报告和简历声明。

## 7. `paged-serving`

当前边界：已有 BlockPool、调度、429、SSE、取消入口、metrics、closed/Poisson loadgen
和正式结果包。后续不是“从零实现 serving”，而是关闭主动取消、无界事件队列、指标语义、
网络失败回归、真实 backend 持续门禁和三引擎公平矩阵。

### PSRV-P0-001：实现请求所有权驱动的主动取消

- **复杂度**：L3。
- **目标**：consumer 关闭、handler abort、`n>1` 部分准入失败时主动取消所有已准入请求，
  不等待下一次非空 chunk send failure。
- **当前证据**：`src/server.rs` 的 submit/engine loop/stream response，
  `src/engine.rs::cancel_request`、`src/scheduler.rs::cancel_by_request_id` 和现有断连测试。
- **前置与范围**：先完成取消状态机设计；允许改 server、最小 engine/scheduler 接口和
  integration tests；禁止新建第二套 request state machine。
- **验收**：pending/prefill/decode、HF 暂无文本、unary abort、SSE disconnect、n>1
  partial admission 全覆盖；每条路径 request slot、KV block、backend sequence 回基线。
- **命令**：server integration cancel filters、engine/scheduler resource tests、
  `cargo clippy --all-targets -- -D warnings`。
- **证据/停止**：必须证明 exactly-once terminal/release；若 cancellation 与 response
  ownership 无法线性化，停在设计评审。
- **下游**：PSRV-P0-002/003、PSRV-P1-003。

### PSRV-P0-002：为 SSE 和 fan-in 建立有界背压

- **复杂度**：L3。
- **目标**：替换单请求事件和 `n>1` fan-in 的无界队列，冻结慢消费者策略。
- **当前证据**：`src/server.rs` 使用 `mpsc::UnboundedSender/Receiver`，fan-in 也新建
  unbounded channel；submission queue 虽有 1024 上限，但 token event 没有。
- **前置与范围**：依赖 PSRV-P0-001 的 ownership；允许改 server、config、error 和测试；
  禁止阻塞整个 engine loop、禁止无限缓冲、禁止静默丢 token。
- **验收**：容量可配置且有安全默认；慢 consumer 产生明确 cancel/error/overflow policy；
  一个慢流不饿死其他请求；内存上界可解释；n>1 保持终态一致。
- **命令**：server integration 的 slow consumer/stress tests、完整 cargo test/clippy。
- **证据/停止**：若策略会改变 OpenAI API 行为，先冻结错误码/SSE terminal contract；
  不得只把容量设成一个巨大常量。
- **下游**：PSRV-P0-003、PSRV-P1-003/004。

### PSRV-P0-003：冻结服务指标语义并补生命周期回归

- **复杂度**：L2。
- **目标**：明确 requests/errors/inflight/streaming 和 engine counters 的计数单位、开始/
  结束时点及错误路径。
- **当前证据**：`src/server.rs::ServerMetrics/SharedEngineMetrics` 与 `/metrics` 已存在；
  现有测试主要验证名称，流式 response 构造后 inflight guard 已释放。
- **前置与范围**：依赖取消/背压设计；允许改 metrics 实现、文档和数值测试；
  禁止改变指标含义却沿用原名而不记录 breaking change。
- **验收**：malformed JSON、429、admission error、SSE terminal error、disconnect、
  success、n>1 的计数均冻结；active/KV 在终态回基线。
- **命令**：`cargo test --test server_integration metrics` 加新增 filters；
  engine metrics tests 和 clippy。
- **证据/停止**：若 inflight 定义是 handler lifetime 还是 generation lifetime 未决，
  先由 reviewer 选择并更新 HELP 文本。
- **下游**：PSRV-P1-003/004。

### PSRV-P0-004：为 loadgen 补真实 HTTP/SSE 失败回归

- **复杂度**：L2。
- **目标**：用本地可控 HTTP server 验证 `run_request`、closed/Poisson 和 summary，
  覆盖全部错误分类。
- **当前证据**：`src/bin/loadgen.rs` 已实现 timeout、429、4xx、5xx、connection、
  stream/protocol/no_done 等分类，但大量测试仍偏解析器/纯函数。
- **前置与范围**：允许在 loadgen tests 内建临时 server，必要时最小拆出 `src/loadgen.rs`；
  禁止长 sleep、外网依赖或把 chunk count 当 token count。
- **验收**：LF/CRLF、split UTF-8、invalid JSON、server error、无 `[DONE]`、usage 有/无、
  coverage 不完整和 fixed-seed Poisson 均确定性验证；warmup 不进正式 summary。
- **命令**：`cargo test --bin loadgen`；随后完整 cargo test/clippy。
- **证据/停止**：每类错误保留非空 detail 与样例 record；若需公开稳定 API 才能测，
  先评审最小模块拆分。
- **下游**：PSRV-P1-001/003/004。

### PSRV-P1-001：升级正式结果语义校验和收敛审计

- **复杂度**：L2。
- **目标**：validator 校验 per-request、summary、metadata、重复配置和 methodology，
  `plots.py` 拒绝混合不兼容 run。
- **当前证据**：`benchmarks/serving/validate_results.py` 当前主要检查文件/schema；
  `methodology.md` 已要求 3 repetitions 和 >10% 未收敛。
- **前置与范围**：依赖 PSRV-P0-004；允许改 validator/plots/methodology/template 和新增
  fixtures；禁止按结果好坏判通过或重写 raw data。
- **验收**：total=success+failed、error totals、sample count、coverage、JSONL count、
  throughput/wall time、重复参数一致；波动输出 machine-readable `non_converged`。
- **命令**：新增 Python tests；对历史 2026-09-07 正式包运行 `--formal` 和 plots。
- **证据/停止**：旧包若不通过必须给迁移诊断；warning/hard failure 未达成一致时升级
  methodology 评审。
- **下游**：PSRV-P1-003/004。

### PSRV-P1-002：建立真实 tiny-llm backend 非 skip 门禁

- **复杂度**：L3。
- **目标**：独立 lane 启用 `tiny-llm` feature；缺 library/model/tokenizer/GPU 时明确
  blocked/failure，不允许测试函数提前 return 后显示 passed。
- **当前证据**：`Cargo.toml`、`build.rs`、`tests/tiny_llm_backend.rs`、
  `tests/tiny_llm_text_e2e.rs`、`tests/tokenizer_real_diff.rs`。
- **前置与范围**：冻结跨仓 artifact/ABI/模型提供方式；允许改 build、workflow 和真实
  backend tests；禁止提交模型/secret 或下载 floating revision。
- **验收**：feature link、load、greedy、3 并发、错误路径资源回收、tokenizer/text
  oracle；artifact/model 绑定 commit/SHA-256。
- **命令**：以任务卡环境变量运行三个现有 integration tests，再运行
  `cargo test --features tiny-llm`。
- **证据/停止**：无 GPU/合法模型/artifact 时 blocked；ABI 不匹配立即联合评审两仓。
- **下游**：PSRV-P1-004。

### PSRV-P1-003：接入服务遥测并固化取消/HOL/fairness 场景

- **复杂度**：L3。
- **目标**：sweep 定时采样 `/metrics`，归档 KV、queue/admission/step 指标，并增加取消、
  长短 prompt HOL 和 priority fairness 场景。
- **当前证据**：server 已暴露瞬时 KV/active；`run_sweep.sh` 有结果目录框架；
  methodology 明确 sampler/step duration 尚未完成。
- **前置与范围**：依赖 PSRV-P0-003/004 与 PSRV-P1-001；允许改已冻结 metrics、loadgen、
  sweep、schema/plots；禁止实现 preemption/chunked prefill/prefix cache。
- **验收**：raw metrics 带单调时间戳和测量窗口；scrape 失败标 unavailable；取消后资源
  回基线；HOL/fairness 只陈述实际观察；采样开销有 A/B。
- **命令**：loadgen/server tests、完整 cargo test/clippy、正式 validator。
- **证据/停止**：时钟无法对齐或 sampler 显著扰动且无对照时停止；CPU/mock 只能验证
  harness，真实 serving 性能仍 not_measured。
- **下游**：PSRV-P1-004。

### PSRV-P1-004：采集三引擎正式 serving 矩阵

- **复杂度**：L4。
- **目标**：用同一 loadgen、数据集和请求参数采集 paged-serving、llama-server、vLLM
  的当前基线和负结果。
- **当前证据**：现有正式包只覆盖 paged-serving；methodology 已定义 closed/Poisson、
  warmup 和 repetitions。
- **前置与范围**：依赖 PSRV-P1-001/002/003；默认只新增结果包和索引；禁止边测边优化
  代码、删除 OOM/429/启动失败或混合不同量化冒充公平。
- **验收**：每引擎先过 prompt/SSE/`[DONE]`/usage canary；固定版本、模型 SHA、量化、
  tokenizer、dataset、max_tokens、seed；每格 3 repetitions；CV>10% 标未收敛。
- **命令**：构建固定 loadgen，按 `benchmarks/serving/README.md` 运行 `run_sweep.sh`，
  再运行 validator/plots。
- **证据/停止**：无法固定外部引擎版本、模型许可或关键参数时保留 blocked 单元格；
  不得只跑一个引擎后称三引擎完成。
- **下游**：最终 serving 报告和简历声明。

## 8. `kvtier`

当前边界：这是 SGLang HiCache/vLLM KV offloading 的上游研究和单卡 L2 实验脚手架，
不是自研 tiering engine。仓库已有 W/E/R/P workload、server 配置校验、结果审计器和
离线 tests；真实 GPU L2 结果仍未完成。

### KVT-P0-001：刷新可审计的上游证据基线

- **复杂度**：L2。
- **目标**：将 SGLang symbols、架构和 issue/PR 状态绑定同一 commit/复核日期，区分本仓
  实现、上游实现、假设和未来目标。
- **当前证据**：`README.md`、`PLAN.md`、`docs/01-sota-survey.md`、
  `docs/02-hicache-dataflow.md` 与多个 issue/PR 草稿时间点不同。
- **前置与范围**：允许更新研究文档、evidence table 和引用；禁止修改上游源码或根据 issue
  标题推断当前实现。
- **验收**：每个关键 symbol 有 repo/commit/path；issue/PR 有 checked-at 与状态来源；
  过时结论明确撤回。
- **命令**：对 pinned upstream checkout 运行精确 `rg`/tests；本仓 `make check`。
- **证据/停止**：上游 commit 无法取得或私有讨论不可访问时写 unknown，不得用缓存印象。
- **下游**：KVT-P0-002/003、KVT-P1-003。

### KVT-P0-002：冻结并实现结果 schema v2

- **复杂度**：L3。
- **目标**：把单个可运行 JSON 升级为可审计实验包，complete 状态必须具备 provenance。
- **当前证据**：`bench/repro-31600/workload.py` 输出 `schema_version: 1`；
  `validate_results.py` 尚缺 dirty、toolchain、model hash、command/raw hash/limitations。
- **前置与范围**：先提交 schema v2 design；允许改 workload、validator、tests、
  README/ENVIRONMENT；禁止删除 v1 迁移诊断或伪造缺失字段。
- **验收**：commit/dirty、Python/SGLang/CUDA/driver、GPU、模型 identity/hash、server/
  workload 命令、参数、raw log/hash、状态和 limitations 全部机器可校验。
- **命令**：`python3 -m unittest discover -s bench/repro-31600 -p 'test_*.py'`；
  `python3 bench/repro-31600/validate_results.py <fixtures>`。
- **证据/停止**：schema 字段和 complete/blocked/partial 状态未批准前不改正式结果；
  不得自动把 v1 缺失 provenance 补成猜测。
- **下游**：KVT-P0-003、KVT-P1-001/002。

### KVT-P0-003：建立 host DRAM 回载 correctness 门禁

- **复杂度**：L3。
- **目标**：证明每个 R 请求确实在 W backup、E eviction 后从 host 回载，并与相同输入的
  cold execution 输出一致。
- **当前证据**：`workload.py` 当前用固定 `backup_wait`、run 末 counter delta 和 cache
  details；SSE text 没有作为 correctness oracle 保存。
- **前置与范围**：依赖 KVT-P0-001/002；允许改 workload、validator、tests 和最小
  methodology；禁止仅用全局 counter 正增量证明每个 request。
- **验收**：per-phase timestamp/counter/cache evidence；poll 或有界条件替代盲 sleep；
  R 与 P 的 token/text/logit 可比 oracle；namespace 和输入完全一致。
- **命令**：离线 unit tests + dry-run；真实 server canary 后运行一组 W/E/R/P 并 audit。
- **证据/停止**：上游 API 不提供足够逐请求证据时标 partial 并记录限制，不得把相关性
  写成因果证明。
- **下游**：KVT-P1-001/002。

### KVT-P0-004：建立 CPU-only 离线 CI

- **复杂度**：L1。
- **目标**：每次提交运行 unit tests、dry-run、shell syntax 和最小依赖安装。
- **当前证据**：仓库没有 workflow；`bench/repro-31600/requirements.txt`、tests、
  `run_server.sh` 和 Makefile 已提供基础。
- **前置与范围**：允许新增 `.github/workflows/ci.yml` 和最小 Make target；
  禁止下载模型、启动真实 SGLang 或把离线 CI 叫 GPU correctness。
- **验收**：固定 Python 范围、依赖可复现；tests/dry-run/shell syntax 均有明确日志；
  cache 不影响正确性。
- **命令**：`make test`、workload dry-run、`bash -n bench/repro-31600/run_server.sh`。
- **证据/停止**：依赖版本冲突时先冻结支持矩阵；不得使用 floating unbounded dependency。
- **下游**：所有 KVT-P1。

### KVT-P1-001：采集真实 GPU 单卡 L2 baseline

- **复杂度**：L2。
- **目标**：至少完成一个通过 schema v2 audit 的 W/E/R/P host DRAM 回载 run；只有收敛
  后才报告性能。
- **当前证据**：`PLAN.md` 和 README 明确真实 GPU 结果未运行。
- **前置与范围**：依赖全部 KVT-P0；默认只新增结果包/报告和索引；禁止边测边改 workload
  或删除负结果。
- **验收**：固定 upstream commit、模型 SHA、GPU/driver/CUDA、命令和参数；至少 3 trials；
  correctness/counter/path 门禁通过；报告 reload/cold 但不外推。
- **命令**：按 `run_server.sh` 启动 pinned SGLang，运行 `workload.py`，再 `make audit
  RESULT=<result>`。
- **证据/停止**：显存占用、模型许可或上游构建阻塞时归档 blocked；历史环境笔记不能代替
  当前 run。
- **下游**：KVT-P1-002 和作品集证据。

### KVT-P1-002：运行 IO backend 与 KV dtype 回载矩阵

- **复杂度**：L3。
- **目标**：固定硬件、模型、输入和 commit，对 pinned SGLang 支持的 `HICACHE_IO` 与
  `KV_CACHE_DTYPE` 组合测量 load-back TTFT 和 transfer 行为。
- **当前证据**：`run_server.sh` 已暴露两个参数，但仓库没有公平矩阵。
- **前置与范围**：依赖 KVT-P1-001；允许新增结果包、矩阵配置和报告；如脚本必须调整，
  单独开 harness PR，禁止在同一实验中调上游算法。
- **验收**：每格 correctness 先通过；相同 prompt/token/model/context；raw counters、
  timings 和配置完整；不支持组合明确 blocked。
- **命令**：对批准矩阵逐格运行 server/workload/audit；正式格至少 3 repetitions。
- **证据/停止**：找不到可比 backend、CV>10%、或回载未被证明时不输出 speedup；
  不先验归因 NUMA、layout 或 kernel。
- **下游**：后续数据驱动优化设计。

### KVT-P1-003：冻结上游复杂回归的 L4 实验设计

- **复杂度**：L4。
- **目标**：只做设计，不直接实现：定义当前 SGLang main 上与 #31600 可比的 speculative
  draft state、L2+L3、TP/CP/多卡契约和资源门禁。
- **当前证据**：当前 workload 强制 `speculative_algorithm=None`、
  `hicache_storage_backend=None`、并行度 1，因此不能冒充 #31600 复现。
- **前置与范围**：依赖 KVT-P0-001 和至少一个可信单卡 baseline；允许新增设计文档；
  禁止租云 GPU、改上游生产代码或发布“已复现”结论。
- **验收**：假设、版本、拓扑、模型、资源预算、correctness oracle、fault matrix、metrics、
  stop condition 和最小阶段全部冻结。
- **命令**：仅运行上游 symbol/配置存在性检查和本仓文档校验。
- **证据/停止**：没有相应多卡资源、L3 backend 或稳定 upstream revision 时保持 design-only；
  后续实测必须另开批准任务。
- **下游**：未来多 GPU/上游回归会话，不影响当前求职主线。

## 9. 跨仓依赖和文件所有权

### 9.1 `tiny-llm` 与 `paged-serving`

这是唯一内部 runtime 硬依赖，双方维护双源 C ABI：

- `tiny-llm/include/tiny_llm/ffi.h`
- `paged-serving/src/tiny_llm_ffi.rs`

任何 ABI 任务必须共同冻结：

- `repr(C)` size、alignment、field order；
- 参数顺序、整数宽度、nullability 和 buffer capacity；
- error code；
- backend/client ownership；
- allocate/step/free 生命周期；
- cancel/timeout/disconnect 后资源回到基线；
- `max_num_blocks == 0` 和策略 1/2 语义；
- block table 的 layer/request/kv_head/position/dim 含义。

禁止两个仓分别合并不兼容版本。推荐顺序是：

```text
联合 ABI 设计
  → 两侧静态 layout/size 测试
  → tiny-llm implementation
  → paged-serving adapter
  → 双仓固定 commit integration test
```

### 9.2 `trifuse` 与 `cuflash`

两仓不是 runtime 依赖。只能在语义等价时做方法和性能对照：

- 相同 dtype、shape、layout、causal、scale、head geometry；
- 相同输入、seed、warmup、repetitions 和统计；
- 相同 correctness oracle；
- Triton/CUDA/PyTorch baseline 名称明确；
- kernel 结果不能外推为 serving 结果。

### 9.3 Shared files

每个仓库的 README、workflow、build config、public header 和结果 schema 属于 shared
files。同一批次只允许一个 integration owner 修改。其他 Agent 提供 patch 建议或在独立
文件工作，不能同时写同一 shared file。

## 10. 委托后的统一验收

Reviewer 在接受任何任务前必须回答：

1. Agent 是否重新记录了 exact commit 和 dirty state？
2. 任务是否只改 allowed scope？
3. reference 是否独立于生产实现？
4. invalid、ragged、tail、failure 和 cleanup 是否覆盖？
5. GPU case 是否真的运行，而不是 skip？
6. correctness 是否先于 benchmark？
7. raw evidence 是否存在，失败样本是否保留？
8. 性能数据是否包含环境、输入、warmup、repetitions 和 limitations？
9. 跨仓 ABI 或 shared file 是否经过唯一 owner？
10. 文档是否只陈述本次证据能够支持的范围？

任一答案为“否”时，状态只能是 partial、blocked 或 changes_requested，不能标记 complete。
