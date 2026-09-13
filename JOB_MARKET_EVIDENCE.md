# 岗位市场证据（JOB_MARKET_EVIDENCE）

基线采样日期：**2026-08-19**，n = 23 个岗位；最近增量复核：
**2026-09-13**，n = 8 个仍可访问的岗位。样本覆盖 Kernel / 推理运行时 / Serving /
编译器 / 分布式方向，同时覆盖全球与中国的代表性公司。数据来源为各公司官方
招聘页或其聚合页；标注 **(snippet)** 的条目仅取得官方 URL + 搜索摘要，未能
抓取全文，其技能计数为保守下界。

> 注：原始计划中给出的 OpenAI Ashby 链接已失效（页面不再渲染 JD），已用
> OpenAI 官网当前等价岗位替换。

## 2026-09-13 增量复核

本轮不重新计算 2026-08 基线频次，而是检查岗位要求是否发生足以改变项目路线的变化。

| 公司 | 岗位 | 新增或被强化的信号 |
|------|------|--------------------|
| OpenAI | [Software Engineer, GPT Infrastructure](https://openai.com/careers/software-engineer-gpt-infrastructure-san-francisco/) | 将 kernel/runtime/serving 优化做成可重复平台；明确要求 correctness、profiling、benchmark、artifact provenance、回归、可观测性和安全边界 |
| OpenAI | [Inference Engineer, Robotics](https://openai.com/careers/inference-engineer-robotics-san-francisco/) | kernel、数据搬运、Serving 效率和可靠性必须在真实多模态 workload 中形成端到端结果 |
| Perplexity | [MTS, AI Inference Engineer](https://jobs.ashbyhq.com/perplexity/8a976851-9bef-4b07-8d36-567fa9540aef) | Rust Serving、CUDA/CuTe DSL、跨代硬件可移植性、FP8/FP4、NCCL/RDMA、Kubernetes、prefill/decode disaggregation |
| Modal | [MTS, Research—Inference](https://jobs.ashbyhq.com/modal/73c97bbc-8e27-4c5d-b38b-90b3afdb0d93) | cost/token、tail latency、speculative decoding、disaggregated prefill/decode、KV 管理、量化、弹性扩缩容和生产可观测性 |
| Baseten | [Software Engineer—Model Performance](https://jobs.ashbyhq.com/baseten/d29e748c-7209-460d-a024-8f77ae0a3d4d) | quantization、speculative decoding、KV reuse、chunked prefill、LoRA，以及 vLLM/SGLang/TRT-LLM 的源码级调试 |
| Fireworks AI | [MTS, Performance Optimization](https://job-boards.greenhouse.io/fireworksai/jobs/4001152009) | CUDA/Triton、Nsight、跨 kernel 到多机系统的性能归因、benchmark/monitoring 基础设施 |
| Cerebras | [Senior Performance Engineer, Inference](https://jobs.ashbyhq.com/cerebras/50e42a6b-89b3-49e9-b907-624447e40d82) | 真实客户 workload、公平可复现比较、TTFT/并发延迟/tok/s/TCO，以及竞争产品持续跟踪 |
| 字节跳动 | [AI 性能优化专家—计算](https://jobs.bytedance.com/experienced/position/7320451652795746586/detail) | Linux C++/Python/Go、分布式调试、异构计算/网络/存储、软硬协同、国产加速器和量化 |

### 相比基线被强化的五个方向

1. **从单点优化转向全栈闭环**：岗位不只要 kernel，而要能沿
   `workload → scheduler → runtime → kernel → hardware → metric` 定位问题。
2. **证据工程成为正式能力**：correctness、raw samples、artifact provenance、
   regression、可观测性和公平 benchmark 不再只是作品集包装，而是岗位职责本身。
3. **Serving 技术继续前移**：KV reuse、chunked prefill、speculative decoding、
   prefill/decode disaggregation、tail latency、autoscaling 和 cost/token 反复出现。
4. **硬件和软件可移植性升温**：CuTe DSL、ROCm、国产加速器、异构 qualification
   表明“只在一张卡上快”弱于“知道如何验证新硬件、解释 dispatch 和保留回归”。
5. **生产系统边界更重要**：Rust/C++、Linux、容器、Kubernetes、NCCL/RDMA、
   incident/retry/checkpoint/security 与性能工程同时出现。

### 对当前路线的判断

- **不需要新增项目，也不需要推翻 Kernel + Runtime/Serving 双主线**。现有仓库与岗位
  关键词高度同向。
- 需要把优先级从“继续堆算子/功能”调整为“真实链路、性能归因、故障路径、证据包和一个
  上游贡献”。
- CuTe DSL、FP8/FP4、多机 RDMA 和完整 Kubernetes 平台是趋势，但在当前 RTX 3060
  Laptop 6GB 条件下不应伪造实测。它们只在目标岗位明确要求、且有合适硬件或上游任务时
  升级为执行项。
- 多数代表性岗位仍偏 senior。转行候选人不能靠仓库数量补偿经验差距，必须用可复现结果、
  代码 review、故障分析和上游协作证明生产判断力。

## 岗位样本

| # | 公司 | 岗位 | URL | 地点 | 级别 | 关键技能 |
|---|------|------|-----|------|------|---------|
| 1 | Perplexity | MTS, AI Inference Engineer | [ashby](https://jobs.ashbyhq.com/Perplexity/e4777627-ff8f-4257-8612-3a016bb58592) | SF（远程可谈） | MTS | KV cache、paged attention、continuous batching、speculative decoding、vLLM/SGLang/TRT-LLM、CUDA/CuTe、Triton、并行、量化、CUDA Graphs、C++、Linux perf、benchmark & SLO |
| 2 | OpenAI | SWE, Kernel Performance & AI Tooling | [openai.com](https://openai.com/careers/software-engineer-kernel-performance-and-ai-tooling-san-francisco/) | SF | any | kernel 级性能分析、GPU benchmarking、编译器、C++/Python |
| 3 | Cerebras | Senior Performance Engineer, Inference | [ashby](https://jobs.ashbyhq.com/cerebras/50e42a6b-89b3-49e9-b907-624447e40d82/) | Toronto/Los Altos | senior | cpufreq、火焰图、nsys/nsight、cache 拓扑、NUMA、压测方法学、OS internals |
| 4 | Baseten | SWE – GPU Kernels | [ashby](https://jobs.ashbyhq.com/baseten/ddb5bc98-6116-49a2-802e-1c05398663f1) | SF/MTL/NY/TO | mid–senior | CUDA/Triton 扩展、GEMM/attention/MoE kernel、CUTLASS/PTX、量化（GPTQ/AWQ）、Nsight Compute、PyTorch internals/torch.compile/Inductor |
| 5 | NVIDIA | Sr DL Kernel Performance Architect | [nvidia](https://jobs.nvidia.com/careers/job/893392800816) | Santa Clara | senior | GEMM/attention kernel 性能分析、C/C++/Python |
| 6 | NVIDIA | Principal SWE – AI Inference (snippet) | [nvidia](https://jobs.nvidia.com/careers/job/893393627506) | Santa Clara | principal | vLLM/SGLang on NVIDIA GPU |
| 7 | Meta | SWE, AI Kernels & Perf (MTIA) (snippet) | [metacareers](https://www.metacareers.com/profile/job_details/1477723764162264/) | US | any | 并行架构 kernel 编写/优化（CUDA） |
| 8 | Google | Staff ML Compiler Eng, TPU Perf (snippet) | [google](https://www.google.com/about/careers/applications/jobs/results/83143356728648390-ml-compiler-engineer-tpu-performance-optimizations) | MV/SV/Raleigh | staff | JAX/PyTorch、XLA、ML 编译器性能优化 |
| 9 | Microsoft | Principal SWE – Performance (snippet) | [linkedin](https://www.linkedin.com/jobs/view/principal-software-engineer-performance-at-microsoft-4382374886) | Redmond | principal | LLM GPU benchmark、全栈性能调试、云规模 GPU 推理 |
| 10 | Anthropic | TPU Kernel Engineer | [greenhouse](https://job-boards.greenhouse.io/anthropic/jobs/4720576008) | SF/NY/SEA | any | 硬件级 kernel 性能调试、低层系统 |
| 11 | Mistral AI | Eng Manager, Inference (snippet) | [ashby](https://jobs.ashbyhq.com/mistral.ai/6dfcbf55-d854-4723-85e4-f44f3032fc63) | NY | manager | 推理 API 延迟/成本/uptime SLO、事件管理 |
| 12 | AMD | Principal Compiler SDE – AI/ML (snippet) | [amd](https://careers.amd.com/careers-home/jobs/89589?lang=en-us) | US | principal | 编译器、ML 框架、GPU 架构、ROCm |
| 13 | 字节跳动 Seed | 推理 GPU 性能优化专家 | [bytedance](https://jobs.bytedance.com/experienced/position/7366450100144523570/detail) | 北京 | senior/专家 | CUDA 性能优化、深度学习基础 |
| 14 | 字节跳动 火山方舟 | 大模型推理系统工程师 (snippet) | [bytedance](https://jobs.bytedance.com/experienced/m/position/detail/7408116545665157402) | 北京 | any | Linux C/C++、Python、大规模 ML 系统 |
| 15 | 腾讯 | 大模型推理性能工程师 (snippet) | [tencent](https://careers.tencent.com/jobdesc.html?postId=2037101976877170688) | 深圳/北京 | any | C/C++、Python、vLLM/SGLang/TensorRT-LLM、大规模部署 |
| 16 | 百度昆仑芯 | 深度学习高性能计算研发工程师 | [baidu](https://talent.baidu.com/jobs/detail/SOCIAL/d16b195d-394e-44e1-9612-38d351f3ffa2) | 北京 | any | AI 芯片高性能计算库、PaddlePaddle 图优化、分布式训练/推理 |
| 17 | 阿里云 | 大模型推理优化专家 (snippet) | [aliyun/BOSS](https://www.zhipin.com/zhaopin/b2ba92d5c25440661nx_3Ny5Fw~~/) | 杭州/北京 | senior | Diffusion + LLM 推理加速、低成本高性能推理服务 |
| 18 | 小米 MiMo | 大模型训练与推理 Infra 工程师 | [xiaomi](https://xiaomi.jobs.f.mioffice.cn/index/m/position/7446241662216700012/detail) | 北京/上海 | any | CUDA、NCCL、cuDNN、GPU/NPU 架构、分布式 |
| 19 | 月之暗面 Kimi | AI Infra / 推理工程师 (snippet) | [zhipin](https://www.zhipin.com/job_detail/8dae5b02f9a2d0630nR82tu_FFBY.html)（官方 [careers.kimi.com](https://careers.kimi.com/)） | 北京/上海 | junior~ | 推理引擎计算效率、Python/C++、性能问题分析、CUDA |
| 20 | B 站 | 大模型推理优化工程师 (snippet) | [bilibili](https://jobs.bilibili.com/social/positions/28366) | 上海 | any | vLLM/TensorRT-LLM 部署、高性能算子开发 |
| 21 | DeepSeek | 深度学习研发工程师 (snippet) | [deepseek](https://talent.deepseek.com/) | 北京/杭州 | any | ML/DL、强编程、研究能力 |
| 22 | SambaNova | Principal AI Systems Perf Eng (snippet) | [monster](https://www.monster.com/job-openings/principal-ai-systems-performance-engineer-san-jose-ca--207219fb-8f61-4eb0-8d58-37be6b7528e7) | San Jose | principal | RDU 推理栈系统性能工程 |
| 23 | NVIDIA | DL Perf SWE – LLM Inference (snippet) | [builtin](https://builtin.com/job/dl-performance-software-engineer-llm-inference/10563942) | Santa Clara | any | LLM 推理 GPU kernel 优化、给 vLLM 贡献特性 |

## 技能出现频次（n=23）

| 技能领域 | 提及数 | 说明 |
|---------|--------|------|
| GPU 架构 / 性能分析（Nsight、profiling、火焰图） | 11 | **最高频**，全球岗位尤其突出 |
| CUDA / CuTe / PTX | 8 | 全球 kernel 岗核心；中国岗位同样普遍 |
| Python | 9 | 与 C++ 成对出现 |
| LLM 推理（KV cache、continuous batching、推理框架） | 9 | 中国岗位的标志性要求（vLLM/SGLang/TRT-LLM） |
| C++ | 7 | 中国岗位几乎逐字写"C/C++ + Python" |
| Serving / 可观测性 / benchmark / SLO | 7 | 压测方法学与指标口径被反复点名 |
| Kernel 库（FlashAttention/FlashInfer/vLLM/SGLang/TRT-LLM） | 5 | |
| 分布式 / 通信（NCCL、TP、大规模系统） | 4 | |
| 编译器（TVM/MLIR/XLA/ROCm） | 4 | 独立子赛道 |
| Triton | 2 | 主要出现在推理平台公司（Perplexity、Baseten） |
| 量化 | 2 | 同上 |
| Linux 系统（OS internals、cpufreq） | 2 | Cerebras/字节明确要求 |
| PyTorch internals / torch.compile | 1 | 仅 Baseten 明确列出 |

## 对时间权重的推导（→ TOPIC_WEIGHTS.md）

- CUDA+Profiling 22%：CUDA 8/23 + 性能分析 11/23 双高频，且是本人短板（Nsight）。
- 推理运行时 22%：9/23 高频，且已有 tiny-llm/paged-serving 证据可放大。
- 项目证据 18%：所有岗位都要求"可复现 benchmark"，证据包是一票否决项。
- Triton/PyTorch 集成 10%：显式提及仅 2/23，但作为 kernel 岗加分项保留。
- Serving/Linux/通信 12%：7/23 压测可观测性 + 4/23 分布式（理论）。
- C++/算法 8%：中国岗位笔试硬门槛。
- 求职执行 8%：不体现在 JD，但决定转化率。

## 局限

- 12/23 条目为 snippet 级证据，频次为下界。
- 岗位样本偏 senior（principal/staff 占 6），junior 岗位要求可能更低。
- 市场随时间变化；W6 时复查一次失效链接并补充 5 个新样本。
