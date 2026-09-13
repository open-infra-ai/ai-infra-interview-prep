# AI Infra 实验、学习与职业转型实战手册

> 本手册回答“每天具体做什么、怎样做实验、怎样判断学会、何时可以投递”。  
> 宏观时间表仍以 [ROADMAP.md](ROADMAP.md) 和 `weekly/week-01.md` 至
> `weekly/week-12.md` 为准；本手册是执行方法，不创建第二套冲突计划。

## 1. 你的最佳转型路线

### 1.1 主攻方向

优先级保持为：

1. **LLM Inference Performance / GPU Kernel Engineer**
2. **LLM Inference Runtime / Serving Engineer**
3. **ML Compiler Engineer（可选）**

前三个月不把“分布式训练平台”作为主线。单卡 RTX 3060 Laptop 6GB 足以完成
CUDA、Triton、Runtime、KV Cache 和单机 Serving 的主要学习；多 GPU 内容在没有真实
设备时只能写为理论学习或模拟。

### 1.2 作品集主线

不要在面试中讲七个平级项目，只讲两条故事：

```text
CUDA / Triton:
cuda-foundations → trifuse → cuflash

Runtime / Serving:
tiny-llm → paged-serving
```

`kvtier` 作为 KV offload 研究和上游贡献辅助项目。组织总仓只负责导航和证据索引。

### 1.3 求职定位

第一阶段目标不是证明自己已经能负责生产级集群，而是证明：

- 能读懂并修改 CUDA / Triton kernel；
- 能建立独立 correctness reference；
- 能用 profiler 定位瓶颈；
- 能解释 LLM prefill、decode、KV Cache、quantization 和 batching；
- 能建立可复现 benchmark；
- 能实现并验证调度、背压、取消和资源回收；
- 能诚实区分已实现、未实现、实测和理论。

## 2. 使用方法

### 2.1 每日闭环

每次学习只做一个可验证闭环：

1. 用自己的话写出今天要回答的问题；
2. 阅读最少必要资料；
3. 在纸上或白板推导；
4. 运行或修改一个最小实验；
5. 保存命令和原始输出；
6. 写出结果支持什么、不支持什么；
7. 不看资料口述五分钟；
8. 更新当周 checkbox。

一天结束时必须留下至少一种证据：

- 代码提交；
- correctness 日志；
- raw JSON/JSONL；
- profiler 报告；
- 图表；
- 面试问答；
- 失败实验和原因。

只看视频、论文或代码但没有输出，不计为完成。

### 2.2 每周节奏

按 24 小时基准分配：

| 活动 | 时间 |
|------|-----:|
| 原理和白板推导 | 4h |
| 阅读核心源码 | 4h |
| 实现或修复 | 7h |
| correctness / benchmark / profiling | 5h |
| 面试表达和复盘 | 3h |
| 求职或社区行动 | 1h |

18 小时或 12 小时时，减少扩展阅读和次要实验，不减少：

- correctness；
- 原始证据；
- 复盘；
- 面试口述。

### 2.3 阶段门禁

不要因为日历进入下一周就跳过基础。只有满足退出条件才进入下一阶段：

```text
会解释 → 会运行 → 会修改 → 会验证 → 会归因 → 会在面试中防守
```

如果某周未完成，保留真实状态并顺延，不把 checkbox 假装勾完。

## 3. 第一次实验前的环境检查

### 3.1 记录环境

每个正式结果包至少记录：

```bash
date -u
git rev-parse HEAD
git status --short
nvidia-smi
nvidia-smi --query-gpu=name,driver_version,memory.total,pstate,temperature.gpu,power.draw,clocks.sm,clocks.mem --format=csv
nvcc --version
cmake --version
python3 --version
```

涉及 Python 时额外记录：

```bash
python3 - <<'PY'
import platform
import torch

print("platform:", platform.platform())
print("torch:", torch.__version__)
print("torch_cuda:", torch.version.cuda)
print("cuda_available:", torch.cuda.is_available())
if torch.cuda.is_available():
    print("gpu:", torch.cuda.get_device_name(0))
PY
```

涉及 Rust 时记录：

```bash
rustc --version
cargo --version
```

### 3.2 建立结果目录

正式实验不要把唯一结果留在系统临时目录。推荐：

```text
results/
└── YYYY-MM-DD-<gpu>-<experiment>/
    ├── README.md
    ├── metadata.json
    ├── commands.sh
    ├── raw/
    ├── summary/
    ├── plots/
    └── profiles/
```

其中：

- `metadata.json`：commit、dirty、GPU、driver、CUDA、模型 SHA-256、配置；
- `commands.sh`：可直接重跑的命令；
- `raw/`：逐 iteration 或逐请求数据；
- `summary/`：聚合统计；
- `plots/`：只由 raw data 生成；
- `profiles/`：`.nsys-rep`、`.ncu-rep` 和导出的 CSV；
- `README.md`：结论、限制、失败实验。

### 3.3 正式运行前检查表

- [ ] `git status --short` 已保存；
- [ ] 被测 commit 已保存；
- [ ] 模型 SHA-256 已保存；
- [ ] 测试命令已先通过；
- [ ] GPU 空闲情况已确认；
- [ ] 温度和功耗状态已记录；
- [ ] 输入、dtype、layout、shape 已固定；
- [ ] baseline 和 variant 唯一区别已说明；
- [ ] warmup、iterations、进程数和随机种子已固定；
- [ ] 失败时也保存原始结果。

## 4. 正确性实验标准流程

性能优化前必须先证明输出正确。

### 4.1 写出算子契约

至少说明：

- 输入 shape；
- dtype；
- contiguous / stride / layout；
- device；
- 支持的 head dimension；
- causal 或非 causal；
- 输出 shape 和 dtype；
- 容差；
- 非法输入如何失败；
- stream 和 workspace 合约；
- 空输入、tail 和对齐边界。

### 4.2 建立独立 reference

优先级：

1. NumPy 双精度参考；
2. PyTorch eager；
3. PyTorch SDPA / cuBLAS；
4. 已知成熟实现；
5. CPU 标量实现。

reference 不能复用被测 kernel 的核心计算代码，否则不是独立验证。

### 4.3 设计测试矩阵

不要只测“好看”的 shape。每个 kernel 至少覆盖：

| 维度 | 建议值 |
|------|--------|
| batch | 1、2、4、8 |
| sequence | 1、7、16、31、32、33、127、128、129、512、2048 |
| head dim | 32、64、128 和一个不支持值 |
| dtype | FP32、FP16、BF16（按实际支持） |
| causal | true / false |
| layout | contiguous 和明确支持的非连续输入 |
| 数值 | 0、小值、大值、正负混合、随机、重复值 |

`32/33`、`127/128/129` 用于暴露 tile、warp 和 tail 边界。

### 4.4 比较标准

记录：

- `max_abs_error`；
- `max_rel_error`；
- `mean_abs_error`；
- mismatch 数量；
- 最差元素索引；
- reference 值和实际值。

FP16/BF16 容差必须来自误差分析或成熟 reference，不要为了通过测试不断扩大容差。

### 4.5 差分和属性测试

算子级：

- 自实现 vs reference；
- causal vs 显式 mask；
- 分页 KV vs 连续 KV；
- Graph on vs Graph off；
- CUDA vs Triton。

系统级不变量：

- `used_blocks + free_blocks == total_blocks`；
- 完成、取消、失败后资源回到基线；
- 同一 greedy 输入生成 token 序列一致；
- retry 不产生重复 token 或资源泄漏；
- 流式 chunk 拼接等于非流式完整文本。

### 4.6 Compute Sanitizer

先构建 debug 或带行号版本，再执行：

```bash
compute-sanitizer --tool memcheck <test-command>
compute-sanitizer --tool racecheck <test-command>
compute-sanitizer --tool initcheck <test-command>
compute-sanitizer --tool synccheck <test-command>
```

四个工具分别重点检查：

- `memcheck`：越界、非法访问、泄漏；
- `racecheck`：共享内存数据竞争；
- `initcheck`：未初始化 device memory；
- `synccheck`：错误同步和 warp/barrier 使用。

不要把某个工具“不适用”写成通过；记录跳过原因。

## 5. 性能 benchmark 标准流程

### 5.1 先写假设卡

模板：

```markdown
## 假设

- 问题：
- baseline：
- variant：
- 只改变的变量：
- 预计改善的指标：
- 预计改善原因：
- 可能回退的 shape：
- 推翻假设的结果：
- correctness oracle：
```

没有可证伪假设时，不开始写优化代码。

### 5.2 Kernel 计时

CUDA kernel 用 CUDA Event：

```cpp
cudaEventRecord(start, stream);
for (int i = 0; i < iterations; ++i) {
    kernel<<<grid, block, shared_bytes, stream>>>(...);
}
cudaEventRecord(stop, stream);
cudaEventSynchronize(stop);
cudaEventElapsedTime(&milliseconds, start, stop);
```

要求：

- 计时前 warmup；
- event 和 kernel 在同一 stream；
- 检查 launch error；
- 避免把 allocation、H2D/D2H 和 Python import 混入 kernel 时间；
- 报告的是平均、median 还是单次；
- 极短 kernel 通过多次循环降低 timer overhead。

端到端请求使用单调墙钟；不要用 CUDA Event 代替网络和队列延迟。

### 5.3 Warmup、重复和 A/B 顺序

默认起点：

- kernel：20 次 warmup，100–200 次正式运行；
- Runtime：3 次 warmup，至少 10 次正式运行；
- Serving：每个配置至少 3 个独立进程或独立 server run；
- A/B 顺序：`A-B-B-A` 或按固定种子随机交错。

正式结论至少报告：

- p50；
- p95；
- min/max 或 IQR；
- 独立进程间 CV；
- 样本数；
- 错误数、429 和 OOM。

如果关键指标重复间波动超过 10%，先判断为“未收敛”，不要写精确提升。

### 5.4 控制噪声

- 关闭无关 GPU 进程；
- 固定 workload；
- 记录功耗、温度和 clocks；
- 笔记本保持相同电源与散热条件；
- 不在 baseline 和 variant 之间更换依赖或模型；
- 每个正式进程重新启动，避免只测热缓存；
- 记录是否包含 compilation、Graph capture、allocator warmup。

不建议为了得到好看的数字绕过温度或功耗保护；真实记录硬件边界。

### 5.5 判断结果是否值得写

结果可以进入正式报告，需要同时满足：

- correctness 不下降；
- 实验条件完整；
- raw data 存在；
- 多次重复方向一致；
- 提升超过噪声；
- 主要 shape 没有未解释的大幅回退；
- 限制已写明。

一次运行、截图、单个平均值或无法定位 commit 的数字只能作为 canary，不能写入简历。

## 6. Nsight Systems：先定位端到端瓶颈

官方文档：
[Nsight Systems User Guide](https://docs.nvidia.com/nsight-systems/UserGuide/index.html)。

### 6.1 目标

回答：

- CPU 在等待什么；
- kernel 是否被频繁小粒度启动；
- H2D/D2H 是否阻塞；
- stream 是否有并行；
- Graph 是否减少 launch gap；
- prefill、decode、sampling、SSE 分别耗时多少。

### 6.2 添加 NVTX

为长期保留的阶段添加稳定名称：

```text
request
prefill
decode_step
attention
mlp
kv_gather
sampling
http_stream
```

NVTX range 用于描述长期语义，不写“本次修复”等只对 diff 有意义的名字。

### 6.3 采集

示例：

```bash
nsys profile \
  --trace=cuda,nvtx,osrt \
  --sample=none \
  --force-overwrite=true \
  --output=results/<run>/profiles/timeline \
  <benchmark-command>
```

只采稳定区间，不把模型下载、首次编译等混入正式窗口。

### 6.4 阅读顺序

1. 查看 CUDA API 与 kernel 之间是否有空洞；
2. 检查 memcpy 与 kernel 是否串行；
3. 查看 kernel 数量和 launch 粒度；
4. 对比 Graph on/off；
5. 用 NVTX 汇总 prefill 与每个 decode step；
6. 记录最值得用 ncu 深挖的 1–3 个 kernel。

### 6.5 输出

至少保存：

- `.nsys-rep`；
- 一张完整 timeline 截图；
- kernel summary；
- NVTX summary；
- 三条基于时间线的事实；
- 一个下一步可验证假设。

## 7. Nsight Compute：解释单个 kernel 为什么慢

官方文档：
[Nsight Compute Profiling Guide](https://docs.nvidia.com/nsight-compute/ProfilingGuide/index.html)。

### 7.1 不要一开始就 `--set full`

先用低开销集合和 kernel filter：

```bash
ncu \
  --set basic \
  --kernel-name 'regex:<kernel-name>' \
  --launch-skip <N> \
  --launch-count 1 \
  --export results/<run>/profiles/kernel \
  <benchmark-command>
```

确认采到了目标 kernel 后，再按问题选择 sections。`--set full` 会多次 replay，
可能显著改变工作负载。

### 7.2 每次只回答一个问题

| 问题 | 观察方向 |
|------|----------|
| 是否内存受限 | DRAM/L2 throughput、bytes、arithmetic intensity |
| occupancy 为什么低 | registers/thread、shared memory、active warps |
| Tensor Core 是否使用 | tensor pipe utilization、SASS 指令 |
| warp 在等待什么 | Warp State / stall reasons |
| 访存是否合并 | global load/store efficiency、sectors/request |
| causal 优化是否有效 | executed instructions、divergence、skipped tiles |

### 7.3 报告格式

```markdown
## Kernel
- 名称：
- shape/dtype：
- baseline commit：
- variant commit：

## 观察
- duration：
- registers/thread：
- achieved occupancy：
- DRAM/L2 throughput：
- dominant stall：
- SM/Tensor utilization：

## 推断
- 证据直接显示：
- 我的解释：
- 尚未确认：

## 下一实验
- 只改变：
- 预期：
```

严格区分 profiler 直接显示的事实和你的理论。

## 8. 指标口径

### 8.1 Runtime

- **TTFT**：请求开始到第一个输出 token/首个非空文本片段；
- **TPOT**：首 token 后，每生成一个 token 的平均耗时；
- **ITL**：相邻输出 token 的间隔；若 SSE chunk 含多个 token，不得直接叫 token 级 ITL；
- **decode tok/s**：通常为 \(1000 / TPOT_{ms}\)；
- **常驻显存差值**：加载前后 `cudaMemGetInfo` 差值，不是峰值显存；
- **峰值显存**：必须用能覆盖整个运行区间的采样或 allocator 指标。

### 8.2 Serving

- 请求吞吐：completed requests / second；
- token 吞吐：成功生成 token / second；
- TTFT p50/p95/p99；
- TPOT 或 inter-chunk latency；
- end-to-end latency；
- queue wait；
- 成功率；
- HTTP 429；
- timeout / OOM / backend failure；
- active sequences；
- batch size；
- KV utilization。

分位数必须来自逐请求数据，不能对已聚合的 p95 再计算 p95。

## 9. Serving 压测

### 9.1 Closed-loop

固定并发，每个客户端完成后立即发送下一个请求。用于观察：

- 饱和吞吐；
- 并发提高后的延迟；
- 调度与 batching 是否扩展；
- 资源利用率。

建议并发矩阵：

```text
1, 2, 4, 8
```

RTX 3060 Laptop 6GB 超出显存时停止并记录，不把 OOM 配置删除。

### 9.2 Open-loop Poisson

按泊松到达率产生请求，用于模拟独立用户到达并观察排队和过载：

```text
0.25×、0.5×、0.8×、1.0×、1.2× 已测饱和容量
```

每档固定随机种子，报告：

- offered load；
- achieved throughput；
- queue wait；
- TTFT/latency p95/p99；
- 429；
- 失败分类。

### 9.3 `paged-serving` 当前入口

构建和生成数据集：

```bash
cargo build --locked --release --bin loadgen
TINY_LLM_DIR=../tiny-llm/build \
  cargo build --locked --release --features tiny-llm

python3 benchmarks/serving/datasets/synth/gen_synth.py \
  --outdir benchmarks/serving/datasets/synth
```

启动真实后端时必须显式选择：

```bash
PAGED_SERVING_TINY_LLM_MAX_SEQS=8 \
./target/release/paged-serving --serve \
  --backend tiny-llm \
  --model-path <model.gguf> \
  --tokenizer <tokenizer.json> \
  --port 3000
```

先做 canary，再做矩阵。完整入口、结果校验和报告模板以
`paged-serving/benchmarks/serving/README.md` 为准。

### 9.4 公平 baseline

对比 `paged-serving`、llama-server 和 vLLM 时固定：

- GPU；
- 模型家族；
- prompt 数据集；
- output length；
- sampling；
- context length；
- loadgen；
- 并发/到达率。

W8A16、Q4_K_M 和 FP16 不是同量化，必须在表头醒目标注，不能把差异全部归因于引擎。

## 10. 项目实验阶梯

以下实验按顺序执行。已有结果可以先复现，再设计新变体。

### 实验 0：环境和计时 canary

目标：证明工具链、GPU 和结果记录方法可用。

步骤：

1. 记录环境；
2. 运行一个 vector add 或已有最小 GPU 测试；
3. 用 CUDA Event 计时；
4. 用 nsys 看到 kernel；
5. 用 ncu 采一个 basic report；
6. 用 Compute Sanitizer 跑最小测试；
7. 保存所有 artifact。

退出条件：

- [ ] 能解释 wall clock 与 CUDA Event 差异；
- [ ] 能打开 `.nsys-rep` 和 `.ncu-rep`；
- [ ] 能指出一个 profiler metric 的物理含义。

### 实验 1：`cuda-foundations` SGEMM 优化阶梯

构建：

```bash
cmake --preset default
cmake --build --preset default
ctest --preset default
```

独立模块：

```bash
cd 01-sgemm-tutorial
make GPU_ARCH=sm_86 benchmark
make test
```

实践：

1. 先画出 naive、tiled、bank-conflict-free、double-buffered、WMMA 数据流；
2. 对每版做 cuBLAS 差分；
3. 加入非 tile 整数倍 shape；
4. 比较不同 M/N/K；
5. 用 ncu 判断每次优化改变了 bandwidth、occupancy 还是 tensor pipe；
6. 保留一个没有变快的版本并解释原因。

退出条件：

- [ ] 能白板推导 global/shared memory traffic；
- [ ] 能解释 bank conflict；
- [ ] 能解释 WMMA tile、warp 和 accumulation；
- [ ] 所有数字绑定 raw data 和 profiler。

### 实验 2：`trifuse` CUDA/Triton 对照

验证：

```bash
ruff format --check .
ruff check .
mypy trifuse --ignore-missing-imports
pytest -q
python -m build
```

GPU benchmark：

```bash
python -m tests.benchmarks.bench_gated_mlp
python -m tests.benchmarks.bench_rmsnorm_rope
```

实践：

1. 选择 RMSNorm+RoPE 或 online-softmax；
2. 写出 NumPy/PyTorch reference；
3. 覆盖动态 shape 和 tail；
4. 分析 Triton program id、block size、num_warps；
5. 与 PyTorch eager/SDPA 公平比较；
6. 用 ncu 对比 CUDA 和 Triton 生成 kernel 的资源使用。

退出条件：

- [ ] 能解释 Triton 自动分块与手写 CUDA 的取舍；
- [ ] 能解释 `torch.library.custom_op` 和 `register_fake`；
- [ ] 能指出 fusion 何时因额外 GEMM 或中间写回而失效。

### 实验 3：`cuflash` Attention 深挖

构建和测试：

```bash
cmake --preset release
cmake --build --preset release
ctest --preset release --output-on-failure
```

benchmark：

```bash
./build/release/cuflash_bench \
  --benchmark_filter='Forward_FP16|Forward_Causal|Decode_FP16' \
  --benchmark_time_unit=ms \
  --benchmark_min_time=0.2s \
  --benchmark_out=results.json
```

实践：

1. 手推 online softmax 更新公式；
2. 与 PyTorch SDPA 做差分；
3. 分析 causal tile skip；
4. 分析 prefill 与 decode 的并行度差异；
5. 比较 scalar、WMMA、Split-KV；
6. 用 nsys 选 kernel，再用 ncu 分析；
7. 检查 workspace、stream 和 Graph capture 合约。

退出条件：

- [ ] 能推导 online softmax；
- [ ] 能解释为什么不物化 \(N^2\) attention matrix；
- [ ] 能解释该实现与 FA2/FA3 的差距；
- [ ] 能讲一个负结果和一个 profiler 驱动优化。

### 实验 4：`tiny-llm` 端到端正确性

构建：

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTS=ON
cmake --build build -j"$(nproc)"
ctest --test-dir build --output-on-failure --timeout 300
```

实践：

1. 固定 GGUF 和 SHA-256；
2. 检查模型 config 和 tensor 元数据；
3. 验证 tokenizer 逐 id；
4. 验证反量化；
5. 验证连续 KV 与分页 KV 的 greedy token；
6. 验证 Graph on/off token；
7. 检查取消/失败后资源释放；
8. 保存固定 prompt oracle。

退出条件：

- [ ] 能从 GGUF 讲到一个输出 token；
- [ ] 能解释 W8A16 的 scale、group 和误差；
- [ ] 能解释 GQA/MQA head 映射；
- [ ] 能区分常驻显存差值和峰值。

### 实验 5：`tiny-llm` CUDA Graph A/B

示例：

```bash
./build/tiny_llm_bench <model.gguf> \
  --prompt "Explain KV cache briefly." \
  --max-tokens 128 \
  --warmup 3 \
  --iters 10 \
  --json
```

分别运行 Graph on/off，使用多个独立进程和交错顺序。

需要回答：

- Graph capture 包含哪些 kernel；
- 为什么主要影响 decode；
- 为什么 TTFT 可能不改善；
- 哪些动态 shape 或 allocator 会破坏 capture；
- launch overhead 在 RTX 3060 上占多少。

退出条件：

- [ ] raw JSONL 可重算 p50/p95；
- [ ] Graph on/off token 一致；
- [ ] 能用 nsys timeline 解释差异。

### 实验 6：Paged KV gather 路径

实践：

1. 画出 BlockPool、PageTable、block table upload 和物理页布局；
2. 统计 gather/scatter bytes；
3. 用 nsys 标出 gather 与 attention；
4. 比较连续 KV 和分页 KV 的 token correctness；
5. 按 context 128/512/2048 测 TPOT；
6. 记录 workspace 和显存；
7. 解释控制面分页为什么不等于 direct PagedAttention。

退出条件：

- [ ] 能指出当前性能损失发生在哪里；
- [ ] 能写出 direct paged attention 的索引公式；
- [ ] 能提出可测试的改造方案。

### 实验 7：direct paged attention 深改造

这是优先级最高的后续旗舰任务之一。

步骤：

1. 保留现有 gather 路径作为 reference；
2. 定义 kernel 输入：Q、page pool、block table、sequence length；
3. 先实现 batch=1、固定 head dim；
4. 测 block boundary 和 tail；
5. 扩展 GQA/MQA；
6. 扩展 batch；
7. 跑 token oracle 和 Sanitizer；
8. 做 context length A/B；
9. 用 ncu 验证 memory traffic 假设；
10. 报告更快、持平和更慢的 shape。

退出条件：

- [ ] 固定 prompt 0 非预期 token mismatch；
- [ ] block 复用、取消和 tail 有测试；
- [ ] 代表性 workload 的改善超过噪声；
- [ ] 没有把 microbenchmark 外推为 Serving 提升。

### 实验 8：`paged-serving` 负载矩阵

步骤：

1. CPU reference 后端先验证协议和调度；
2. tiny-llm 后端做 3–4 请求 canary；
3. closed-loop c=1/2/4/8；
4. 找到近似饱和吞吐；
5. Poisson 0.25×–1.2×；
6. 保存逐请求 TTFT、TPOT/inter-chunk、latency、status；
7. 记录 active sequences、KV utilization、429；
8. 与 llama-server 比较；
9. 显存允许时再加入 vLLM；
10. 对未收敛指标增加重复，而不是挑选最好 run。

退出条件：

- [ ] 能解释 throughput plateau；
- [ ] 能解释 closed-loop 和 Poisson 的区别；
- [ ] 能解释 continuous batching 控制面与 fused compute batch 的区别；
- [ ] 能指出当前容量和 SLO 结论的外推边界。

### 实验 9：故障注入与可观测性

故障：

- 客户端断开；
- 请求取消；
- 超长 prompt；
- 高水位线；
- backend error；
- 模型路径错误；
- server graceful shutdown；
- 若有双副本，终止一个 replica。

检查：

- 错误分类是否明确；
- KV block 是否全部回收；
- 流式请求是否产生错误结束；
- metrics 与日志能否关联 request id；
- 失败请求是否污染后续请求；
- 429 是否有清晰的过载含义。

退出条件：

- [ ] 每类故障有自动测试或可复现脚本；
- [ ] 资源泄漏为 0；
- [ ] dashboard/日志能回答“为什么慢、为什么失败”。

### 实验 10：多 GPU（仅在真实设备可用时）

最低项目二选一：

1. `nccl-tests`：correctness、algorithm bandwidth、bus bandwidth、消息规模和 topology；
2. 双 GPU Tensor Parallel 或双副本 Serving。

没有真实设备时只能完成：

- collective 公式；
- TP/PP/DP 通信量推导；
- 模拟 scheduler；
- 设计文档；
- 测试计划。

禁止把模拟写成实测。

真实实验至少保存：

```bash
nvidia-smi topo -m
nvidia-smi
```

以及 NCCL 版本、命令、消息规模、warmup、iterations、错误和原始输出。

## 11. 云 GPU 使用

详细预算和机型选择见 [CLOUD_GPU_PLAYBOOK.md](CLOUD_GPU_PLAYBOOK.md)。原则：

1. 本地完成代码、CPU 测试和 GPU smoke；
2. 云 GPU 开机前写好命令清单；
3. 首选一张与目标问题匹配的 GPU，不为“更高级”盲目租 H100；
4. correctness 通过后才跑性能；
5. 先 canary，再完整矩阵；
6. 上传 raw artifact 后立即关机；
7. 检查实例、磁盘和公网资源是否仍计费。

建议用途：

| GPU | 适合任务 |
|-----|----------|
| RTX 4090 | Ada 消费级对照、Triton/CUDA kernel |
| L40S 48GB | 默认单卡 Runtime/Serving、大模型或长上下文 |
| A100 | 数据中心 Ampere、HBM 和 Tensor Core 对照 |
| H100 | Hopper 专属特性，只有明确要测 TMA/WGMMA/FP8 时使用 |

## 12. 面试准备

### 12.1 每个项目准备三种版本

- 30 秒：项目、问题、结果、边界；
- 2 分钟：架构、关键实现、正确性、性能；
- 10 分钟：白板推导、源码定位、profiler、失败实验和后续设计。

### 12.2 每个项目必须回答

1. 为什么做这个项目？
2. 你本人实现了什么？
3. 最难的 correctness bug 是什么？
4. 最难的 performance bug 是什么？
5. baseline 是否公平？
6. profiler 给了什么证据？
7. 哪个优化没有成功？
8. 结果能外推到什么范围？
9. 为什么它不是生产级？
10. 如果再做两周，优先改什么？

### 12.3 白板题

必须能独立推导：

- tiled GEMM；
- arithmetic intensity；
- online softmax；
- FlashAttention IO 复杂度；
- GQA/MQA；
- KV Cache 内存；
- paged KV 地址映射；
- TTFT / TPOT / ITL；
- continuous batching；
- Tensor Parallel 通信量；
- Roofline；
- p50/p95/p99。

### 12.4 面试复盘

每次模拟面试记录：

```markdown
- 问题：
- 第一版回答：
- 追问：
- 卡住位置：
- 正确答案：
- 对应源码：
- 对应实验：
- 下次 30 秒答案：
```

如果回答没有指向源码或实验，继续补证据。

## 13. 简历

每条 bullet 使用：

```text
动作 + 技术难点 + 验证方法 + 条件受限的结果
```

模板：

```text
实现 [组件/算法]，通过 [reference/属性测试/Sanitizer] 验证 [正确性边界]；
在 [GPU/模型/shape/负载/commit] 上相对 [baseline] 将 [指标] 改善 [数字]，
原始结果与 profiler artifact 可复现。
```

没有可靠数字时：

```text
实现 [组件] 并建立 [测试/benchmark/profiler] 证据链，定位 [瓶颈]；
当前完成 [已实现范围]，尚未覆盖 [生产/分布式边界]。
```

禁止：

- 把 skip 写成 passed；
- 把 CPU 测试写成 GPU correctness；
- 把 microbenchmark 写成端到端加速；
- 把常驻显存差值写成峰值；
- 把 W8A16 与 Q4_K_M 写成同量化公平对比；
- 把 3 并发 fixture 写成生产容量；
- 把单卡模拟写成分布式实测；
- 使用无法定位 raw data 的数字。

## 14. 求职执行

### 14.1 何时开始投递

不必等所有项目完美。满足以下最低条件即可小规模投递：

- 一个 Runtime/Serving 旗舰能讲 10 分钟；
- 一个 Kernel 旗舰能白板推导；
- 至少一个完整 correctness → profiler → optimization → result 闭环；
- GitHub 首页能在 90 秒内找到代码、测试、结果和限制；
- 完成三次有评分的模拟面试；
- 简历无夸大数字。

### 14.2 投递节奏

1. 先投匹配度 60%–75% 的岗位校准市场；
2. 每周复盘面试反馈；
3. 将高频缺口回填到 `SKILL_MATRIX.md`；
4. 每两周调整岗位关键词和项目顺序；
5. 主方向岗位使用 Kernel/Runtime 版本简历；
6. Serving 岗突出调度、资源不变量、压测和可观测性；
7. 不因单次拒绝立即更换主线。

岗位、联系人、薪资和投递状态只能保存在 `.local` 文件中。

## 15. 每周复盘

周日运行：

```bash
make progress
make check
make verify
```

回答：

1. 本周真正形成了什么证据？
2. 哪个 checkbox 只是“看过”，还不能“做出”？
3. 哪个结果未收敛？
4. 哪个结论被实验推翻？
5. 哪个面试问题仍无法脱稿回答？
6. 下周唯一最重要的技术闭环是什么？
7. 是否应该删掉低价值任务？

不要用“学习了很多”总结；写 commit、测试、raw data、profile 或可回答的问题。

## 16. 转型完成标准

达到以下标准后，可以把自己定位为具备真实项目证据的初级到初中级 AI Infra 候选人：

- [ ] 能从 kernel 解释到 token，再解释到 HTTP 请求；
- [ ] 能手写并验证一个 CUDA/Triton 核心算子；
- [ ] 能使用 nsys 和 ncu 做一次完整瓶颈归因；
- [ ] 能设计正确的 warmup、重复、A/B 和统计协议；
- [ ] 能解释 TTFT、TPOT、ITL、throughput 和 tail latency；
- [ ] 能解释 KV Cache、Paged KV 和 continuous batching；
- [ ] 能展示一个负结果并说明为什么保留；
- [ ] 能讲清项目未达到生产级的原因；
- [ ] 能在 10 分钟内完成一个旗舰项目 defense；
- [ ] 能通过 CUDA/C++、Runtime 和系统设计三类模拟面试；
- [ ] 所有简历数字都可追溯；
- [ ] 已开始持续投递和复盘。

## 17. 官方资料

- [CUDA C++ Programming Guide](https://docs.nvidia.com/cuda/cuda-c-programming-guide/)
- [Nsight Systems User Guide](https://docs.nvidia.com/nsight-systems/UserGuide/index.html)
- [Nsight Compute Profiling Guide](https://docs.nvidia.com/nsight-compute/ProfilingGuide/index.html)
- [Compute Sanitizer](https://docs.nvidia.com/compute-sanitizer/ComputeSanitizer/index.html)
- [PyTorch Benchmark Utils](https://docs.pytorch.org/docs/stable/benchmark_utils.html)
- [PyTorch Timer Quick Start](https://docs.pytorch.org/tutorials/recipes/recipes/timer_quick_start.html)
- [vLLM Benchmark CLI](https://docs.vllm.ai/en/stable/benchmarking/cli/)
- [vLLM Serve Benchmark](https://docs.vllm.ai/en/stable/cli/bench/serve/)
- [NVIDIA NCCL Tests](https://github.com/NVIDIA/nccl-tests/)

先使用仓库内已验证的命令和固定版本，再根据官方资料扩展。博客可以帮助理解，但不作为
接口、指标或性能结论的唯一依据。
