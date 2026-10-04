# 【姓名待填】 · LLM 推理运行时 / Serving 工程师

**联系方式**：手机【待填】｜邮箱【待填】｜现居地【待填】
**GitHub**：[holtwood](https://github.com/holtwood)｜[open-infra-ai](https://github.com/open-infra-ai)

> 【真实年限待填】年后端 / 系统工程经验，转向 LLM inference serving。重点覆盖请求调度、
> Paged KV 生命周期、跨语言 runtime 集成和可复验的尾延迟/吞吐评测方法，而不把正确性用例
> 误写成生产容量。

## 工作经历

### 【公司】｜【岗位】｜【起止时间】

- 【填写真实的实时服务、并发控制、资源调度、网络协议、稳定性或性能优化成果。】
- 【每条使用“场景 → 本人动作 → 可验证结果”的结构；无证据的规模和指标不要填写。】

## 开源项目

### [paged-serving](https://github.com/open-infra-ai/paged-serving)｜Rust LLM Serving 控制面

- 实现 Paged KV 的 BlockPool / PageTable、continuous batching、准入控制、优先级和 decode reserve，
  通过 OpenAI 兼容 HTTP/SSE API 承载请求生命周期；调度资源守恒由属性测试约束。
- 通过 C ABI 接入 `tiny-llm` 真实 CUDA 后端并上传 `block_tables`。3 并发 e2e 用于证明
  跨语言生命周期和 greedy 输出正确性。[正式 closed-loop / Poisson 21-run 报告](https://github.com/open-infra-ai/paged-serving/tree/master/benchmarks/serving/results/2026-09-07-RTX3060Laptop-paged-serving-p2-batch-postprocess-streaming)
  绑定 GPU、模型、双仓 commit 与原始请求；保留 429 和未收敛项，不将其包装为稳定容量或生产 SLO。

### [tiny-llm](https://github.com/open-infra-ai/tiny-llm)｜真实 CUDA 推理后端

- 打通 GGUF 加载、W8A16、KV Cache、decode 和 C ABI，使 Serving 控制面能调用真实模型路径。
- 在 RTX 3060 Laptop 6GB、固定 Qwen2.5-0.5B-Instruct 与 64-token greedy decode 下，
  CUDA Graph **decode A/B** 将 TPOT 8.322→5.225 ms/token（-37.2%），decode 吞吐
  120.168→191.384 tok/s（+59.3%）；原始 JSONL、模型 SHA-256 和 TTFT 限制可
  [复验](https://github.com/open-infra-ai/tiny-llm/blob/master/docs/performance/results/2026-08-23-cuda-graphs-ab.md)。

## 技能

- **Serving**：continuous batching、Paged KV、请求状态机、准入/429、HTTP/SSE；
  有界背压与主动取消的完整保障仍待验证，不能把未合入 PR 写成本人已交付能力。
- **评测**：closed-loop、Poisson、TTFT/TPOT、成功率、429、token coverage、`summary.json` / `per_request.jsonl` 原始产物契约。
- **系统与运行时**：Rust、C++17、CUDA C++、C ABI / FFI、GGUF、W8A16、KV Cache、CMake、CI、属性测试。

**投递前检查**：填写真实工作经历、联系方式和教育背景；外部基线的量化格式差异必须紧随数字说明；
没有正式 profiler 报告或 Serving 结果时，不写 GPU 利用率、QPS、容量或 Nsight 熟练度。
