---
name: create-skill
description: "创建、修改、优化 Agent Skills。当用户想要创建新 skill、改进现有 skill、编写 SKILL.md、讨论 skill 设计、优化 skill 的 description 触发准确率、或将当前对话工作流封装为可复用 skill 时使用此技能。即使用户没有明确说 'skill' 但描述了想要封装、自动化、模板化某个重复工作流的意图，也应使用。"
argument-hint: "[skill-name] [description or 'improve']"
---

# Skill 创建与优化指南

你是一个 Agent Skills 专家。帮助用户从零创建 skill、改进已有 skill、或将当前对话工作流封装为可复用的 skill。

高层流程：

1. 明确意图 — 用户想让 skill 做什么、何时触发
2. 草拟 SKILL.md
3. 设计 2-3 个测试提示词，运行验证
4. 帮用户评估结果（定性 + 定量）
5. 根据反馈改进 skill
6. 重复直到满意
7. 优化 description 触发准确率

你的工作是判断用户处于上述哪个阶段，然后帮他推进。如果用户已有草稿，直接跳到评估/迭代环节。如果用户说"不需要跑评估，跟我一起 vibe 就行"，那就顺着来。灵活处理。

---

## 第一步：明确意图

### 从对话中提取

当前对话可能已经包含了用户想封装的工作流（比如用户说"把刚才这个流程做成 skill"）。此时从对话历史提取：用了哪些工具、操作顺序、用户做的修正、输入输出格式。

### 需要确认的关键问题

1. 这个 skill 要让 Claude/Copilot 做什么？
2. 什么场景应该触发？（哪些用户短语/上下文）
3. 期望的输出格式是什么？
4. 是否需要测试用例？
   - 有客观可验证输出的 skill（文件转换、数据提取、代码生成）→ 建议设置测试
   - 主观输出的 skill（写作风格、创意内容）→ 通常不需要
   - 建议合适的默认值，但让用户决定

### 访谈与调研

主动询问：边界情况、输入输出格式、示例文件、成功标准、依赖项。在搞清楚这些之前不要急着写测试用例。

如果有可用的 MCP 工具用于调研（搜索文档、查找类似 skill），尽量利用。

---

## 第二步：编写 SKILL.md

### 目录结构

```
skill-name/
├── SKILL.md           # 主指令文件（必需）
├── scripts/           # 可执行脚本 — 确定性/重复性任务
├── references/        # 参考文档 — 按需加载到上下文
└── assets/            # 静态资源 — 模板、图标等，用于输出
```

### 存储位置

| 范围 | VS Code Copilot | Claude Code |
|------|-----------------|-------------|
| 个人 | `~/.copilot/skills/<name>/` | `~/.claude/skills/<name>/` |
| 项目 | `.github/skills/<name>/` | `.claude/skills/<name>/` |
| 企业 | — | 通过 managed settings 部署 |
| 通用 | `.agents/skills/<name>/`（两者都支持） | `.agents/skills/<name>/` |

### 渐进式加载架构

理解这个架构对写好 skill 至关重要：

1. **元数据**（~100 tokens/skill）— `name` + `description` 始终在上下文中
2. **SKILL.md 正文**（< 500 行）— 仅在 skill 被触发时加载
3. **辅助资源** — 仅在正文引用且需要时加载（脚本可以执行而无需加载到上下文）

这意味着：
- SKILL.md 保持在 500 行以内；超出时拆分到 references/ 并在正文中清晰标注何时查阅
- 大型参考文件（> 300 行）包含目录
- 多领域/框架的 skill 按变体组织 references/

### Frontmatter 配置

```yaml
---
name: my-skill                      # 小写字母、数字、连字符，≤64 字符，必须与文件夹名匹配
description: '功能描述和触发场景'      # 最大 1024 字符 — 这是触发机制的核心
argument-hint: '[参数提示]'           # 斜杠命令自动补全提示
disable-model-invocation: false     # true = 仅用户可手动调用
user-invocable: true                # false = 从 / 菜单隐藏，仅 LLM 可调用
allowed-tools: Read, Grep, Glob     # 限制可用工具（可选）
model: claude-sonnet-4-20250514                   # 指定模型（可选，仅 Claude Code）
context: fork                       # 在子代理中运行（可选，仅 Claude Code）
agent: Explore                      # 子代理类型（可选，仅 Claude Code）
hooks: {}                           # 生命周期钩子（可选，仅 Claude Code）
---
```

调用方式矩阵：

| 配置 | 斜杠命令 | LLM 自动触发 | 适用场景 |
|------|---------|-------------|---------|
| 默认（均省略） | 是 | 是 | 通用 skill |
| `user-invocable: false` | 否 | 是 | 背景知识（LLM 按需使用） |
| `disable-model-invocation: true` | 是 | 否 | 有副作用的操作（deploy、commit） |
| 两者均设置 | 否 | 否 | 禁用 |

> **注意差异**：在 Claude Code 中 `disable-model-invocation: true` 会让 description 完全不注入上下文（零 token 开销）；在 VS Code Copilot 中 description 仍在上下文中、只是 LLM 不会主动触发。

### 两种 Skill 类型

**参考型** — 提供 Claude 在工作中应用的知识（规范、模式、风格指南），通常内联运行。

```yaml
---
name: api-conventions
description: 'API 设计规范。在编写 API 端点、设计接口、讨论 REST 风格时使用。'
---
编写 API 端点时：
- 使用 RESTful 命名
- 返回一致的错误格式
- 包含请求验证
```

**任务型** — 提供执行特定操作的步骤指令，通常手动调用。

```yaml
---
name: deploy
description: '部署应用到生产环境'
disable-model-invocation: true
---
部署 $ARGUMENTS：
1. 运行测试套件
2. 构建应用
3. 推送到部署目标
```

---

## 第三步：编写 Description（最重要的字段）

Description 是 skill 的发现面（discovery surface）— LLM 完全依赖其中的关键词来决定是否加载 skill。写好 description 比写好正文更重要。

### 原则：宁可"主动"不可"被动"

当前 LLM 倾向于"欠触发"skill — 该用的时候不用。为了对抗这一点，description 要稍微"推"一些。

**差的写法：**
```yaml
description: '用于构建数据看板'
```

**好的写法：**
```yaml
description: '构建简洁快速的数据看板来展示内部数据。当用户提到看板、数据可视化、内部指标，或想要展示任何类型的数据时使用此 skill，即使用户没有明确说"看板"。'
```

### 关键技巧

- 同时描述 skill 做什么 **和** 什么场景应该使用
- 包含用户可能说的多种表述方式
- 所有"何时使用"信息放在 description 里，不要放到正文中
- 包含邻域关键词（用户可能用不同词描述同一需求）

---

## 第四步：编写正文的原则

### 解释"为什么"而不是堆砌"必须"

当前的 LLM 很聪明，有良好的 theory of mind。当你给出合理的解释，它能举一反三。如果你发现自己在写大量的 ALWAYS 或 NEVER（全大写），这是一个黄色信号 — 尝试重写为解释原因，让模型理解为什么这件事重要。这比僵硬的约束更有效。

```markdown
# 差：堆砌规则
ALWAYS use TypeScript. NEVER use any. MUST include error handling.

# 好：解释原因
使用 TypeScript 而非 JavaScript，因为类型安全能在编译期捕获大量错误，
减少运行时 debug 成本。避免 any 类型，因为它会让类型系统形同虚设。
包含错误处理，因为未捕获的异常会导致用户看到白屏。
```

### 从示例中归纳，而非过度拟合

Skill 会被使用无数次、面对无数种提示。不要为了让几个测试用例通过而加入狭隘的、过度具体的指令。如果某个问题很顽固，尝试换个比喻或推荐不同的工作模式。

### 保持精简

去掉没有拉动效果的内容。阅读测试运行的完整记录（不只是最终输出）— 如果 skill 让模型浪费大量时间做无用功，删掉导致这个行为的指令部分。

### 检测重复工作，封装为脚本

阅读测试运行记录时，如果发现每次运行都独立编写了类似的辅助脚本（比如都写了一个 `create_docx.py`），这是强烈信号：应该将这个脚本封装到 `scripts/` 目录中，让 skill 直接使用。

### 定义输出格式

```markdown
## 报告结构
始终使用此模板：
# [标题]
## 摘要
## 关键发现
## 建议
```

### 提供示例

```markdown
## Commit 消息格式
**示例 1:**
输入：添加了使用 JWT 的用户认证
输出：feat(auth): implement JWT-based authentication
```

---

## 第五步：测试与迭代

### 设计测试用例

编写 2-3 个真实的测试提示词 — 真正的用户会说的话。与用户确认后运行。

好的测试提示词是具体的、有细节的，接近真实场景：

```
# 差：太抽象
"格式化这个数据"

# 好：具体、有上下文
"我老板刚发了个 xlsx 文件（在 Downloads 里，叫 'Q4 sales final v2.xlsx'），
她要我加一列利润率百分比。收入在 C 列，成本在 D 列。"
```

### 迭代循环

1. 运行测试 → 用户评估输出
2. 根据反馈改进 skill（归纳而非过度拟合）
3. 重新运行所有测试 → 再次评估
4. 重复直到：用户满意 / 反馈全为空 / 不再有实质进展

---

## 高级功能

### 字符串替换

| 变量 | 用途 |
|-----|------|
| `$ARGUMENTS` | 所有参数；未在正文中出现时自动追加为 `ARGUMENTS: <value>` |
| `$ARGUMENTS[N]` / `$N` | 按位置访问第 N 个参数（0-based） |
| `${CLAUDE_SESSION_ID}` | 当前会话 ID |
| `${CLAUDE_SKILL_DIR}` | skill 所在目录路径（仅 Claude Code） |

### 动态上下文注入（仅 Claude Code）

`` !`command` `` 在发送给 Claude 前执行 shell 命令，输出替换占位符：

```markdown
## Context
- Current branch: !`git branch --show-current`
- Recent commits: !`git log --oneline -5`
```

### 子代理执行（仅 Claude Code）

设置 `context: fork` 在隔离环境运行，skill 正文成为子代理的 prompt：

```yaml
---
name: deep-research
context: fork
agent: Explore
---
Research $ARGUMENTS thoroughly:
1. Find relevant files using Glob and Grep
2. Read and analyze the code
3. Summarize findings with specific file references
```

> 注意：`context: fork` 仅适用于包含明确任务指令的 skill。如果 skill 只是指南没有任务，子代理会无事可做。

### Extended Thinking（仅 Claude Code）

在正文中包含 "ultrathink" 启用深度思考模式。

---

## Description 优化（可选进阶）

在 skill 创建或改进完成后，可以优化 description 以提升触发准确率。

### 生成触发评估查询

创建 16-20 个评估查询 — 应触发和不应触发各半：

**应触发查询**（8-10 个）：
- 不同措辞表达同一意图（正式、口语混合）
- 用户没有显式提到 skill 名称但明显需要的场景
- 不常见的使用场景
- 与其他 skill 竞争但应该赢的场景

**不应触发查询**（8-10 个）：
- 最有价值的是"近似未中"— 共享关键词但实际需要不同东西的查询
- 避免太明显不相关的查询（"写个斐波那契函数"测 PDF skill 毫无意义）

所有查询必须像真实用户那样具体、有细节、有上下文。

### 迭代优化

用评估查询测试当前 description → 根据失败案例调整 → 重新测试 → 重复。注意在训练集上表现好不代表泛化好，保留一部分查询作为测试集。

---

## 安全原则

Skill 不得包含恶意代码、漏洞利用或任何可能危害系统安全的内容。如果被描述出来，skill 的内容不应让用户在意图上感到意外。不要创建意图误导的 skill 或用于未授权访问、数据窃取的 skill。

---

## 检查清单

- [ ] 创建 `<skill-name>/SKILL.md`，name 与文件夹名匹配
- [ ] description 包含功能描述 + 触发场景关键词，稍微"主动"一些
- [ ] 正文解释"为什么"而非堆砌"必须"
- [ ] 正文 < 500 行，详细内容拆到 references/
- [ ] 辅助文件用相对路径引用，并标注何时读取
- [ ] 选择正确的调用方式（用户/LLM/两者）
- [ ] 设计 2-3 个真实测试提示词并运行验证
- [ ] 根据反馈迭代改进

---

## 参考资源

- [Agent Skills 开放标准](https://agentskills.io/) / [规范](https://agentskills.io/specification)
- [VS Code Copilot Skills 文档](https://code.visualstudio.com/docs/copilot/customization/agent-skills)
- [Claude Code Skills 文档](https://code.claude.com/docs/en/skills)
- [Anthropic Skills 参考仓库](https://github.com/anthropics/skills)
- [社区 Skills 集合](https://github.com/github/awesome-copilot)
- [Description 优化指南](https://agentskills.io/skill-creation/optimizing-descriptions)
- [template.md](template.md) — SKILL.md 模板
- [examples/](examples/) — 示例 skills
