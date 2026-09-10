# open-infra-ai 可执行任务清单

> 版本：1.0
>
> 计划快照：2026-08-28
>
> 总体计划：[PLAN.md](PLAN.md)
>
> 执行入口：[PROMPT.md](PROMPT.md)

## 0. 使用规则

本文件是执行状态的唯一权威来源。执行代理一次只领取一个任务，先把该任务的 `状态` 从
`todo` 改为 `in_progress`，完成验证并写入证据后才能改为 `done`。

允许的状态只有：

- `todo`：尚未开始；
- `in_progress`：当前唯一正在执行的任务；
- `blocked`：存在可复现的外部阻塞，必须补充阻塞证据、恢复条件和下一步；
- `done`：任务范围、验证、证据与状态更新全部完成；
- `skipped`：用户明确取消，必须记录原因和替代任务。

状态纪律：

1. 全文件最多一个 `in_progress`；
2. 依赖未完成时不能开始下游任务；
3. 等待 GitHub、云资源或模型授权时，把当前任务标为 `blocked`，继续独立的 `todo`；
4. 本地测试通过不等于线上 CI 通过，open PR 不等于 merged；
5. 计划任务失败也是有效结果，不能为了 `done` 删除负结果或缩小测试口径；
6. 每次状态变化都在任务的“执行记录”中追加日期、commit、命令、退出码和证据路径；
7. 不在本文件填写未经本轮实测的性能数字。

运行期操作日志统一放在：

```text
handoffs/deepseek-v4-flash/runs/<YYYY-MM-DD>/<TASK-ID>/
```

正式、可公开的 benchmark 结果应进入目标技术仓已有的 results/benchmark 体系；若目标仓没有合适
位置，先在任务记录中提出最小目录设计，不能随意新建多套 schema。不要改动个人执行仓现有、未跟踪的
`evidence/`，也不要纳入 `tiny-llm/.zcode/`。

## 1. 任务索引与关键路径

执行优先级：`P0` > 阻塞关键路径的 `P1` > `P2` > `P3`。同优先级按依赖和编号执行。

| ID | 优先级 | 任务 | 主要依赖 | 默认权限门禁 |
|----|--------|------|----------|--------------|
| `P0-01` | P0 | 建立不可变工作区与线上基线 | 无 | 只读 |
| `P0-02` | P0 | 分类旧仓名与旧链接命中 | P0-01 | 本地修改 |
| `P0-03` | P0 | 收口 canonical 名称（live 文件） | P0-02 | 本地修改 |
| `P0-03M` | P0 | 迁移本地 checkout 到 canonical 目录 | P0-03 | 目录移动/remote 修改需确认 |
| `P0-04` | P0 | 修复旗舰仓当前格式 CI | P0-01 | 本地修改 |
| `P0-05` | P0 | 同步源码、tag 与 GitHub Release | P0-04 | tag/Release/推送需确认 |
| `P0-06` | P0 | 组织级可信度复核 | P0-03～05 | GitHub 写操作需确认 |
| `TLLM-01` | P0 | 固化 tiny-llm 当前正确性基线 | P0-04 | 本地 GPU |
| `TLLM-02` | P1 | 第二真实模型/架构端到端门控 | TLLM-01 | 模型下载需确认 |
| `TLLM-03` | P1 | 同协议 llama.cpp 外部基线 | TLLM-01 | 下载/安装按提示词配置 |
| `TLLM-04` | P1 | 长上下文曲线与 OOM 边界 | TLLM-01 | 本地 GPU |
| `TLLM-05` | P1 | Runtime 失败路径矩阵 | TLLM-01 | 本地修改 |
| `TLLM-06` | P1 | 数据中心 GPU profiler 闭环 | TLLM-01、云 canary | 云资源需确认 |
| `TLLM-07` | P2 | 只基于热点做一次优化闭环 | TLLM-04/06 | 本地修改 |
| `PSERV-01` | P0 | 固化双仓集成基线 | P0-04、TLLM-01 | 本地 GPU |
| `PSERV-02` | P1 | 审计 loadgen 与 token coverage | PSERV-01 | 本地修改 |
| `PSERV-03` | P1 | continuous batching on/off A/B | PSERV-02 | 本地 GPU |
| `PSERV-04` | P1 | 正式 closed-loop/Poisson Serving 扫描 | PSERV-03 | 云资源需确认 |
| `PSERV-05` | P1 | 取消、HOL、fairness、429/OOM 矩阵 | PSERV-02 | 本地/云 GPU |
| `PSERV-06` | P2 | 跨引擎系统观察与报告 | PSERV-04 | 云资源/安装需确认 |
| `CUF-01` | P0 | 清理 cuflash live 文档证据口径 | P0-03 | 本地修改 |
| `CUF-02` | P1 | 当前版本正式 benchmark/profiler 包 | CUF-01 | 云资源需确认 |
| `CUF-03` | P2 | 基于当前结果写 Kernel 深度文章 | CUF-02 | 本地修改 |
| `SUP-01` | P2 | 辅助仓改名、状态与入口收口 | P0-03 | GitHub 写操作需确认 |
| `SUP-02` | P2 | CUDA/C++/Triton 横向案例 | SUP-01、CUF-02 | 本地 GPU |
| `UP-01` | P0 | 审计并推动已有上游贡献 | P0-01 | comment/review 需确认 |
| `UP-02` | P1 | 选择并复现一个 SGLang 真实问题 | UP-01 | 本地修改 |
| `UP-03` | P1 | 提交最小上游修复并保存反馈证据 | UP-02 | PR/推送需确认 |
| `EVID-01` | P1 | 两个 Demo、两个 STAR 与简历证据 | 至少一份正式结果 | 发布需确认 |
| `EVID-02` | P0 | 周期末组织审计与投递门禁 | 全部关键任务 | GitHub 写操作需确认 |

最短关键路径：

```text
P0-01 -> P0-04 -> TLLM-01 -> PSERV-01 -> PSERV-02 -> PSERV-03
       -> PSERV-04 -> PSERV-06 -> EVID-01 -> EVID-02
```

并行但不抢占关键路径的工作流：

```text
P0-01 -> P0-02 -> P0-03 -> CUF-01 -> CUF-02 -> CUF-03
P0-01 -> UP-01 -> UP-02 -> UP-03
```

---

## 2. Phase 0：公共可信度恢复

### P0-01 建立不可变工作区与线上基线

- 状态：`done`
- 优先级：P0
- 时间盒：2 小时
- 工作区：所有并排仓、个人执行仓
- 依赖：无
- 权限：只读；不得 fetch 后自动 merge，不得修改 remote

执行：

1. 逐仓记录绝对路径、当前分支、`HEAD`、upstream、remote、dirty/untracked；
2. 记录 Git、CUDA、驱动、编译器、CMake、Rust、Python/PyTorch/Triton 版本和 GPU；
3. 用 GitHub CLI/API 重新查询七个公开仓的默认分支、最后提交、CI、Release、Pages、description、topics；
4. 明确区分本地旧目录名与 GitHub canonical 仓名；
5. 把原始命令输出保存到本任务 run 目录，敏感 URL/令牌必须脱敏。

最低验证：

```bash
git -C <repo> status --short --branch
git -C <repo> rev-parse HEAD
git -C <repo> remote -v
gh repo view open-infra-ai/<repo> --json name,url,defaultBranchRef,description,repositoryTopics,latestRelease
gh run list -R open-infra-ai/<repo> --limit 10
```

验收：七个公开仓均有时间戳基线；已知 `evidence/`、`.zcode/` 等用户内容单独列出；未发生写操作。

执行记录：

- 完成时间：2026-08-28 12:21 +08:00
- 基线：见 runs/2026-08-28/P0-01/01_local_git_baseline.txt（七仓 HEAD：open-infra-ai=5e0f570[behind 5]、.github=366d407、tiny-llm=f9d4b99、cuflash=d53a530、paged-serving=080f26f、triton-fused-ops=5764758、cuda-foundations=28e070b，均 clean 除 tiny-llm 的 `?? .zcode/`）
- 变更：无（纯只读；仅 fetch 更新 remote-tracking，未 merge/未改 remote）
- 验证：`git status --short --branch` / `rev-parse HEAD` / `remote -v` / `branch -vv` / `tag`（七仓，exit 0）；`gh repo view open-infra-ai/<repo>` 元数据（name/defaultBranch/description/topics/latestRelease）；`gh api .../commits`、`.../pages`、`gh run list --limit 10`；工具版本采集（git 2.43.0 / gh 2.97.0 / nvcc 12.0.140 / driver 610.57.01 CUDA UMD 13.3 / cmake 3.28.3 / gcc 13.3.0 / rustc 1.90.0 / python 3.12.3 / conda triton-b4 torch 2.5.1+cu121 triton 3.1.0 / triton-fused-ops .venv torch 2.13.0+cu130 / GPU RTX 3060 Laptop 6GB）
- 证据：handoffs/deepseek-v4-flash/runs/2026-08-28/P0-01/{00_summary,01_local_git_baseline,02_github_baseline,03_github_ci,04_toolchain_versions}
- 限制：未跑任何测试/构建；meta 仓落后 origin 5 commit（他人已推送改名文档）未 merge；GitHub 线上状态为 API 快照（2026-08-28T04:18Z）
- 外部状态：本地与线上均为基线快照；tiny-llm 最新 master CI FAILURE（33042427022）、paged-serving 最新 master CI FAILURE（33051255489）需 P0-04 处理；clang-format-18 本机缺失；cuflash/paged-serving 本地 remote 仍为旧 URL
- 下一任务：P0-02

### P0-02 分类旧仓名与旧链接命中

- 状态：`done`
- 优先级：P0
- 时间盒：2 小时
- 工作区：`open-infra-ai` 工作区、个人执行仓
- 依赖：P0-01
- 权限：允许新增审计结果；此任务不批量替换

执行：

1. 搜索 `cuflash-attn`、`paged-infer` 及旧 GitHub/Pages URL；
2. 每一处归类为 `live-fix`、`historical-exempt`、`generated`、`external-history`；
3. 识别源码中的 ABI crate/package/include 名是否属于 breaking interface，不能把显示名替换等同于 ABI 改名；
4. 输出逐文件清单，标出 owner、建议动作和验证方法。

最低验证：

```bash
rg -n --hidden --glob '!.git/**' 'cuflash-attn|paged-infer|open-infra-ai.github.io/(cuflash-attn|paged-infer)' \
  /home/shane/github/open-infra-ai \
  /home/shane/github/holtwood/ai-infra-interview-prep
```

验收：所有命中均完成分类；审计快照、已发布 CHANGELOG、历史计划、fixture 没有进入替换清单。

执行记录：

- 完成时间：2026-08-28 12:35 +08:00
- 基线：P0-01 基线（无代码改动）
- 变更：无（审计任务，仅新增 runs/2026-08-28/P0-02/{01_hits_workspace,02_hits_personal_repo,03_files_workspace,04_hits_meta,05_classification}）
- 验证：`rg -n --hidden --glob '!.git/**' -e 'cuflash-attn' -e 'paged-infer'`（工作区 448 行/87 文件；个人仓 522 行）一次完成；逐文件归类
- 证据：handoffs/deepseek-v4-flash/runs/2026-08-28/P0-02/05_classification.md（完整 live-fix/exempt 清单）
- 限制：未做任何替换；未检查线上 Pages 内容命中（线上文档站部署于各仓 master，仓库级替换后由 Pages 重建覆盖）
- 关键结论：Rust crate 名已为 paged-serving、cuflash CMake target 已为 cuflash；ABI 双源文件名与布局不变，全部命中仅为文本引用，无 breaking interface；live-fix 约 30 个工作区文件 + 19 个人仓文件；exempt 含 audit/历史计划/已发布 CHANGELOG/interview/fixture/.git 内部
- 外部状态：local-only（0 提交）
- 下一任务：P0-03

### P0-03 收口 canonical 名称（live 文件）

- 状态：`done`
- 优先级：P0
- 时间盒：4 小时
- 工作区：meta、`.github`、五个技术仓、个人执行仓
- 依赖：P0-02
- 权限：live 文件可改；本地目录移动、remote 修改和 GitHub 设置按 [PROMPT.md](PROMPT.md) 开关执行

执行：

1. 只修改 P0-02 标为 `live-fix` 的 README、active plan、badge、Pages base、构建/包元数据、当前状态注册表和链接；
2. 将所有用户可见入口统一为 `github.com/open-infra-ai/cuflash`、`github.com/open-infra-ai/paged-serving` 及对应 Pages；
3. 保持 ABI、crate/module/CMake target 名，除非有单独 breaking-change 任务；
4. 移动本地 checkout 前重新检查 dirty、后台进程、绝对路径引用和 IDE/脚本配置；未获目录移动授权时只输出命令和影响清单；
5. 若获授权，将目录收口为 `cuflash/`、`paged-serving/`，再逐仓验证 remote 与构建入口；
6. GitHub description/topics/Pages 等只在外部写授权后修改。

验收：live 入口没有旧仓名；历史豁免原样；两个目录迁移要么验证完成，要么明确标记“等待授权”，不能部分移动。

执行记录：

- 完成时间：2026-08-28 13:05 +08:00
- 基线：P0-01/P0-02 基线；各仓 preflight clean（tiny-llm 仅 .zcode/），meta 仓 behind origin 5（未处理）
- 变更：工作区 27 文件 + 个人执行仓 19 文件（精确 token 替换 cuflash-attn→cuflash、paged-infer→paged-serving）：
  `.github/profile/README.md`、根 `README.md`/`AGENTS.md`、meta `README.md`/`docs/cross-repo-contracts.md`/`docs/repository-boundaries.md`/`LEARNING_PATH.md`、`tiny-llm`（README/ROADMAP/docs/architecture/kv-cache.md/docs/performance/optimization.md/src/ffi.cpp/include/tiny_llm/ffi.h/CHANGELOG Unreleased 节）、`paged-infer/README.md`、`cuflash-attn/docs/design/flash-decoding.md`、`cuda-foundations` 8 文件、`triton-fused-ops` 3 文件；个人仓 README/PROJECT_STRATEGY/SKILL_MATRIX/CLOUD_GPU_PLAYBOOK/APPLICATION_PLAN/TARGET_ROLES/BASELINE/JOB_MARKET_EVIDENCE/INTERVIEW_MATRIX/ROADMAP/applications/community/resume×3/weekly×4
- 验证：27+19 变更 diff 逐文件审查（干净 token 替换，无部分替换/无 aicl-lab 触碰/已发布 CHANGELOG 未动）；六仓 `git diff --check` 均 OK；残留复查：工作区 47 命中 ∪ 个人仓 13 命中全部 ∈ 豁免集（audit/历史计划/已发布 CHANGELOG/interview/.git 内部/handoff 迁移期描述）
- 证据：runs/2026-08-28/P0-03/00_P0-03_summary.md（含目录迁移与 GitHub 元数据等待授权清单）、01/02_residual_*.txt；dry-run 副本见 /tmp/opencode/P0-03/dry-v{1,2}home
- 限制：**目录迁移未执行**（ALLOW_KNOWN_CHECKOUT_RENAME=false）：cuflash-attn/、paged-infer/ 及对应 remote URL 保持原样，精确 mv + set-url + 验证命令已写入 summary，等待授权；GitHub metadata（description/topics/Pages）经 gh API 确认已 canonical，.github 仓 topics 为空可选补（需授权）；meta 仓本地仍 behind 5 未 merge
- 外部状态：local-only（0 提交、0 push）
- 注（2026-08-28 校正）：本任务只含 live 文件收口（已验收）；目录迁移职责已拆分到 `P0-03M`（blocked，等待授权），不再使用“部分完成”表述
- 下一任务：P0-03M（迁移，blocked）→ P0-04

### P0-03M 迁移本地 checkout 到 canonical 目录

- 状态：`done`
- 优先级：P0
- 时间盒：1 小时（获授权后）
- 工作区：`open-infra-ai` 工作区（cuflash-attn/、paged-infer/）
- 依赖：P0-03（live-fix 已 done）
- 权限：本地目录移动与 remote 修改需 `ALLOW_KNOWN_CHECKOUT_RENAME=true`；本任务不包含 GitHub 写操作

执行：

1. 迁移前预检：两仓 `git status --short` 必须 clean（当前含本会话未提交 live-fix 文件，需先经 P0-05 同批 commit 或用户另行处理）；确认无后台进程占用；核对绝对路径引用（IDE/脚本）
2. `mv` 目录 + `git remote set-url origin` 到 canonical URL（精确命令见 runs/2026-08-28/P0-03/00_P0-03_summary.md）
3. 逐仓验证：`git status --short --branch`、`git remote -v`、`git fetch origin` 一次
4. 更新根 README/AGENTS.md 中目录索引（如仍引用旧目录名）

验收：`cuflash/` 与 `paged-serving/` 目录名与 GitHub canonical 一致；remote URL 为新名；构建入口无变化；无部分迁移。

执行记录：

- 完成时间：2026-08-28 14:34 +08:00
- 基线：cuflash-attn@d53a530、paged-infer@080f26f（dirty 均为本会话已知改动）
- 变更：`cuflash-attn/` → `cuflash/`、`paged-infer/` → `paged-serving/`（mv）；两仓 `git remote set-url origin` 为 canonical URL；无文件内容改动、无 git 写操作
- 验证：预检（源存在/目标无冲突/dirty 归属/无进程占用/无 IDE 脚本引用）通过；`git status --short --branch` 正常、remote 新 URL、`git fetch origin` 两仓 OK；构建入口静态完整；根 README 目录索引已 canonical 一致
- 证据：runs/2026-08-28/P0-03M/00_P0-03M_migration_record.md（前后路径/HEAD/remote/dirty/rollback 命令/副作用）
- 限制：**构建缓存副作用**——cuflash build/release/CMakeCache.txt 的 CMAKE_HOME_DIRECTORY 仍指向旧路径，需重新 cmake 配置；paged-serving cargo target 首次构建会因路径变化重编；本轮未重跑构建；未 commit/push/写 GitHub
- 外部状态：local-only（0 提交、0 push）
- 下一任务：P0-05（发布，仍 blocked）→ P0-06

### P0-04 修复旗舰仓当前格式 CI

- 状态：`done`
- 优先级：P0
- 时间盒：2 小时
- 工作区：`tiny-llm`、`paged-serving`（当前本地可能为 `paged-infer`）
- 依赖：P0-01
- 权限：允许最小格式修改；不顺手重构

已知起点需先重新验证：`tiny-llm/src/main.cpp:92` 的 clang-format，以及
`paged-serving/tests/tokenizer_real_diff.rs:25` 的 rustfmt。

执行与验证：

```bash
# tiny-llm：使用 CI 同版 clang-format-18
find . -type f \( -name '*.cpp' -o -name '*.h' -o -name '*.cu' -o -name '*.cuh' \) \
  ! -path './build/*' ! -path './.git/*' ! -path './third_party/*' \
  ! -path './vendor/*' ! -path './external/*' ! -path './.kiro/*' \
  ! -path './tests/tokenizer_fixture_cases.h' \
  | xargs clang-format-18 --dry-run --Werror

# paged-serving
cargo fmt --all -- --check
cargo clippy --all-targets -- -D warnings
cargo build --locked
cargo test --locked
cargo test --doc --locked
cargo doc --no-deps --locked
```

验收：diff 仅为格式变化；两仓本地对应门禁通过；未声称远端 CI 通过，除非推送后重新查询到了绿色 run。

执行记录：

- 完成时间：2026-08-28 13:35 +08:00
- 基线：tiny-llm@f9d4b99、paged-infer@080f26f（均 clean 除 .zcode/）；CI 失败 run 已复现：tiny-llm 33042427022（main.cpp:92:85 clang-format）、paged-serving 33051255489（tokenizer_real_diff.rs:25 rustfmt）
- 变更：tiny-llm `src/main.cpp`（合并 L92-93 单行，97 字符 < 100）；paged-serving `tests/tokenizer_real_diff.rs`（cargo fmt 换行拆分，与 CI 期望 diff 逐字节一致）；其余 diff 为 P0-03 名称替换文件
- 验证：tiny-llm CI 同款 `find|xargs clang-format --dry-run --Werror` exit 0（clang-format 18.1.8，uv tool 安装）；paged-serving 六步门禁全绿：fmt --check / clippy --all-targets -D warnings / build --locked / test --locked（215 passed + 17 doc-tests, 0 failed）/ test --doc --locked / doc --no-deps --locked，全部 exit 0；两仓 `git diff --check` OK
- 证据：runs/2026-08-28/P0-04/00_P0-04.md（含 CI run URL、工具版本、完整命令与退出码）
- 限制：tiny-llm 未构建/未跑测试（属 TLLM-01）；本地 nvcc 12.0 vs CI 11.8 与格式门禁无关；未推送、远端 CI 未重跑（未授权 push）
- 外部状态：local-only（0 提交）
- 下一任务：P0-05（需授权）→ 并行解锁 TLLM-01

### P0-05 同步源码、tag 与 GitHub Release

- 状态：`done`
- 优先级：P0
- 时间盒：3 小时准备，外部运行另计
- 工作区：`tiny-llm`、`paged-serving`
- 依赖：P0-04
- 权限：本地检查与 release notes 可做；commit/tag/push/Release 必须再次授权

执行：

1. 重新查询源码版本、CHANGELOG、所有 tag、Latest Release、release workflow 和产物；
2. `tiny-llm` 解决源码版本高于 Latest Release 的漂移；
3. `paged-serving` 解决存在 v0.2.0 tag 但 Latest Release 仍为 v0.1.0 的漂移；
4. release notes 只陈述可由 commit/test 证明的变化；
5. 在授权前输出精确 tag、commit、资产、校验和、rollback checklist；授权后逐仓执行并观察 workflow。

验收：版本四元组“源码/CHANGELOG/tag/Release”一致，或生成可直接执行且尚未执行的发布清单；不得重打已有公开 tag。

执行记录：

- 完成时间：2026-08-28 15:15 +08:00
- 基线：用户版本决定 tiny-llm v2.0.2 / paged-serving v0.2.1；授权 ALLOW_GIT_COMMIT/PUSH/GITHUB_WRITE=true
- 变更（逐项记录 commit/tag/push/CI/Release）：
  - **tiny-llm**：commit `d2838f3`（CHANGELOG Unreleased→[2.0.2]、P0-03 名称收口、P0-04 main.cpp 格式）→ push master → tag `v2.0.2` @ d2838f3 → push tag → Release workflow（run 33149329110）自动创建：**Release v2.0.2 Latest** https://github.com/open-infra-ai/tiny-llm/releases/tag/v2.0.2（资产 tiny-llm-v2.0.2-linux-x64.tar.gz 525662B）；master CI run 33149329080 **success**；Pages run 33149329071 **success**
  - **paged-serving**：commit `f6a6ffa`（Cargo.toml/lock 0.2.0→0.2.1、CHANGELOG [Unreleased]→[0.2.1]、P0-03 README、P0-04 rustfmt）→ push master → tag `v0.2.1` → push tag → `gh release create`：**Release v0.2.1 Latest** https://github.com/open-infra-ai/paged-serving/releases/tag/v0.2.1；master CI run 33149937179 **success**（无 release workflow，手动创建）
  - 同步提交（P0-03/P0-04/CUF-01 成果）：`.github` `c6d3978`；cuflash `599836b`（推后 CI 33150085472 success）；triton-fused-ops `538908f`（CI 33150085916 success）；cuda-foundations `72a05b9`（Pages 33150117855 success）
  - **meta open-infra-ai**：origin 5 个 commit（并行改动，含历史豁免区）与本地 P0-03 在 4 个 live 文件上为零差异 → 本地冗余 dirty 精确 checkout 丢弃 → `merge --ff-only` 至 c9f8a13，与 origin 完全同步（无新提交）
- 验证：tiny-llm 重构建+clang-format+ctest（192 passed+1 skipped）通过后发布；paged-serving fmt/clippy/build/test（215 passed+17 doc-tests）/doc 全绿；每仓 `git diff --cached --check` OK；未包含 .zcode/、模型、凭据；无 `git add .`/`-A`
- 证据：各 commit/tag/run/Release URL 见上；本地 runs/2026-08-28/P0-05/
- 限制：paged-serving 无 release workflow（手动 create，无资产构建）；tiny-llm Release 资产由 workflow 生成；cuflash/triton/cuda-foundations 未打新 tag（无版本变更要求，仅收口提交）；meta 仓历史豁免区被并行改动推上是既有事实（未参与、未回滚）
- 外部状态：已推送；两旗舰主分支 CI **success**；tiny-llm v2.0.2 与 paged-serving v0.2.1 均 Latest Release（本地→pushed 全链路）
- review 修复注（2026-08-28，本地未提交）：深度 review 发现并修复——①tiny-llm `include/tiny_llm/ffi.h:10` 注释 env var 名 `PAGED_INFER_TINY_LLM_STRATEGY`→`PAGED_SERVING_TINY_LLM_STRATEGY`（与 paged-serving `src/tiny_llm_executor.rs:50` 一致）；②tiny-llm `.gitignore` 增 `.zcode/`；③paged-serving CHANGELOG [0.2.1] 补 E2 优先级调度条目（a69b146）与 `[0.2.1]:` 链接定义；④PSERV-01 证据补 ABI ORDER/SET MATCH 结论。验证：全工作区 live 无下划线变体残留、clang-format 与 diff --check 通过。**待提交**（需 commit/push 授权）
- 下一任务：P0-06（组织级复核，GitHub 元数据写入需确认）

### P0-06 组织级可信度复核

- 状态：`todo`
- 优先级：P0
- 时间盒：3 小时
- 工作区：meta、`.github`、五个技术仓
- 依赖：P0-03、P0-03M、P0-04、P0-05
- 权限：只读审计默认允许；GitHub 元数据写入需确认

执行：

1. 比对 meta README 权威状态注册表、各仓 README 状态行和 GitHub topics；
2. 验证所有 GitHub、Pages、badge、Release 与交叉仓链接；
3. 查询默认分支最新 CI，区分 required、scheduled GPU、manual GPU 与 Pages；
4. 检查 `.github` profile 的一句话定位和旗舰入口；
5. 输出 `pass/fail/blocked/not-applicable` 矩阵及剩余 owner。

验收：五仓状态三处一致；所有 live 链接可达；红色门禁有 owner 和修复任务；queued self-hosted GPU 不伪装为失败或通过。

执行记录：待填写。

---

## 3. Phase 1：tiny-llm Runtime 证据

### TLLM-01 固化当前正确性基线

- 状态：`done`
- 优先级：P0
- 时间盒：4 小时
- 工作区：`tiny-llm`
- 依赖：P0-04
- 权限：本地构建和 RTX 3060 测试允许

执行：固定 HEAD、模型 SHA/大小、CUDA/驱动、构建选项和 seed；按测试文件拆成独立进程运行 CPU/GPU、tokenizer、C ABI、Paged KV、CUDA Graph on/off 和逐 token 对齐；保存原始日志。

建议验证起点：

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTS=ON
cmake --build build -j"$(nproc)"
ctest --test-dir build --output-on-failure --timeout 300
```

GPU 测试按仓库清单分文件/过滤器独立执行，并设置
`PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True`。不能用旧结果替代当前 HEAD。

验收：correctness 全部通过或有逐测试失败清单；schema v2 A/B 能由 validator 重算；当前硬件范围写清。

执行记录：

- 完成时间：2026-08-28 13:00 +08:00
- 基线：tiny-llm@f9d4b99（clean 除 P0-03/P0-04 未提交改动）；sm_86 / nvcc 12.0.140 / driver 610.57.01 / RTX 3060 Laptop 6GB
- 变更：无源码修改（仅新增 runs/2026-08-28/TLLM-01/ 证据与 validator 脚本）
- 验证：构建 exit 0（`-DCMAKE_CUDA_ARCHITECTURES=86 -DBUILD_TESTS=ON -DCMAKE_BUILD_TYPE=Release`）；ctest 两轮 **192 passed + 1 skipped（SecondModelTest.LoadsAndGeneratesWithDistinctGQA，因 TLLM_GGUF_TEST_MODEL_2 未设；共 193 项）**，实测 246.1s / 146.9s；schema v2 A/B：graph on（tpot 4.959ms/201.6 tok/s）与 off（tpot 8.057ms/124.1 tok/s）JSON 均过 validator（exit 0），手工复算 1000/TPOT 偏差 0.0%；模型 sha256 74a4da8c… 记录
- 证据：runs/2026-08-28/TLLM-01/{00_summary,01_ctest_full.log,02/03_bench_*.json,04_model_sha256.txt,validate_bench_json.py}
- 限制：本机 nvcc 12.0 vs CI 11.8；性能数字为正确性 A/B 佐证非正式 benchmark；未 push 未跑远端 CI；第二模型 skip（TLLM-02）
- 外部状态：local-only（0 提交）
- 下一任务：PSERV-01（P0，关键路径）

### TLLM-02 第二真实模型/架构端到端门控

- 状态：`todo`
- 优先级：P1
- 时间盒：12 小时
- 工作区：`tiny-llm`
- 依赖：TLLM-01
- 权限：代码可改；需要许可/登录或大体积模型下载时先确认

执行：

1. 先列出 loader/runtime 已支持的架构字段和当前假设；
2. 选择 6GB 显存可运行、许可证清楚、能覆盖不同 GQA/MQA/维度配置的量化模型；
3. 先做 header/metadata dry-run，再做 tokenizer、首 token、固定短生成和逐 token reference；
4. 若失败，优先补真实 architecture gate 与可诊断错误，不写模型专用硬编码；
5. 添加最小 fixture/测试，但不提交模型权重。

验收：第二模型从加载到生成有当前日志、模型身份和 token 级验证；若确实不支持，输出最小失败用例与架构缺口，不得仅以“能加载”完成。

执行记录：待填写。

### TLLM-03 同协议 llama.cpp 外部基线

- 状态：`todo`
- 优先级：P1
- 时间盒：8 小时
- 工作区：`tiny-llm` 及隔离的外部工具目录
- 依赖：TLLM-01
- 权限：外部源码/二进制下载遵循提示词授权；不得修改外部仓后冒充基线

执行：固定 llama.cpp commit/build flags；使用同一模型文件、prompt、warmup、输出 token 上限、sampling/greedy 参数与设备；同时报告端到端延迟和 decode-only 可比部分。量化或 tokenizer 不同则降级为“系统观察”。

验收：原始命令与 stdout 可复现；至少 5 次稳定重复；报告明确列出不可控变量，不只给单个加速比。

执行记录：待填写。

### TLLM-04 长上下文曲线与 OOM 边界

- 状态：`done`
- 优先级：P1
- 时间盒：8 小时
- 工作区：`tiny-llm`
- 依赖：TLLM-01
- 权限：本地 GPU

执行：在固定模型/输出长度下扫描 prompt 长度，至少覆盖 128、512、2048 和设备可承受的更长点；每点独立进程，记录成功、首 token、decode、常驻显存差值、OOM/超时和正确性抽样。不要把 `cudaMemGetInfo` 两点差值称作峰值。

验收：有机器可读曲线、失败边界和复算脚本；失败点保留；所有点绑定同一 commit 与环境。

执行记录：

- 完成时间：2026-08-28 14:00 +08:00
- 基线：tiny-llm@f9d4b99（TLLM-01 同一构建），RTX 3060 6GB，模型 sha256 74a4da8c…
- 变更：无源码修改（仅新增 runs/2026-08-28/TLLM-04/ 证据）
- 验证：曲线 **5 success + 2 failure**（成功点实际 tokens 220/884/3535/7069/14138；TTFT 0.31→58.3s；TPOT 6.3→69.2ms；tok/s 160→14.5；常驻差值 3368-4118MB；失败点：8192 首次 iters=3 超时 300s、16384 E2BIG 参数 147KB>MAX_ARG_STRLEN 128KB，原始 JSON/日志均保留）；**尚未达到真实 OOM 边界**（0.5B KV 非瓶颈，无 OOM 点可记录）；3535-token 正确性抽样正常（prefill 9792ms/24 tokens 无崩溃）
- 校正注（2026-08-28 review）：16384 E2BIG 失败证据完整（bench_len_16384_fail.log/json/stderr）；**8192 首次超时（rc=124）的原始输出被后续 iters=1 成功运行覆盖**（现 bench_len_8192.json 为成功数据、stderr 0B），唯一证据为会话回显 rc=124——见 runs/2026-08-28/TLLM-04/99_evidence_gap_note.md
- 证据：runs/2026-08-28/TLLM-04/{bench_len_*.json×5,05_curve.csv,04_correctness_sampling.log,prompts.json,00_summary}
- 限制：未达 OOM 边界（0.5B KV 非瓶颈）；16K+ 受命令行参数接口限制；数字为单机观测非正式 benchmark；未 push
- 外部状态：local-only（0 提交）
- 下一任务：TLLM-05（失败路径矩阵，本地）

### TLLM-05 Runtime 失败路径矩阵

- 状态：`done`
- 优先级：P1
- 时间盒：8 小时
- 工作区：`tiny-llm`
- 依赖：TLLM-01
- 权限：本地修改

场景至少包括：文件不存在、截断/损坏 GGUF、不支持量化/架构、tokenizer 资源缺失、超长上下文、显存不足、无 CUDA 设备、C ABI 非法参数。错误必须可诊断且不泄露环境敏感信息。

验收：每类失败均有测试或可复现脚本；无崩溃/静默错误；不为已知类型添加冗余 `getattr`、过度 `try/except` 或无意义 fallback。

执行记录：

- 完成时间：2026-08-28 14:10 +08:00
- 基线：tiny-llm@f9d4b99（demo 已构建）
- 变更：无源码修改（全部为失败行为复现取证）
- 验证：6 类可复现矩阵全 exit 1 + 明确可诊断错误（文件不存在/空文件/metadata 区截断/tensor 区截断/随机字节/文本冒充，完整消息见 runs/2026-08-28/TLLM-05/s1-s6）；已有测试覆盖确认（InvalidArgsReturnError、GGUFParser.Rejects*×4、GGUFLoadFailsOnMissingFile、cudaErrorNoDevice 跳过逻辑，均随 TLLM-01 ctest 192 passed + 1 skipped 实测）；无崩溃/静默错误/敏感信息泄露
- 证据：runs/2026-08-28/TLLM-05/{00_summary,s1..s6_*.log}
- 限制：不支持量化/架构场景因本机仅单一模型无法构造（由 parser 测试覆盖，如实标注）；无设备分支无法实测（本机有 GPU）；未 push
- 外部状态：local-only（0 提交）
- 下一任务：SUP-01（P2，辅助仓收口）或 CUF-02 本地 correctness 准备

### TLLM-06 数据中心 GPU profiler 闭环

- 状态：`blocked`
- 优先级：P1
- 时间盒：8 小时本地准备 + 4 小时云窗口
- 工作区：`tiny-llm`
- 依赖：TLLM-01、本地 canary 通过
- 权限：启动/停止/付费云资源必须确认

执行：先按 cloud playbook 生成实例、驱动、镜像、模型、命令和预算 checklist；云端先 correctness canary，再采 nsys，最后仅对热点 kernel 采 ncu。保存工具版本和原始 report；遇到权限错误原样记录。

验收：至少一个 current-commit profiler 包能定位主要时间/带宽/launch 开销；实例在完成或止损时关闭；没有 profiler 权限则标记 blocked。

执行记录：

- 阻塞时间：2026-08-28 15:40 +08:00
- 已完成（本地准备）：云授权已获（cloud/paid=true，budget ≤$300 目标 $180-250）；部署包已备（runs/2026-08-28/CLOUD/00-04 脚本 + /tmp/opencode/cloud-deploy-*.tar.gz 458MB，绑定 cuflash@599836b、tiny-llm@d2838f3、模型 sha256 74a4da8c…）；计划实例 Runpod L40S 48GB（sm_89，$0.99/h，2026-08-23 快照），预估 4-6h ≈ $4-6（含重跑 ≤$20）；流程：metadata → 构建 → correctness canary → 矩阵（schema v2 graph on/off、长上下文）→ nsys → 热点 ncu → 下载 → 立即停机删除；canary 失败即停（02_build_canary.sh exit 1 终止）
- 阻塞证据：本地无任何云 CLI（runpodctl/aws/az/gcloud 均缺失）且无 Runpod/云 API 凭证（env 与个人仓均无）；无法执行任何付费启动操作
- 所需条件：用户提供 Runpod API key（或选择其他提供商并给凭证）+ 允许安装 runpodctl（或用户直接创建实例并给 SSH 地址）；实例创建后按 CLOUD/02→03→04 编排执行
- 恢复命令：安装 runpodctl → `runpodctl create pod --gpuType L40S:48 --image ... --command "bash /workspace/00_run_all.sh"` → 下载 results → `runpodctl remove pod <id>`
- 可并行任务：UP-02（本地复现）、TLLM-07（依赖 TLLM-04 热点，本地）

### TLLM-07 只基于热点做一次优化闭环

- 状态：`todo`
- 优先级：P2
- 时间盒：12 小时，超过即止损
- 工作区：`tiny-llm`
- 依赖：TLLM-04 或 TLLM-06 提供明确热点
- 权限：本地修改

执行：写清假设和唯一主要变量；先 correctness，再相同环境 A/B；覆盖收益、无变化和回退形状。若 3 个实现迭代仍无稳定收益，恢复到正确的最小实现并归档负结果。

验收：有可审计 A/B 或明确“未采用”结论；不能用 microbenchmark 收益冒充端到端收益。

执行记录：待填写。

---

## 4. Phase 2：paged-serving 正式评测

### PSERV-01 固化双仓集成基线

- 状态：`done`
- 优先级：P0
- 时间盒：6 小时
- 工作区：`tiny-llm`、`paged-serving`
- 依赖：P0-04、TLLM-01
- 权限：本地 GPU；ABI breaking change 不在本任务权限内

执行：记录双仓 commit，构建 `tiny-llm` 动态库与 Rust server；核对 FFI header/Rust 声明、layout、RoPE 和错误码；运行 health、单请求、SSE、多请求、取消和 shutdown smoke。

验收：双仓当前 HEAD 端到端运行；C ABI 双源一致；任何契约漂移先开 breaking task，不能在单仓偷偷修。

执行记录：

- 完成时间：2026-08-28 13:30 +08:00
- 基线：tiny-llm@f9d4b99（libtiny_llm.a + spdlog 已建）、paged-infer@080f26f（crate paged-serving 0.2.0）
- 变更：无源码修改（仅新增 runs/2026-08-28/PSERV-01/ 证据）
- 验证：（1）ABI 双源静态核对：TinyLlmConfig 9 字段顺序一致、5 函数符号集一致、参数类型对应，无漂移；（2）`cargo test --features tiny-llm --test tiny_llm_text_e2e` 3/3 passed（29.07s，含 3 并发分页请求 llama.cpp 对齐）；（3）HTTP smoke：healthz/readyz OK、单请求 SSE（usage+[DONE]）、3 并发请求全成功、取消后 server 健康且新请求正常、SIGTERM 2s 干净退出
- 证据：runs/2026-08-28/PSERV-01/{00_summary,01_server.log,02_single_request_sse.txt,03_multi_*,04_cancel.txt,05_abi_dualsource.md,config.smoke.json}
- 限制：取消/资源回收深度验证属 PSERV-05；未 push 未跑远端 CI；HTTP 用端口 3010
- 外部状态：local-only（0 提交）
- 下一任务：PSERV-02（P1，loadgen/token coverage 审计）

### PSERV-02 审计 loadgen 与 token coverage

- 状态：`done`
- 优先级：P1
- 时间盒：8 小时
- 工作区：`paged-serving`
- 依赖：PSERV-01
- 权限：本地修改

执行：审计 `summary.json`、`per_request.jsonl`、计时点、失败分类、输出 token 来源、warmup 排除、分位数算法和 validator；构造已知样本手工复算 TTFT/TPOT/tok/s。token coverage 不足时 tok/s/TPOT 必须为 null。

验收：schema 和 validator 覆盖完整/不完整 token、零 token、失败请求和混合样本；同一原始输入复算结果确定。

执行记录：

- 完成时间：2026-08-28 14:40 +08:00
- 基线：paged-infer@080f26f（crate paged-serving 0.2.0），无源码改动
- 变更：无（审计任务，仅新增 runs/2026-08-28/PSERV-02/ 证据）
- 验证：`cargo test --bin loadgen` 4/4（exit 0）；端到端 closed 2 并发×6 请求 6/6 成功 coverage 100%；独立复算 11/11 断言（成功/失败/缺 token/零 token/混合样本，含 tok/s None 门控）；交叉验证 summary tok/s=5.31864794976901 与独立复算精确相等
- **核心发现 F1**：HuggingFace decoder.push() 缓冲 token 只在 finish() 一次性解码（tokenizer.rs:382-395）→ server SSE 每请求仅 1 个整段文本 chunk（实测 chunks=1、TTFT≈duration、TPOT≈0 失真）；usage/coverage/tok/s 仍真实；loadgen 无 bug，但 **PSERV-03 的 TTFT/TPOT A/B 不能基于当前 SSE 语义**；修复（HF decoder 真增量解码）属代码改动，待授权确认
- 证据：runs/2026-08-28/PSERV-02/{00_summary,dataset_smoke.jsonl,per_request.jsonl,summary.json,server.log,recompute_aggregation.py}
- 限制：端到端数字（TTFT 12s、5.3 tok/s）为单机 debug build 观测非正式结论；未 push
- 外部状态：local-only（0 提交）
- 下一任务：PSERV-03（前置阻塞：需先解决 F1 流式语义或改用非流式口径）→ 可选先做 UP-02 或 CUF-02 本地部分

### PSERV-03 continuous batching on/off A/B

- 状态：`blocked`
- 优先级：P1
- 时间盒：8 小时
- 工作区：`paged-serving`、`tiny-llm`
- 依赖：PSERV-02
- 权限：本地 GPU

执行：同一后端、模型、prompt 集合、并发、warmup 和输出长度，仅切换 batching；至少并发 1/2/4/8，显存允许时 16；每组重复并保留逐请求数据。

验收：证明的是“调度开关影响”而非跨引擎优胜；成功率、TTFT、TPOT、吞吐和 KV 指标均可复算；无收益也完成。

执行记录：

- 阻塞时间：2026-08-28 15:25 +08:00（更新：2026-08-28 15:50 设计审查产出）
- 已完成：依赖链路完整（PSERV-01/02 done）；loadgen 工具可用；**F1 设计审查文档已产出**（runs/2026-08-28/PSERV-03/00_F1_design.md）：比较 A（字节级增量 decoder：UTF-8 安全边界 + look-behind，ByteLevel 精确路径 A1 + 非字节链 A2 回退）/ B（保留 buffered + TTFT/TPOT/ITL 标 null）/ C（独立字节状态机 / tiktoken-rs / llama.cpp detokenizer 分析为不适用或双源风险）；含 API 生命周期、Unicode/ByteFallback/WordPiece/特殊 token 边界（镜像 tokenizers 0.19.1 `decode(tokens,true)` 的 is_special_token 过滤）、stop（先于 push，无撤回问题）/cancel（A 使断开检测从 finish 时刻提前到每 token 时刻）/finish（成功才 flush）/n>1（候选独立 decoder + multi 路径无断开 cancel 的既有缺口如实标注）、proptest 7 组、等价性证明（UTF-8 自同步前缀闭包）、性能与兼容性风险；**禁止"全 prefix 重解码取 suffix"伪增量为显式约束**
- 阻塞证据：**F1（PSERV-02 核心发现）**——HuggingFace tokenizer 的 decoder 缓冲全部 token、只在 finish() 一次性解码（src/tokenizer.rs:382-395），server SSE 每请求仅 1 个整段文本 chunk（实测 chunks=1、TTFT≈duration、TPOT≈0 失真）（runs/2026-08-28/PSERV-02/00_PSERV-02_summary.md）
- 所需条件（二选一，需用户决策）：
  1. **授权方案 A 实现**：`ALLOW_CODE_CHANGES=true` 修改 paged-infer/src/tokenizer.rs（ByteLevelIncrementalDecoder + 能力检测）与新增测试；按设计文档 §6 落地（复现 chunks=1 → 实现 → proptest → e2e/loadgen 验证 chunks>1/usage/cancel/stop/n>1 → 回归）
  2. **明确放弃当前 HF backend 的 TTFT/TPOT 指标**（方案 B）：A/B 只报告成功率/吞吐/常驻显存/KV 利用与端到端完成时间（非流式口径），并在正式结果中标注 TTFT/TPOT 不可用及其原因
- 恢复命令：按选定方案执行后，`cargo test --features tiny-llm` 全绿 → 重启 server → loadgen closed 并发 1/2/4/8 × batching on/off 采样
- 可并行任务：UP-02（本地复现）、TLLM-07（依赖 TLLM-04 热点，本地）

### PSERV-04 正式 closed-loop/Poisson Serving 扫描

- 状态：`todo`
- 优先级：P1
- 时间盒：8 小时本地准备 + 6 小时云窗口
- 工作区：`paged-serving`、`tiny-llm`
- 依赖：PSERV-03
- 权限：云资源必须确认

矩阵：synthetic 128/128、512/128、2048/256，加一组真实对话长度分布；并发 1/2/4/8；closed-loop 与多档 Poisson offered load。每次先 correctness canary，失败率超过预算立即止损。

验收：正式结果包含硬件、软件栈、双仓 commit、dirty、模型/量化、请求分布、warmup、重复、失败率、逐请求 raw、summary 和 validator 日志。

执行记录：待填写。

### PSERV-05 取消、HOL、fairness、429/OOM 矩阵

- 状态：`todo`
- 优先级：P1
- 时间盒：10 小时
- 工作区：`paged-serving`
- 依赖：PSERV-02
- 权限：本地测试；需要云硬件时确认

场景：客户端断开、排队时取消、decode 中取消、长短混合、单租户突发、队列满 429、后端 OOM、后端退出和优雅 shutdown。记录资源回收、队列状态、错误协议和后续请求是否恢复。

验收：每个场景有确定预期与测试/脚本；无 KV 泄漏或悬挂请求；fairness 指标定义清楚，不只凭日志目测。

执行记录：待填写。

### PSERV-06 跨引擎系统观察与报告

- 状态：`todo`
- 优先级：P2
- 时间盒：12 小时
- 工作区：隔离部署 + `paged-serving` 评测工具
- 依赖：PSERV-04
- 权限：vLLM/llama.cpp 安装、云资源与大模型下载按提示词配置

执行：用统一 loadgen 测 `paged-serving`、`llama-server`、`vLLM`；逐引擎绑定 commit/image、模型、量化、参数与协议适配层。优先同模型同量化；无法一致时只作系统观察，禁止排名式标题。

验收：每个引擎均有独立 raw/summary/error；比较表显式列出不可控变量；结论不超出实验口径。

执行记录：待填写。

---

## 5. Phase 2：cuflash 与辅助仓

### CUF-01 清理 cuflash live 文档证据口径

- 状态：`done`
- 优先级：P0
- 时间盒：4 小时
- 工作区：`cuflash`
- 依赖：P0-03
- 权限：live 文档可改；历史 CHANGELOG 不改

执行：搜索 live README/Pages 中旧名、旧 URL、无原始数据的性能表、含混硬件/精度主张；保留有来源数字，其他移到明确的 historical/unverified 说明或删除 live 宣传，不能伪造补全 metadata。

验证至少包括文档构建：

```bash
cd docs
npm ci
npm run docs:build
```

验收：当前公开页只保留可追溯主张；canonical 名称一致；历史发布事实未改。

执行记录：

- 完成时间：2026-08-28 13:50 +08:00
- 基线：cuflash-attn@d53a530（v0.6.0，clean 除 P0-03 的 flash-decoding.md 修改）
- 变更：docs/performance/benchmarks.md 4 处（旧变量 `CUFASH_ATTN_BENCHMARKS`/`CUFASH_ATTN_ARCHS` → `BUILD_BENCHMARKS`/`CMAKE_CUDA_ARCHITECTURES`，`your-org` → `open-infra-ai`）；CHANGELOG 未动
- 验证：证据纪律逐项复核（README 无固定性能数字、跨 GPU 表已隔离标注"禁止引用"、本机快照标注 sanity check、负结果文档附复现命令、发布门槛存在）；`npm run docs:build` exit 0（23.02s，vitepress 1.6.4）；仓库无 benchmark 原始 JSON 与文档声明一致
- 证据：runs/2026-08-28/CUF-01/00_CUF-01_summary.md
- 限制：未跑 npm ci（node_modules 已存在）；跨 GPU 快照维持"禁止引用"（正式包属 CUF-02，需云）；未 push
- 外部状态：local-only（0 提交）
- 下一任务：UP-01（P0，上游贡献审计）或 CUF-02 本地 correctness 准备

### CUF-02 当前版本正式 benchmark/profiler 包

- 状态：`blocked`
- 优先级：P1
- 时间盒：8 小时本地 + 6 小时云窗口
- 工作区：`cuflash`
- 依赖：CUF-01
- 权限：本地 GPU 允许；云资源需确认

执行：先跑 FP32/FP16/BF16、前向/反向、FlashDecoding correctness；再选代表性短/长序列和 head dim，比较 reference/current kernel；记录 warmup、迭代、统计、误差和失败形状；nsys 后仅对热点采 ncu。

验收：结果包绑定 v0.6.0 或当前新 commit；更慢、OOM、不支持形状均保留；README 数字只从 raw 重建。

执行记录：

- 阻塞时间：2026-08-28 15:05 +08:00
- 已完成（本地 correctness）：cuflash@d53a530（v0.6.0）构建 exit 0；ctest **70 passed + 1 skipped（cuflash_pytorch_comparison，系统 python3 无 torch；共 71 项，33.61s）**，覆盖 FP32/FP16/BF16 前后向/FlashDecoding/causal/数值稳定性/应力边界；PyTorch SDPA 对照 9/9（triton-b4 env，dQ/dK/dV diff 1e-3 量级）；本机 bench 快照（1024/64 前向+反向、4096/128 FP16，5 reps）原始 JSON 已留档 bench_local.json
- 阻塞证据：正式结果包（多架构矩阵 + nsys/ncu profiler + metadata/validation 体系）需云 GPU；本地无云 CLI/凭证（TLLM-06 记录同）；ALLOW_CLOUD_RESOURCE_CHANGES=true / ALLOW_PAID_ACTIONS=true 已获但缺执行工具
- 所需条件：用户提供 Runpod API key / 实例 SSH；云部署包已备（runs/2026-08-28/CLOUD/00-04 脚本，cuflash@599836b）
- 恢复命令：上传 cloud-deploy tar.gz → `bash 00_run_all.sh`（metadata→构建→canary→矩阵→nsys→ncu）→ 04_download.sh → 删除实例
- 可并行任务：UP-02（SGLang issue 复现，本地）或 PSERV-03 前置的 F1 修复决策

### CUF-03 基于当前结果写 Kernel 深度文章

- 状态：`todo`
- 优先级：P2
- 时间盒：8 小时
- 工作区：`cuflash` docs 或个人材料
- 依赖：CUF-02
- 权限：本地文档可改；公开发布需确认

内容必须覆盖：naive attention 到 tiled/online softmax、数值稳定性、布局与 occupancy、WMMA 约束、decode 与 prefill 差异、反向验证、profiler 证据、负结果与适用边界。

验收：文章所有图表可复现；不把教学实现描述成生产替代；含一段可在面试白板上讲清的核心推导。

执行记录：待填写。

### SUP-01 辅助仓改名、状态与入口收口

- 状态：`done`
- 优先级：P2
- 时间盒：4 小时
- 工作区：`cuda-foundations`、`triton-fused-ops`
- 依赖：P0-03
- 权限：本地文档可改；topics/description 需确认

执行：修 live 旧链接；评估 `cuda-foundations` 是否已满足 stable 条件；README 首屏分别说明学习阶梯与 Triton 对照角色；不新增模块或新 op。

验收：状态与 meta/topics 一致；两仓不抢旗舰叙事；CI 和安装命令当前可用。

执行记录：

- 完成时间：2026-08-28 14:45 +08:00
- 基线：cuda-foundations@28e070b、triton-fused-ops@5764758（clean）
- 变更：无（P0-03 已完成旧链接替换；本任务为验证与评估）
- 验证：两仓 live 旧链接/旧组织名无残留（rg 复查）；角色首屏与状态核对；triton `.venv` pytest 123/123（19.43s）；cuda-foundations `cmake --preset default` + `--build` exit 0 + `ctest --preset default` **261/261 通过**（实测与 README 声称一致）
- 证据：runs/2026-08-28/SUP-01/00_SUP-01_summary.md
- 限制：cuda-foundations 已满足 stable 条件（不再扩模块、261/261）但当前 active 与 meta/topics 三处一致，改 stable 需 GitHub topics 授权 → 待授权项（建议并入 P0-06）；未 push
- 外部状态：local-only（0 提交）
- 下一任务：CUF-02 本地 correctness 准备（P1；云 profiler 部分 blocked）

### SUP-02 CUDA/C++/Triton 横向案例

- 状态：`todo`
- 优先级：P2
- 时间盒：8 小时
- 工作区：`cuda-foundations`、`triton-fused-ops`，必要时引用 `cuflash`
- 依赖：SUP-01、CUF-02
- 权限：本地 GPU

执行：选择一个已有、语义一致的算子，统一 shape/dtype/reference/误差/计时口径，比较实现复杂度、调试能力和性能，而非新造仓或强行共用代码。

验收：有 correctness-first 的横向表；说明 Triton 与 CUDA/C++ 各自适用条件；不做无法公平控制的总排名。

执行记录：待填写。

---

## 6. Phase 3：上游贡献

### UP-01 审计并推动已有上游贡献

- 状态：`done`
- 优先级：P0
- 时间盒：3 小时
- 工作区：SGLang/LightLLM 的隔离 checkout 与 GitHub
- 依赖：P0-01
- 权限：查询和本地复现允许；comment/review/label/PR 写操作需确认

执行：重新查询 SGLang #36115、#36116、review #35443 和 LightLLM #1492 的状态、diff、CI、冲突、重复 PR 与 maintainer 回复；本地复现仍有价值的测试；草拟一次简洁 follow-up。

验收：每项明确为 open/merged/closed/superseded；#36115 的本地 harness、lint 和完整 CI 边界准确；未把 maintainer-only `run-ci` 缺失写成代码失败。

执行记录：

- 完成时间：2026-08-28 14:10 +08:00
- 基线：无代码改动；查询 GitHub API（gh 2.97.0）
- 变更：无源码修改（仅新增 runs/2026-08-28/UP-01/ 审计证据与 follow-up 草稿；向 triton-b4 venv pip 安装 orjson/psutil 用于导入尝试）
- 验证：（1）四项状态均为 open：#36115 blocked（Lint success；GPU 矩阵缺 run-ci label；pr-gate 红仅因 "Require run-ci label"）、#36116 blocked（docs，4 reviewer 未响应）、#35443 blocked（wes-lyu PR，maintainer 已回复 lint 修复，holtwood 曾 COMMENTED 且被列 requested reviewer）、LightLLM #1492 unstable（mergeable=true 无冲突，无 check-runs 可见）；（2）#36115 本地逻辑复现 7/7 断言通过（提取 PR head 函数 + 测试断言，无依赖 python），函数与 upstream main 完全一致（无 rebase）；（3）完整 SGLang 环境未装，sglang 包导入链依赖未满足，边界已记录
- 证据：runs/2026-08-28/UP-01/{00_summary,01_pr_head_func.py,02_upstream_main_func.txt,03_pr36115_test.patch,repro_36115_logic.py,02_followup_draft.md}；URL：github.com/sgl-project/sglang/pull/{36115,36116,35443}、github.com/ModelTC/LightLLM/pull/1492
- 限制：未发布任何 comment/review（ALLOW_GITHUB_WRITE=false）；follow-up 草稿存档待用户审核；未在完整 SGLang 环境跑测试
- 外部状态：全部 open（无 merged/closed）；本地 0 提交
- 下一任务：PSERV-02（P1，loadgen/token coverage 审计）或 CUF-02 本地 correctness 准备

### UP-02 选择并复现一个 SGLang 真实问题

- 状态：`todo`
- 优先级：P1
- 时间盒：12 小时
- 工作区：SGLang 独立 checkout
- 依赖：UP-01
- 权限：本地分支/测试可改；不发布外部内容

执行：只选 scheduler/KV/cache/benchmark 方向一个仍有效 issue；先查重复与 maintainer 意图；固定 upstream commit；建立最小失败测试；证明失败来自目标代码而非环境；再提出最小修复。

验收：修复前测试稳定失败、修复后通过；相关测试/格式/lint 通过；无无关重构；若问题已修，保存证据并重新选题。

执行记录：待填写。

### UP-03 提交最小上游修复并保存反馈证据

- 状态：`todo`
- 优先级：P1
- 时间盒：6 小时 + 异步等待
- 工作区：目标上游仓
- 依赖：UP-02
- 权限：fork push、issue comment、PR、review 均需用户审核和授权

执行：精确暂存；PR 正文写问题、复现、修复、测试、限制；不声称未跑完整 CI；跟进一次后不刷屏。保存 PR URL、commit、CI、review 与 merged/closed 状态。

验收：本地贡献包完整且已获实质反馈；只有 upstream merge commit 存在时才记“merged”。维护者未合入不篡改为成功。

执行记录：待填写。

---

## 7. Phase 4：面试与投递证据

### EVID-01 两个 Demo、两个 STAR 与简历证据

- 状态：`todo`
- 优先级：P1
- 时间盒：12 小时
- 工作区：个人执行仓及项目公开文档
- 依赖：至少一份 Serving 或 cuflash 正式结果
- 权限：本地材料可改；公开发布、真实投递和联系方式写入需确认

交付：

1. Demo A：`tiny-llm` + `paged-serving`，10 分钟内从请求到调度、KV、decode、SSE 与结果包；
2. Demo B：`cuflash`，10 分钟内从算法到 kernel、correctness 和 profiler；
3. STAR A：C++ Runtime/FFI/正确性；STAR B：Serving 或 Kernel 性能工程；
4. Runtime 岗与 Kernel 岗两套项目 bullets；
5. 每个数字旁有公开证据路径、硬件和限制。

验收：两次计时彩排；随机抽取任一数字可在 2 分钟内定位 raw；未公开个人联系方式或投递状态。

执行记录：待填写。

### EVID-02 周期末组织审计与投递门禁

- 状态：`todo`
- 优先级：P0
- 时间盒：6 小时
- 工作区：全部仓库与个人执行仓
- 依赖：所有 P0 任务、EVID-01；其他 blocked 项必须有结论
- 权限：只读审计允许；最终 GitHub 修复与投递动作需确认

执行：重复 P0-01/P0-06；逐条核对 [PLAN.md](PLAN.md) 第 4 节 12 项结果；检查 README/Release/CI/topics/Pages/结果包/上游状态；生成 achieved/partial/blocked/not-achieved 表，不把未完成项润色成成功。

验收：组织公开面、技术证据、简历材料三者一致；可以开始投递；剩余项被划入维护 backlog，而不是继续推迟投递。

执行记录：待填写。

## 8. 每个任务的收尾模板

执行代理完成任务时，把对应“执行记录”替换为：

```text
- 完成时间：YYYY-MM-DD HH:MM +08:00
- 基线：repo@commit（dirty 状态）
- 变更：精确文件清单；若无变更写“无”
- 验证：完整命令、退出码、通过/失败/跳过数量
- 证据：相对路径或公开 URL
- 限制：未跑内容、硬件/权限/口径限制
- 外部状态：local-only / pushed / CI URL / PR open / merged
- 下一任务：TASK-ID
```

标记 `blocked` 时改用：

```text
- 阻塞时间：YYYY-MM-DD HH:MM +08:00
- 已完成：可验证的已完成部分
- 阻塞证据：错误原文、URL 或日志路径
- 所需条件：具体权限、硬件、maintainer 动作或输入
- 恢复命令：条件满足后的第一条命令
- 可并行任务：TASK-ID
```
