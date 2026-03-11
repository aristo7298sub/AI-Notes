# SKILL.md 模板

## 参考型（背景知识，LLM 按需使用）

```yaml
---
name: <skill-name>
description: '<功能描述>。当用户<场景1>、<场景2>、或<场景3>时使用，即使用户没有明确提到<关键词>。'
---

# <技能标题>

<简要说明这个 skill 的目的和价值 — 解释"为什么"而非罗列规则>

## 指南

<用解释性语言描述规范，让模型理解背后的原因>

## 示例

**示例 1:**
输入：<具体输入>
输出：<期望输出>

**示例 2:**
输入：<具体输入>
输出：<期望输出>
```

---

## 任务型（用户手动调用）

```yaml
---
name: <skill-name>
description: '<任务描述>'
argument-hint: '[参数说明]'
disable-model-invocation: true
---

# <任务标题>

执行以下步骤处理 $ARGUMENTS：

1. <步骤一 — 解释为什么需要这一步>
2. <步骤二>
3. <步骤三>

## 注意事项

- 注意点一
- 注意点二
```

---

## 子代理模板（隔离执行）

```yaml
---
name: <skill-name>
description: <描述功能>
context: fork
agent: Explore
allowed-tools: Read, Grep, Glob
---

# <任务标题>

对 $ARGUMENTS 执行以下研究：

1. 使用 Glob 和 Grep 查找相关文件
2. 阅读并分析代码
3. 总结发现，包含具体文件引用

## 输出格式

<定义期望的输出结构>
```

---

## 带动态上下文的模板

```yaml
---
name: <skill-name>
description: <描述功能>
allowed-tools: Bash(gh:*)
---

# <任务标题>

## 当前上下文
- Git 分支: !`git branch --show-current`
- 最近提交: !`git log --oneline -3`

## 任务

根据上述上下文，执行 $ARGUMENTS
```

---

## 可视化输出模板

```yaml
---
name: <skill-name>
description: <描述功能，生成可视化输出>
allowed-tools: Bash(python:*)
---

# <可视化任务>

生成交互式可视化：

运行以下脚本：
```bash
python ~/.claude/skills/<skill-name>/scripts/visualize.py $ARGUMENTS
```

这将在当前目录生成 HTML 文件并在浏览器中打开。
```
