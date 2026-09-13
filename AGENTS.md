# AGENTS.md — 给 AI 代理的仓库操作指南

本文件遵循 [GitHub AGENTS.md 规范](https://docs.github.com/en/code-security/agents-md)。
读取本文件后即可高效协助用户管理此仓库;细节请按需打开对应文件,**不要通读全仓**。

## 仓库定位

AI Infra 面试准备的个人执行仓库:12 周转行计划(2026-08-24 ～ 2026-11-15),
包含岗位分析、能力矩阵、每周计划、进度追踪、面试与投递执行。

## 文档地图(渐进披露:先读标题,按需展开)

| 文件 | 一句话用途 | 何时打开 |
|------|-----------|---------|
| `README.md` | 唯一入口:定位、文档地图、执行入口 | 新会话必读 |
| `TARGET_ROLES.md` | 主/次/可选岗位方向与边界 | 涉及岗位决策时 |
| `JOB_MARKET_EVIDENCE.md` | 23 个岗位采样与技能频次 | 更新岗位证据时 |
| `BASELINE.md` | 已有优势与真实短板 | 复盘/自评时 |
| `SKILL_MATRIX.md` | 能力等级、证据、差距行动 | 每周自评时 |
| `TOPIC_WEIGHTS.md` | 288h 时间权重表(可被脚本校验) | 调整时间分配时 |
| `ROADMAP.md` | 12 周主线与每周必须交付 | 宏观规划时 |
| `study-plan.md` | 每周节奏与执行方法 | 安排当周节奏时 |
| `PROJECT_STRATEGY.md` | 已定项目组合 | 项目相关工作时 |
| `CLOUD_GPU_PLAYBOOK.md` | 云 GPU 选型、预算、实验闭环与评测矩阵 | 采购/租用云算力时 |
| `AI_INFRA_PRACTICE_AND_CAREER_GUIDE.md` | 逐步实验、性能分析、面试与职业转型手册 | 指导用户动手实践时 |
| `AGENT_EXECUTION_GUIDE.md` | 低成本 Agent 任务拆分、证据和验收规范 | 委托技术任务给其他 Agent 时 |
| `P0_P1_AGENT_BACKLOG.md` | 六仓可直接委托的 P0/P1 单任务包 | 选择具体实现、测试或实验任务时 |
| `L3_L4_DESIGN_REVIEW_PACKAGES.md` | 高复杂度 kernel、并发、FFI、schema 与性能评审包 | L3/L4 任务写生产代码前 |
| `FINAL_EXECUTION_PLAYBOOK.md` | 最终优先级、岗位路线和低成本 Agent 延续流程 | 决定下一步任务或缩减范围时 |
| `NEXT_AGENT_START_HERE.md` | 新 Agent 的稳定入口、当前事实和历史信息陷阱 | 新会话开始时第一份读取 |
| `INTERVIEW_MATRIX.md` | 面试题五要素矩阵 | 准备/复盘面试题时 |
| `APPLICATION_PLAN.md` | 简历与投递规则 | 投递阶段时 |
| `resume/` | 公开脱敏简历与本地副本规则 | 改简历时 |
| `applications/` | 公司清单与投递跟踪模板 | 求职执行时 |
| `community/` | 上游 issue 筛选、复现与贡献记录 | 社区参与时 |
| `weekly/week-01..12.md` | 逐周目标/预算/实验/交付物/退出条件 | 执行某周时 |
| `progress-tracker.md` | 每周进度表格 + 每日打卡 | 周日复盘时 |
| `weekly-review.md` | 集中式周复盘模板 | 周日复盘时 |
| `knowledge-map.md` / `resources.md` / `interview-prep.md` | 主题知识索引与资源 | 查找知识/资源时 |
| `INDEX.md` | 全仓文档四类归档索引 | 定位文档时 |

## 关键约定(必须遵守)

1. **每周文件 frontmatter**(YAML,机器可解析):
   ```yaml
   week: 1
   title: 主题
   start: 2026-08-24   # YYYY-MM-DD
   end: 2026-08-30     # 与 start 相差 6 天
   hours: 24           # 12 | 18 | 24
   status: upcoming    # upcoming | active | done
   ```
2. **checkbox 语义**:`- [ ]` = 未完成,`- [x]` = 已完成。`scripts/progress.py`
   按此统计完成度并推断 status(100% → done,>0 → active,0 → upcoming)。
   修改交付物清单时保持 `- [ ]` / `- [ x]` 前缀格式。
3. **周次连续性**:weekly 文件命名 `week-01.md` … `week-12.md`;日期每周 7 天无缝衔接。
4. **事实唯一来源**:deep-dives 在 `holtwood/github-repos-hub`,技术作品与跨仓契约在
   `open-infra-ai` 组织,本仓库**不保留副本**。
5. **公开边界**:本仓库只提交脱敏材料。真实联系方式、联系人、薪资与投递状态只能写入
   `.gitignore` 覆盖的 `.local` 文件。
6. **诚实原则**:多 GPU / 无实验条件的产出必须标注"理论学习/模拟",禁止伪造实验数据。
7. **语言**:所有文档用中文;代码标识符保持原文。
8. **技术任务委托**:跨仓实现、测试、benchmark 或 profiling 任务按
   `AGENT_EXECUTION_GUIDE.md` 的标准任务单、证据和升级规则执行。
9. **逐仓任务与高复杂度门禁**:从 `P0_P1_AGENT_BACKLOG.md` 一次选择一个任务;
   L3/L4 必须先完成 `L3_L4_DESIGN_REVIEW_PACKAGES.md` 的 G0-G8 评审。
10. **停止继续规划**:总路线已冻结;后续优先产生实现、测试、raw evidence、实验与面试
    复盘。需要选择路线时先读 `FINAL_EXECUTION_PLAYBOOK.md`,不再新增重复总计划。
11. **新会话入口**:先按 `NEXT_AGENT_START_HERE.md` 重新发现 repo、commit、PR 和证据状态;
    dated handoff 只作历史参考,不得直接恢复其中的路径、名称或完成状态。

## 常用命令(仓库根目录)

```bash
make check          # 链接健康检查(本地)
make verify         # 计划一致性校验(权重/日期/frontmatter)
make progress       # 只看进度统计
make progress-write # 统计并写回 progress-tracker / frontmatter / README 状态
```

## 你能帮用户做的事

- **周日复盘**:运行 `make progress`,读 `progress-tracker.md` 与当周 `weekly/week-N.md`,
  按 `weekly-review.md` 模板生成复盘草稿。
- **面试题**:按 `INTERVIEW_MATRIX.md` 的格式(答案要点/追问树/代码定位/实验证据/评分标准)
  为某周问题生成/补充答案草稿。
- **计划调整**:改 `TOPIC_WEIGHTS.md` 后跑 `make verify` 确认合计仍为 288h。
- **一致性维护**:改任何文档后跑 `make check && make verify`。
- **进度更新**:用户勾选 checkbox 后,运行 `make progress-write` 自动汇总。
