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

## 它解决什么核心问题？

**AI 对话的 context 是短命的，但学习是长期的。**

每次关掉对话，AI 就不记得你上次学过什么、卡在哪里、下一步该做什么。靠 AI 的上下文管理一个持续数月的学习计划，根本不可能。

而人自己又很难坚持——今天想学这个，明天忘了那个，学了两周就不知道自己在哪了。

LoopOS 的解法很简单：**把学习记忆从 AI 脑子里拿出来，放进文件里。**

```
dashboard.bat  →  不用打开 AI 也能看进度、做计划
progress.json  →  每次学习结束自动 +1，AI 不记得文件记得
journal/       →  学过的内容、卡点、用时，全部落地
CLAUDE.md      →  每次新对话 AI 读这个文件，立刻恢复状态
```

效果就是：你可以**围绕一个大目标发散学习**，今天学 A，明天学 B，不用操心 AI 记不记得——文件帮你记住了。每次打开新对话，AI 读一遍进度文件和 CLAUDE.md，直接进入状态，像从来没断过一样。

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
