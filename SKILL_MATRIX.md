# 能力矩阵（SKILL_MATRIX）

更新日期：2026-10-04。等级：1 了解 / 2 能用 / 3 能独立完成并解释原理 / 4 能优化并给出量化证据 / 5 能设计并教学。
下表数值保留 2026-08-23 的历史自评，**全部待本人闭卷复测，不是已验证当前等级**。
工程现状见 [BASELINE.md](BASELINE.md)；目标由岗位证据校准，不由测试数量或 Agent 代写涨级。

| 能力 | 历史自评（待复测） | 目标（12 周末） | 证据（现有 → 计划） | 差距行动 |
|------|------|----------------|--------------------|---------|
| CUDA 编程模型与 kernel 优化 | 3 | 4 | cuda-foundations/cuflash → 本人解释与 profiler 归因 | W7 诊断，W9 实战 |
| GPU 架构（SM/warp/内存层次/roofline） | 2.5 | 4 | 源码与部分指标表 → 本人白板/roofline | W7 诊断，W9 归因 |
| GEMM 优化（tiling/WMMA/pipeline） | 3 | 4 | SGEMM 阶梯 → 差分+benchmark 复述 | W7 诊断，W9 深挖 |
| FlashAttention 算法与实现 | 3 | 4 | cuflash → 手推 online softmax + 调优故事 | W7 诊断，W9 深挖 |
| Triton | 3 | 4 | trifuse 两投影指标与 gate → CUDA/Triton 取舍 | W7 校准，W9 实战 |
| PyTorch 自定义算子 / torch.compile | 2 | 3 | torch.library 注册已做 → extension-cpp + inductor 实验 | W4 |
| LLM 推理全链路（加载/量化/decode） | 3 | 4 | tiny-llm → 端到端指标拆解 | W5–W6 |
| KV Cache / PagedAttention / 调度 | 3 | 4 | direct/split-KV 已有；默认 legacy → 代码走读与资源不变量 | W7–W8 |
| CUDA Graph | 4 | 4 | tiny-llm on/off token 一致 + clean commit 五组配对 A/B（原始 JSONL）→ 云 GPU timeline/计数器补充因果归因 | W6 |
| Serving 压测与可观测性 | 2 | 3 | 9/7 正式报告已有 → 配对实验、错误分类与收敛复核 | W8–W9 |
| Linux 性能分析 | 2 | 3 | 零散 → perf/火焰图与故障实验 | W11 |
| NCCL/并行策略/通信重叠 | 1 | 2（理论） | 无真实多卡证据 → 公式与通信量推导 | W10 选修，不挤占主线 |
| C++/并发/算法 | 3 | 3.5 | fq-compressor → 限时实现、测试、复杂度解释 | 剩余每周 4h 暂定 |
| 简历/面试表达 | 2 | 4 | 未模拟 → 两次有评分完整模拟 | W11 |

## 使用规则

- 每两周在 progress-tracker.md 重新自评一次，必须附新证据链接，无证据不涨级。
- W7 诊断后按最低分重排：代码不能独立写则增加限时编程；不能读原始实验则优先统计与
  profiling；不能讲请求生命周期则优先控制面。未明确目标岗位前，不自动断言转向 Kernel。
