# 面试题矩阵（INTERVIEW_MATRIX）

更新日期：2026-08-19。每道题五要素：**答案要点 / 追问树 / 代码定位 / 实验证据 / 评分标准**。
W3 起每周补充当周主题的 3–5 题并自评。此文件是索引 + 示范格式；正文按主题增长。

## 评分标准（通用）

- **A（4/4）**：要点完整、能画图、能定位到自己仓库的具体代码、有量化数字与口径。
- **B（3/4）**：要点完整、能讲原理，缺代码定位或数字。
- **C（2/4）**：能复述概念，追问两层即卡住。
- **D**：答不上。→ 回到周计划补课，两周后重测。

---

## Q1（P0·Kernel）FlashAttention 为什么快？（W3）

- **答案要点**：标准 attention 的中间矩阵 S/P 显存 O(N²) 导致 HBM 往返；
  FA 用 tiling + online softmax（running max/sum）把中间量留在 SRAM，
  复杂度不变但 HBM 访问从 O(N²) 降到 O(N²d²/M)；FA2 改进并行划分（序列维）
  与减少非 matmul FLOPs。
- **追问树**：online softmax 数值稳定性？→ 为什么不能先算完 max？→ causal mask
  如何跳块？→ KV 在 SRAM 放不下怎么办？→ 与 PagedAttention 的关系（正交：一个管
  计算分块，一个管显存分页）。
- **代码定位**：open-infra-ai/cuflash 前向 kernel（WMMA 分块 + causal 边界跳过）；
  trifuse 的 Triton 版对照。更名说明：trifuse 即原 `triton-fused-ops`
  （2026-08-31 全面更名，GitHub 旧链接 301 重定向；本仓 handoffs/2026-08-28
  基线快照中的旧仓名为当时事实，不回写）。
- **实验证据**：cuflash 的 FP32/FP16/BF16 差分测试与 benchmark（口径见该仓）。
- **自评**：__待测（W3）__

## Q2（P0·Kernel）GEMM 优化阶梯，每一步解决什么瓶颈？（W2）

- **答案要点**：naive（无重用）→ coalescing（合并访存）→ shared memory tiling
  （重用）→ register tiling/vectorize → 双缓冲/异步拷贝 → WMMA/MMA（Tensor Core）。
  每步给出 roofline 上的移动方向（访存受限 → 计算受限）。
- **追问树**：bank conflict 怎么产生/消除？→ occupancy 与寄存器压力的权衡？→
  为什么要 swizzle？→ cuBLAS 还做了什么（split-k、kernel 选择启发式）？
- **代码定位**：open-infra-ai/cuda-foundations SGEMM 阶梯；Fork siboehm/SGEMM_CUDA 对照。
- **实验证据**：cuda-foundations 各阶梯 benchmark 表 + W2 的 Nsight Compute 报告。
- **自评**：__待测（W2）__

## Q3（P0·推理）PagedAttention 解决什么问题？块大小怎么选？（W7）

- **答案要点**：连续 KV 预留导致内部/外部碎片与浪费；分页把 KV 切成固定 block，
  按需分配、可共享（prefix caching）、可抢占。块大小的权衡：小→碎片少但元数据与
  间接寻址开销大；大→反之（vLLM 默认 16）。
- **追问树**：copy-on-write 前缀共享怎么实现？→ 抢占式调度两种模式（recompute/
  swap）？→ 与 continuous batching 的调度循环怎么交互？→ TTFT/TPOT 分别受什么影响？
- **代码定位**：open-infra-ai/paged-serving 分配器与调度器状态机；tiny-llm 分页 KV 策略 1。
- **实验证据**：paged-serving 3 并发 e2e 对齐记录；W7 补状态机不变量文档。
- **自评**：__待测（W7）__

## Q4（P0·推理）W8A16 量化的误差与性能权衡？（W5）

- **答案要点**：权重 int8、激活 fp16；per-channel scale 降低误差；dequant 在 kernel
  内做还是外部做影响访存模式；TPOT 收益主要来自权重搬运减半与带宽节省。
- **追问树**：为什么不算子融合后量化？→ 与 FP8/W4A16 的对比？→ 如何验证量化后
  正确性（逐 token 差分 vs 端到端 perplexity）？
- **代码定位**：open-infra-ai/tiny-llm 量化加载与 dequant kernel。
- **实验证据**：tiny-llm W8A16 TPOT ≈ 6.1 ms/token（本机，口径见该仓）。
- **自评**：__待测（W5）__

## Q5（P0·Serving）TTFT 和 TPOT 分别由什么决定？怎么压尾延迟？（W8）

- **答案要点**：TTFT ≈ 排队 + prefill 计算；TPOT ≈ decode 每 step 的 kernel +
  调度开销。压 p99：batch 上限、抢占、chunked prefill、CUDA Graph 消除 launch
  开销、隔离 prefill/decode。
- **追问树**：continuous batching 下新请求何时插入？→ 如何测量（压测口径、warmup、
  分布拟合）？→ 容量规划怎么做（并发-吞吐-延迟曲线找拐点）？
- **代码定位**：open-infra-ai/paged-serving 调度循环与 HTTP 层。
- **实验证据**：W8 压测报告（计划交付）。
- **自评**：__待测（W8）__

## Q6（P1·系统）NCCL 做了什么？TP 通信与计算怎么重叠？（W9·理论）

- **答案要点**：集合通信原语（AllReduce/AllGather）的 ring 与 tree 算法、
  拓扑感知通道；TP 每层两次集合通信，靠异步通信 + 计算分块（GEMM 切分）重叠；
  NVLink vs PCIe 带宽差决定重叠收益。
- **追问树**：ring AllReduce 带宽公式？→ 为什么 TP 对小 batch 不友好？→
  sequence parallel 减少了什么通信？
- **代码定位**：理论题；源码参考 Fork open-mpi/ompi 的通信抽象（选读）。
- **实验证据**：**无多 GPU 实验条件，只谈理论与论文/源码结论，明确声明。**
- **自评**：__待测（W9）__

## Q7（P1·工程）torch.library 自定义算子注册的流程与坑？（W4）

- **答案要点**：定义 schema、注册实现（CPU/CUDA/meta）、autograd；
  坑：schema 与实现签名不一致、fake tensor/meta 注册缺失导致 torch.compile 失败。
- **代码定位**：open-infra-ai/trifuse 的 `torch.ops.trifuse.*` 注册。
- **自评**：__待测（W4）__

---

## 追加规则

- 每周文件中的"面试问题"默认三要素（要点/追问/代码定位），达到 A 级才在 progress-tracker 打卡。
- 模拟面试（W11）全部从本矩阵抽题，评分记录追加到各题"自评"处。
