---
week: 8
title: 取消、背压、失败回收与 Serving
start: 2026-10-12
end: 2026-10-18
hours: 24
status: upcoming
---

# 第 8 周：取消、背压、失败回收与 Serving

## 相关文档

- [INTERVIEW_MATRIX](../INTERVIEW_MATRIX.md) — 本周面试题加入矩阵
- [SKILL_MATRIX](../SKILL_MATRIX.md) — 能力自评与证据
- [knowledge-map](../knowledge-map.md) — 主题知识地图
- [progress-tracker](../progress-tracker.md) — 进度打卡

## 本周目标

review 已有主动取消 PR #23，聚焦慢客户端、中断和失败后的资源回收；有界背压
只有获得本轮具体实现授权并完成设计时才修改。正式报告已有，不重复追求“第一份”。

## 先修知识

W7 的调度；Linux 基础。

## 时间预算

暂定 24h：生命周期实验 8h · 调度/队列知识 5h · 限时编程 4h · 故障答辩 5h · 岗位 2h。
18h/12h 档减少负载矩阵，保留一个慢客户端和一个取消场景，不降低资源守恒断言。

## 阅读范围

- paged-serving：HTTP/SSE 接口与现有日志
- Cerebras/Perplexity JD 的压测与可观测性要求（见 JOB_MARKET_EVIDENCE.md）
- Linux perf/火焰图教程 + lectures（Fork）相关讲义

## 动手实验

1. 先查 PR #23 当前 head/CI/diff，核对 RequestGuard/watch、n>1 部分准入、abort 和重复取消；
   OPEN 不是已交付，review 不自动授权 merge。
2. 对慢消费者/断连/后端失败记录队列、请求、KV 的前后状态；先复用现有测试，缺哪条补哪条。
3. 若做有界队列，冻结容量、满队列策略与取消优先级；证明不会让慢客户端卡住整个 worker。
4. 复述 9/7 原始结果：closed 与 Poisson 各证明什么，429 和未收敛为什么必须保留。

## 可验证交付物

- [ ] PR #23 review：通过项、缺口和默认分支状态
- [ ] 慢客户端/断连/失败回收的测试或最小复现日志（资源回基线）
- [ ] INTERVIEW_MATRIX Q5 达 B 级以上

## 面试问题

- 怎么压尾延迟（batch 上限、chunked prefill、抢占、CUDA Graph）？
- 容量规划怎么做？
- warmup 与测量统计口径的坑？

## 退出条件

能解释取消时序、队列满策略和 KV 回收；缺 GPU 的部分明确保留为控制面验证。

## 未完成时

没有具体实现授权则只交 review/复现和设计；Linux 深挖顺延 W11，不开启第二条深改造。
