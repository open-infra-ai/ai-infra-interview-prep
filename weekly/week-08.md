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

本人复述已合入的取消/背压整改，聚焦慢客户端、中断、失败和终态竞态，明确 CPU
释放通知尚未证明的原生 GPU 回收。代码已完成代理审阅，剩余 GPU 实验先批准具体
设计；正式报告已有，不重复追求“第一份”。

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

1. 从已合入的 [PR #24](https://github.com/open-infra-ai/paged-serving/pull/24) 和 commit
   `23338ad` 开始，闭卷解释 RequestGuard/watch、n>1 部分准入、abort、重复取消与
   文本 EOF/终态竞态；Agent 完成代码审阅不代表本人已掌握。
2. 对慢消费者/断连/后端失败记录队列、请求、KV 的前后状态；先复用现有测试，缺哪条补哪条。
3. 复述现有有界队列的容量、满队列策略与取消优先级，定位慢客户端不会卡住整个 worker
   的测试；改变策略或新增 GPU 实验前先批准具体设计。
4. 复述 9/7 原始结果：closed 与 Poisson 各证明什么，429 和未收敛为什么必须保留。

## 可验证交付物

- [ ] 已合入整改 review：取消不变量、终态竞态与仍未证明的 GPU 回收
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
