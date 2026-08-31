# 求职执行计划（APPLICATION_PLAN）

更新日期：2026-08-24。12 周计划见 [ROADMAP.md](ROADMAP.md)；岗位样本见
[JOB_MARKET_EVIDENCE.md](JOB_MARKET_EVIDENCE.md)。

## 简历版本

| 版本 | 定位 | 主打项目顺序 |
|------|------|-------------|
| v-performance | LLM Inference Performance / GPU Kernel | tiny-llm → cuflash → cuda-foundations + trifuse |
| v-serving | LLM 推理运行时与 Serving | paged-serving → tiny-llm → cuflash |

- 公开草稿分别在 [`resume/resume-performance.zh.md`](resume/resume-performance.zh.md)
  与 [`resume/resume-serving.zh.md`](resume/resume-serving.zh.md)；两版必须共享同一组已核验证据，
  禁止维护两套互相漂移的数字。
- 每个项目条目只保留 2–3 个 bullet；每条都包含动作、技术难点、量化结果和限制条件。
- 性能数字必须带硬件/软件/输入/统计口径，并能点击到仓库结果文件。
- 非同量化、CPU 参考后端、跳过的测试和未具备多 GPU 条件必须紧跟结论说明。
- Fork、AI 翻译成果和未被上游接受的“可能修复”不得写成项目成果。
- 公开版保留占位符；真实联系方式填写到 `resume/*.local.*`，不进入 Git。
- tiny-llm 的首个可投递性能数字已满足 clean commit、schema v2、五组配对与原始数据
  归档要求；引用时必须写成“CUDA Graph decode A/B”，不得改写为整体推理加速。

## 投递节奏

- W1 起：每周固定 2–4 小时社区参与，目标是一个深度复现、review 或小 PR，而不是
  批量评论。材料在 [`community/`](community/)；最终证据以上游链接为准。
- W1：完成个人 GitHub 与两版简历的真实信息填写；从
  [`applications/tracking.template.md`](applications/tracking.template.md) 复制本地
  `tracking.local.md`，投 3–5 家非首选岗位做漏斗校准。
- W2–W4：每周 5–8 个匹配且完成定制的有效投递；同时用真实 JD 反向检查关键词、证据缺口与
  地点/年限硬门槛。大陆岗位优先寻找熟悉业务的人交流，全球岗位使用官网和 LinkedIn 直投。
- W5 起：根据面试转化调整到每周 8–12 个有效投递；不要为等待“完美项目”暂停投递。
- 每次笔试/面试后 24 小时内在本地记录复盘，并更新 SKILL_MATRIX 与
  INTERVIEW_MATRIX 的自评。

## 反馈闭环

- 简历投出 20 份无面试邀请：按岗位族分别统计，不混合 Kernel 与 Serving；重写项目首屏、
  核对年限/地点/学历硬门槛和关键词覆盖。
- 一面通过率 < 30%：每周增加一次有评分模拟面试，按“原理、代码、实验、边界、反问”定位失分项。
- 笔试失败：从 C++/算法 8% 时间桶增加每日 30 分钟限时练习，不挤占主项目证据建设。
- 面试频繁追问同一缺口：把它转成主项目的一个最小实验；没有数据时直接说明尚未验证。

## GitHub 展示顺序

Profile 首屏 Pin 三项：`tiny-llm`、`paged-serving`、`cuflash`，顺序与两版简历保持一致。
其余仓库由组织首页导航。个人 Profile 简介直接写 C++ / CUDA / LLM inference systems，并公开
与 `open-infra-ai` 的成员关系，不解释“转行焦虑”。

## 必须由本人完成的事项

- 填写真实公司、任职时间、职责、教育背景和可验证的工作成果；AI 不代造数据。
- 发送投递、内推请求和上游评论/PR；发布前逐句以第一人称复核。
- 维护本地 `applications/tracking.local.md`，不把联系人、薪资和面试细节推到公开仓库。
