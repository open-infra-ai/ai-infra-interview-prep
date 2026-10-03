# 面试题矩阵（INTERVIEW_MATRIX）

更新日期：2026-10-04。每道题五要素：**答案要点 / 追问树 / 代码定位 / 实验证据 / 评分标准**。
七仓搭建关系、逐阶段成果和项目叙事见
[PROJECT_MILESTONES_AND_INTERVIEW_GUIDE.md](PROJECT_MILESTONES_AND_INTERVIEW_GUIDE.md)。
W3 起每周补充当周主题的 3–5 题并自评。此文件是索引 + 示范格式；正文按主题增长。

## 三张答辩牌

面试不需要把所有功能念一遍。任选一张，用 2 分钟讲“直觉 → 反例 → 决策 → 边界”：

1. **省一次 gather，为什么反而可能更慢？** 用已有 DPA 三路数据解释间接寻址代价；
   机制要由 profiler 验证，不能凭源码给因果结论。对应 Q8。
2. **一个 kernel 约 6×，为什么没有打开默认？** 对比 2048 的收敛结果与短窗口噪声/
   combine 成本，再解释 kernel 不等于模型或 Serving。对应 Q8/Q10。
3. **并发从 1 到 8，为什么不是“吞吐扩展成功”？** 9/7 正式矩阵没有证明随并发扩展，
   还包含未收敛项和 429；讲清调度 batch 与计算 batch 的区别。对应 Q5/Q13。

这些是答辩提示，不是本人贡献证明。陈述“我做了”前须能指出本人决策、代码和验证；
暂时说不清，就把它当现场读实验练习。

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
  间接寻址开销大；大→反之（本仓结果覆盖 block size 16/32，不能替代通用最优值）。
- **追问树**：copy-on-write 前缀共享怎么实现？→ 抢占式调度两种模式（recompute/
  swap）？→ 与 continuous batching 的调度循环怎么交互？→ TTFT/TPOT 分别受什么影响？
- **代码定位**：paged-serving 分配器/调度器；tiny-llm `kernels/attention.cu` 的
  `attention_decode_paged` 与 `src/transformer.cpp` 模式选择，区分默认 legacy 和 opt-in direct。
- **实验证据**：paged-serving 3 并发 e2e 对齐记录；W7 补状态机不变量文档。
- **自评**：__待测（W7）__

## Q4（P0·推理）W8A16 量化的误差与性能权衡？（W5）

- **答案要点**：权重 int8、激活 fp16；本仓是 per-group scale（默认 group size 128）；
  dequant 的位置影响访存和计算，收益必须由公平 W8A16/FP16 A/B 证明，不能从权重大小推断 TPOT。
- **追问树**：为什么不算子融合后量化？→ 与 FP8/W4A16 的对比？→ 如何验证量化后
  正确性（逐 token 差分 vs 端到端 perplexity）？
- **代码定位**：open-infra-ai/tiny-llm 量化加载与 dequant kernel。
- **实验证据**：[Graph A/B](https://github.com/open-infra-ai/tiny-llm/blob/master/docs/performance/results/2026-08-23-cuda-graphs-ab.md)
  使用 W8A16，但比较的是 Graph off/on，不证明量化本身加速；≈6.1ms 的旧单值不作现用证据。
- **自评**：__待测（W5）__

## Q5（P0·Serving）TTFT 和 TPOT 分别由什么决定？怎么压尾延迟？（W8）

- **答案要点**：TTFT ≈ 排队 + prefill 计算；TPOT ≈ decode 每 step 的 kernel +
  调度开销。压 p99：batch 上限、抢占、chunked prefill、CUDA Graph 消除 launch
  开销、隔离 prefill/decode。
- **追问树**：continuous batching 下新请求何时插入？→ 如何测量（压测口径、warmup、
  分布拟合）？→ 容量规划怎么做（并发-吞吐-延迟曲线找拐点）？
- **代码定位**：open-infra-ai/paged-serving 调度循环与 HTTP 层。
- **实验证据**：[9/7 正式矩阵](https://github.com/open-infra-ai/paged-serving/tree/master/benchmarks/serving/results/2026-09-07-RTX3060Laptop-paged-serving-p2-batch-postprocess-streaming)，
  含逐请求原始数据、429 与未收敛记录。本人复述与配对因果实验仍待完成。
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

- **答案要点**：定义 schema、注册实现（CPU/CUDA/meta），autograd 是独立能力；
  坑：schema 与实现签名不一致、fake tensor/meta 注册缺失导致 torch.compile 失败。
- **代码定位**：open-infra-ai/trifuse 的 `torch.ops.trifuse.*` 注册。
- **追问树**：fake 为什么不能读 data pointer？→ 动态 shape 如何表达？→ inference custom op
  的注册为什么不等于已实现 backward？
- **实验证据**：`tests/test_torch_library.py`，CPU/fake 与 CUDA 运行分层；未跑 case 不称通过。
- **自评**：__待测（W4）__

## Q8（P0·Runtime）Direct 和 split-KV 为什么不能凭名字判断更快？（W7/W9）

- **答案要点**：direct 省 gather 但引入间接寻址；split 增加并行度，也增加 partial workspace
  与 combine。9/15 在 RTX 5070 Ti、visible=2048、block=16 的收敛 kernel 结果中，
  split16 相对单遍 direct 约 6.028×，相对 legacy_splitkv16 约 1.269×；两种分母不能混用。
- **追问树**：短窗口为何回退？→ CV 和 repeat spread 为何都要看？→ 为什么默认仍 legacy、
  split 关闭？→ 怎么设计端到端 A/B 推翻 kernel 收益假设？
- **代码定位**：`tiny-llm/kernels/attention.cu`、`src/transformer.cpp`、`scripts/summarize_dpa.py`。
- **实验证据**：[9/15 报告与 raw](https://github.com/open-infra-ai/tiny-llm/blob/master/docs/performance/results/2026-09-15-rtx5070ti-splitkv.md)，
  32 shape 仅 4 个全比较路径收敛；无端到端 TPOT/Serving 改善结论。
- **评分/自评**：B 需说清两种分母、短窗口与默认；A 再独立读 raw 并设计反证。__待本人复测__。

## Q9（P0·测量）Gated MLP 的 TFLOPS 和带宽怎样算才不造假？（W7）

- **答案要点**：当前输出是 intermediate，两次 GEMM，无 down projection；GEMM FLOPs
  `4MNK`，逻辑 bytes `(MK+2KN+MN)×element_size`。同步墙钟循环平均包含 launch，
  不是 CUDA Event 纯 kernel 时间；逻辑带宽不是实测 DRAM 带宽。
- **追问树**：算三次为何错？→ 共享输入能否乘二？→ 正确性失败为何不返回 speedup？
  → 默认峰值参数能否当 RTX 3060 峰值？
- **代码定位**：`trifuse/performance.py`、`benchmark/suite.py`、`tests/test_benchmark_gate.py`。
- **实验证据**：指标与拒绝计时 CPU 测试；无新的 GPU raw 性能包。
- **评分/自评**：B 需正确写公式和统计量；A 需识别一次错误的性能归因。__待本人复测__。

## Q10（P0·CUDA）Workspace 与 stream 的复用何时安全？（W9）

- **答案要点**：所有权、容量、存活期与 stream happens-before 是不同约束；函数级
  static scratch 不自动支持多流，不能靠数值测试通过证明并发安全。
- **追问树**：两 stream 交错 resize 会怎样？→ event/allocator 如何建立顺序？→ Graph
  capture/replay 要保持哪些地址？→ split partial 与 combine 谁持有 workspace？
- **代码定位**：`cuflash/src/forward/flash_decoding.cu`；tiny-llm `LayerWorkspace` 与 split-KV。
- **实验证据**：现有单流数值证据；cuflash 多流/可重入 workspace 仍是剩余任务。
- **评分/自评**：B 需画出正确存活期；A 需设计能揭露竞态的交错测试。__待本人复测__。

## Q11（P0·Serving）断连取消为什么不能只靠 send 失败？（W8）

- **答案要点**：没有新 token 时 send 不发生；consumer/handler 所有权应驱动取消，
  包括 n>1 部分准入、abort、重复取消和 exactly-once 回收。引擎 try_send，满队列局部取消；
  独立 oneshot 让失败终态不被满队列阻挡，成功终态先排空文本。unary 不订阅文本，
  多候选直接拉取合并；算完最后 token 不等于完整交付。
- **追问树**：慢客户端怎样不阻塞全局 worker？→ 满队列丢 token 是否合法？→ 取消与 EOS
  同时到达怎么办？→ 最后一步算完但文本投递溢出，哪个 counter 仍增加？
  → 谁保证 block/metric 回基线？→ 为什么网络 shutdown 仍不能声称固定排空时限？
- **代码定位**：`paged-serving/src/server.rs`；[PR #23](https://github.com/open-infra-ai/paged-serving/pull/23)
  的 RequestGuard/watch，与默认分支对比。
- **实验证据**：PR #23 仍 OPEN；[整改提交](https://github.com/open-infra-ai/paged-serving/commit/59d90c84aa0ea849322c18d3c741f8f9eef34dc9)
  的 CPU 回归覆盖队列满、末步溢出、静默 decode、body drop、abort、部分准入与 backend 回收。
  默认分支尚未合入，未执行真实 CUDA/网络压力；独立取消计数仍待补。
- **评分/自评**：B 需说清无新 token 场景；A 需推演部分准入失败与资源回收。__待本人复测__。

## Q12（P1·工程）为什么 stable CI 绿不能证明 MSRV？（W7）

- **答案要点**：声明只约束包元数据，锁定依赖可能要求更高版本；必须用最低工具链检查
  全部默认目标，并冻结依赖解析。本仓锁定 ICU 2.3 要求 1.88，criterion 0.8.2 要求 1.86。
- **追问树**：cargo check 和 test 各验证什么？→ --locked 失败说明什么？→ default targets
  通过能否说明 CUDA FFI feature 或其他平台通过？
- **代码定位**：paged-serving `Cargo.toml`、`Cargo.lock`、`.github/workflows/ci.yml` 的 msrv job。
- **实验证据**：1.88.0 的 locked/all-targets 检查与默认测试；不替代实际 CUDA 链接。
- **评分/自评**：B 需区分编译器和依赖；A 需现场定位不一致与提出最小修复。__待本人复测__。

## Q13（P0·实验）吞吐持平、尾延迟变高的并发结果该怎样解释？（W8/W9）

- **答案要点**：多请求准入不代表 GPU 计算融合；closed-loop 会反馈减速，Poisson 到达
  暴露排队/过载。429、失败和 token coverage 都要保留，未收敛不写稳定容量。
- **追问树**：coordinated omission？→ 先测哪段时间线？→ 怎样区分 CPU、GPU 和排队瓶颈？
  → 未配对的两包数据为什么不能算优化 speedup？
- **代码定位**：paged-serving `src/bin/loadgen.rs`、Serving methodology 与 9/7 原始请求。
- **实验证据**：正式 21-run 报告，不把 c1→c8 的观察外推为所有模型的结论。
- **评分/自评**：B 需区分观察与因果；A 需设计一个单变量配对实验。__待本人复测__。

## Q14（P0·C++）30 分钟写一个容量守恒的 block allocator（每周）

- **答案要点**：先写接口与不变量，再实现 allocate/free；覆盖耗尽、重复释放、非法 ID，
  失败时资源状态不变；解释复杂度、所有权和异常保证。
- **追问树**：如何加入并发？→ lock 顺序？→ shared block 的引用计数如何扩展？→ RAII cleanup？
- **代码定位**：以 paged-serving 的 BlockPool 为对照，但限时实现不得复制现有代码。
- **实验证据**：本人限时源码、测试和错点记录；没有记录则未测，不由 Agent 完成代替。
- **评分/自评**：B 需功能与守恒测试通过；A 需说明竞态边界和失败原子性。__待本人复测__。

## Q15（P0·所有权）哪一个决定是你自己做的，而不是 Agent 替你完成的？（W7/W11）

- **答案要点**：选一个真实提交，区分本人提出问题、批准设计、写实现、审查、运行实验和
  Agent 参与；说明被拒绝的方案与真实反例，不把代理产出冒充独立完成。
- **追问树**：没有工具你能改哪段？→ 实验如何推翻你？→ 一处 bug 能否当场定位？
- **代码定位**：由本人选择 exact commit/symbol，不能由模板预填责任。
- **实验证据**：对应 diff、测试、raw 与本人闭卷复述；仓库链接只是必要条件。
- **评分/自评**：B 需责任边界具体；A 需在追加追问下独立推导或调试。__待本人复测__。

---

## 追加规则

- 每周文件中的"面试问题"默认三要素（要点/追问/代码定位），达到 A 级才在 progress-tracker 打卡。
- 模拟面试（W11）全部从本矩阵抽题，评分记录追加到各题"自评"处。
