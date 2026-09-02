# 🎯 AI Infra Interview Prep

> 12 周 AI Infra 转行准备：目标岗位、能力矩阵、周计划、面试与求职执行。
> **执行周期：2026-08-24 ～ 2026-11-15**（默认 24h/周，附 12h/18h 缩放档）。

## 定位与职责边界

- 本仓库（公开）：转行计划、学习 TODO、能力矩阵、项目策略、脱敏简历、面试与
  求职执行模板。真实联系方式、联系人、薪资与投递状态只写入 Git 忽略的 `.local` 文件。
- 仓库盘点/分类/深读：[github-repos-hub](https://github.com/holtwood/github-repos-hub)
  （deep-dives 唯一事实来源，本仓库不再保留副本）。
- 技术作品、状态注册表与跨仓契约：
  [open-infra-ai/open-infra-ai](https://github.com/open-infra-ai/open-infra-ai)。
- 技术仓只放可运行作品；本仓只放个人执行材料，边界以
  [组织仓说明](https://github.com/open-infra-ai/open-infra-ai/blob/master/docs/repository-boundaries.md)
  为准。
- Star 资源：[stars-db](https://github.com/holtwood/stars-db)。

## 文档地图

完整索引见 [INDEX.md](INDEX.md)（按规划/执行/追踪/参考归档）；AI 代理请看 [AGENTS.md](AGENTS.md)。

| 分类 | 文档 | 内容 |
|------|------|------|
| 规划 | [TARGET_ROLES.md](TARGET_ROLES.md) | 主/次/可选岗位方向与边界 |
| 规划 | [JOB_MARKET_EVIDENCE.md](JOB_MARKET_EVIDENCE.md) | 2026-08-19 采样的 23 个岗位与技能频次 |
| 规划 | [BASELINE.md](BASELINE.md) | 已有优势与真实短板 |
| 规划 | [SKILL_MATRIX.md](SKILL_MATRIX.md) | 能力等级、目标、证据、差距行动 |
| 规划 | [TOPIC_WEIGHTS.md](TOPIC_WEIGHTS.md) | 时间权重（合计 288h，可核对）与三档缩放 |
| 规划 | [ROADMAP.md](ROADMAP.md) | 12 周主线与每周必须交付 |
| 规划 | [PROJECT_STRATEGY.md](PROJECT_STRATEGY.md) | 已定项目（推理系统 / Kernel / C++ 辅助） |
| 规划 | [CLOUD_GPU_PLAYBOOK.md](CLOUD_GPU_PLAYBOOK.md) | 云 GPU 选型、预算、实验闭环与评测矩阵 |
| 执行 | [weekly/](weekly/) | 逐周计划（状态见下表） |
| 执行 | [study-plan.md](study-plan.md) | 每周节奏与执行方法 |
| 追踪 | [progress-tracker.md](progress-tracker.md) | 进度打卡（每周进度 + 每日打卡） |
| 追踪 | [weekly-review.md](weekly-review.md) | 集中式周复盘模板 |
| 面试 | [INTERVIEW_MATRIX.md](INTERVIEW_MATRIX.md) | 面试题五要素矩阵 |
| 面试 | [APPLICATION_PLAN.md](APPLICATION_PLAN.md) | 简历版本、投递节奏、迭代规则 |
| 求职 | [resume/](resume/) | 公开脱敏简历；真实信息用本地忽略副本 |
| 求职 | [applications/](applications/) | 目标公司清单与投递追踪模板 |
| 社区 | [community/](community/) | issue 筛选、最小复现与上游贡献记录 |
| 参考 | [knowledge-map.md](knowledge-map.md) / [resources.md](resources.md) / [interview-prep.md](interview-prep.md) | 主题知识索引与资源 |

## 每周状态

> ⬜ 未开始 · 🔄 进行中 · ✅ 已完成（由 `make progress-write` 自动更新）

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

## 执行入口（每周循环）

**周一启动**
1. 打开本周 [weekly/week-01.md](weekly/week-01.md)（当前周）→ 按时间预算规划日程。
2. 相关文档：[SKILL_MATRIX.md](SKILL_MATRIX.md)（自评基线）、[INTERVIEW_MATRIX.md](INTERVIEW_MATRIX.md)（本周面试题）。

**执行中**
3. 在 [progress-tracker.md](progress-tracker.md)「每日打卡」随手记录。
4. 完成交付物就在周文件里勾选 `- [x]`（脚本会自动汇总）。

**周日复盘**
5. 运行 `make progress` 看完成度 → 勾选已完成项 → `make progress-write` 自动更新状态。
6. 按 [weekly-review.md](weekly-review.md) 模板写周复盘（完成/未完成/原因/下周调整）。
7. 更新 [SKILL_MATRIX.md](SKILL_MATRIX.md) 自评（附证据链接）。
8. 每两周复查一次 [JOB_MARKET_EVIDENCE.md](JOB_MARKET_EVIDENCE.md) 的链接有效性。

## 仓库维护

```bash
make check          # 链接健康检查（本地）
make verify         # 计划一致性校验（288h / 周次日期 / frontmatter）
make progress       # 只看进度统计
make progress-write # 统计并写回 progress-tracker / frontmatter / README 状态
```

## 核心事实（2026-08-19 审计）

- 目标：GPU Kernel / LLM Inference Performance Engineer（主）、Serving（次）、编译器（可选）。
- 推理加速面试旗舰是 **tiny-llm**；`cuflash` 证明 kernel 深度，`paged-serving`
  证明 serving/调度能力，另外两仓提供基础与 Triton 对照。
- 项目已定，不再为单个优化点拆出重复玩具仓；新想法先进入现有仓的实验、benchmark
  或上游 issue/PR。详见 [PROJECT_STRATEGY.md](PROJECT_STRATEGY.md)。
- P2 大仓（vllm/sglang/TensorRT-LLM/triton/flashinfer/flash-attention/LightLLM）只做
  "五个一"目标导向阅读，不做全仓通读。
- 多 GPU 相关内容一律标注理论学习，不伪造实验数据。
