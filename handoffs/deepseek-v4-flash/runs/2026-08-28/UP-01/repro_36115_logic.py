#!/usr/bin/env python3
"""UP-01 本地逻辑复现：SGLang PR #36115 测试断言 × 被测函数实现（无 sglang 依赖）。

来源：
- 函数：PR head 9c449782 的 allocation_sizing.py page_aligned_decode_alloc_lens
  （已验证与 upstream main 完全一致）
- 测试：PR #36115 的 test_allocation_sizing.py 全部断言（gh api 拉取）

边界：仅验证函数-测试逻辑一致性，不验证 sglang 包导入/CI 容器环境。
"""
import sys
from pathlib import Path
from types import SimpleNamespace

# 相对脚本自身定位，避免依赖仓库的绝对克隆路径
func_src = (Path(__file__).resolve().parent / "01_pr_head_func.py").read_text(encoding="utf-8")
ns = {}
exec(func_src, ns)
page_aligned_decode_alloc_lens = ns["page_aligned_decode_alloc_lens"]


def _req(kv_allocated_len, kv_committed_len):
    return SimpleNamespace(
        kv=SimpleNamespace(kv_allocated_len=kv_allocated_len),
        kv_committed_len=kv_committed_len,
    )


cases = [
    ("test_empty_requests", lambda: page_aligned_decode_alloc_lens([], reserve=16, page_size=4) == ([], [], 0)),
    ("test_rounds_target_up_to_page", lambda: page_aligned_decode_alloc_lens(
        [_req(kv_allocated_len=8, kv_committed_len=10)], reserve=4, page_size=4) == ([8], [16], 8)),
    ("test_exact_boundary_is_not_rounded_to_next_page", lambda: page_aligned_decode_alloc_lens(
        [_req(kv_allocated_len=4, kv_committed_len=8)], reserve=4, page_size=4) == ([4], [12], 8)),
    ("test_allocated_length_is_never_reduced", lambda: page_aligned_decode_alloc_lens(
        [_req(kv_allocated_len=32, kv_committed_len=10)], reserve=4, page_size=4) == ([32], [32], 0)),
    ("test_page_size_one", lambda: page_aligned_decode_alloc_lens(
        [_req(kv_allocated_len=7, kv_committed_len=9)], reserve=3, page_size=1) == ([7], [12], 5)),
    ("test_multiple_requests_sum_needed_tokens", lambda: page_aligned_decode_alloc_lens(
        [_req(0, 5), _req(8, 5), _req(20, 30)], reserve=4, page_size=4) == ([0, 8, 20], [12, 12, 36], 32)),
    ("test_large_reserve_crosses_multiple_pages", lambda: page_aligned_decode_alloc_lens(
        [_req(kv_allocated_len=8, kv_committed_len=8)], reserve=17, page_size=8) == ([8], [32], 24)),
]

fails = 0
for name, fn in cases:
    try:
        ok = fn()
    except Exception as e:
        ok, err = False, repr(e)
    if ok:
        print(f"PASS {name}")
    else:
        fails += 1
        print(f"FAIL {name}")
print(f"\n{len(cases) - fails}/{len(cases)} 断言通过" if fails == 0 else f"{fails} 个失败")
sys.exit(1 if fails else 0)