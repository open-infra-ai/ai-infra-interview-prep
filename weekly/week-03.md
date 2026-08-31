---
week: 3
title: Attention、Online Softmax、FlashAttention
start: 2026-09-07
end: 2026-09-13
hours: 24
status: upcoming
---

# 第 3 周：Attention、Online Softmax、FlashAttention

## 相关文档

- [INTERVIEW_MATRIX](../INTERVIEW_MATRIX.md) — 本周面试题加入矩阵
- [SKILL_MATRIX](../SKILL_MATRIX.md) — 能力自评与证据
- [knowledge-map](../knowledge-map.md) — 主题知识地图
- [progress-tracker](../progress-tracker.md) — 进度打卡

## 本周目标

手推 online softmax 与 FlashAttention 分块公式；把 cuflash 的实现讲成自己的故事。

## 先修知识

W2 的 tiling/WMMA；标准 attention 公式。

## 时间预算

24h：算法手推 6h · cuflash 代码重读+注释 8h · 差分/benchmark 复现 6h · C++/算法 2h · 复盘 2h。

## 阅读范围

- open-infra-ai/cuflash：前向 kernel（WMMA 分块、causal 边界跳过）、后向
- trifuse：Triton 版 FlashAttention 对照
- Fork flash-attention（P2，"五个一"）：只读 `core` 目录前向主链路
- 论文：FlashAttention (NeurIPS'22)、FlashAttention-2 (2023)

## 动手实验

1. 重跑 cuflash 的 FP32/FP16/BF16 差分测试与 benchmark，记录口径。
2. 复述 grid.y 65535 越界 bug 的发现、修复与回归测试（真实调试故事）。
3. 用 Triton 版与 CUDA 版做同口径性能对照。

## 可验证交付物

- [ ] 手推笔记（online softmax 两参数递推 + 数值稳定性）
- [ ] cuflash 代码定位文档（kernel 入口、分块结构、WMMA 调用点）
- [ ] flash-attention（P2）"五个一"产出
- [ ] INTERVIEW_MATRIX Q1 达到 B 级以上

## 面试问题

- 为什么 online softmax 能保持数值稳定？
- causal mask 如何按块跳过？节省多少计算？
- FA2 相对 FA1 改了什么（并行划分、非 matmul FLOPs）？

## 退出条件

白板手推无卡顿；能打开仓库任一关键文件现场讲解。

## 未完成时

后向传播细节可降级为"理解思路"；前向必须完全掌握。
