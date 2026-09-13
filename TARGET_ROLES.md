# 目标岗位（TARGET_ROLES）

更新日期：2026-09-13。岗位样本与证据见 [JOB_MARKET_EVIDENCE.md](JOB_MARKET_EVIDENCE.md)。

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

## 2026-09 市场校准

- **主方向不变，但对外名称收敛为 `LLM Inference Performance / Runtime Engineer`**。
  最新岗位普遍跨 kernel、runtime、serving 和 benchmark；只写 “CUDA Kernel Engineer”
  会隐藏 `tiny-llm + paged-serving` 的差异化证据。
- Kernel 版本简历强调 `cuflash + tiny-llm` 的真实热点、Nsight 归因和数值正确性；
  Runtime/Serving 版本强调 `tiny-llm + paged-serving` 的 KV 生命周期、调度、尾延迟、
  backpressure/cancellation 和 C ABI。
- 不以当前项目投递 Staff/Principal 分布式平台岗位；优先选择允许用强 C++/CUDA/系统背景
  抵消 LLM Infra 年限不足的 engineer、performance、runtime 和 inference systems 岗位。
- 只有当最近 20 个真实投递岗位中至少 6 个把 Kubernetes/集群运维列为核心职责，才为
  Serving 路线增加完整 K8s 实验；否则只保留容器化、metrics 和部署契约，不挤占
  direct paged attention 与真实压测时间。
