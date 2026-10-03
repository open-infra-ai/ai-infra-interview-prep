# 能力基线（BASELINE）

更新日期：2026-10-04。用于校准证据与本人复测，源码存在不等于本人掌握。
旧测试数保留为 2026-08-23 快照，不称当前数量，也不由其推断面试等级。

## 已有工程证据（不直接评定本人能力）

| 能力 | 证据 |
|------|------|
| CUDA 编程与 kernel 优化 | cuda-foundations 的 SGEMM 阶梯与 cuflash 前后向/WMMA/FlashDecoding；2026-08-23 测试快照分别为 261/261、81/81，非当前验证数量 |
| Triton 算子 | trifuse 的 kernel/reference 与 torch.library；Gated MLP 只有 gate/up 两投影，无 down projection；旧 123/123 是 GPU 数值快照，缺 raw 的旧延迟表不作性能证据 |
| LLM 推理引擎 | tiny-llm 的 GGUF、W8A16、KV、Graph；[Graph 配对 A/B](https://github.com/open-infra-ai/tiny-llm/blob/master/docs/performance/results/2026-08-23-cuda-graphs-ab.md) 绑定 clean commit `565da79` 与原始 JSONL，只证明报告设置下的 decode 观察 |
| Direct paged / split-KV | [9/14 DPA](https://github.com/open-infra-ai/tiny-llm/blob/master/docs/performance/results/2026-09-14-rtx5070ti-dpa.md) 与 [9/15 split-KV](https://github.com/open-infra-ai/tiny-llm/blob/master/docs/performance/results/2026-09-15-rtx5070ti-splitkv.md) 是 RTX 5070 Ti kernel 结果；实现与 Transformer/FFI 接入已存在，默认 legacy、split 关闭，不外推 TPOT/Serving |
| 推理调度与控制面 | paged-serving 的分页 KV、continuous batching、HTTP/SSE 与 [9/7 正式 21-run 矩阵](https://github.com/open-infra-ai/paged-serving/tree/master/benchmarks/serving/results/2026-09-07-RTX3060Laptop-paged-serving-p2-batch-postprocess-streaming) 已存在；含 429 和未收敛结果，不证明稳定 SLO；主动取消 [PR #23](https://github.com/open-infra-ai/paged-serving/pull/23) 尚未合入 |
| C++ 工程质量 | open-genomics/fq-compressor：C++23、oneTBB、CI、Sanitizer、O(1) 随机访问；fastq-tools 零拷贝 I/O |
| 系统背景 | 原自述包含 ZEGO 实时音视频、BGI 基因数据工程、Mindray 医疗影像；工作职责与本人贡献由本人确认，本次未重新核验 |

## 真实短板（当前无证据或未验证）

| 短板 | 现状 | 影响 |
|------|------|------|
| Nsight Systems/Compute 深度使用 | 9 月 kernel 报告已有指标表；原始 profiler 包、端到端归因和本人现场解读仍需补齐 | Kernel 岗高频考点，不能称完全未做或已熟练 |
| Linux 性能调优（perf、内存、NUMA、CPU 频率） | 经验零散，无文档化实验 | Serving 岗考察 |
| NCCL / NVLink / RDMA / Tensor Parallel | 纯理论，无多 GPU 实验（硬件限制） | 分布式话题只能谈原理与源码 |
| 推理服务压测与可观测性 | 正式 CUDA 报告已有；缺配对因果实验、未收敛项处理、有界背压和主动取消合入 | Serving 岗核心证据缺口不是“第一份报告” |
| torch.compile / PyTorch 内部机制 | 只写过 C++ extension，未深入 dispatch/inductor | 部分岗位必考 |
| 面试表达 | 项目证据充分但未经过有评分的完整模拟面试 | 最后一公里 |
| 算法/笔试 | 长期未系统刷题 | 国内岗位笔试门槛 |

## 环境约束

- 本地基线是 RTX 3060 Laptop 6GB；归档中另有 RTX 5070 Ti 实验，不代表当前持续可用。
  云 GPU 和预算须另行确认，不自动租卡。无实际多卡证据时 TP/PP 保持理论学习。

## 本人复测起点

W7 做一次 90 分钟闭卷诊断：核心公式 20 分钟、旗舰请求路径 20 分钟、限时编程
30 分钟、原始实验读数 20 分钟。记录回答、提示次数与错点，不由 Agent 代答后评分。
先测能力再调周预算；不把所有历史任务机械重跑，也不补勾未确认的交付物。
