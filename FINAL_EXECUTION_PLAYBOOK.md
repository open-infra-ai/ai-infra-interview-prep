# AI Infra 最终执行与低成本 Agent 延续手册

> 目标：在规划和高能力 Agent 支持结束后，仍能依靠当前仓库、低成本模型和本人实践，
> 持续完成技术实现、实验、面试和求职闭环。

## 1. 现在最重要的判断

### 1.1 规划层已经完成

当前已经具备：

- 七仓价值审计与两条旗舰主线；
- correctness、benchmark、Nsight、Serving 和求职手册；
- 低成本 Agent 执行规范；
- 六仓 44 个 P0/P1 单任务包；
- L3/L4 的 G0-G8 设计评审包；
- 12 周学习、实验、面试和投递计划。

从现在开始，**除非实现或证据发生变化，不再继续写新的总路线图**。新增文档应主要是：

- 设计评审决定；
- 测试矩阵；
- raw result 和实验报告；
- profiler 观察；
- bug/negative-result 复盘；
- 面试复盘；
- 简历 claim 与证据链接。

再增加抽象规划的边际收益已经很低；真正提高面试通过率的是完成一条可验证的实现链。

### 1.2 不再增加新项目

现有项目已经覆盖：

```text
CUDA 基础
  → Triton/custom op
  → FlashAttention/FlashDecoding
  → LLM runtime/quantization/KV
  → Rust serving/benchmark
  → KV tiering 上游研究
```

新增第八个练习仓会让面试官更难判断主线，也会增加 README、CI 和证据维护成本。

### 1.3 只做一个旗舰深改造

默认优先级：

1. **Runtime/综合方向**：`tiny-llm` direct paged decode attention。
2. **Kernel 方向**：`cuflash` decode workspace/stream safety。
3. **Serving 方向**：`paged-serving` cancellation + bounded backpressure。

三条路径只能选一条作为当前深改造。其余保持 backlog，不同时进入 production
implementation。

## 2. 你的最终作品集结构

### 旗舰一：单 GPU LLM Runtime + Serving

```text
tiny-llm（数据面）
  + paged-serving（控制面）
```

需要讲清：

- GGUF/量化/Tokenizer/Transformer；
- contiguous 与 paged KV；
- direct paged compute 与 paged storage 的区别；
- C ABI；
- request/sequence/block 生命周期；
- admission、429、cancellation、backpressure；
- TTFT、TPOT、throughput、error、收敛。

### 旗舰二：CUDA/Triton Attention

```text
cuflash（CUDA 深挖）
  + trifuse（Triton/PyTorch 对照）
```

需要讲清：

- online softmax；
- FlashAttention 的 I/O 目标；
- Split-KV/FlashDecoding；
- WMMA 与 scalar fallback；
- CUDA stream/workspace；
- Triton block/warp 选择；
- `torch.library`、fake/meta、compile/export；
- 公平 baseline。

### 辅助证据

- `cuda-foundations`：展示学习路径和 profiler 驱动的优化方法。
- `kvtier`：展示上游代码阅读、可复现实验和诚实边界。
- `open-infra-ai`：展示跨仓架构、契约和公开证据索引。

简历最多突出两个旗舰项目。辅助仓在面试追问或 GitHub 导航中出现，不逐个写成长篇 bullet。

## 3. 先选择目标岗位

### 3.1 Kernel / GPU Performance

选择条件：

- 愿意手推 online softmax、GEMM tiling、memory traffic；
- 愿意阅读 PTX/SASS 或至少掌握 Nsight 指标；
- 更喜欢局部数值和硬件问题，而不是 HTTP/调度状态机。

主路线：

```text
CUF-P0-001
  → CUF-P0-002
  → CUF-P0-003
  → CUF-P0-004
  → CUF-P1-001
  → CUF-P1-002
  → CUDA-P1-001
  → TRI-P1-007
```

必须由本人掌握：

- online softmax 递推；
- tile、warp、shared memory、register pressure；
- occupancy 与性能的非单调关系；
- Tensor Core 输入/累加语义；
- profiler 观察与推断的区别。

### 3.2 LLM Runtime / Inference Engine

选择条件：

- 喜欢 C++/CUDA、模型数据布局、KV 和 runtime lifecycle；
- 希望同时体现 kernel 与系统边界；
- 能接受真实模型、量化和 ABI 带来的复杂性。

默认推荐路线：

```text
TLLM-P0-001
  → TLLM-P0-002
  → TLLM-DPA 设计评审
  → TLLM-P0-004
  → TLLM-P0-005
  → TLLM-P1-001
  → PSRV-P1-002
```

必须由本人掌握：

- GGUF tensor、量化和 dequantization；
- Transformer decode 数据流；
- GQA/MQA head mapping；
- RoPE 和 position；
- contiguous/paged KV；
- CUDA Graph 地址稳定与 fallback；
- C ABI ownership。

### 3.3 Serving / Inference Systems

选择条件：

- 更喜欢 Rust、异步、调度、资源生命周期和压测；
- 能解释 open-loop/closed-loop、tail latency 和 overload；
- 愿意做 failure injection，而不只跑 happy path。

主路线：

```text
PSRV-P0-004
  → PSRV-P0-001 设计与实现
  → PSRV-P0-002 设计与实现
  → PSRV-P0-003
  → PSRV-P1-001
  → PSRV-P1-002
  → PSRV-P1-003
  → PSRV-P1-004
```

必须由本人掌握：

- request 与 sequence state machine；
- cancellation exactly-once cleanup；
- bounded channel/backpressure；
- admission/429；
- TTFT/TPOT/inter-chunk latency；
- Poisson arrival 与 coordinated omission；
- metrics 生命周期。

### 3.4 不确定时的默认选择

选择 **LLM Runtime**。它最容易把用户已有的 CUDA、模型、KV、FFI 和 Serving 经验连接为
一条完整故事；后续仍可向 Kernel 或 Serving 岗位偏移。

## 4. 可用时间决策

### 4.1 只有约 20 小时

不要实现 L4 kernel。目标是让已有成果可信并开始投递：

1. 修复 GPU skip/CI 真实性；
2. 选择一份现有结果包做完整口头复盘；
3. 完成一个 profiler 分析；
4. 校正 README 和简历 claim；
5. 完成两次模拟面试；
6. 开始投递并记录反馈。

### 4.2 约 60 小时

完成一个“设计 + oracle + 最小实现”：

- Runtime：TLLM-P0-002 + DPA design + 最小 kernel；
- Kernel：CUF-P0-001/002/003；
- Serving：PSRV-P0-001/002/003。

剩余时间只做 correctness、sanitizer、一次 profiler 和面试讲述，不扩展第二条深改造。

### 4.3 约 120 小时以上

完成一条全链：

```text
design
  → independent reference
  → implementation
  → GPU correctness
  → sanitizer/failure
  → integration
  → raw benchmark
  → profiler
  → README/resume/demo
```

全链完成后，优先做外部 baseline 或上游贡献，不自动开始第二个 L4 项目。

## 5. 第一轮最值得做的 10 个任务

以下顺序优先修复“证据会误导”而不是优先追逐新功能：

| 顺序 | 任务 | 价值 |
|------|------|------|
| 1 | CUDA-P0-001 | 消除 GPU 测试假绿 |
| 2 | TRI-P1-008 | 区分 CPU skip 与 GPU pass |
| 3 | KVT-P0-004 | 让离线实验脚手架进入 CI |
| 4 | PSRV-P0-004 | 真实验证 loadgen 的网络失败分类 |
| 5 | CUDA-P0-002 | 建立 ragged/NaN/Inf correctness |
| 6 | TRI-P0-001 | 冻结 custom-op eager/fake 契约 |
| 7 | TLLM-P0-002 | 建立 direct paged 的 independent oracle |
| 8 | CUF-P0-001 | 冻结 workspace/stream 设计 |
| 9 | PSRV-P0-001 | 冻结并实现主动取消 |
| 10 | KVT-P0-002 | 建立 schema v2 provenance |

这些任务完成后，再根据目标岗位进入一个深改造。

## 6. 每个任务的标准循环

### Step 1：选择

- 从 `P0_P1_AGENT_BACKLOG.md` 选一个 ID；
- 检查它是否被前置任务阻塞；
- 确认本轮唯一 owner；
- 记录 base commit 和 dirty state。

### Step 2：分级

- L0-L1：可直接派给低成本 Agent；
- L2：可派给低成本 Agent，但必须有独立 reviewer；
- L3：强模型先做设计，批准后再实现；
- L4：设计、oracle、实现、benchmark 至少拆成不同任务。

### Step 3：先验收 contract

在 Agent 写代码前，本人或 reviewer 必须能回答：

- 输入输出是什么？
- 数据 layout 是什么？
- 谁拥有资源？
- stream/concurrency 是什么？
- 错误和 fallback 是什么？
- reference 如何独立？
- 哪些 case 必须失败？
- 如何回滚？

答不出时，不允许开始 production implementation。

### Step 4：最小改动

- 一个 PR 一个目标；
- 先 failing test/reference；
- 再最小实现；
- 不同时重构；
- shared files 只有一个 owner；
- 不改测试掩盖错误。

### Step 5：分层验证

```text
CPU/build:
GPU correctness:
Sanitizer:
Performance:
Integration:
```

没有运行的栏必须保留，并写 `not_run` 或 `blocked`。

### Step 6：证据与复盘

每项任务结束必须留下：

- exact command 和 exit code；
- raw log/result；
- environment metadata；
- limitations；
- failed/negative case；
- next task；
- 本人能口头解释的 3 个问题。

## 7. 套餐结束后的 Agent 组织方式

### 7.1 不要让一个模型做全部工作

最稳妥的角色拆分：

```text
Agent A：事实审计
Agent B：设计
Agent C：独立 reference/tests
Agent D：实现
Agent E：代码审查
Agent F：benchmark/profiling
本人：批准 contract、运行真实实验、面试表达
```

低成本时可以复用同一个模型，但必须开启新对话并只提供当前角色所需上下文，避免它继续
为自己的设计和实现背书。

### 7.2 每次只提供最小上下文

发给 Agent：

1. 仓库 URL；
2. branch/base commit；
3. 一个 task ID；
4. 对应任务卡；
5. 已批准设计包；
6. 相关 symbols/files；
7. 当前 failing test；
8. allowed/forbidden scope；
9. 验证命令；
10. 输出格式。

不要发：

- 整个 12 周计划；
- 所有 44 个任务；
- 与当前文件无关的长聊天记录；
- 未确认的性能目标；
- secret 或私人求职信息。

### 7.3 主调度 Prompt

```text
你只执行一个任务：<TASK_ID>。

仓库：<REPOSITORY>
base branch：<BRANCH>
base commit：<40 位 SHA>
当前工作树：<clean/已有改动>

必须先阅读：
- AGENTS.md
- README.md
- <任务卡>
- <已批准设计包；L0-L2 可写 none>
- <相关文件列表>

规则：
1. 先验证任务卡的 current evidence；不一致时停止并报告。
2. 只修改 allowed files；需要越界时停止。
3. 不修改测试来掩盖实现错误。
4. CPU/build、GPU correctness、sanitizer、performance 分开报告。
5. 没有真实运行时写 not_run/blocked，不得写 passed。
6. L3/L4 若设计未批准，只能输出设计，不得改生产代码。
7. 不提交 benchmark 数字，除非保留 raw data、环境和重复信息。

输出：
- status
- base commit / dirty state
- changed files and symbols
- commands and exit codes
- evidence artifacts
- not run
- remaining risks
- out-of-scope findings
- recommended next task
```

### 7.4 Reviewer Prompt

```text
你是独立 reviewer，不继续实现功能。

检查 <TASK_ID> 的 diff、设计包、tests 和 evidence：
- 是否超出 allowed scope；
- reference 是否独立；
- ragged/tail/invalid/failure/cleanup 是否覆盖；
- GPU case 是否真的运行；
- 并发和 ownership 是否有未定义行为；
- fallback 是否可观察；
- benchmark 是否语义公平；
- claim 是否超过证据。

输出只能是：
approved / changes_requested / rejected

并按严重度列出：
blocker / major / minor / evidence_gap
```

### 7.5 Benchmark Agent Prompt

```text
你只负责运行和审计 benchmark，不修改生产算法。

前置：
- correctness commit：<SHA>
- GPU correctness：passed，artifact=<PATH/URL>
- sanitizer：passed/not_applicable，原因=<...>
- benchmark matrix：<...>

必须：
- 记录 commit/dirty/GPU/driver/CUDA/toolchain/model/hash；
- 保存每次 raw sample；
- 固定 warmup/repetitions/seed；
- 保留 OOM/failure；
- 计算 CV/spread；
- CV > 10% 标 not_converged；
- 不筛选最好结果；
- 不把 kernel latency 写成 serving 指标。
```

## 8. 必须由本人完成的工作

AI 可以帮助实现和整理，但以下内容不能外包：

1. **逐行阅读旗舰代码路径。**
   - Runtime：从 FFI step 到 Transformer/KV/kernel。
   - Serving：从 HTTP handler 到 scheduler/backend/SSE cleanup。
   - Kernel：从 API validation 到 launch/layout/online softmax。
2. **亲自运行至少一次完整实验。**
3. **亲自解释一个失败和一个负优化。**
4. **白板推导核心公式。**
5. **在没有文档提示时定位一次 bug。**
6. **决定简历使用哪些 claim，并承担真实性。**
7. **完成模拟面试和真实投递反馈闭环。**

如果代码主要由 Agent 编写，但本人不能解释参数、layout、ownership、错误和 benchmark，
这个项目不应进入简历主项目。

## 9. GPU 预算不足时

### 可以先完成

- API/ABI 和 design review；
- CPU reference；
- synthetic fixtures；
- error/invalid tests；
- result schema/validator；
- loadgen 本地网络 failure tests；
- CI skip 真实性；
- benchmark harness；
- 面试白板和代码走读。

### 必须保持未完成

- GPU correctness；
- Compute Sanitizer；
- CUDA Graph runtime；
- Tensor Core dispatch；
- Nsight 指标；
- 性能数字；
- 真实模型/Serving 容量。

### 租 GPU 前

一次会话尽量批量完成：

```text
environment canary
  → correctness
  → sanitizer
  → benchmark
  → profiler
  → artifact upload
  → shutdown
```

不要在计费 GPU 上现场设计 API、写长文档或大规模重构。

## 10. 遇到阻塞时

### 代码与任务卡不一致

停止。报告 expected、observed、base commit 和受影响设计，不要静默按旧路径实现。

### 缺 GPU/模型/profiler

完成不依赖资源的部分，将状态写成 partial/blocked；不要寻找不可信模型或伪造结果。

### 测试失败

先最小复现和定位，再修实现。不得：

- 删除测试；
- 放宽容差直到通过；
- 标记 skip；
- 只跑通过的 case；
- 隐藏 sanitizer error。

### benchmark 波动

检查：

- warmup；
- GPU clock/power；
- 同机 load；
- allocation/sync；
- 输入是否一致；
- A/B 顺序；
- sample 数。

仍不稳定时写 `not_converged`，保留 raw data，不强行得出结论。

### Agent 反复越界

缩小任务为：

```text
只读一个 symbol
  → 只新增一个 failing test
  → 只修改一个实现文件
  → 只运行一个 test filter
```

两次仍越界，换 reviewer/模型，不继续堆叠 prompt。

## 11. 何时开始投递

不需要等待 44 个任务全部完成。满足以下最低门槛即可开始：

1. 两条旗舰主线能用 90 秒讲清；
2. 至少一个旗舰达到真实 GPU correctness；
3. 至少一份 E4 级可复现性能结果；
4. 至少一个深问题能讲 design→bug→test→result→limitation；
5. README 和简历没有越级 claim；
6. 能展示 raw artifact；
7. 完成两次模拟面试；
8. 准备 Kernel/Runtime/Serving 至少一个岗位版本简历。

投递和完善项目应并行。等待“所有项目完美”会推迟最重要的市场反馈。

## 12. 面试准备的最小闭环

每个旗舰项目准备：

### 30 秒

- 解决什么问题；
- 本人负责什么；
- 最强证据是什么；
- 最大限制是什么。

### 2 分钟

- 架构；
- 一个难点；
- 如何验证；
- 一项观察；
- 下一步。

### 10 分钟

- 数据流/状态机；
- API 和 layout；
- correctness oracle；
- failure/ownership；
- benchmark 和 profiler；
- 负结果；
- 与成熟系统的边界。

### 必答追问

1. 为什么不用 llama.cpp/vLLM/FlashAttention 官方实现？
2. 哪一部分是本人实现，哪一部分是 Agent 辅助？
3. 如何知道结果是正确的？
4. 性能数字如何复现？
5. 为什么这个 baseline 公平？
6. 哪些输入不支持？
7. 并发或失败时资源如何释放？
8. 如果再做一次，会先改什么？

## 13. 简历 claim 决策

每个 bullet 在写入前建立：

| 字段 | 内容 |
|------|------|
| Claim | 准备写入的句子 |
| Repository | 证据仓 |
| Commit | exact SHA |
| Evidence level | E2/E3/E4/E5 |
| Correctness | test/report |
| Performance | raw/report 或 not_measured |
| Scope | GPU/model/shape/workload |
| Limitation | 不可外推内容 |
| Interview owner | 本人是否能解释 |

删除或降级满足任一条件的 claim：

- 找不到 exact commit；
- 只有 README 数字，没有 raw evidence；
- GPU tests 实际 skipped；
- baseline 不公平；
- 本人无法解释实现；
- 当前代码已不再支持；
- claim 使用“全面、生产级、通用、显著”等超范围词。

## 14. 最后的优先级

```text
P0 证据真实性
  > 一个旗舰深改造
  > GPU correctness + sanitizer
  > profiler 解释
  > 公平 baseline
  > 面试排练
  > 投递反馈
  > 第二个深改造
  > 新项目
```

如果只能记住一句：

> 不要试图证明“做过很多”；要证明你能把一个复杂系统的接口、布局、生命周期、正确性和
> 性能证据完整闭环，并且知道结论不能外推到哪里。

## 15. 本仓文档使用顺序

1. `FINAL_EXECUTION_PLAYBOOK.md`：决定目标岗位、时间和下一条路线。
2. `P0_P1_AGENT_BACKLOG.md`：选择一个任务 ID。
3. `L3_L4_DESIGN_REVIEW_PACKAGES.md`：L3/L4 先冻结设计。
4. `AGENT_EXECUTION_GUIDE.md`：生成任务 Prompt 和验收。
5. `AI_INFRA_PRACTICE_AND_CAREER_GUIDE.md`：运行 correctness/benchmark/profiler。
6. `INTERVIEW_MATRIX.md`：准备追问。
7. `APPLICATION_PLAN.md`：投递和反馈闭环。

执行完成后回到第一步，只重新选择下一个任务，不重新设计整套路线。
