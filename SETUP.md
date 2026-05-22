# 零基础上手指南

> 从 GitHub 下载到第一次学习，预计 10 分钟。

---

## 你需要准备什么

| 需要 | 说明 | 免费？ |
|------|------|--------|
| 一台 Windows 电脑 | PowerShell 脚本需要 Windows | - |
| Claude Code / Cherry Studio | AI 助手，用来读 CLAUDE.md | Cherry Studio 免费 + 自备 API Key |
| 一个 AI API Key | Claude / DeepSeek / OpenAI 等 | 需要付费（用量很小） |

> **Mac/Linux 用户：** 核心逻辑全都在 CLAUDE.md 和 JSON 文件里。dashboard/log_session 脚本需要自己写 Python 等价版（约 100 行）。但教学系统本身可以用任何 AI 助手。

---

## Step 1：下载和解压

```bash
# 或者直接 GitHub 网页下载 ZIP
git clone https://github.com/你的用户名/AI-Learning-OS.git
cd AI-Learning-OS
```

下载后目录结构应该是：

```
AI-Learning-OS/
├── CLAUDE.md              # ← 核心：AI 的教学指令
├── progress.json          # ← 你的进度数据
├── current_session.md
├── pending_tasks.json
├── scripts/               # ← 终端工具
├── journal/               # ← 你的学习日志
└── demo/                  # ← 演示用
```

---

## Step 2：配置 AI 助手（最关键的一步）

这个系统依赖 AI 能**读取 CLAUDE.md** 并按指令执行。不同工具配置方式不同：

### 方式 A：用 Cherry Studio（推荐新手）

```
1. 下载 Cherry Studio（免费）
2. 设置 → AI 助手 → 添加自定义助手
3. 助手指令 → 把 CLAUDE.md 的完整内容粘贴进去
4. 选择你用的模型（DeepSeek / Claude / 通义等）
5. 保存
```

### 方式 B：用 Claude Code（官方 CLI）

```
1. 安装 Node.js
2. npm install -g @anthropic-ai/claude-code
3. 在 AI-Learning-OS 目录下运行 claude
4. CLAUDE.md 要放在项目根目录
   Claude Code 会自动读取它
```

### 方式 C：用其他 AI 工具

只要 AI 工具支持**自定义系统指令/人格设定**，把 CLAUDE.md 的内容粘贴进去即可。

---

## Step 3：配置你自己的学习计划

打开 `progress.json`，把示例改成你的：

```json
{
    "stages": {
        "0-my-goal": {
            "name": "我的目标",
            "progress": 0,
            "target": 10,
            "status": "in_progress",
            "priority": "最高"
        },
        "1-supplement": {
            "name": "基础补充",
            "progress": 0,
            "target": 10,
            "status": "in_progress",
            "sub_items": {
                "math": {
                    "name": "数学",
                    "progress": 0,
                    "target": 8,
                    "status": "in_progress"
                }
            }
        }
    },
    "session_count": 0,
    "start_date": "2026-05-22",
    "daily_goal_hours": 2,
    "weekly_goal_days": 5
}
```

> **start_date** 填今天的日期——dashboard 用这个日期算进度预期。

---

## Step 4：规划你的长周期计划

这个系统不需要你一次性规划 57 周的详细路线图。你只需要定义**阶段骨架**，AI 会每周帮你滚动更新计划。

### 设计原则

```
progress.json  ←  阶段级别（粗粒度，不改动）
weekly_plan.json  ←  周级别（6 周滚动，AI 维护）
current_session.md  ←  天级别（AI 每次写）
```

只维护 6 周计划，不维护长期路线图。每周结束 AI 自动删掉已完成周、末尾追加新周。

### 如何定义阶段

在 `progress.json` 中，每个阶段只需要：

| 字段 | 说明 |
|------|------|
| `name` | 阶段名称，例如"实习冲刺"、"多模态入门" |
| `target` | 总进度目标（比如 10 表示这个阶段计划 10 次学习） |
| `status` | `in_progress` / `not_started` / `completed` |
| `priority` | 设为 `highest` 会在 dashboard 高亮显示 |
| `sub_items` | 可选：拆分子阶段（比如 CSAPP / MIT / 数学） |

### target 填多少？

`target` 是**学习的次数**，不是时间，也不是知识点数量。

- 一个 10 周的阶段 → target = 10（每周 1 次）
- 一个密集冲刺阶段 → target = 20（每周 3-4 次）
- 一个跨月的子任务 → target = 8（每周 2 次，持续 1 个月）

dashboard 用 `target` + `start_date` 自动算进度预期：

```
已过天数 / (target × 7) × target = 预期进度
```

实际进度 > 预期 → 绿色"超前"；< 预期 → 红色"落后"。一目了然。

### 实际例子

```json
{
    "0-internship": {
        "name": "Summer Intern Prep",
        "progress": 0,
        "target": 20,
        "status": "in_progress",
        "priority": "highest"
    },
    "1-foundation": {
        "name": "CS Foundation",
        "progress": 0,
        "target": 30,
        "status": "in_progress",
        "sub_items": {
            "csapp": {
                "name": "CSAPP",
                "progress": 0,
                "target": 8,
                "status": "in_progress"
            },
            "mit": {
                "name": "MIT 6.S191",
                "progress": 0,
                "target": 10,
                "status": "in_progress"
            }
        }
    }
}
```

### AI 如何维护计划

每次学习结束时，AI 自动：

1. progress.json → progress + 1
2. journal → 写日志
3. weekly_plan.json → 检查当前周是否完成
4. 如果当周完成 → 删除已完成周，末尾追加新周

你不需要手动维护 weekly_plan.json。AI 会根据你的进度动态调整。

### 何时需要手动调整

- 新增/删除阶段 → 改 `progress.json`
- 调整优先级 → 改 `priority` 字段
- 整体方向变化 → 和 AI 说，AI 会更新 `weekly_plan.json`

---

## Step 5：试用仪表盘

```bash
# 双击
scripts/dashboard.bat
```

如果看到终端面板，说明脚本能跑。即使进度全是 0，能看到面板就是成功。

---

## Step 6：开始第一次学习

对 AI 说一句话：

> **"开始今天的学习"**

AI 会：
1. 读取 `progress.json` 了解你的进度
2. 读取 `pending_tasks.json` 看有没有卡点
3. 写 `current_session.md` 设定今日目标
4. 开始教学

---

## Step 7：学习结束

对 AI 说：

> **"今天就到这"**

AI **自动执行**（不等你确认）：
1. `progress.json` 进度 +1
2. `journal/今天日期.md` 写日志
3. `current_session.md` 打 [x]
4. 更新术语表

---

## 日常工作流

```
早上 → 双击 dashboard.bat → 看进度 → 选板块
    → 对 AI 说"开始今天的学习"

白天 → "教我 [主题]" / "解释 [概念]" / "做练习 [主题]"
    → AI 教学 → 追问 → 出题

晚上 → "今天就到这" → AI 自动记录
    → 关闭
```

---

## 独立学习（不打开 AI 时）

如果只是自己看书/做题，不想和 AI 对话：

```bash
# 双击
scripts/log_session.bat
```

终端会问你：学了哪个阶段、主题、用时、笔记。填完自动写 journal + 更新 progress。

---

## 常见问题

### Q：AI 不听指令怎么办？

检查 CLAUDE.md 是否被正确加载。不同 AI 工具的安装位置不同——Cherry Studio 需要粘贴到自定义指令里，Claude Code 需要放在项目根目录。

### Q：能用自己的 AI 模型吗？

可以。CLAUDE.md 的内容是自然语言指令，任何 AI 模型都能理解。教学效果取决于模型能力。

### Q：Mac/Linux 无法运行 .bat 脚本？

dashboard 和 log_session 的核心逻辑很简单——读取 JSON + 展示 + 写文件。用 Python 重写约 100 行：

```python
# 伪代码
import json
progress = json.load(open("progress.json"))
for stage, data in progress["stages"].items():
    bar = "#" * data["progress"] + "." * (data["target"] - data["progress"])
    print(f"{data['name']}: {bar} {data['progress']}/{data['target']}")
```

### Q：我不想用终端面板，只用 AI 可以吗？

可以。dashboard 是辅助工具，核心教学系统在 CLAUDE.md 里。即使从来不用 dashboard，AI 也会在每次对话时读取进度文件。

### Q：文件被我改乱了怎么办？

`_snapshot.ps1` 会备份最近 15 份配置文件。运行它：

```bash
scripts\_snapshot.ps1
```

备份在 `_snapshots/` 目录下，按时间戳命名。
