---
week: 11
title: CUDA/C++/系统设计模拟面试
start: 2026-11-02
end: 2026-11-08
hours: 24
status: upcoming
---

# 第 11 周：CUDA/C++/系统设计模拟面试

## 相关文档

- [INTERVIEW_MATRIX](../INTERVIEW_MATRIX.md) — 本周面试题加入矩阵
- [SKILL_MATRIX](../SKILL_MATRIX.md) — 能力自评与证据
- [knowledge-map](../knowledge-map.md) — 主题知识地图
- [progress-tracker](../progress-tracker.md) — 进度打卡
- [APPLICATION_PLAN](../APPLICATION_PLAN.md) — 简历与投递规则

## 本周目标

至少两次有评分的完整模拟面试（一次技术深挖、一次系统设计），修复暴露的短板。

## 先修知识

INTERVIEW_MATRIX 全部题目。

## 时间预算

暂定 24h：Linux/故障实验 8h · C++/系统知识 5h · 限时编程 4h · 模拟/复盘 5h · 岗位 2h。
18h/12h 档缩小实验范围，保留两次模拟与错题重测，不按刷题数量计分。

## 阅读范围

- INTERVIEW_MATRIX.md（抽题来源）
- SKILL_MATRIX 中低于 B 级的条目对应材料

## 动手实验

1. 模拟 1（技术深挖 60min）：白板手推 FlashAttention + 现场讲 cuflash 代码 + 两层追问。
2. 模拟 2（系统设计 60min）：先设计可在单卡验证的 LLM 推理服务（批处理、KV 管理、
   指标、容量），再把多卡扩展明确标为理论设计，不声称做过真实实验。
3. 每次 24h 内写复盘：卡壳点 → 对应 SKILL_MATRIX 条目 → 补课动作。
4. Linux/C++：一次 perf 或线程/内存问题定位，加一段限时编程；保存错误假设和测试。

## 可验证交付物

- [ ] 两次模拟的评分记录（用 INTERVIEW_MATRIX 的 A–D 标准）
- [ ] 复盘文档 ×2
- [ ] SKILL_MATRIX 更新
- [ ] 简历修订版

## 面试问题

全部从 INTERVIEW_MATRIX 抽取；系统设计题：单机推理服务的完整设计。

## 退出条件

两次模拟中技术深挖 ≥ B 级；所有卡壳点都有补课记录。

## 未完成时

第二次模拟不可由阅读替代；只补复测最低分，实验拓展顺延。
