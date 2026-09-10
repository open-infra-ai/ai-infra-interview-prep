#!/usr/bin/env bash
# 云部署包 - 01 本地打包（开机前阶段）
# 产出：扁平 bundle，解压后即 /workspace 布局：
#   /workspace/00_run_all.sh 01_pack_local.sh 02_build_canary.sh 03_formal_matrix.sh 04_download.sh
#   /workspace/src/cuflash /workspace/src/tiny-llm /workspace/models
#   /workspace/VERSIONS.txt /workspace/manifest.json
set -euo pipefail

BUNDLE_STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="/tmp/opencode/cloud-bundle-${BUNDLE_STAMP}"
TARNAME="/tmp/opencode/cloud-bundle-${BUNDLE_STAMP}.tar.gz"
mkdir -p "$OUT/src/cuflash" "$OUT/src/tiny-llm" "$OUT/models"
RUN="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # 相对脚本自身定位，不依赖仓库绝对路径

echo "== 源码（git archive，tracked-only，天然排除 .git/.zcode/build/凭据）=="
git -C /home/shane/github/open-infra-ai/cuflash archive --format=tar HEAD | tar -x -C "$OUT/src/cuflash"
git -C /home/shane/github/open-infra-ai/tiny-llm archive --format=tar HEAD | tar -x -C "$OUT/src/tiny-llm"
echo "  排除校验："
find "$OUT" -name '.git' -o -name '.zcode' -o -name '*.gguf' | head -5 || true
echo "  (src 内不应出现上述路径；模型只放 /workspace/models)"

echo "== 脚本（5 个部署脚本扁平放入顶层）=="
cp "$RUN/00_run_all.sh" "$RUN/02_build_canary.sh" "$RUN/03_formal_matrix.sh" "$RUN/04_download.sh" "$OUT/"
cp "$RUN/01_pack_local.sh" "$OUT/01_pack_local.sh"

echo "== 模型（本地上传，云端不重新下载）=="
cp /home/shane/github/open-infra-ai/models/qwen2.5-0.5b-instruct-q4_k_m.gguf "$OUT/models/"
cp /home/shane/github/open-infra-ai/models/tokenizer.json "$OUT/models/"

echo "== 版本与校验（VERSIONS.txt + 独立 manifest.json）=="
GGUF_SHA=$(sha256sum /home/shane/github/open-infra-ai/models/qwen2.5-0.5b-instruct-q4_k_m.gguf | cut -d' ' -f1)
TOK_SHA=$(sha256sum /home/shane/github/open-infra-ai/models/tokenizer.json | cut -d' ' -f1)
CUF_SHA=$(git -C /home/shane/github/open-infra-ai/cuflash rev-parse HEAD)
TLLM_SHA=$(git -C /home/shane/github/open-infra-ai/tiny-llm rev-parse HEAD)
# dirty 状态在打包时刻记录（云端为 tar 展开，无法复算 git 状态）
CUF_DIRTY=$(git -C /home/shane/github/open-infra-ai/cuflash status --porcelain | { grep -v '^??' || true; } | wc -l)
TLLM_DIRTY=$(git -C /home/shane/github/open-infra-ai/tiny-llm status --porcelain | { grep -v '^??' || true; } | wc -l)
REMOTE_CUF=$(git -C /home/shane/github/open-infra-ai/cuflash rev-parse origin/master)
REMOTE_TLLM=$(git -C /home/shane/github/open-infra-ai/tiny-llm rev-parse origin/master)
PACK_TIME=$(date -u +%Y-%m-%dT%H:%M:%SZ)
{
  echo "cuflash_commit=$CUF_SHA"
  echo "tiny_llm_commit=$TLLM_SHA"
  echo "gguf_sha256=$GGUF_SHA"
  echo "tokenizer_sha256=$TOK_SHA"
  echo "bundle_sha256=见同目录 cloud-bundle-${BUNDLE_STAMP}.manifest.json"
  echo "pack_time=$PACK_TIME"
} > "$OUT/VERSIONS.txt"

# tar 内 manifest（bundle sha 在 tar 后回填，tar 内版本该字段为 null）
python3 - "$OUT" "$CUF_SHA" "$TLLM_SHA" "$GGUF_SHA" "$TOK_SHA" "null" "$BUNDLE_STAMP" "$CUF_DIRTY" "$TLLM_DIRTY" "$REMOTE_CUF" "$REMOTE_TLLM" "$PACK_TIME" "$TARNAME" << 'PYEOF'
import json, sys
out, c, t, g, tok, bundle, stamp, cd, td, rc, rt, pack, tarname = sys.argv[1:]
m = {
  "schema_version": 1,
  "pack_time_utc": pack,
  "bundle_stamp": stamp,
  "bundle_file": tarname.split("/")[-1],
  "commits": {
    "cuflash": c, "cuflash_origin_master": rc, "cuflash_clean_tracked_changes": int(cd),
    "tiny_llm": t, "tiny_llm_origin_master": rt, "tiny_llm_clean_tracked_changes": int(td),
  },
  "hashes": {"gguf_sha256": g, "tokenizer_sha256": tok, "bundle_sha256": bundle},
  "cloud_scope": ["CUF-02", "TLLM-06"],
  "excluded": [".git", ".zcode", "build/", "target/", "*.gguf-in-src", "credentials"],
}
open(f"{out}/manifest.json", "w").write(json.dumps(m, ensure_ascii=False, indent=2))
PYEOF

echo "== 打包 =="
tar -czf "$TARNAME" -C "$OUT" .

echo "== bundle sha 回填（tar 旁权威 manifest）=="
BUNDLE_SHA=$(sha256sum "$TARNAME" | cut -d' ' -f1)
python3 - "$OUT" "$TARNAME" "$CUF_SHA" "$TLLM_SHA" "$GGUF_SHA" "$TOK_SHA" "$BUNDLE_SHA" "$BUNDLE_STAMP" "$CUF_DIRTY" "$TLLM_DIRTY" "$REMOTE_CUF" "$REMOTE_TLLM" "$PACK_TIME" << 'PYEOF'
import json, sys
out, tarname, c, t, g, tok, bundle, stamp, cd, td, rc, rt, pack = sys.argv[1:]
m = {
  "schema_version": 1,
  "pack_time_utc": pack,
  "bundle_stamp": stamp,
  "bundle_file": tarname.split("/")[-1],
  "commits": {
    "cuflash": c, "cuflash_origin_master": rc, "cuflash_clean_tracked_changes": int(cd),
    "tiny_llm": t, "tiny_llm_origin_master": rt, "tiny_llm_clean_tracked_changes": int(td),
  },
  "hashes": {"gguf_sha256": g, "tokenizer_sha256": tok, "bundle_sha256": bundle},
  "cloud_scope": ["CUF-02", "TLLM-06"],
  "excluded": [".git", ".zcode", "build/", "target/", "*.gguf-in-src", "credentials"],
}
text = json.dumps(m, ensure_ascii=False, indent=2)
open(f"{tarname}.manifest.json", "w").write(text)   # 权威清单（tar 旁）
PYEOF
echo "== 产物：$TARNAME =="
du -sh "$TARNAME"
echo "-- VERSIONS.txt --"
cat "$OUT/VERSIONS.txt"
echo "-- 权威 manifest.json（tar 旁）--"
cat "${TARNAME}.manifest.json" | head -22
echo
echo "== 本地 git 与远端一致性 =="
echo "cuflash:  local=$CUF_SHA  origin/master=$REMOTE_CUF  tracked-dirty=$CUF_DIRTY"
echo "tiny-llm: local=$TLLM_SHA  origin/master=$REMOTE_TLLM  tracked-dirty=$TLLM_DIRTY"