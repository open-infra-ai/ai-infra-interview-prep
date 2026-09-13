# 下一位 AI Agent 从这里开始

> 本页是新 Agent 的稳定入口，不是新的路线图。它用于在上下文丢失、模型更换、本地路径变化
> 或旧 handoff 过期后，重新建立可信当前状态，并只执行一个任务。

## 1. 给 Agent 的第一条指令

```text
不要重新设计整个 AI Infra 学习计划，不要通读所有仓库，也不要新增项目。
先按本文重建当前事实，然后从 P0_P1_AGENT_BACKLOG.md 选择一个任务 ID。
一次只执行一个任务；L3/L4 必须先过设计评审。
```

## 2. 当前冻结事实

### 仓库集合

公开技术与治理仓：

```text
open-infra-ai/open-infra-ai
open-infra-ai/cuda-foundations
open-infra-ai/trifuse
open-infra-ai/cuflash
open-infra-ai/tiny-llm
open-infra-ai/paged-serving
open-infra-ai/kvtier
```

个人执行仓：

```text
open-infra-ai/ai-infra-interview-prep
```

### 旗舰边界

```text
旗舰系统：
  tiny-llm runtime data plane
      ⇅ 受测试的 C ABI
  paged-serving serving control plane

Kernel 深度：
  cuflash

Triton/PyTorch 对照：
  trifuse

基础：
  cuda-foundations

上游研究：
  kvtier
```

不可重新决定：

- 不新增第八个练习项目；
- `cuflash` 和 `trifuse` 不是 `tiny-llm` runtime 硬依赖；
- `tiny-llm` 当前 paged storage/gather 路径不能自动称为 direct PagedAttention；
- `paged-serving` scheduler batching 不能自动称为 fused GPU batch compute；
- `kvtier` 是上游研究和实验脚手架，不是自研生产 tiering engine；
- CPU/build、GPU correctness、benchmark、profiler 和 Serving 是不同证据层。

如果当前代码与上述事实发生实质变化，Agent 必须提供 commit、symbol、test 和 evidence，
不能只依据 README 宣布边界已改变。

## 3. 信息优先级

发生冲突时按以下顺序：

```text
用户当前明确指令
  > 目标路径上的 AGENTS.md
  > 当前代码与真实测试/结果
  > P0_P1_AGENT_BACKLOG.md 的当前任务
  > 已批准的 L3_L4_DESIGN_REVIEW_PACKAGES.md 设计
  > PROJECT_MILESTONES_AND_INTERVIEW_GUIDE.md 的阶段/面试映射
  > FINAL_EXECUTION_PLAYBOOK.md
  > 其他 live 文档
  > dated handoff / archive / 旧聊天摘要
```

不能用旧计划覆盖当前代码，也不能用当前猜测改写历史事实。

## 4. 必须识别的旧信息陷阱

以下内容可能出现在历史文件中，但不能直接当作当前事实：

| 旧信息 | 当前处理 |
|--------|----------|
| `holtwood/ai-infra-interview-prep` | 当前个人执行仓为 `open-infra-ai/ai-infra-interview-prep` |
| `triton-fused-ops` | 当前公开仓名为 `trifuse` |
| “五个技术仓” | 当前有六个技术仓，另有一个 meta 仓 |
| `AICL-Lab` / `aicl-lab` | 历史组织名；archive 中保持原样 |
| `/home/shane/...` 等固定路径 | 只表示历史机器；必须重新发现当前 checkout |
| 2026-08 的 commit/CI/结果状态 | 历史快照；重新 fetch 和验证 |
| `handoffs/deepseek-v4-flash/` | dated archive；可学习格式，不作为当前任务状态 |
| archive 面试数字 | 只有当前技术仓 raw evidence 仍有效时才可引用 |

禁止全仓批量替换这些历史字符串。先区分 live 与 archive。

## 5. 新会话启动算法

### Step 1：读取最小入口

只先读：

1. 本文件；
2. 本仓 `AGENTS.md`；
3. 本仓 `FINAL_EXECUTION_PLAYBOOK.md` 的第 1、3、5、6、14 节；
4. 目标技术仓从根到目标文件路径上的 `AGENTS.md`；
5. 目标仓 README 中与当前任务直接相关的部分。

不要在选择任务前通读所有 12 周文件、archive 或全部技术仓。

### Step 2：发现真实 checkout

不要假设路径。若工具提供仓库列表，先使用仓库列表；已有本地目录时验证 remote：

```bash
git -C <repo> remote -v
git -C <repo> status --short --branch
git -C <repo> rev-parse HEAD
git -C <repo> rev-parse --is-shallow-repository
```

如果 shallow 且任务需要 history，再 `git fetch --unshallow`。不需要 history 时不要无意义下载。

### Step 3：同步但不破坏工作树

```bash
git -C <repo> fetch origin --prune
git -C <repo> status --short
```

若存在未知 dirty/untracked：

- 不删除；
- 不 reset；
- 不 stash；
- 先识别 owner 和任务来源；
- 与用户声明的预期不符时立即报告。

### Step 4：检查外部状态

检查：

- 默认分支；
- open PR；
- 当前 branch 是否已关联 PR；
- CI；
- review comments；
- 任务引用的 issue/PR 是否仍存在；
- 结果 artifact 链接是否可访问。

不能从本地 branch 名猜 PR 状态，也不能因旧 handoff 写 `merged` 就跳过检查。

### Step 5：选择一个任务

在 `P0_P1_AGENT_BACKLOG.md` 中搜索完整 task ID，只读取该任务和直接依赖。

若用户没有指定岗位或任务，默认建议：

```text
TLLM-P0-002：建立 paged/contiguous synthetic oracle
```

原因：

- 不依赖真实模型即可先做大部分工作；
- 为 direct paged attention 提供独立 correctness 门禁；
- 同时服务 Runtime 和 Serving 主线；
- 风险低于直接写 L4 kernel。

替代入口：

| 用户目标 | 首选任务 |
|----------|----------|
| CUDA/Kernel | `CUF-P0-001`，先冻结 workspace/stream lifecycle |
| Serving | `PSRV-P0-004`，先验证真实 HTTP/SSE failure path |
| 纯 CPU/无 GPU | `KVT-P0-004` 或 `TRI-P0-001` |
| 修证据真实性 | `CUDA-P0-001` 或 `TRI-P1-008` |

若首选任务已经完成，必须在当前默认分支找到 merged commit 和验收证据，再选择它的直接下游，
不能因为文件存在就判定完成。

### Step 6：确定复杂度

```text
L0/L1：直接执行
L2：执行 + 独立 review
L3：先设计评审，再实现
L4：设计、reference、实现、benchmark 分开
```

L3/L4 必须读取 `L3_L4_DESIGN_REVIEW_PACKAGES.md` 对应包。设计没有 `approved` 时，Agent
只能提交设计、tests 或 oracle，不能修改 production algorithm。

## 6. 第一份状态回报

Agent 在修改前只回报以下内容，不写长篇规划：

```yaml
task_id: <one id>
repository: <owner/name>
base_branch: <branch>
base_commit: <40-char SHA>
current_branch: <branch>
dirty: <true/false>
open_pr: <number/null>
complexity: <L0-L4>
dependencies:
  - <task id or none>
current_evidence:
  - <verified code/test/result>
expected_output:
  - <one concrete deliverable>
validation:
  - <exact command>
blocked:
  - <none or exact blocker>
```

随后直接执行权限内工作。不要用状态回报代替工作。

## 7. 权限矩阵

未明确授权时采用保守默认：

```yaml
local_read: true
local_edit_in_scope: true
local_build_test: true
local_gpu: only_if_available_and_free
git_commit: true
git_push: true
create_pr: true
merge_pr: false
paid_gpu: false
download_restricted_model: false
external_issue_or_comment: false
change_public_api_or_abi: false
```

规则：

- 用户授权一种操作不自动授权其他操作；
- paid GPU、受限模型、外部发帖、breaking ABI 必须单独批准；
- 没有某项授权时，完成所有安全准备，在精确门禁处标 `blocked`，不要反复询问；
- 仓库已有写权限不代表可以直接 push 默认分支。

## 8. 上下文预算规则

低成本 Agent 容易在大上下文中忽略 contract，因此：

### 只加载

- 一个 task card；
- 直接依赖；
- 已批准设计；
- 目标 symbols；
- 相邻 tests；
- build/test command；
- 一个最近有效 evidence package。

### 不加载

- 全部 44 个任务；
- 全部周计划；
- 全部历史 handoff；
- archive 面试材料；
- 所有仓库 README；
- 与任务无关的 benchmark 数字。

### 搜索顺序

```text
task ID
  → public symbol
  → call sites
  → tests
  → result/benchmark entry
  → history（只有需要时）
```

不要先凭文件名猜架构。

## 9. 代码任务执行规则

1. 先验证任务卡的 `current evidence`；
2. 冻结 input/output/layout/ownership/error；
3. 先写 independent reference 或 failing test；
4. 做最小 production change；
5. scoped test/lint；
6. affected suite；
7. GPU/sanitizer（若需要且可用）；
8. review diff；
9. commit、push、PR；
10. 记录 evidence 和 handoff。

禁止：

- 修改测试来适配错误实现；
- 为通过 CI 关闭安全策略或 hook；
- 增加未经需要的依赖；
- 顺手重构相邻模块；
- 把 L3/L4 一次塞入单个超大 PR；
- correctness 未通过就测性能；
- 自动筛掉失败/OOM/429；
- 没有 raw data 就写 speedup。

## 10. 文档任务执行规则

总体规划已经完成。只有以下情况才新增文档：

- 新 implementation 需要 design/contract；
- 新实验需要 methodology/schema/report；
- 新证据需要 manifest/limitations；
- 新面试反馈需要复盘；
- live 文档与当前代码发生可证实的不一致。

不要新增：

- 第三份“总路线图”；
- 重复的 12 周计划；
- 没有 owner 和验收的愿望清单；
- 从技术仓复制过来的源码说明；
- 未运行实验的数字表；
- 仅为增加 GitHub commit 数量的文档。

## 11. Evidence 处理

新正式结果应遵循组织 meta 仓：

```text
docs/evidence-artifact-lifecycle.md
docs/evidence-manifest.schema.json
```

Agent 必须：

- 先看 manifest 和 raw，再看 summary；
- 验证 artifact hash；
- 绑定 exact commit/dirty；
- 区分 E0–E5；
- 保留 failure/not-converged；
- 只使用 allowed claim；
- 代码路径变化时检查旧证据是否 stale。

旧结果没有 manifest 时，不要求一次性迁移；只有重新引用或重新发布时补齐。

## 12. PR 与 Review

一个 PR 应满足：

- 一个 task ID 或一个紧密不可分的 contract；
- 描述 why、current behavior、new behavior、validation、limitations；
- 不夹带进度表或私人求职信息；
- 不依赖未提交的本地文件；
- 所有 required evidence 可访问；
- L3/L4 有 design decision；
- benchmark PR 绑定 correctness commit。

实现 Agent 不应成为唯一 reviewer。Reviewer 至少检查：

- reference 是否独立；
- ragged/tail/invalid/failure；
- ownership/cleanup/stream；
- skip 是否可见；
- baseline 是否等价；
- claim 是否越级；
- rollback 是否可执行。

## 13. 会话结束交接

使用 `AGENT_EXECUTION_GUIDE.md` 第 15 节压缩格式，至少记录：

```yaml
task_id:
status: complete | partial | blocked | failed
base_commit:
current_commit:
dirty:
changed_files:
decisions:
verified:
failed:
not_run:
artifacts:
open_questions:
next_task_id:
next_exact_command:
```

完成判定：

### `complete`

- acceptance 全部满足；
- required validation 已运行；
- artifact 可访问；
- PR/commit 状态清楚；
- 没有把 required test 写入 `not_run`。

### `partial`

- 有可复用产出，但仍缺 acceptance；
- 明确剩余工作，不称“基本完成”。

### `blocked`

- 精确说明缺 GPU、secret、权限、外部依赖或批准；
- 已完成安全的前置工作；
- 给出解锁后的第一条命令。

### `failed`

- 保留复现、日志和尝试；
- 不删除失败分支或 raw artifact；
- 给出最安全的 rollback。

## 14. 给本人检查 Agent 的五个问题

每轮只问：

1. 你修改的核心 symbol 是什么，为什么只改这些？
2. reference 是否真的不复用生产逻辑？
3. 哪个 test 证明错误路径或 cleanup？
4. 哪些验证没有运行，为什么？
5. 下一位 Agent 用哪条命令可以继续？

任何一个问题无法回答，都不应把任务标记为完成。

## 15. 最短可复制 Prompt

```text
先读仓库根 NEXT_AGENT_START_HERE.md 和 AGENTS.md。
不要重新规划，也不要通读全仓。

目标：执行 <TASK_ID>。
仓库：<OWNER/REPO>
base：<BRANCH + COMMIT>
允许文件：<...>
禁止范围：<...>

先验证任务卡 current evidence；不一致就停止并报告。
L3/L4 若无 approved design，只做设计/reference/tests。
CPU、GPU correctness、sanitizer、performance 分开报告。
未运行写 not_run；blocked、failed、OOM、429、not_converged 不得隐藏。
最后按 AGENT_EXECUTION_GUIDE.md 第 15 节交接。
```

## 16. 下一步唯一建议

如果用户没有新的岗位选择、外部面试反馈或紧急 CI，下一位 Agent 不应继续写建议文档。

执行：

```text
审计 TLLM-P0-002 当前状态
  → 缺失时完成 independent paged/contiguous synthetic oracle
  → 通过后进入 direct paged attention 的 G0-G8 设计
```

这是当前从“文档齐全”进入“旗舰技术证据”的最短路径。
