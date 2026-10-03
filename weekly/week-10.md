---
week: 10
title: 一个上游框架、证据包与简历
start: 2026-10-26
end: 2026-11-01
hours: 24
status: upcoming
---

# 第 10 周：一个上游框架、证据包与简历

## 相关文档

- [INTERVIEW_MATRIX](../INTERVIEW_MATRIX.md) — 本周面试题加入矩阵
- [SKILL_MATRIX](../SKILL_MATRIX.md) — 能力自评与证据
- [knowledge-map](../knowledge-map.md) — 主题知识地图
- [progress-tracker](../progress-tracker.md) — 进度打卡
- [PROJECT_STRATEGY](../PROJECT_STRATEGY.md) — 项目策略
- [APPLICATION_PLAN](../APPLICATION_PLAN.md) — 简历与投递规则

## 本周目标

只深读一个上游框架的一条请求路径，并与旗舰系统对照；把已有效的证据压成两版
简历与答辩素材。默认 SGLang，岗位要求 vLLM 时替换，不同时通读两仓。

## 先修知识

W7–W9 诊断和有效结果；不要求先做完所有历史 checklist。

## 时间预算

暂定 24h：上游调用链/最小实验 8h · 核心知识 5h · 限时编程 4h · 对照讲述 5h · 岗位/简历 2h。
18h/12h 档砍拓展模块，只保留一条请求、一个关键结构与一张 claim 证据表。

## 阅读范围

- open-infra-ai meta 仓的只读历史证据矩阵（仅作索引，不改写）
- 各技术仓当前 README、benchmark 结果与复现命令
- github-repos-hub 的 original-projects.md（简历候选池）
- SGLang scheduler/KV/batch 路径（先绑定实际 checkout SHA）；NCCL/TP 最多公式级选修

## 动手实验

1. “五个一”：一条调用链、一个关键结构、一次最小实验、一张架构图、一道对照追问。
2. 每个简历 claim 核对 source/test/raw/commit/边界/本人贡献；说不清的实现先退出主 bullet。
3. 准备可现场执行的 demo 与无 GPU 备用方案；三张答辩牌每张限时 2min。
4. 投递和主页改动经本人批准后执行；真实投递只写忽略的 .local 文件，不由 Agent 代造。

## 可验证交付物

- [ ] 一个框架的“五个一”与 flagship 对照（含 SHA）
- [ ] Demo 脚本 × 2
- [ ] v-performance 与 v-serving 简历初稿
- [ ] 两个主项目 claim 核对与本人 2min 讲述记录

## 面试问题

（本周不新增题目，把 INTERVIEW_MATRIX 全部题目自评到 B 以上。）

## 退出条件

简历两版完成；Demo 脚本在干净环境可跑通。

## 未完成时

源码拓展可砍；保留核心调用链和 claim 核对。对外投递不因计划安排自动获得授权。
