---
week: 7
title: 可信度整改、闭卷诊断、Paged KV 答辩
start: 2026-10-05
end: 2026-10-11
hours: 24
status: upcoming
---

# 第 7 周：可信度整改、闭卷诊断、Paged KV 答辩

## 相关文档

- [INTERVIEW_MATRIX](../INTERVIEW_MATRIX.md) — 本周面试题加入矩阵
- [SKILL_MATRIX](../SKILL_MATRIX.md) — 能力自评与证据
- [knowledge-map](../knowledge-map.md) — 主题知识地图
- [progress-tracker](../progress-tracker.md) — 进度打卡

## 本周目标

验收第一批工程可信度整改，再用本人闭卷诊断确定短板。把“仓库里有什么”和
“本人能当场完成什么”分开，不重写已有 direct/split-KV，不补造 W1–W6 进度。

## 先修知识

已有源码和 raw 即可启动；W1–W6 的本人完成情况通过诊断补证，不要求先补齐全部清单。

## 时间预算

暂定 24h：整改复核/实验 8h · 核心知识 5h · 限时编程 4h · 闭卷诊断/答辩 5h · 岗位 2h。
18h 档减少拓展实验；12h 档保留诊断、整改复核和一条请求链路，扩展项顺延。

## 阅读范围

- open-infra-ai/paged-serving（主线）：block 分配器、调度循环、HTTP 控制面
- tiny-llm：`kernels/attention.cu`、`src/transformer.cpp`、9/14–9/15 raw 与汇总工具
- trifuse：两投影计算图与错误输出拒绝计时；paged-serving 的 MSRV/锁定依赖门禁

## 动手实验

1. 按 BASELINE 做 90min 闭卷诊断，记录提示次数、错误和源码定位，禁止 Agent 代答后计分。
2. 独立运行 raw 汇总与 CPU 回归；解释为什么 correctness pass、统计收敛和速度优势是三件事。
3. 徒手画实际请求生命周期，按真实 enum/cleanup 对齐；抢占未实现，不画成现有状态。
4. 30min 限时实现简化 block allocator，验证容量守恒、重复释放和失败时原状态不变。

## 可验证交付物

- [ ] 第一批整改命令与结果核对（不把 CPU pass 当 GPU pass）
- [ ] 本人 90min 诊断记录与最低分补课动作
- [ ] 一条真实请求路径 + block 生命周期白板与源码定位
- [ ] INTERVIEW_MATRIX Q3/Q8/Q9 闭卷评分与一次限时编程记录

## 面试问题

- 抢占式调度 recompute vs swap 的取舍？
- copy-on-write 前缀共享怎么实现？
- block size 怎么选（碎片 vs 元数据开销）？

## 退出条件

能区分 direct 实现、legacy 默认和 kernel/Serving 证据；至少一个短板有本人复测记录。

## 未完成时

诊断不可由阅读替代；对照框架顺延 W10。只修诊断最弱项，不机械补跑全部历史周任务。
