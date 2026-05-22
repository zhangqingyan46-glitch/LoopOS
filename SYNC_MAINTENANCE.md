# 学习系统文件维护手册

## 一、文件依赖关系图

```
                    ┌──► current_session.md (今日计划)
                    │
用户学习 ──► AI ────┼──► journal/日期.md (日志)
                    │
                    ├──► progress.json (进度 + last_updated)
                    │
                    ├──► pending_tasks.json (卡点标记完成)
                    │
                    └──► notes/glossary.md (术语表追加)
                                              │
                                              ▼
                                     dashboard.ps1 读取:
                                     ├ progress.json → 阶段进度 + last_updated
                                     ├ journal/ → 连续天数 + 本周出勤
                                     ├ current_session.md → 今日任务清单
                                     └ pending_tasks.json → 待处理计数
```

## 二、文件角色速查

| 文件 | 角色 | 谁写 | 谁读 | 更新频率 |
|------|------|------|------|----------|
| `progress.json` | **唯一进度源** | AI / log_session.ps1 | AI, dashboard | 每次学习结束 |
| `journal/日期.md` | **学习日期源** | AI / log_session.ps1 | dashboard | 每次学习结束 |
| `current_session.md` | 今日目标 | AI | AI, dashboard | 每次学习前 |
| `pending_tasks.json` | 卡点队列 | AI | AI, dashboard | 遇到卡点时 / 完成时 |
| `weekly_plan.json` | 滚动周计划 | AI | AI | 每周推进 |
| `scripts/dashboard.ps1` | 只读面板 + 交互菜单 | 直接编辑 | 用户双击 | 修改逻辑时编辑 |
| `scripts/log_session.ps1` | 快速记录工具 | 直接编辑 | 用户双击 | 修改逻辑时编辑 |
| `CLAUDE.md` | AI 行为指令 | 编辑 | AI | 规则变更时 |
| `notes/glossary.md` | 术语积累 | AI | AI, 用户 | 每次学习结束 |

## 三、更新协议（严格执行）

### 3.1 学习结束 → 写操作顺序

必须按此顺序执行，不可跳过，不可颠倒：

```
1. progress.json  ←── 改 progress + 1, session_count + 1, last_updated = 今天
2. journal/日期.md ←── 写本次内容、不清晰点、用时
3. current_session.md ←── 已完成项打 [x]
4. pending_tasks.json ←── 对应 topic 改为 done
5. notes/glossary.md  ←── 追加 3-8 个新术语（不重复）
```

**严禁**：
- 只写日志不更新 progress.json（dashboard 读不到学习日期）
- 只更新 progress 不写日志（无法算连续天数）
- 更新了进度但忘记改 last_updated（dashboard 日期兜底失效）

### 3.2 学习开始前 → 读操作顺序

```
1. Read progress.json    → 确认当前进度、各阶段状态
2. Read pending_tasks.json → 检查是否有遗留卡点
3. Read weekly_plan.json → 确认本周计划主题
4. Write current_session.md → 写今日目标和安排
```

### 3.3 每周推进规则

```
当前周完成时:
  1. 更新 progress.json 中对应阶段的 progress
  2. weekly_plan.json.rolling_weeks 删掉已完成周
  3. 末尾追加一周新计划（保持共 6 周）
  4. 更新 milestones 中对应阶段的状态
```

## 四、dashboard 数据读取逻辑

### 4.1 "上次学习" 显示不对
```
dashboard 判定逻辑:
  1. 遍历 journal/ 最近 14 天 → 取最新日期记为 A
  2. 读 progress.json.last_updated → 记为 B
  3. 取 max(A, B) 作为 "上次学习日期"
  4. 用这个日期算天数差 → 评分扣分
```

### 4.2 本周出勤不对
```
dashboard 判定逻辑:
  1. 遍历 journal/ 中本周七天的日期 → 有文件即为出勤
  2. 叠加 progress.json.last_updated → 如果 last_updated 是本周某天也标出勤
```

### 4.3 综合评分不准
评分公式（dashboard.ps1 #Scoring 段）：
```
基础 60
+ 今日已学 15  /  有连续则 +8
+ 连续 >=3 天 +7
+ 上次学习 <=1 天 +5  /  <=3 天 +2  /  >3 天每天 -10（最多扣 50）
- 高优先待办 ×6
- 普通待办 ×3
```

### 4.4 进度 vs 预期对比不准
```
dashboard 预期计算:
  1. start_date (progress.json) → 计算已过天数
  2. stageWeeks 表映射:  每个阶段对应的周数
  3. expected = (daysElapsed / (weeks * 7)) × target
  4. gap = actual - expected
  5. gap > 0.5 → 超前 (绿色)  /  gap < -0.5 → 落后 (红色)
```

## 五、常见故障与修复

### 故障 1：Dashboard 打开报错 "Cannot read progress.json"
```
原因: progress.json 被删除或损坏
修复: 从 _snapshots/ 恢复最近的版本
      或手动重建最小版本（至少包含 stages 对象）
```

### 故障 2：Dashboard 显示 "从未学习"
```
原因: journal/ 目录为空 且 progress.json 没有 last_updated 字段
修复: 手动添加 last_updated 到 progress.json
      或运行 scripts/log_session.bat 记录一次学习
```

### 故障 3：Dashboard 显示的进度比实际少
```
原因: 某次学习结束没有写 progress.json
修复: 手动改 progress.json 中对应阶段的 progress 值
      或运行 scripts/log_session.bat 补记
```

### 故障 4：Dashboard 显示阶段名称为乱码
```
原因: dashboard.ps1 编码损坏（缺少 UTF-8 BOM）
修复: 用 VSCode 重新以 UTF-8 编码保存
```

## 六、关键约束

1. **progress.json 永远是第一写入目标** — 它是 dashboard 的最终兜底
2. **journal/ 和 progress.json 不能长期不一致** — 只要有一方更新了日期，dashboard 就能正确显示
3. **不要手动编辑 journal/ 日期.md** — 格式由 AI 或 log_session.ps1 统一维护
4. **weekly_plan.json 保持 ≤6 周滚动** — 不维护长期计划
5. **CLAUDE.md 是唯一 AI 指令文件** — 旧指令移入 _obsolete/
