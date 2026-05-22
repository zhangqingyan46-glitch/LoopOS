# LoopOS

> An AI-powered Personal Learning Operating System — with persistent memory, adaptive planning, and terminal-first workflow.

一个基于 **AI 助手 + 终端脚本** 双通道的个人学习操作系统。

让每次学习的进度**自动沉淀**，让你只关注学本身。

> **初次使用？→ 看 [SETUP.md](SETUP.md)**，10 分钟从零开始。

---

## 30 秒理解

```
       progress.json  (唯一进度源)
             ↑
             │ 写入        ───── 1. dashboard.ps1 读取进度
             │                              ↓
    AI ←── current_session.md  ←──  2. 用户选择板块
             ↑                              ↑
             │ AI 教学               ───── 3. 双击 dashboard.bat
             │
 journal/YYYY-MM-DD.md
             ↑
             │ AI 结束自动写（不等确认）
             │
       progress.json .last_updated 更新
```

**一次学习的完整闭环：**

双击 `dashboard.bat` → 看进度 → 选板块 → 写计划 →
和 AI 说"开始今天的学习" → AI 教学 → 说"今天就到这" →
**AI 自动写日志 + 更新进度** → 关掉 → 明天重复

---

## 演示

运行 `demo\demo.bat` 查看 5 步流程演示（无需配置 AI）：

```
STEP 1/5  查看仪表盘
STEP 2/5  选择板块 → 自动写计划
STEP 3/5  AI 对话教学
STEP 4/5  结束学习 → 自动记录
STEP 5/5  重新打开 → 进度已更新
```

---

## 它能解决什么？

| 自学的通病 | 这个系统的方案 |
|-----------|---------------|
| 学完就忘，没有积累感 | AI **自动写日志 + 更新进度**，dashboard 实时可见 |
| 坚持不下去 | 综合评分 + 连续天数 + 进度预期对比，形成正向激励 |
| 计划赶不上变化 | 6 周滚动计划，AI 动态调整，不维护冗长的路线图 |

---

## 文件结构

```
AI-Learning-OS/
├── CLAUDE.md              # AI 行为指令 — 给 AI 的教学规则
├── progress.json          # [唯一进度源] 各阶段完成度
├── current_session.md     # 今日课表
├── pending_tasks.json     # 卡点/待办
├── weekly_plan.json       # 滚动 6 周计划
│
├── scripts/
│   ├── dashboard.bat      # 双击：进度面板 + 选择板块
│   ├── dashboard.ps1
│   ├── log_session.bat    # 双击：独立学习快速记录
│   └── log_session.ps1
│
├── journal/               # 每日学习日志（AI 自动生成）
│   ├── 2026-05-01.md
│   └── 2026-05-02.md
│
└── demo/
    ├── demo.bat           # 5 步自动演示
    └── screenshots/
```

---

## Quick Start（5 分钟）

### 1. 初始化

```bash
# 复制本仓库到你的学习目录
# 编辑 progress.json，把示例阶段改成你的目标
```

### 2. 放入 CLAUDE.md

把 `CLAUDE.md` 放到你的 AI 助手可读取的位置（Claude Code 等项目根目录，或 Cherry Studio 的工作区）。

### 3. 开始学习

```bash
# 双击打开仪表盘
scripts/dashboard.bat

# 选择板块 → 自动写 today plan
# 对 AI 说："开始今天的学习"
```

---

## 工作流

```
双击 dashboard.bat → 看进度 + 选板块
         ↓
对 AI 说"开始今天的学习"
         ↓
AI 读取进度 → 开始教学
         ↓
"教我 [主题]" / "解释 [概念]" / "做练习 [主题]"
         ↓
"今天就到这" → AI 自动记录（不等确认）
```

---

## 两条通道

- **AI 通道**：对话教学中，AI 自动完成所有数据记录
- **终端通道**：独立学习时双击 `log_session.bat` 快速记录，数据自动汇入

---

## 评分系统

```
基础 60  +  今日已学 +15  +  连续≥3天 +7  +  上次≤1天 +5
- 待办扣分  =  综合评级 A~F
```

---

## 设计原则

1. **零摩擦记录** — 不要求手动打卡，AI 自动完成
2. **唯一数据源** — progress.json 是唯一的进度权威
3. **滚动计划** — 只维护 6 周，不维护冗长的长期计划
4. **双通道** — AI 和终端各司其职
5. **积累感驱动** — 评分和进度对比是为了让努力可见
