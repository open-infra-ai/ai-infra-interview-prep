# AI Infra 低成本 AI Agent 执行规范

> 目标：把 AI Infra 开发任务拆成低成本模型也能可靠执行、强模型和人工容易复核的
> 小任务。本文不授权 Agent 自行扩大范围，也不允许用生成文本代替真实测试、benchmark
> 或 profiling。

## 1. 核心原则

所有 Agent 必须遵守：

1. **先读规则，再改代码**：先读目标仓库的 `README.md`、`AGENTS.md`、
   `CONTRIBUTING.md` 和构建配置。
2. **只修改授权文件**：未列入 `allowed_files` 的文件不得修改。
3. **一次只解决一个问题**：不顺手重构、不升级无关依赖、不清理无关 warning。
4. **正确性先于性能**：没有独立 reference 和测试，不开始优化。
5. **证据先于结论**：命令、退出码和 raw artifact 必须真实存在。
6. **失败也要保存**：OOM、429、未收敛、性能回退和环境阻塞都是结果。
7. **不知道就写 unknown**：不得猜测 API、硬件、提交状态或性能原因。
8. **不把未来目标写成已完成**。
9. **不把 skip 写成 passed**。
10. **不把模拟或理论写成真实 GPU/多 GPU 实验**。

## 2. 哪些任务适合低成本模型

### 适合

- 读取有限文件并生成结构化摘要；
- 补充已明确接口的单元测试；
- 将重复 benchmark 输出转换成 CSV/JSON；
- 实现已有伪代码和验收标准的小函数；
- 增加参数校验和错误消息；
- 修复文档链接、术语不一致和索引；
- 为已有 experiment 补 metadata/schema 校验；
- 运行确定的 lint、typecheck 和 scoped test；
- 对小 diff 做 checklist 式代码审查；
- 根据 raw data 生成图表，不解释因果。

### 需要强模型或人工复核

- 新 CUDA/Triton kernel 设计；
- 数值稳定性和并行算法；
- direct paged attention；
- 并发、stream、workspace、allocator 和 CUDA Graph 生命周期；
- Rust/C++ FFI ownership；
- scheduler、preemption、prefix cache；
- benchmark 公平性和性能归因；
- ncu/nsys counter 解释；
- 安全、ABI、数据竞争和内存错误；
- 大规模重构或跨仓契约变更；
- 简历中的性能数字和技术声明；
- 分布式算法与故障恢复结论。

低成本模型可以为这些复杂任务准备测试、调用图、候选方案和 evidence packet，但不能单独
批准合并或发布结论。

## 3. 任务复杂度分级

| 等级 | 典型范围 | 建议执行者 | 必需复核 |
|------|----------|------------|----------|
| L0 | 只读检索、索引、格式、命令执行 | 低成本模型 | 自动检查 |
| L1 | 单文件、接口明确、无并发/性能语义 | 低成本模型 | 常规模型或人工 |
| L2 | 2–5 文件、补测试、小功能、schema | 中等模型 | 强模型或人工 |
| L3 | CUDA/Triton、FFI、调度、benchmark | 强模型 | 人工 + 实测 |
| L4 | 跨仓架构、分布式、生产 SLO、简历结论 | 强模型 + 人工 | 用户最终批准 |

如果执行中出现以下情况，任务自动升级一级：

- 需要修改未授权文件；
- 发现接口与任务描述不一致；
- 需要调整测试期望；
- 需要改变性能口径；
- 需要新增依赖；
- 遇到非确定性、数据竞争、OOM 或未解释回退；
- 结论要进入 README、简历或正式性能报告。

## 4. 标准任务单

不得只给 Agent 一句“优化一下”。使用：

```yaml
task_id: TLLM-PAGED-001
title: 为 direct paged attention 增加输入契约测试
repository: open-infra-ai/tiny-llm
base_branch: master
objective: >
  为现有 paged KV API 增加 block boundary、tail 和 invalid block id 测试，
  不实现新 kernel。
why: >
  先冻结正确性契约，供后续 direct paged attention 使用。
allowed_files:
  - tests/test_paged_kv.cu
  - docs/paged-kv-contract.md
forbidden:
  - 不修改生产 kernel
  - 不修改容差
  - 不增加依赖
inputs:
  - 当前 API 头文件
  - 现有连续 KV reference test
acceptance:
  - 新测试覆盖 block_size-1、block_size、block_size+1
  - invalid block id 返回现有错误类型
  - 原有 scoped suite 通过
commands:
  - cmake --build build -j2
  - ctest --test-dir build -R paged_kv --output-on-failure
required_evidence:
  - git diff --check
  - 命令、退出码和测试摘要
  - 修改文件列表
out_of_scope:
  - benchmark
  - direct paged attention 实现
stop_conditions:
  - 当前 API 无法表达 invalid block id
  - 需要修改生产代码
```

每个任务必须包含：

- 仓库和 base branch；
- 目标和原因；
- 允许修改的文件；
- 明确不做什么；
- 输入材料；
- 验收标准；
- 验证命令；
- 证据；
- 停止和升级条件。

## 5. 上下文包

低成本模型上下文越小越可靠。只提供：

1. 仓库规则；
2. 任务单；
3. 目标接口；
4. 相邻实现；
5. 相关测试；
6. 构建/测试命令；
7. 现有错误日志；
8. 必要设计文档。

不要直接把全仓、几万行日志或无关历史塞入 prompt。

### 上下文摘要格式

```markdown
## Repository contract
- Language/toolchain:
- Required commands:
- Style:
- Do not:

## Relevant symbols
- `symbol`: file, responsibility

## Existing behavior
- Input:
- Output:
- Error:

## Known evidence
- Passing:
- Failing:
- Not run:

## Decision already made
- ...

## Unknown
- ...
```

如果摘要来自另一个 Agent，接收者必须通过源码或命令核对关键事实。

## 6. 标准执行流程

### Step 1：确认边界

Agent 在修改前输出：

```text
目标：
允许文件：
不会修改：
验收命令：
需要升级的条件：
```

发现任务中声明的文件、脚本、分支或配置不存在时立即停止，报告“预期是什么、实际是什么”；
不得自行新建替代品掩盖问题。

### Step 2：建立基线

- 运行最小相关测试；
- 记录基线是否通过；
- 保存失败日志；
- 确认 GPU/模型是否真实可用；
- 查看 `git status --short`，避免覆盖他人修改。

如果没有基线，最终不能声称“没有回归”。

### Step 3：最小实现

- 模仿相邻代码风格；
- 不修改无关格式；
- 不做“顺手优化”；
- 不修改测试使错误实现通过；
- 不使用硬编码绕过通用逻辑；
- 不新增未经确认的依赖；
- 不更改安全、依赖或 branch policy。

### Step 4：Scoped 验证

先运行：

- 改动文件 lint/format；
- 相关单测；
- 失败测试的精确 filter；
- 最小 smoke。

通过后再运行受影响 suite。没有要求时，不用低成本 Agent 长时间跑全仓 GPU 矩阵。

### Step 5：审阅 diff

检查：

- 是否只改 allowed files；
- 是否改变公开 API；
- 是否扩大 scope；
- 是否添加无根据声明；
- 是否残留 debug；
- 是否将 skip 当成功；
- 是否写入机器路径、模型路径或 secret；
- 是否修改用户未授权的测试期望。

### Step 6：结构化汇报

最终只报告事实：

```markdown
## Status
complete | partial | blocked

## Changed
- 文件：
- 符号：

## Validation
| Command | Exit | Result |
|---------|-----:|--------|

## Evidence
- raw artifact:
- test log:
- commit/diff:

## Not run
- 命令：
- 原因：

## Remaining risks
- ...

## Out-of-scope findings
- ...
```

## 7. 证据规范

### 7.1 三种验证必须分开

Agent 的报告必须区分：

```text
CPU tests:
GPU correctness:
Performance benchmark:
```

例如：

```text
CPU tests: 57 passed
GPU correctness: not run — no CUDA device
Performance benchmark: not run
```

禁止写成“所有测试通过”。

### 7.2 正式性能结果的最小 metadata

```json
{
  "timestamp_utc": "",
  "repository": "",
  "commit": "",
  "dirty": false,
  "gpu": "",
  "driver": "",
  "cuda": "",
  "compiler": "",
  "framework": "",
  "model": "",
  "model_sha256": "",
  "dtype_or_quantization": "",
  "input": {},
  "warmup": 0,
  "iterations": 0,
  "independent_processes": 0,
  "random_seed": 0,
  "command": "",
  "raw_result": "",
  "limitations": []
}
```

缺少关键字段时只能标为 canary 或 exploratory，不能标为正式结果。

### 7.3 原始数据

必须保留：

- 每次 iteration；
- 每个请求；
- 错误、429 和 timeout；
- baseline 和 variant；
- 实际执行顺序；
- 随机种子；
- 环境 metadata。

图表和 summary 必须由 raw data 生成，不得手工抄写后删除原始结果。

### 7.4 性能结论

低成本模型可以计算：

- mean；
- median；
- p95/p99；
- IQR；
- CV；
- 配对差值。

低成本模型不得仅凭这些数字断言：

- kernel 是 memory-bound；
- Tensor Core 已饱和；
- scheduler 是瓶颈；
- 优化可以推广到其他 GPU；
- 实现全面超过 vLLM、llama.cpp、PyTorch 或 FlashAttention。

这些结论需要 profiler、源码和人工复核。

## 8. benchmark 任务规则

Agent 必须先验证：

- baseline 与 variant 使用同一 commit 基础；
- GPU、模型、输入和量化固定；
- warmup 不进入统计；
- 没有后台 GPU 污染；
- A/B 顺序交错；
- 每配置至少三个独立进程；
- correctness 先通过；
- raw output 不被覆盖。

必须报告：

- 成功和失败样本；
- p50/p95；
- 进程间波动；
- 主要回退 shape；
- 结果是否收敛；
- 不能证明什么。

如果 CV 或关键重复波动超过任务阈值，返回 `status=partial` 和
`conclusion=not_converged`，不得挑最好的一次。

## 9. profiling 任务规则

### Nsight Systems

低成本 Agent 可以：

- 运行已给定的 `nsys profile` 命令；
- 导出 summary；
- 列出耗时最多的 kernels；
- 标注明显 launch gap 和 memcpy。

需要升级：

- 推断 CPU/GPU 因果；
- 决定 CUDA Graph 边界；
- 判断并发和 stream 设计。

### Nsight Compute

低成本 Agent 可以：

- 按指定 filter 采集 `.ncu-rep`；
- 导出任务指定 metrics；
- 对比 baseline/variant 数值。

需要升级：

- 解释 stall 原因；
- 选择 tile、block、register 或 shared memory 改造；
- 解释 Roofline；
- 判断 replay 是否污染测量；
- 将 counter 写成 README 或简历结论。

## 10. 多 Agent 并行

### 文件所有权

每个 Agent 获得不重叠的文件集合：

```yaml
agent_a:
  owns:
    - src/paged_attention.cu
agent_b:
  owns:
    - tests/test_paged_attention.cu
agent_c:
  owns:
    - benchmarks/paged_attention_bench.cu
```

共同文件由单一 integration Agent 修改：

- build config；
- public header；
- lockfile；
- README；
- release notes。

### 依赖顺序

```text
contract → tests/reference → implementation → benchmark → profiling → docs/review
```

如果下游需要上游未完成接口，不允许猜接口。等待契约或返回 blocked。

### 冲突处理

- 不覆盖他人未提交修改；
- 不用 destructive git command；
- 不自行解决架构冲突；
- clerical conflict 可由 integration Agent 处理；
- 接口语义冲突必须升级人工；
- 不通过复制同一逻辑到新文件绕过冲突。

## 11. 升级和停止条件

Agent 必须停止并升级：

- 用户声明存在的文件、secret、GPU 或模型实际不存在；
- 需要修改未授权文件；
- 需要改公开 API；
- 需要新增依赖；
- 测试与设计文档互相矛盾；
- baseline 已失败且原因不明；
- 性能结果明显回退；
- benchmark 未收敛；
- profiler 与预期相反；
- 发现数据竞争、越界或资源泄漏；
- 需要使用真实凭证；
- 需要声称生产级、分布式或简历数字。

阻塞报告：

```markdown
## Expected

## Observed

## Attempts

## Evidence

## Safest options
1.
2.

## Recommendation
```

## 12. Review checklist

Reviewer 只批准满足以下条件的任务：

- [ ] 任务单完整；
- [ ] 修改范围未扩大；
- [ ] 实现与接口契约一致；
- [ ] 测试没有为通过而弱化；
- [ ] CPU/GPU/performance 结果已分开；
- [ ] skip 未写成 passed；
- [ ] raw artifact 存在；
- [ ] benchmark metadata 完整；
- [ ] 没有伪造硬件、模型或多 GPU；
- [ ] 失败和未运行项已写明；
- [ ] 没有个人路径、secret 或敏感信息；
- [ ] 公共声明与当前实现一致；
- [ ] 复杂性能结论已由强模型或人工复核。

## 13. 完成定义

一个 Agent 任务只有在以下条件全部满足时才是 `complete`：

1. 验收项逐条满足；
2. allowed files 之外没有修改；
3. 必需命令实际执行；
4. 退出码和结果已记录；
5. raw evidence 已保存；
6. 未运行项明确说明；
7. 没有 unresolved correctness failure；
8. 没有把环境缺失、skip 或 canary 包装成成功；
9. reviewer 可以只看任务单、diff 和 evidence 复核。

否则使用 `partial` 或 `blocked`。

## 14. 可复制 Prompt 模板

### 14.1 小型代码实现

```text
你是执行 Agent，只完成下面任务，不扩大范围。

[粘贴标准任务单]

先读取仓库 README、AGENTS、CONTRIBUTING 和目标文件。修改前列出目标、
allowed files、验收命令和停止条件。

要求：
- 只修改 allowed_files；
- 不修改测试期望来掩盖错误；
- 不新增依赖；
- 不做无关重构；
- 先运行 scoped baseline；
- 完成后运行任务单中的命令；
- 按 Status/Changed/Validation/Evidence/Not run/Remaining risks 输出；
- 无法验证时返回 partial 或 blocked，不得猜测。
```

### 14.2 补正确性测试

```text
为指定接口补充 correctness 测试。先写出输入/输出/dtype/layout/容差/错误语义，
再寻找独立 reference。

[粘贴标准任务单]

必须覆盖正常、边界、非法输入和资源回收。不得复制生产实现作为 reference；
不得扩大容差来通过测试。CPU test、GPU correctness、Sanitizer 分开报告。
```

### 14.3 运行 benchmark

```text
只运行和审计 benchmark，不修改生产代码。

[粘贴标准任务单]

开始前记录 commit、dirty、GPU、driver、CUDA、compiler、模型 SHA-256、输入、
warmup、iterations、独立进程数和命令。先跑 correctness canary，再按 A/B 交错。
保存逐 iteration/逐请求 raw data。报告 p50/p95、波动、失败和回退；未收敛时明确
写 not_converged，不得挑最好 run，不得解释 profiler 未证明的原因。
```

### 14.4 采集 profiler

```text
只采集任务指定的 nsys/ncu 证据，不修改算法。

[粘贴标准任务单]

先用 nsys 确认目标区间和 kernel，再用精确 kernel filter 运行 ncu。保存原始
.nsys-rep/.ncu-rep、命令和导出 summary。将“工具直接显示的事实”“你的解释”
和“尚未确认”分开。不要从单次 profile 推广到其他 GPU 或 workload。
```

### 14.5 文档真实性审计

```text
审计文档声明是否能由当前源码、测试和 artifact 支持，不实现新功能。

[粘贴标准任务单]

为每条关键声明标记：
- verified：源码/测试/原始结果直接支持；
- partial：只支持较窄范围；
- planned：尚未完成；
- stale：与当前实现不一致；
- unknown：证据不足。

重点检查 skip、性能数字、量化、PagedAttention、batching、FlashAttention、
Tensor Core、GPU 架构和分布式声明。只修改 allowed_files；不创造不存在的证据。
```

### 14.6 代码审查

```text
你是只读 reviewer，不修改文件。

[粘贴任务目标和 diff]

按严重度输出 correctness、内存安全、并发/stream、API、性能测量、测试缺口和文档
真实性问题。每条 finding 必须包含文件/符号、触发条件、影响和最小修复建议。
不要报告纯风格问题，除非违反仓库规则。没有证据时写 question，不写 bug。
```

### 14.7 失败恢复

```text
不要继续扩大修改。基于现有任务单和日志，输出 Expected、Observed、Attempts、
Evidence、Safest options 和 Recommendation。区分代码 bug、环境缺失、权限问题、
GPU/模型缺失和 benchmark 未收敛。不要自行替换模型、GPU、接口或测试目标。
```

## 15. 任务交接压缩格式

多轮或多 Agent 交接时只传：

```yaml
task_id:
status:
base_commit:
current_commit:
dirty:
allowed_files:
changed_files:
decisions:
verified:
failed:
not_run:
artifacts:
open_questions:
next_exact_command:
```

禁止只写“差不多完成”“测试应该能过”“性能看起来更快”。交接信息必须让下一位执行者
可以复现，而不是重新猜测上下文。
