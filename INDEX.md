# 🗺️ 文档索引

本仓库全部文档按「规划 → 执行 → 追踪 → 参考」四类归档。
**入口始终是 [README.md](README.md)**;本文用于快速定位。AI 代理请看 [AGENTS.md](AGENTS.md)。

## 规划(定方向)

| 文档 | 内容 | 何时用 |
|------|------|--------|
| [TARGET_ROLES.md](TARGET_ROLES.md) | 主/次/可选岗位方向与边界 | 岗位决策、方向调整 |
| [JOB_MARKET_EVIDENCE.md](JOB_MARKET_EVIDENCE.md) | 23 个基线岗位、8 个增量岗位与技能趋势 | 每两周复查链接有效性 |
| [BASELINE.md](BASELINE.md) | 已有优势与真实短板 | 自评、复盘 |
| [SKILL_MATRIX.md](SKILL_MATRIX.md) | 能力等级、证据、差距行动 | 每周自评 |
| [TOPIC_WEIGHTS.md](TOPIC_WEIGHTS.md) | 288h 时间权重 + 三档缩放 | 调时间分配(改后跑 `make verify`) |
| [ROADMAP.md](ROADMAP.md) | 12 周主线与每周必须交付 | 宏观规划 |
| [PROJECT_STRATEGY.md](PROJECT_STRATEGY.md) | 已定项目组合 | 项目相关工作 |
| [CLOUD_GPU_PLAYBOOK.md](CLOUD_GPU_PLAYBOOK.md) | 云 GPU 选型、预算、实验闭环与评测矩阵 | 采购/租用云算力前 |
| [study-plan.md](study-plan.md) | 每周节奏与执行方法 | 安排当周节奏 |

## 执行(每周计划)

| 文档 | 内容 | 何时用 |
|------|------|--------|
| [AI_INFRA_PRACTICE_AND_CAREER_GUIDE.md](AI_INFRA_PRACTICE_AND_CAREER_GUIDE.md) | 实验、正确性、benchmark、profiling、面试和转型执行手册 | 每次技术实践前 |
| [AGENT_EXECUTION_GUIDE.md](AGENT_EXECUTION_GUIDE.md) | 低成本 AI Agent 的任务单、证据、升级和 Prompt 模板 | 委托 AI 执行任务前 |
| [P0_P1_AGENT_BACKLOG.md](P0_P1_AGENT_BACKLOG.md) | 六仓 P0/P1 任务 ID、代码锚点、范围、验收、证据与依赖 | 给 Agent 派发一个具体技术任务时 |
| [L3_L4_DESIGN_REVIEW_PACKAGES.md](L3_L4_DESIGN_REVIEW_PACKAGES.md) | direct paged attention、workspace、FFI、并发和性能矩阵设计门禁 | 任何 L3/L4 任务实现前 |
| [FINAL_EXECUTION_PLAYBOOK.md](FINAL_EXECUTION_PLAYBOOK.md) | 规划完成后的岗位选择、时间决策、任务优先级、Agent 调度与投递门槛 | 决定下一步或高能力 Agent 支持结束前 |
| [NEXT_AGENT_START_HERE.md](NEXT_AGENT_START_HERE.md) | 新 Agent 的事实重建、历史陷阱、默认任务、权限和最终交接协议 | 开启任何新的编码 Agent 会话时首先发送 |
| [PROJECT_MILESTONES_AND_INTERVIEW_GUIDE.md](PROJECT_MILESTONES_AND_INTERVIEW_GUIDE.md) | 七仓逐阶段任务、成果证据、搭建关系和面试叙事 | 制定项目迭代或准备项目面试 |

| 周次 | 主题 | 日期 | 状态 |
|------|------|------|------|
| [第 1 周](weekly/week-01.md) | 基线评估、CUDA 模型、环境与性能工具 | 08-24 ~ 08-30 | ⬜ |
| [第 2 周](weekly/week-02.md) | GEMM、访存、Tiling、共享内存、WMMA | 08-31 ~ 09-06 | ⬜ |
| [第 3 周](weekly/week-03.md) | Attention、Online Softmax、FlashAttention | 09-07 ~ 09-13 | ⬜ |
| [第 4 周](weekly/week-04.md) | Triton、PyTorch 自定义算子 | 09-14 ~ 09-20 | ⬜ |
| [第 5 周](weekly/week-05.md) | Transformer 推理、量化、模型加载 | 09-21 ~ 09-27 | ⬜ |
| [第 6 周](weekly/week-06.md) | KV Cache、Decode、CUDA Graph、性能指标 | 09-28 ~ 10-04 | ⬜ |
| [第 7 周](weekly/week-07.md) | Paged KV、Continuous Batching、调度 | 10-05 ~ 10-11 | ⬜ |
| [第 8 周](weekly/week-08.md) | HTTP/SSE、压测、可观测性、Linux 调优 | 10-12 ~ 10-18 | ⬜ |
| [第 9 周](weekly/week-09.md) | NCCL、并行策略、通信/计算重叠 | 10-19 ~ 10-25 | ⬜ |
| [第 10 周](weekly/week-10.md) | 项目证据包、简历项目、GitHub 展示 | 10-26 ~ 11-01 | ⬜ |
| [第 11 周](weekly/week-11.md) | CUDA/C++/系统设计模拟面试 | 11-02 ~ 11-08 | ⬜ |
| [第 12 周](weekly/week-12.md) | 查漏补缺、投递、复盘 | 11-09 ~ 11-15 | ⬜ |

> 状态列由 `make progress-write` 自动更新:⬜ 未开始 / 🔄 进行中 / ✅ 已完成。

## 追踪(复盘与打卡)

| 文档 | 内容 | 何时用 |
|------|------|--------|
| [progress-tracker.md](progress-tracker.md) | 每周进度表格 + 每日打卡 | 周日复盘 |
| [weekly-review.md](weekly-review.md) | 集中式周复盘模板 | 周日复盘 |

## 面试与求职

| 文档 | 内容 | 何时用 |
|------|------|--------|
| [INTERVIEW_MATRIX.md](INTERVIEW_MATRIX.md) | 面试题五要素矩阵 | 准备/复盘面试题 |
| [APPLICATION_PLAN.md](APPLICATION_PLAN.md) | 简历版本、投递节奏、迭代规则 | 投递阶段 |
| [resume/](resume/) | 公开脱敏简历与本地副本规则 | 改简历时 |
| [applications/](applications/) | 目标公司与投递追踪模板 | 投递和每周复盘 |
| [community/](community/) | 上游 issue 筛选、复现与贡献证据 | 每周社区时段 |

## 参考(知识索引与资源)

| 文档 | 内容 |
|------|------|
| [knowledge-map.md](knowledge-map.md) | 主题知识地图 |
| [resources.md](resources.md) | 学习资源与 deep-dive 链接 |
| [interview-prep.md](interview-prep.md) | 面试准备主题索引 |
| [learning-path.md](learning-path.md) | 学习路径概览 |
| [CHANGELOG.md](CHANGELOG.md) | 变更记录 |

---

*索引维护:新增/重命名文档时同步更新本文件、README.md 与 [llms.txt](llms.txt)。*
