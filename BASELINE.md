# 能力基线（BASELINE）

更新日期：2026-08-23。用于校准 SKILL_MATRIX 的"当前等级"，避免高估或低估。

## 已有优势（有可验证证据）

| 能力 | 证据 |
|------|------|
| CUDA 编程与 kernel 优化 | cuda-foundations（SGEMM 阶梯，261/261 测试）+ cuflash（FlashAttention 前后向、WMMA、FlashDecoding，81/81 测试）；本机 RTX 3060 Laptop 6GB 可复现 |
| Triton 算子 | trifuse（RMSNorm+RoPE/SwiGLU/FlashAttention/SGEMM + torch.library）；RTX 3060 Laptop 123/123 测试通过 |
| LLM 推理引擎 | tiny-llm：GGUF、W8A16、分页 KV、CUDA Graph；clean commit `565da79` 的 schema v2 五组配对 A/B 中，Graph off→on 的 TPOT 8.322→5.225 ms（-37.2%）、decode 吞吐 120.168→191.384 tok/s（+59.3%），10 个进程原始 JSONL 已归档；193 项测试可复现 |
| 推理调度与控制面 | paged-serving（Rust）：分页 KV + continuous batching + HTTP/SSE；默认 232 项测试通过，3 并发 e2e 与 llama.cpp 对齐（量化分歧已记录） |
| C++ 工程质量 | open-genomics/fq-compressor：C++23、oneTBB、CI、Sanitizer、O(1) 随机访问；fastq-tools 零拷贝 I/O |
| 系统背景 | ZEGO 实时音视频（实时系统）、BGI 基因数据工程、Mindray 医疗影像 |

## 真实短板（当前无证据或未验证）

| 短板 | 现状 | 影响 |
|------|------|------|
| Nsight Systems/Compute 深度使用 | 仅基础使用；无系统性 flame graph / warp stall 分析产出 | Kernel 岗高频考点 |
| Linux 性能调优（perf、内存、NUMA、CPU 频率） | 经验零散，无文档化实验 | Serving 岗考察 |
| NCCL / NVLink / RDMA / Tensor Parallel | 纯理论，无多 GPU 实验（硬件限制） | 分布式话题只能谈原理与源码 |
| 推理服务压测与可观测性 | paged-serving 已有口径校正后的 loadgen/产物契约，但尚无真实 CUDA 后端的系统报告（吞吐/尾延迟/容量曲线） | Serving 岗核心证据缺口 |
| torch.compile / PyTorch 内部机制 | 只写过 C++ extension，未深入 dispatch/inductor | 部分岗位必考 |
| 面试表达 | 项目证据充分但未经过有评分的完整模拟面试 | 最后一公里 |
| 算法/笔试 | 长期未系统刷题 | 国内岗位笔试门槛 |

## 环境约束

- 单卡 RTX 3060 Laptop 6GB：FP16 小模型可跑；任何多 GPU、TP/PP 实验均不可行，
  相关内容一律写成"理论学习 + 模拟"，不得声称实测。
