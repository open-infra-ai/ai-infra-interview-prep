# TLLM-P0-002 paged/contiguous synthetic oracle（2026-09-14）

## 交接压缩格式

```yaml
task_id: TLLM-P0-002
status: complete
repository: open-infra-ai/tiny-llm
base_branch: master
base_commit: 2b15fb2b6e16671a91c648a5e1b3cf0666099b3f   # = backlog 审查参考 commit
current_branch: tllm-p0-002-paged-oracle
current_commit: bff2af6
dirty: false
complexity: L3
dependencies: none
changed_files:
  - tests/paged_attention_oracle.h        # 新增：纯 host 独立参考 + 冻结 contract
  - tests/test_paged_oracle.cpp           # 新增：kernel 级 / layer 级 / contract 测试
  - src/transformer.cpp                   # +12 行：forwardPaged 块表长度校验
  - src/kv_cache.cpp                      # +9 行：create() 清零 append_pos_
  - CHANGELOG.md
decisions:
  - 只做设计包 §4.5 的第 1 步 Oracle PR（reference / layout tests / invalid tests）；
    不写 direct kernel，不改 FFI/C ABI。
  - test seam 使用既有 kernels/*.cuh（测试目标已 include kernels/），不新增 public API。
  - layer 级强门禁改为「按冻结公式读回 pool，与连续 KV cache 逐层位级比较 K/V」：
    先前的最终 hidden 比对受 fp16 输出量化 + 残差主导影响，对真实 bug 不敏感
    （实测会把注入的 scatter/layer 步长 bug 判为通过），已废弃该做法。
  - 块表长度 contract 下移到 forwardPaged 入口：这是「invalid table length」验收项在
    无 GPU/无 GGUF 条件下唯一可安全测试的方式（否则只能测未定义行为）。
  - append_pos_ 清零属根因修复，而非修改既有测试来掩盖。
verified:
  - ./build/tiny_llm_tests：195 passed / 11 skipped / 0 failed
  - ./build/tiny_llm_tests --gtest_filter='PagedOracle*'：8 passed
  - compute-sanitizer --tool memcheck --gtest_filter='PagedOracle*'：0 errors
  - clang-format 18.1.8（CI 同版本）--dry-run --Werror 全仓：0 violation
  - CI Format job：pass
  - 变异检验：scatter 忽略 position 被 kernel 级增量测试捕获；
    attentionPaged 层步长丢 max_num_blocks 被 layer 级逐层 K/V 门禁捕获（报 layer 1）
failed: []
not_run:
  - 11 项需要真实 GGUF 模型的既有测试（本机未提供 TLLM_GGUF_TEST_MODEL）；
    未运行项不作通过声明
  - 任何 benchmark / profiler / serving 实验：本任务不产生性能证据
artifacts:
  - PR open-infra-ai/tiny-llm#4
open_questions:
  - forwardPaged 与 ffi.cpp 各自算一遍 required_blocks，重复口径；TLLM-P0-004 的
    direct kernel 是否应把 table_length 显式作为参数并只保留一处校验？
  - PagedKVCacheView 的 visible_blocks 目前仅用于校验，gather 长度实际由
    position/num_tokens 推导；设计包 §4.2 需决定 table_length 与 visible_tokens 的关系。
next_task_id: TLLM-P0-004 PR-3（Transformer dispatch + TLLM_PAGED_ATTENTION 开关）
next_exact_command: |
  # 设计包已批准（tiny-llm#5 §12），8 项决议全部关闭，实现不再被阻塞。
  # PR-1 是唯一有真实爆炸半径的 PR（改现有热路径 kernel），先做它并请第二方复核。
  cd tiny-llm && git fetch origin
  git checkout master && git pull --ff-only            # 先合并 #4（oracle）与 #6（C ABI 校验）
  git checkout -b tllm-dpa-pr1-tile-loop
  # 改动范围仅 kernels/attention.cu：把 decode 的 tile loop 抽成 __device__ 模板
  # + 寻址策略（连续版改用它，行为不变）
  cmake -S . -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_TESTS=ON
  cmake --build build -j"$(nproc)"
  ./build/tiny_llm_tests --gtest_filter='PagedOracle*'   # 必须与重构前逐元素一致
  ./build/tiny_llm_tests                                 # 全量不得减少通过数
  ./build/tiny_llm_kernel_bench                          # PR-1 必须附前后对比证明无回归
```

## 同日追加：TLLM-P0-004 设计包已批准 + C ABI 边界缺陷已修

### 1. 设计包（`open-infra-ai/tiny-llm#5`）

- 文件 `docs/architecture/direct-paged-decode-attention-design.md`（base `2b15fb2`）。
  按 `L3_L4_DESIGN_REVIEW_PACKAGES.md` §3 模板填充，覆盖 G0–G8 与 §4（TLLM-DPA）
  的全部必答项；已冻结地址公式、stride、整数宽度、`visible_tokens = position + 1`
  不变量、`visible_tokens = 0`、非法块 id 的零行语义。
- **Decision: `approved`（2026-09-14）**，8 项待决议题全部关闭（Q1 flat 参数 /
  Q2 抽取共享 tile loop + 强制性能不回归检查 / Q3 冻结零行语义 / Q4 逐元素严格相等 /
  Q5 校验位置改到 C ABI 边界 / Q6 收益不得外推 TTFT-TPOT / Q7 scratch 保留 + follow-up /
  Q8 取消不可达的几何回落）。
- **独立性缺陷已记录在 §12**：本包由作者编写、也由作者汇总决议，不满足
  「实现 Agent 不应成为唯一 reviewer」。**PR-1 是唯一有真实爆炸半径的决定**
  （改现有热路径 kernel），合并前应由第二方复核其 diff 与前后性能数据。

### 2. 本轮新发现：C ABI 模型几何越界读（`open-infra-ai/tiny-llm#6`）

- 现象：`num_heads` 不被 `num_kv_heads` 整除时，attention kernel 的
  `kv_head = q_head / (num_heads / num_kv_heads)` 越界，最后一个 token 的 K/V 读
  越过缓冲末尾。最小复现 + Compute Sanitizer 证实（`Hq=14/Hkv=3`，13 errors，
  `cudaDeviceSynchronize -> unknown error`，CUDA 上下文被毒化）。
- 范围：`validateModelConfig` 早已实现该校验，但全仓只有 `InferenceEngine::Load`
  调用；C ABI 路径 `tinyllm_load`（分页/策略 1 与 paged-serving 走的那条）不调用，
  且 `extractModelConfig` 对异常元数据是补默认值而非报错。
- 修复：在 `tinyllm_load` 的 `extractModelConfig()` 之后、`loadGGUF()` 之前调用
  `Validator::validateModelConfig`；一处覆盖整条 C ABI 路径，对合法模型零行为变化。
- 新增 `tests/test_validator.cpp`（纯 host，无 GPU 也运行；`Validator` 此前零覆盖）。
  变异检验：移除校验调用后边界测试失败。
- 该修复与 TLLM-P0-004 解耦，可独立合并。

### 3. TLLM-P0-004 实现：门禁先否决，后按 issue #8 翻转

- **PR-1（抽取共享 decode tile loop）先被它自己的门禁否决**。设计包 §10 预先写明
  "出现可测回归则退回复制实现"，而抽取实测给生产 kernel `attention_decode` 带来
  **+1.4~2.3% 的可复现回归**（两轮独立重复分别 7/8 与 6/8 几何为正，D=128/S=512 达
  +4.9%）。完整证据与三次测量方法修正见设计包 §10.1。
  - 测量陷阱（后人勿重蹈）：GPU 空闲时 SM 时钟停在 900/3090 MHz，小 kernel 拉不动
    boost，逐次差异可达 50%；scratch 程序误编到 sm_75 而非生产的 sm_120；现成 harness
    的 host-int 重载每次调用带一次 4 字节 H2D memcpy。
  - 可信方法：时钟预热 + `-arch=native` + device-int 重载 + 大 S + 顺序平衡交替 +
    **新旧 kernel 编入同一进程交替调用**（消除跨二进制代码布局混淆）。
  - 两种规避写法（策略按值/按引用、无效行返回零行以消分支）均未改变结论。
- **随后按 issue #8 翻转该取舍：接受回归，改回共享循环**（设计包 §10.2）。理由是
  复制方案唯一的风险（两份实现漂移）已由"逐位相同"门禁自动覆盖——**安全来自门禁，
  不来自副本数量**；+1.4~2.3% 落在单 kernel，端到端约 0.1~0.3%，不划算。
  最终形态：`decode_online_softmax` 模板 + `ContiguousRows` / `PagedRows` 取址策略，
  无效行返回共享内存零行（循环内无分支）。
- **PR-2 已提交**：`open-infra-ai/tiny-llm#7`（base = #4，堆叠），含两个 commit。
  - 主门禁：direct 与 legacy 在同一 pool/块表/输入下输出**逐位相同**（12 组几何 × 3 seed），
    另对照 TLLM-P0-002 的独立 oracle；sanitizer 0 error。
  - 连续路径数值**逐位不变**（10 组几何的 fp16 位模式指纹，抽取前后一致）。
  - **变异检验三项**：① 块内偏移写错 → 逐位门禁捕获；② 去掉 `table_len` 防护 → 短块表
    用例捕获；③ **在共享循环里丢掉 online rescale（两条路径同等出错）→ 逐位门禁通过、
    独立 oracle 捕获**。第三项证明"共享归约必须配独立参考"，否则该类错误整体漏过。
  - 边界：只加 kernel 与 kernel 级测试，**未**接入 Transformer dispatch（PR-3），
    生产 decode 路径行为不变；不产生性能数字。
  - **CI**：`ci.yml` 的 `pull_request.branches` 匹配的是 base 分支，堆叠 PR 不会自动
    触发 CI。已用 `workflow_dispatch` 在分支 head 手动跑（翻转前的 bb0f124 与翻转后的
    commit 各一次）。#4 合并后 base 会自动重定向到 master。

### 4. 当前 PR 依赖

| PR | 内容 | 阻塞关系 |
|----|------|----------|
| tiny-llm#4 | TLLM-P0-002 oracle | #7 的 base |
| tiny-llm#5 | TLLM-P0-004 设计包（已批准，§10.1 记录 PR-1 否决） | 无 |
| tiny-llm#6 | C ABI 几何校验 | 无，可独立合并 |
| tiny-llm#7 | TLLM-P0-004 PR-2 direct kernel | 依赖 #4；合并顺序 #4 → #7 |
| ai-infra-interview-prep#9 | 本交接记录 | 无 |

### 5. 下一步

PR-3（`TransformerLayer::attentionPaged` decode 分支切 direct + `TLLM_PAGED_ATTENTION`
开关三态与降级日志）。设计包 §7/§11 已冻结其契约；PR-3 之后才是 PR-5 的三路 benchmark
（legacy / contiguous / direct），届时才允许出现性能数字。

## 复现与验证细节

- 环境（当前机器，不是历史上的 RTX 3060 Laptop）：RTX 5070 Ti 16GB（sm_120）、
  CUDA 13.3.73 / driver 615.65.06、GCC 13.3、CMake 3.28.3。
- 构建：`cmake -S . -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_TESTS=ON`
  然后 `cmake --build build -j12`（exit 0）。
- 基线（同 commit 未改动时）：198 项，187 passed / 11 skipped。
  本 PR 后：206 项，195 passed / 11 skipped。11 项 skip 全部是真实 GGUF 模型门控。

## 变异检验（证明 oracle 不是恒真测试）

| 注入的 bug | 被谁捕获 | 结果 |
|---|---|---|
| `paged_scatter_blocks` 忽略 `position`（`abs = t`） | `PagedOracleKernelTest.IncrementalScatterAtNonZeroPositionsMatchesOracle` | FAILED |
| `attentionPaged` 层步长丢掉 `max_num_blocks` | `PagedOracleLayerTest.ForwardPagedKVMatchesContiguousKVPerLayer` | FAILED，精确报 layer 1 |

两处变异均已还原，`git diff` 中不含变异代码。

## 本 PR 暴露并修复的两处既有缺陷

1. `TransformerLayer::forwardPaged` 不校验块表长度。`visible_blocks` 不足时
   `paged_gather_blocks` 会越界读 `block_table`（未定义行为）。`src/ffi.cpp` 早有
   等价检查（`nb < need_blocks`），但与 kernel/层入口不同源。
2. `KVCacheManager::create` 未初始化 `append_pos_`。同一函数内 `memory_pool_` 有
   `cudaMemset`，`append_pos_` 漏了。调用方（`inference_engine.cpp`、`ffi.cpp`）
   都会先 `setAppendPos`，所以生产路径此前未暴露；但既有的
   `TransformerTest.KeyProjectionUsesItsOwnGroupSize` 依赖它恰好为 0——在本 PR 的
   测试污染分配器后该测试稳定失败，根因是未初始化 device 内存。

## 限制与不得越级的声明

- 被测路径仍是 scatter → gather → continuous attention，**不是** direct
  PagedAttention。本 PR 不改变这一点，也不改变任何能力边界文档。
- 未产生任何性能数字、profiler 结论或 serving 证据。
- layer 级最终 hidden 比对在本文件里只是次要检查：合成权重下残差主导，fp16 输出
  量化会吞掉 attention 的微小差异，因此不作为门禁依据。
