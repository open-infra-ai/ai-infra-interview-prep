#!/usr/bin/env bash
# 云部署包 - 04 结果下载（关机前最后一步，在本地运行）
# 用法：
#   INSTANCE_HOST=1.2.3.4 INSTANCE_PORT=22 INSTANCE_USER=root INSTANCE_KEY=/path/id_ed25519 \
#     bash 04_download.sh [远程结果目录] [本地目标目录]
#
# 安全：保留 host key 校验（accept-new：首次信任并记录，之后严格校验）；
# 密钥路径只用于 ssh/scp -i，绝不打印、不回显密钥内容。
set -uo pipefail

INSTANCE_HOST="${INSTANCE_HOST:?需设置 INSTANCE_HOST}"
INSTANCE_USER="${INSTANCE_USER:-root}"
INSTANCE_PORT="${INSTANCE_PORT:-22}"
INSTANCE_KEY="${INSTANCE_KEY:-$HOME/.ssh/id_ed25519}"
REMOTE_DIR="${1:-/workspace/results}"
DEST_DIR="${2:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/results}"   # 默认落在脚本同级的 results/

[ -f "$INSTANCE_KEY" ] || { echo "错误：密钥文件不存在 $INSTANCE_KEY"; exit 1; }
[ -r "$INSTANCE_KEY" ] || { echo "错误：密钥不可读（请检查权限）"; exit 1; }

SSH_COMMON=(-o "StrictHostKeyChecking=accept-new" -o "UserKnownHostsFile=$HOME/.ssh/known_hosts" -p "$INSTANCE_PORT" -i "$INSTANCE_KEY")

echo "== 检查远端 STATUS/FAILURE =="
ssh "${SSH_COMMON[@]}" "$INSTANCE_USER@$INSTANCE_HOST" "cat $REMOTE_DIR/STATUS.json 2>/dev/null || echo NO_STATUS" || echo "（ssh 检查失败，仍尝试下载原始产物）"

echo "== 下载（scp 不打印密钥）=="
mkdir -p "$DEST_DIR"
scp "${SSH_COMMON[@]}" -r "$INSTANCE_USER@$INSTANCE_HOST:$REMOTE_DIR/" "$DEST_DIR/" || { echo "下载失败"; exit 1; }

echo "== 下载完成，本地校验 =="
du -sh "$DEST_DIR"
python3 - "$DEST_DIR" << 'PYEOF'
import json, glob, os, sys
d = sys.argv[1]
files = sorted(glob.glob(f"{d}/**/*", recursive=True))
print(f"文件数: {len(files)}")
if os.path.exists(f"{d}/STATUS.json"):
    s = json.load(open(f"{d}/STATUS.json"))
    print("远端 overall:", s.get("overall"))
PYEOF

echo "== 下一步（人工/授权后执行，本脚本不自动执行）=="
echo "  1) 删除/停止实例（runpodctl remove pod <id>）"
echo "  2) 核对 Runpod 账单页"
echo "  3) 若 STATUS overall=FAILURE：按 STATUS.json 逐项修复后重跑，不得把失败写成成功"