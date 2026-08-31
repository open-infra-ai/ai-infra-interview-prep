---
week: 4
title: Triton、PyTorch 自定义算子
start: 2026-09-14
end: 2026-09-20
hours: 24
status: upcoming
---

# 第 4 周：Triton、PyTorch 自定义算子

## 相关文档

- [INTERVIEW_MATRIX](../INTERVIEW_MATRIX.md) — 本周面试题加入矩阵
- [SKILL_MATRIX](../SKILL_MATRIX.md) — 能力自评与证据
- [knowledge-map](../knowledge-map.md) — 主题知识地图
- [progress-tracker](../progress-tracker.md) — 进度打卡

## 本周目标

完成同一 kernel 的 CUDA/Triton 对照报告；打通 PyTorch 自定义算子注册到 torch.compile 的链路认知。

## 先修知识

W2–W3；Python 装饰器基础。

## 时间预算

24h：Triton 实验 8h · torch.library/torch.compile 实验 6h · 对照报告 4h · C++/算法 2h · 复盘+矩阵 4h。

## 阅读范围

- open-infra-ai/trifuse：全部算子 + torch.library 注册（主线）
- Fork Triton-Puzzles：做完核心 puzzle
- Fork extension-cpp：C++ 扩展模板（快速过）
- Fork triton（P2，"五个一"）：只读 python/triton 语言前端与 tutorials

## 动手实验

1. 选一个算子（如 fused RMSNorm+RoPE 或 SGEMM）：写 CUDA vs Triton 同口径 benchmark（形状矩阵：M/N/K 三档）。
2. 用 torch.compile（inductor）编译调用了自定义 op 的模型，观察 graph break；补 meta/fake tensor 注册后对比。
3. 解释 trifuse 的注册模式与 vLLM/SGLang 的 custom op 接入一致性。

## 可验证交付物

- [ ] CUDA/Triton 对照报告（数字带口径）
- [ ] torch.library + torch.compile 实验记录（成功与 graph break 案例）
- [ ] INTERVIEW_MATRIX Q7 达 B 级以上

## 面试问题

- Triton 与手写 CUDA 的取舍（开发效率 vs 控制粒度）？
- torch.library 注册缺 meta 实现会怎样？
- num_warps/num_stages 怎么调？

## 退出条件

对照报告数字可复现；能解释注册全流程。

## 未完成时

torch.compile 深挖可顺延；Triton 对照报告不可降级。
