# 项目策略（PROJECT_STRATEGY）

更新日期：2026-08-23。现有五个技术仓已经覆盖 CUDA 基础、Triton、Attention、
推理运行时和 Serving 控制面。接下来不靠增加仓库数量，而靠主项目深度、统一评测和上游贡献
提高求职信号。

## 核心决策

- **推理加速旗舰：`open-infra-ai/tiny-llm`**。
- **Kernel 深挖：`open-infra-ai/cuflash`**。
- **Serving/调度扩展：`open-infra-ai/paged-serving`**。
- `cuda-foundations` 与 `trifuse` 是基础和横向对照，`fq-compressor` 只证明
  C++/并发/工程质量。
- 技术仓名称已被简历与证据链接引用，保持冻结。`paged-serving` 对“分页 KV + 推理控制面”
  的表达足够准确，不为追求听起来更大而重命名。

### 命名结论

- `cuflash` 并不奇怪：slug 直接表达 CUDA + FlashAttention，搜索语义明确；
  README 展示名使用更易读的 **CuFlash-Attn**。只有项目离开 Attention 边界时才需要改名。
- `trifuse` 相对通用，但与 RMSNorm+RoPE、Gated MLP、FlashAttention 和
  `torch.library` 的横向对照职责一致；README 首屏用“Transformer 推理融合算子”收紧
  语义即可。若只剩单一算子或演变为完整 compiler/runtime，才重新评估 slug。
- 重命名的收益目前小于迁移成本：会打断简历、benchmark、Pages、badge、release、PyPI
  包名和上游引用。专业化优先靠清晰边界、可信数据和持续维护，不靠频繁换名。
- **2026-08-31 更新**：经重新评估后执行了全面更名 `triton-fused-ops` → `trifuse`
  （品牌与 cuflash/kvtier 构词统一；上述迁移成本已实际发生并全部收口：GitHub 301、
  6 仓交叉引用、import 名与 `torch.ops.trifuse.*` 命名空间，见 open-infra-ai 根
  `changelog/2026-08-31-rename-trifuse.md`）。上方原评估记录保留如上。

## 项目 1：旗舰 = `tiny-llm`

**一句话**：CUDA 原生 C++ 推理运行时，从 GGUF 权重、W8A16、tokenizer、KV Cache 到
decode 与 C ABI，能在真实 Qwen2.5-0.5B 模型上端到端生成。

**为什么它最适合推理加速面试**：它同时允许讲计算热点、内存布局、量化、kernel launch、
CUDA Graph、真实模型正确性和端到端指标；优化前后能落到同一条 decode 链路，而不是只展示
孤立 microbenchmark。

**当前证据快照**：

- clean commit `565da79` 的 schema v2 五组交错配对 A/B 中，CUDA Graph off→on 的
  TPOT 跨进程中位数 8.322→5.225 ms/token（-37.2%），decode 吞吐
  120.168→191.384 tok/s（+59.3%）；10 个进程原始 JSONL、机器可读聚合和模型哈希
  [已归档](https://github.com/open-infra-ai/tiny-llm/blob/master/docs/performance/results/2026-08-23-cuda-graphs-ab.md)；
- TTFT 配对变化范围 -8.5%～+14.6%，两种聚合方向不一致，故不宣传 TTFT 改善；
- 转置 M==1 GEMM 的历史 schema v1 与 microbenchmark 只用于说明优化沿革，不和上述
  schema v2 Graph 消融混算；
- 与 llama.cpp 的 1.65× 差距是 W8A16 vs Q4_K_M 的非同量化对照，只能作为外部参考，
  不能宣传为公平加速比；
- CUDA Graph 默认启用且 on/off greedy token 一致；
- tokenizer 与 HuggingFace 30 例、417 token 逐 id 对齐；
- 2026-08-23 当前测试 193 项通过。

**下一阶段只补证据，不盲加功能**：

1. 已完成 CUDA Graph clean-commit 五组配对消融；下一步补转置快路径 on/off 与
   连续 KV/分页 KV，每次只改一个因素；
2. 扩展 prompt 长度、输出长度与 batch 矩阵，继续使用 ≥5 个独立进程、交错顺序和
   中位数/范围，不挑最好一次；
3. 用 Nsight Systems 拆 prefill/decode 时间线，用 Nsight Compute 锁定 lm_head、attention、
   dequant 的吞吐、stall 与 occupancy；
4. 画 prompt 长度 × 输出长度 × batch 的 TTFT、TPOT、tok/s、显存曲线；若声称峰值，
   必须使用外部采样器并记录采样频率，不把离散 `cudaMemGetInfo` 差值冒充峰值；
5. 外部基线必须同模型、同 prompt、同采样、同输出长度，并在不能同量化时醒目标注限制。

## 项目 2：Kernel 深挖 = `cuflash`

**一句话**：从零实现 FlashAttention 前后向与 FlashDecoding，覆盖 FP32/FP16/BF16、
WMMA、causal 边界和非整除形状。

**面试价值**：用一个算法讲透 online softmax、tiling、共享内存、Tensor Core、数值容差、
越界修复与负优化，不需要再新建一个 attention 玩具仓。

**下一阶段证据**：选择 4–6 个能代表 prefill/decode 的形状，补 Nsight Compute 报告；在同一
硬件上对比 PyTorch SDPA/官方 FlashAttention（能安装时）并保留更慢的形状，不只展示赢家。

## 项目 3：Serving 扩展 = `paged-serving`

**一句话**：Rust 控制面负责 Paged KV、continuous batching、调度状态机、限流、取消、
OpenAI 兼容 HTTP/SSE 和服务评测，经 C ABI 接 `tiny-llm` 真实后端。

**边界**：它证明系统设计与服务评测，不冒充底层 kernel 性能项目。3 并发 e2e 是正确性证据，
不是生产 QPS 或容量证明；CPU 参考后端只用于协议和调度回归，不能产生 GPU 吞吐结论。

**下一阶段证据**：使用已校正的 serving harness，在真实后端上画并发/到达率 → TTFT p95/p99、
TPOT、吞吐、失败率和显存曲线；报告 warmup、重复次数、token 计数覆盖率和原始 `summary.json`。

不同 KV、调度、抢占或 batching 想法放在本仓的实验/benchmark 场景内，以一个假设、一个
对照和一个结论为单位推进。不要为每个优化点拆新仓，否则复用、评测和维护成本会掩盖学习收益。

## 辅助项目

- `cuda-foundations`：讲 CUDA 编程模型、SGEMM 阶梯、错误配置和性能测量纪律。
- `trifuse`：讲相同算子的 Triton 表达、输入契约与 `torch.library` 集成。
- `open-genomics/fq-compressor`：只在需要证明 C++23、oneTBB、数据布局与工程质量时出现，
  不占 AI Infra 简历的主叙事位置。

## 新仓库门槛

默认不新建项目。一个想法只有同时满足以下条件才值得独立成仓：

1. 受众与现有五仓明显不同；
2. 依赖、发布周期和维护者边界能够独立；
3. 已在现有仓实验或上游 issue 中完成最小验证；
4. 能形成至少一个独立正确性基线和一套可复现 benchmark；
5. 不会复制现有 KV Cache、scheduler、attention 或 runtime 主链路。

参与 vLLM、SGLang、FlashInfer、llama.cpp 等上游比再造一个同类玩具仓更有外部信号，但不把
“PR 必须合入”设为 12 周关键路径。每周固定 2–4 小时做 issue 筛选、复现、review 或小 PR；
最终证据以上游链接为准，本仓 `community/` 只保存调查过程和复现器。

## 2026-09 招聘趋势映射

最新岗位增量复核没有改变项目组合，只改变完成顺序。先完成现有 P0，再从目标岗位选择一个
趋势增强项；不要同时追逐 CuTe、FP4、MoE、speculative decoding、disaggregation 和 K8s。

| 市场要求 | 当前承载仓 | 必须先补 | 通过后可选一个增强项 |
|---------|-----------|---------|----------------------|
| kernel/data movement/硬件利用率 | `cuda-foundations`、`cuflash`、`tiny-llm` | `CUDA-P1-001`、`CUF-P0-001..004`、`TLLM-P0-002..005`，形成真实 Nsight + correctness 链 | 对一个热点做 CUTLASS/CuTe/Triton 横向实现；无支持硬件时只做设计和编译验证 |
| KV/continuous batching/tail latency | `tiny-llm`、`paged-serving` | direct paged attention、真实 backend、取消、背压、指标语义和并发矩阵 | chunked prefill 或 prefix/KV reuse；二选一并给端到端 A/B |
| speculative/disaggregated inference | `tiny-llm`、`paged-serving`、`kvtier` | 先证明现有单机 prefill/decode、KV ownership 和故障回收正确 | 只做一个 L4 设计 + 最小原型，不在缺多 GPU 时声称生产收益 |
| benchmark/provenance/qualification | 所有技术仓 + `open-infra-ai` | 新正式结果采用 evidence manifest；raw/hash/commit/dirty/失败样本可追溯 | 加入 correctness/performance regression gate |
| Rust/C++/Python 跨层系统 | `paged-serving` + `tiny-llm` | 双源 ABI、错误映射、buffer/lifetime、cancel/disconnect 后资源回基线 | 增加可观测的 retry/checkpoint 只限离线实验控制面 |
| Kubernetes/autoscaling/生产运维 | `paged-serving` | `/health`、`/ready`、metrics、容器化、负载与容量曲线 | 仅 Serving 目标触发时增加最小 K8s deployment/HPA 实验 |
| 异构硬件/ROCm/国产卡 | 当前不设新仓 | schema 保留 hardware/toolchain/dispatch，CPU-only CI 不冒充加速器验证 | 有真实设备或上游 issue 后再做 portability PR |

### 市场对齐后的唯一 P0 链

```text
TLLM-P0-002 synthetic oracle
  → TLLM-P0-004 direct paged decode
  → TLLM-P0-005 Transformer/FFI integration
  → PSRV-P0-001..004 lifecycle/failure semantics
  → PSRV-P1-002 real backend gate
  → PSRV-P1-003/004 telemetry + serving matrix
  → one upstream issue/PR with reproducible evidence
```

这条链已经覆盖最新招聘最常见的“kernel + runtime + serving + benchmark + reliability”组合。
在它完成前，新增 MoE kernel、FP4、完整 K8s、第二个 runtime 或新的练习仓都属于分散注意力。

### 七仓具体调整

| 仓库 | 市场价值 | 现在应做 | 暂时不做 |
|------|---------|---------|---------|
| `tiny-llm` | **最高，旗舰数据面** | synthetic oracle → direct paged decode → FFI 集成 → Nsight/长上下文 A/B；补充 exact model/commit/raw evidence | 新模型大而全支持、没有 profiler 证据的量化宣称 |
| `paged-serving` | **最高，旗舰控制面** | cancellation、bounded backpressure、真实 backend gate、TTFT/TPOT/p99/失败率/显存/queue-depth 容量曲线 | 先搭复杂 K8s 平台、把 scheduler batching 写成 fused GPU batching |
| `cuflash` | **高，Kernel 深度** | 先修 workspace/stream 生命周期，GPU correctness + sanitizer 后做 4–6 个代表形状的 Nsight 归因 | 为追逐 JD 同时加 MoE、FP4、CuTe；RTX 3060 上冒充新架构收益 |
| `trifuse` | **中高，框架集成差异化** | 强化 `torch.library`、fake/meta、`torch.export`、dynamic shape 和公平 Triton baseline | 重复 `cuflash` 的全部 CUDA 算子；扩成通用 compiler |
| `cuda-foundations` | **中，教学与基础证明** | 把 SGEMM 优化阶梯变成可复现 roofline/Nsight 教学案例，保留失败与负优化 | 包装成生产 kernel 库，继续堆无主线的小 kernel |
| `kvtier` | **中，前沿研究加分** | 固定 SGLang commit，做 host DRAM 回载 correctness 和单卡 IO/KV dtype 矩阵；说明与 disaggregation/KV reuse 的关系 | 宣称自研生产 tiering engine；缺多机条件时给 disaggregation 性能数字 |
| `open-infra-ai` | **必要但不单独占简历** | 维护 evidence index、manifest、stale/revoked 状态和跨仓 demo 路径 | 把文档数量当项目成果，复制技术仓内容 |

简历首屏只放 `tiny-llm + paged-serving` 作为一个系统项目、`cuflash` 作为一个性能深挖项目；
`trifuse`、`cuda-foundations`、`kvtier` 放链接或面试追问材料，不再七仓等权展示。

## STAR 条目模板（W10 产出）

每个项目一条 STAR：S 背景 → T 目标与指标口径 → A 我的实现与取舍 → R 量化结果
（硬件/版本/日期/commit/命令）。数字必须能溯源到技术仓 benchmark 结果，限制条件紧跟数字，
不能藏在页尾。
