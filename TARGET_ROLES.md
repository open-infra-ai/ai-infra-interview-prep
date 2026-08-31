# 目标岗位（TARGET_ROLES）

更新日期：2026-08-23。岗位样本与证据见 [JOB_MARKET_EVIDENCE.md](JOB_MARKET_EVIDENCE.md)。

## 主方向：LLM Inference Performance / GPU Kernel Engineer

- **做什么**：为 LLM 推理编写和优化 CUDA/Triton kernel（GEMM、Attention、量化、
  采样、KV Cache 操作），做端到端性能分析与调优。
- **核心考察**：CUDA 编程模型与 GPU 架构、访存与计算分析、FlashAttention 系列算法、
  量化 kernel、profiling（Nsight）、与 PyTorch/推理框架的集成。
- **我的证据**：以 open-infra-ai/tiny-llm 的真实推理链路为旗舰，cuflash
  证明 kernel 深度，cuda-foundations 与 trifuse 提供基础和横向对照
  （详见 [PROJECT_STRATEGY.md](PROJECT_STRATEGY.md)）。

## 次方向：LLM 推理运行时与 Serving Engineer

- **做什么**：推理引擎的调度、批处理（continuous batching）、KV Cache 管理、
  serving API、压测与容量规划、可观测性。
- **核心考察**：PagedAttention、调度器状态机、TTFT/TPOT/吞吐/尾延迟指标、
  vLLM/SGLang/TensorRT-LLM 架构、Linux 与网络基础。
- **我的证据**：open-infra-ai 的 tiny-llm + paged-serving，及 ZEGO 实时系统背景。

## 可选方向：ML Compiler Engineer

- **做什么**：图编译、算子融合、自动调度、代码生成（TVM/MLIR/XLA/Triton 编译器）。
- **决策规则**：**只有当实际投递编译器岗位比例 > 30% 时**才把 TVM/MLIR 提升为主线
  （占用 CUDA 时间的 30%），否则保持选修。默认不作为前三月主攻。

## 明确不作为前三个月主攻

- 分布式训练平台（NCCL/多机多卡训练运维）：以理论学习为主，单 RTX 3060 Laptop 6GB
  无法做真实多 GPU 实验，只能做模拟与论文/源码研读，不能伪造实验数据。

## 岗位边界

- 中国大陆（深圳）与全球远程/在岗均投；样本同时覆盖两地（见 JOB_MARKET_EVIDENCE.md）。
- 级别定位：性能/系统方向的工程师岗（不限定 junior/senior，按 JD 要求分层投递）。
