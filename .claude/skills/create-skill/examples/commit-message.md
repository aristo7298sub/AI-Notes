# 示例 Skill: 生成 Commit Message

```yaml
---
name: commit
description: 根据当前 git 变更生成规范的 commit message
disable-model-invocation: true
allowed-tools: Bash(git:*)
---

# 生成 Commit Message

## 当前变更
- Staged changes: !`git diff --cached --stat`
- Diff summary: !`git diff --cached`

## Commit Message 规范

使用 Conventional Commits 格式：

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Type 类型
- `feat`: 新功能
- `fix`: Bug 修复
- `docs`: 文档变更
- `style`: 代码格式（不影响代码运行）
- `refactor`: 重构
- `perf`: 性能优化
- `test`: 测试相关
- `chore`: 构建/工具变更

### 规则
1. subject 不超过 50 字符
2. subject 使用祈使句（Add... 而非 Added...）
3. body 解释 what 和 why，不是 how
4. 每行不超过 72 字符

## 任务

根据上述变更生成合适的 commit message，然后询问用户是否要执行 commit。
```
