---
title: "Agent Skills 深入解析"
date: 2026-03-11
category: deep-dive
tags: [Agent, Skills, Copilot, Claude-Code, VS-Code]
---
# Agent Skills 深入解析

> 本文整理了 VS Code Copilot 和 Claude Code 中 Agent Skills 的工作机制、完整处理流程、Token 消耗分析及两者对比。

## 目录

- [什么是 Agent Skills](#什么是-agent-skills)
- [Skills 的目录结构](#skills-的目录结构)
- [用户请求的完整处理流程](#用户请求的完整处理流程)
- [Skills 是否发送给 LLM](#skills-是否发送给-llm)
- [Token 消耗分析](#token-消耗分析)
- [VS Code Copilot 与 Claude Code 对比](#vs-code-copilot-与-claude-code-对比)
- [控制 Skill 调用方式](#控制-skill-调用方式)
- [最佳实践](#最佳实践)
- [官方文档链接](#官方文档链接)

---

## 什么是 Agent Skills

Agent Skills 是一个[开放标准](https://agentskills.io/)，定义了 AI Agent 按需加载的专业知识包。每个 Skill 由一个文件夹组成，核心是 `SKILL.md` 文件（含 YAML frontmatter 元数据 + Markdown 正文指令），可以附带脚本、文档、模板等资源文件。

Skills 与 Custom Instructions 的区别：

| 维度     | Agent Skills                                         | Custom Instructions              |
| -------- | ---------------------------------------------------- | -------------------------------- |
| 目的     | 专业能力和工作流                                     | 编码标准和规范                   |
| 可移植性 | 跨 VS Code、Copilot CLI、Claude Code 等多个 AI 工具  | VS Code / GitHub.com 专用        |
| 内容     | 指令 + 脚本 + 示例 + 资源                            | 仅指令                           |
| 作用域   | 按需加载，任务特定                                   | 始终应用（或通过 glob 模式匹配） |
| 标准     | 开放标准 ([agentskills.io](https://agentskills.io/)) | 平台特定                         |

---

## Skills 的目录结构

```
skill-name/
├── SKILL.md           # 主文件（必需，name 必须与文件夹名匹配）
├── scripts/           # 可执行脚本
├── references/        # 按需加载的参考文档
└── assets/            # 模板、样板文件等静态资源
```

### 存放位置

**VS Code Copilot:**

| 路径                        | 作用域 |
| --------------------------- | ------ |
| `.github/skills/<name>/`    | 项目级 |
| `.agents/skills/<name>/`    | 项目级 |
| `.claude/skills/<name>/`    | 项目级 |
| `~/.copilot/skills/<name>/` | 个人级 |
| `~/.agents/skills/<name>/`  | 个人级 |
| `~/.claude/skills/<name>/`  | 个人级 |

**Claude Code:**

| 路径                       | 作用域 |
| -------------------------- | ------ |
| `.claude/skills/<name>/`   | 项目级 |
| `~/.claude/skills/<name>/` | 个人级 |
| 通过 managed settings 部署 | 企业级 |
| `<plugin>/skills/<name>/`  | 插件级 |

> Claude Code 支持嵌套目录自动发现：编辑 `packages/frontend/` 下的文件时，会自动扫描 `packages/frontend/.claude/skills/`，适用于 monorepo 场景。

### SKILL.md 格式

```yaml
---
name: skill-name              # 必需：1-64 字符，小写字母数字 + 连字符，必须与文件夹名匹配
description: 'Skill 的功能描述和使用场景。最多 1024 字符。'
argument-hint: '可选：斜杠命令调用时的参数提示'
user-invocable: true          # 可选：是否作为斜杠命令显示（默认 true）
disable-model-invocation: false # 可选：是否禁止 LLM 自动加载（默认 false）
---

# Skill 正文

详细的步骤指令、示例、引用等写在这里...
```

---

## 用户请求的完整处理流程

整个过程是一个 **三阶段渐进式加载（Progressive Loading）**，在 [Agent Skills 规范](https://agentskills.io/specification) 中有明确定义：

### 阶段一：Discovery（发现）

**消耗约 ~100 tokens/skill，始终发生。**

客户端（VS Code / Claude Code）在构建发送给 LLM 的 System Prompt 时，扫描所有已注册的 Skills，将每个 Skill 的 `name` 和 `description` 字段注入到 system prompt 中。

以 VS Code Copilot 为例，注入格式类似：

```xml
<skills>
  <skill>
    <name>webapp-testing</name>
    <description>Test web applications using Playwright. Use for verifying frontend...</description>
    <file>copilot-skill:/webapp-testing/SKILL.md</file>
  </skill>
  <!-- 更多 skills... -->
</skills>
```

LLM 通过这些元数据了解有哪些 Skills 可用，但此时**不会加载 Skill 正文内容**。

### 阶段二：Instructions（指令加载）

**消耗 < 5000 tokens（推荐），按需发生。**

LLM 收到用户问题后，根据 description 中的关键词判断是否需要某个 Skill。如果匹配：
- **VS Code Copilot**：LLM 通过 `read_file` 工具调用读取 `SKILL.md` 完整正文
- **Claude Code**：LLM 通过专用的 **Skill tool** 加载 `SKILL.md` 正文

只有被触发的 Skill 才会加载正文，其他 Skills 不消耗额外 tokens。

### 阶段三：Resources（资源按需加载）

**消耗视文件大小而定，按需发生。**

SKILL.md 正文中引用的子文件（如 `[test script](./scripts/test.js)`、`[reference](./references/REFERENCE.md)`），只在 LLM 判断需要时才通过工具调用逐个读取。

```
┌───────────────────────────────────────────────────────────────┐
│                    用户发送问题                                │
└──────────────────────┬────────────────────────────────────────┘
                       ▼
┌───────────────────────────────────────────────────────────────┐
│  阶段一：Discovery                                            │
│  客户端将所有 Skill 的 name + description 注入 System Prompt   │
│  (~100 tokens/skill，始终发生)                                 │
└──────────────────────┬────────────────────────────────────────┘
                       ▼
┌───────────────────────────────────────────────────────────────┐
│  LLM 分析用户问题，匹配 Skill description 中的关键词           │
│  判断是否需要加载某个 Skill                                    │
└──────────┬───────────────────────────────┬────────────────────┘
           │ 匹配                          │ 不匹配
           ▼                               ▼
┌─────────────────────────┐    ┌─────────────────────────┐
│  阶段二：Instructions    │    │  跳过，无额外消耗        │
│  加载 SKILL.md 正文      │    └─────────────────────────┘
│  (< 5000 tokens)        │
└──────────┬──────────────┘
           ▼
┌─────────────────────────┐
│  阶段三：Resources       │
│  按需读取子文件          │
│  (scripts/references等)  │
└─────────────────────────┘
```

---

## Skills 是否发送给 LLM

**是的，但是分层发送：**

| 阶段         | 发送内容               | Token 消耗                                 | 何时发送         |
| ------------ | ---------------------- | ------------------------------------------ | ---------------- |
| Discovery    | `name` + `description` | ~100 tokens/skill，**始终消耗**            | 每次请求         |
| Instructions | `SKILL.md` body        | < 5000 tokens（推荐），仅在 LLM 判定相关时 | 按需（工具调用） |
| Resources    | 子文件内容             | 视文件大小，仅在正文引用时                 | 按需（工具调用） |

**关键设计理念**：用最小的 discovery 开销（~100 tokens/skill）换取按需加载的灵活性，避免把所有指令全量塞进 system prompt。

---

## Token 消耗分析

### 固定开销（不可避免）

每个 Skill 的 `name` + `description` ≈ 100 tokens。

示例计算：
- 10 个 Skills → 每次请求固定 ~1,000 tokens
- 20 个 Skills → 每次请求固定 ~2,000 tokens
- 50 个 Skills → 每次请求固定 ~5,000 tokens

### 按需开销（可控）

SKILL.md body 只在被触发时才加载。良好实践建议保持 SKILL.md < 500 行，详细内容拆分到 `references/` 子文件。

### Claude Code 的 Token 预算机制

Claude Code 有明确的硬限制：
- **Discovery 阶段总预算 = context window × 2%**（fallback 为 16,000 字符）
- 例如：200K context window → ~4,000 tokens discovery 预算
- 超出预算的 skills 会被**静默排除**
- 可通过 `/context` 命令查看是否有 skills 被排除
- 可通过环境变量 `SLASH_COMMAND_TOOL_CHAR_BUDGET` 覆盖默认预算

### VS Code Copilot 的 Token 预算

VS Code Copilot 未公开类似的明确限制，但逻辑一致 — 所有 Skill 的 name + description 都注入 system prompt，数量多了自然消耗更多 input tokens。

### 对比：Skills vs `applyTo: "**"` 的 Instructions

使用 `applyTo: "**"` 的 Instructions 文件会在每次请求中**全量加载**（不管是否相关），反而更容易浪费 tokens。Skills 的按需加载机制在这方面更加高效。

---

## VS Code Copilot 与 Claude Code 对比

### 相同点

两者都遵循 [Agent Skills 开放标准](https://agentskills.io/specification)，核心机制一致：

1. 三阶段渐进式加载（Progressive Loading）
2. `name` + `description` 作为 discovery surface
3. `SKILL.md` 格式和目录结构相同
4. 支持 `user-invocable` 和 `disable-model-invocation` 控制
5. 通过 `/` 斜杠命令手动调用

### 功能差异

| 维度                 | VS Code Copilot                              | Claude Code                                                         |
| -------------------- | -------------------------------------------- | ------------------------------------------------------------------- |
| **Discovery 预算**   | 未公开具体限制                               | 动态预算 = context window 的 2%，fallback 16K 字符                  |
| **预算可调**         | 无                                           | 环境变量 `SLASH_COMMAND_TOOL_CHAR_BUDGET`                           |
| **Skill 调用机制**   | LLM 判断相关 → `read_file` 工具读取          | 专用 **Skill tool** → 工具调用加载                                  |
| **Subagent 执行**    | 不支持                                       | 支持 `context: fork` — skill 在隔离 subagent 中执行                 |
| **动态上下文注入**   | 不支持                                       | 支持 `` !`command` `` 语法，shell 命令输出预处理替换                |
| **参数替换**         | 不支持                                       | 支持 `$ARGUMENTS`、`$ARGUMENTS[N]`、`$N`、`${CLAUDE_SESSION_ID}` 等 |
| **Hooks**            | 不支持（Skill 级别）                         | 支持 skill 级别的 hooks                                             |
| **Model 指定**       | 不支持                                       | 支持 `model` 字段指定 skill 使用的模型                              |
| **扩展 Frontmatter** | `user-invocable`, `disable-model-invocation` | 额外支持 `context`, `agent`, `model`, `hooks`, `allowed-tools`      |

### `disable-model-invocation: true` 的行为差异

这是一个关键差异：

| 客户端              | 设置 `disable-model-invocation: true` 后的行为                                  |
| ------------------- | ------------------------------------------------------------------------------- |
| **VS Code Copilot** | Description **仍在 context 中**，但 LLM 不会自动触发（仍消耗 discovery tokens） |
| **Claude Code**     | Description **完全不注入 context**，零 token 开销                               |

---

## 控制 Skill 调用方式

### 调用方式矩阵

| 配置                             | 斜杠命令可用 | LLM 自动触发 | 适用场景                             |
| -------------------------------- | ------------ | ------------ | ------------------------------------ |
| 默认（两项均省略）               | 是           | 是           | 通用 skills                          |
| `user-invocable: false`          | 否           | 是           | 背景知识型 skill（用户不需直接调用） |
| `disable-model-invocation: true` | 是           | 否           | 有副作用的操作（如 deploy、commit）  |
| 两项均设置                       | 否           | 否           | 禁用该 skill                         |

### 使用建议

- **通用知识型 Skill**（如 API 规范、代码风格）→ 默认配置，让 LLM 自动判断
- **有副作用的操作**（如部署、发送消息）→ `disable-model-invocation: true`，仅手动触发
- **背景上下文**（如遗留系统说明）→ `user-invocable: false`，由 LLM 自动加载
- **大量 Skills 导致预算紧张时** → 对不常用的 skill 设置 `disable-model-invocation: true` 释放 discovery 空间

---

## 最佳实践

### Description 编写

Description 是 discovery surface，LLM 完全依赖其中的关键词来决定是否加载 Skill。

```yaml
# 好的写法 — 关键词丰富，明确场景
description: 'Test web applications using Playwright. Use for verifying frontend, debugging UI, capturing screenshots.'

# 差的写法 — 模糊，无法被匹配
description: 'A helpful skill for testing.'
```

### 文件组织

- 保持 `SKILL.md` < 500 行
- 详细参考文档拆分到 `references/` 目录
- 使用相对路径引用子文件：`[reference](./references/REFERENCE.md)`
- 文件引用保持一层深度，避免深层嵌套引用链

### YAML Frontmatter 注意事项

- 值中包含冒号时必须加引号：`description: "Use when: doing X"`
- 使用空格缩进，不要用 Tab
- `name` 必须与文件夹名完全匹配

---

## 官方文档链接

| 文档                        | 链接                                                                         |
| --------------------------- | ---------------------------------------------------------------------------- |
| Agent Skills 开放标准       | https://agentskills.io/                                                      |
| Agent Skills 规范           | https://agentskills.io/specification                                         |
| Description 优化指南        | https://agentskills.io/skill-creation/optimizing-descriptions                |
| VS Code Copilot Skills 文档 | https://code.visualstudio.com/docs/copilot/customization/agent-skills        |
| VS Code Custom Instructions | https://code.visualstudio.com/docs/copilot/customization/custom-instructions |
| VS Code Custom Agents       | https://code.visualstudio.com/docs/copilot/customization/custom-agents       |
| VS Code Prompt Files        | https://code.visualstudio.com/docs/copilot/customization/prompt-files        |
| Claude Code Skills 文档     | https://code.claude.com/docs/en/skills                                       |
| Claude Code Subagents       | https://code.claude.com/docs/en/sub-agents                                   |
| Claude Code Plugins         | https://code.claude.com/docs/en/plugins                                      |
| Claude Code Hooks           | https://code.claude.com/docs/en/hooks                                        |
| Claude Code Permissions     | https://code.claude.com/docs/en/permissions                                  |
| 社区 Skills 集合（GitHub）  | https://github.com/github/awesome-copilot                                    |
| Anthropic Skills 参考仓库   | https://github.com/anthropics/skills                                         |

---

*最后更新：2026-03-10*

