# 云 GPU 实验手册

> 目标：用最少云成本补齐本机 RTX 3060 Laptop 6GB 无法完成的 profiler、较大模型、
> serving 容量与多 GPU 实验；云服务器不是日常编辑器，也不替代本地正确性测试。
>
> 价格快照：2026-08-23。GPU 供给、地域和价格会变，创建实例前以
> [Runpod 实时价格页](https://www.runpod.io/pricing)为准。

## 1. 选型结论

### 默认：单卡 L40S 48GB

建议先按小时租，不买包月、不签 3/6 个月预付：

- GPU：1 × NVIDIA L40S 48GB（sm_89，ECC，FP8）；
- CPU：至少 16 vCPU；
- 内存：至少 96GB，原则上不低于 GPU 显存的 2 倍；
- 磁盘：系统盘 80GB + 200–300GB 持久 NVMe/网络卷；
- 系统：Ubuntu 22.04，驱动由云厂商维护；开发环境用固定 CUDA 容器；
- 网络：至少 1Gbps；serving 正式压测时由第二台便宜 CPU 实例发压，避免客户端
  与服务端争用 CPU。

L40S 有 48GB GDDR6 ECC、864GB/s 带宽，且是数据中心卡；它能覆盖 7B/14B
量化推理、长上下文 KV Cache、较高并发和 FP8 学习，同时与当前项目的 Ada/sm_89
路径相容。NVIDIA 官方规格见
[L40S 产品页](https://www.nvidia.com/en-us/data-center/l40s/)；Runpod 当前 Pod 列表给出的
L40S 规格为 48GB VRAM、94GB RAM、16 vCPU、约 $0.99/GPU-hour。

### 按实验切换，不长期占用

| 资源 | 当前参考价 | 何时用 | 不适合 |
|------|-----------:|--------|--------|
| RTX 4090 24GB | $0.74/h | CUDA/Triton kernel 快速迭代、与 Ada 消费卡对照 | 长上下文、高并发、需要 ECC |
| RTX 5090 32GB | $0.99/h | Blackwell/sm_120 专项兼容与新低精度路径 | 当前仓尚未声明 sm_120 时直接当默认基线 |
| L40S 48GB | $0.99/h | **默认单卡：kernel + engine + serving** | NVLink/MIG 实验 |
| A100 PCIe 80GB | $1.39/h | HBM 带宽、80GB 长上下文、Ampere 生产基线 | Ada/FP8 特性 |
| A100 SXM 80GB | $1.59/h | 两卡 NCCL/NVLink 短实验 | 日常单卡开发 |
| H100 PCIe/SXM 80GB | $2.89/$3.29/h | 只在明确 Hopper/TMA/FP8 问题时短租 | 用来跑普通单卡单测 |

以上是 2026-08-23 的页面快照，不是报价承诺。A100 80GB PCIe 官方规格为
80GB HBM2e、最高约 1.94TB/s；L40S 虽计算能力更新，但没有 NVLink。硬件差异本身就是
实验变量，不能把不同 GPU 的 before/after 混成优化收益。

## 2. 12 周预算

建议设置 **$300 硬上限**，目标控制在 $180–250：

| 用途 | 预算用量 | 参考费用 |
|------|---------:|---------:|
| L40S 主实验 | 100h | $99 |
| A100 PCIe 80GB 长上下文/带宽对照 | 20h | $27.80 |
| 2 × A100 SXM 多卡实验 | 12h × 2 | $38.16 |
| 250GB 网络卷 × 3 个月 | 3 个月 | 约 $52.50 |
| 机动与失败重跑 | — | $30–50 |

网络卷当前参考价为 $0.07/GB/月；停止实例后存储仍计费。模型与结果应同步到对象存储或
本地，项目源码只保留可复现配置和小型结果，不能把 GGUF 权重提交进 Git。

止损规则：

1. 充值使用小额分批，设置余额提醒；不开自动扩容。
2. 启动 GPU 前，本地先完成编译、测试矩阵、命令草稿和退出条件。
3. 空闲 15 分钟就关机；当天任务结束后确认 GPU 实例已删除或停止。
4. 每周记录 GPU-hours、失败原因和有效产物；有效产物不足 50% 时，下周先修流程，
   不增加预算。
5. 未连续四周用满计划时数前，不购买长期套餐。

## 3. 每次云实验的闭环

### 开机前（本地，30–60 分钟）

- 写清唯一问题、基线、改动、主要指标和反证条件；
- 固定模型、量化、prompt/数据集、采样参数、输入/输出长度与随机种子；
- 在本机通过单测和小规模 smoke；
- 准备一条可复制命令和预期最长运行时间。

### 开机后（10 分钟）

保存到本次结果目录的 `metadata.json` 或 README：

```text
git SHA + dirty 状态
GPU 型号 / nvidia-smi / 拓扑
driver / CUDA runtime / toolkit / PyTorch / Triton
CPU / RAM / 内核 / 容器 digest
模型 ID、revision、量化、tokenizer revision
功耗与时钟策略、实验命令、开始时间
```

先跑正确性 canary，再跑性能；correctness 不通过时禁止收集或展示性能数字。

### 正式测量

- 每个配置至少 3 个独立进程；每进程先 warmup，再做 10 次以上测量；
- A/B 顺序交错或随机，避免温度、时钟和缓存随时间漂移；
- 同一图只比较同 GPU、同软件栈、同模型/量化、同请求分布的结果；
- 原始逐请求/逐迭代数据是权威，汇总和图片必须可从原始数据重新生成；
- 至少报告 p50/p95、误差/重复带和失败率，不能只选最好一次。

### 关机前（10 分钟）

- 下载 raw JSON/JSONL、summary、图、profiler 报告和完整 stdout/stderr；
- 对结果目录做校验并记录异常；
- 推送小型证据文件前再次确认没有 token、SSH key、模型权重或个人信息；
- 停止/删除实例，再检查账单页和持久卷。

## 4. 项目与服务器任务映射

| 周次 | 云上重点 | 项目 | 必须产物 |
|------|---------|------|---------|
| W1–W2 | Nsight Compute 权限、GEMM/访存 roofline | `cuda-foundations` | 一份 `.ncu-rep` + 指标解释，不只截图 |
| W3 | FlashAttention shape/因果/GQA 矩阵 | `cuflash` | 正确性矩阵 + roofline + p50/p95 |
| W4 | 同一算子 CUDA/Triton 对照 | `trifuse` | 相同 shape/dtype 的速度与误差表 |
| W5–W6 | clean commit 的 TTFT/TPOT、Graphs A/B、长上下文 | **`tiny-llm`** | schema v2 raw JSON + profiler + 正式报告 |
| W7–W8 | 并发、Paged KV、开环/闭环/Poisson 负载 | `paged-serving` | `summary.json`、逐请求 JSONL、饱和曲线 |
| W9 | 两卡 NCCL/topology/TP 最小实验 | 独立实验，不新建产品仓 | nccl-tests + 拓扑 + 通信/计算分解 |
| W10 | clean commit 复测与外部工具交叉验证 | `tiny-llm` + `paged-serving` | 可放简历的最终数据包 |
| W11–W12 | 仅补证据，不探索新主题 | 全部 | Demo、面试追问、复现检查 |

优先级始终是 `tiny-llm` > `cuflash` > `paged-serving`。`cuda-foundations` 和
`trifuse` 用来解释基础与对照，不应抢占旗舰项目时间。

## 5. 评测矩阵与图表

### Kernel 层

- shape：短/中/长序列，整齐边界与非对齐边界，MHA/GQA/MQA；
- dtype：FP32 参考、FP16/BF16、项目真实量化；
- 正确性：CPU/PyTorch 权威参考、绝对/相对误差、属性测试、compute-sanitizer；
- 性能：CUDA Event 延迟、有效带宽/TFLOPS、占用率、DRAM/L2、warp stall；
- 图：roofline 点、延迟随 shape、速度提升及置信区间。

### Engine 层

- 同一请求内测 TTFT；TPOT 只覆盖首 token 之后的输出 token；单 token 时为 N/A；
- 比较时固定模型、量化差异说明、prompt、greedy、max tokens、warmup 与进程数；
- `cudaMemGetInfo` 两个时间点只能称常驻显存差值；峰值显存必须有外部采样器及频率；
- 图：TTFT/TPOT 分布、tokens/s、显存随上下文、Graph on/off 配对差值。

### Serving 层

- 数据集：synthetic 128/128、512/128、2048/256，加一组真实对话分布；
- 负载：并发 1/2/4/8/16；闭环、固定/Poisson 到达率；
- 指标：成功率、错误分类、TTFT p50/p95/p99、TPOT/ITL、请求/输出 token 吞吐；
- 图：吞吐—p95 TTFT Pareto、offered load—goodput、并发—尾延迟、KV 使用率—时间；
- `paged-serving` 自有 loadgen 是主证据；正式报告再用
  [GuideLLM](https://github.com/vllm-project/guidellm) 对 OpenAI 兼容端点交叉验证。
  [vLLM 官方 benchmark 文档](https://docs.vllm.ai/en/latest/benchmarking/cli/)
  也推荐 GuideLLM 做生产服务评测。

## 6. 云环境验收清单

- [ ] 普通用户可运行 ncu/nsys，并成功导出可解析报告；
- [ ] `nvidia-smi topo -m`、GPU 型号与承诺配置一致；
- [ ] 编译五个技术仓的 GPU 目标，不依赖宿主机未记录的软件；
- [ ] 容器重建后 smoke 结果一致；
- [ ] 远程发压网络稳定，客户端 CPU 未打满；
- [ ] 预算提醒、自动关机和结果同步都已演练；
- [ ] 所有正式数字来自 clean commit，报告同时记录 raw data 与限制。
