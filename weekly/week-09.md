---
week: 9
title: Profiler、配对实验与负结果归因
start: 2026-10-19
end: 2026-10-25
hours: 24
status: upcoming
---

# 第 9 周：Profiler、配对实验与负结果归因

## 相关文档

- [INTERVIEW_MATRIX](../INTERVIEW_MATRIX.md) — 本周面试题加入矩阵
- [SKILL_MATRIX](../SKILL_MATRIX.md) — 能力自评与证据
- [knowledge-map](../knowledge-map.md) — 主题知识地图
- [progress-tracker](../progress-tracker.md) — 进度打卡

## 本周目标

选择一个真实热点完成“预测 → 测量 → 反例 → 解释”。优先讲透 direct 的间接寻址
或 split-KV 的并行/归约代价，不同时优化五个 kernel。NCCL 只保留 W10 理论选修。

## 先修知识

W7 的统计口径和本人诊断；GPU/profiler 是否可用先确认。

## 时间预算

暂定 24h：配对实验 8h · 架构/统计知识 5h · 限时编程 4h · 归因答辩 5h · 岗位 2h。
18h/12h 档只保留一个热点和一对 shape；无 GPU 时先重算 raw 与编排命令，采集项 not_run。

## 阅读范围

- tiny-llm：kernel_bench、attention、9/14–9/15 raw 与限制
- 已安装 Nsight 的帮助与 kernel 对应指标；旧报告表格作为假设，不作为新采集证据
- 想做 kernel 岗时可替换为 cuflash 一个热点，但不额外增加工作量

## 动手实验

1. 写一个能被反驳的预测：例如“省 gather 必然更快”；用 raw 找支持与反例，区分观察和归因。
2. 条件允许时用 nsys 定位时间线，再用 ncu 采一个热点；保存可打开 raw 包、命令与环境。
3. A/B 固定模型、commit、shape、warmup、顺序和独立重复；先过 correctness，保留回退与 CV。
4. 说明为什么 2048 kernel 的比值不能写成整个模型 TPOT 改善。

## 可验证交付物

- [ ] 一个热点的 raw profiler/配对计时包，缺条件时明确 not_run
- [ ] 一个预测与反例的归因记录（观察/推断分列）
- [ ] INTERVIEW_MATRIX Q8/Q10/Q13 有评分的闭卷复述

## 面试问题

- ring AllReduce 总数据量公式（2(n-1)/n × size）？
- TP 每层哪两次通信？怎么与计算重叠？
- NVLink vs PCIe 带宽差对重叠收益的影响？

## 退出条件

能用 raw 支持一个有限结论并指出至少一个反例；没有 counter 时不把机制猜测称为证明。

## 未完成时

保留负结果与未运行原因；不为获得正 speedup 隐藏 shape，不自动购买 GPU。
