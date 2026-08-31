# 能力矩阵（SKILL_MATRIX）

更新日期：2026-08-23。等级：1 了解 / 2 能用 / 3 能独立完成并解释原理 / 4 能优化并给出量化证据 / 5 能设计并教学。
当前等级依据 [BASELINE.md](BASELINE.md)；目标等级依据 [JOB_MARKET_EVIDENCE.md](JOB_MARKET_EVIDENCE.md) 的岗位频次。

| 能力 | 当前 | 目标（12 周末） | 证据（现有 → 计划） | 差距行动 |
|------|------|----------------|--------------------|---------|
| CUDA 编程模型与 kernel 优化 | 3 | 4 | cuda-foundations/cuflash → Nsight 分析报告 | W1–W3 profiling 实战 |
| GPU 架构（SM/warp/内存层次/roofline） | 2.5 | 4 | 讲得清但无量化分析 → roofline 报告 | W1–W2 |
| GEMM 优化（tiling/WMMA/pipeline） | 3 | 4 | SGEMM 阶梯 → 差分+benchmark 复述 | W2 |
| FlashAttention 算法与实现 | 3 | 4 | cuflash → 手推 online softmax + 调优故事 | W3 |
| Triton | 3 | 4 | trifuse → 与 CUDA 对照报告 | W4 |
| PyTorch 自定义算子 / torch.compile | 2 | 3 | torch.library 注册已做 → extension-cpp + inductor 实验 | W4 |
| LLM 推理全链路（加载/量化/decode） | 3 | 4 | tiny-llm → 端到端指标拆解 | W5–W6 |
| KV Cache / PagedAttention / 调度 | 3 | 4 | paged-serving → 状态机与不变量讲解 | W6–W7 |
| CUDA Graph | 4 | 4 | tiny-llm on/off token 一致 + clean commit 五组配对 A/B（原始 JSONL）→ 云 GPU timeline/计数器补充因果归因 | W6 |
| Serving 压测与可观测性 | 2 | 3 | paged-serving 已有正确 loadgen → 真实 CUDA 后端 TTFT/TPOT/p99 报告 | W8 |
| Linux 性能分析 | 2 | 3 | 零散 → perf/火焰图实验 | W8 |
| NCCL/并行策略/通信重叠 | 1 | 2（理论） | 无实验条件 → 理论+源码+模拟，明确标注 | W9 |
| C++/并发/算法 | 3 | 3.5 | fq-compressor → 限时练习维持 | 每周 8% |
| 简历/面试表达 | 2 | 4 | 未模拟 → 两次有评分完整模拟 | W11 |

## 使用规则

- 每两周在 progress-tracker.md 重新自评一次，必须附新证据链接，无证据不涨级。
- 降级风险：若 W6 结束 CUDA 路线未达 4，则 W7–W8 向 Kernel 倾斜，压缩 Serving 深度。
