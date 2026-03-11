---
name: knowledge-base
description: 知识库管理大本营。搜索已知问题、生成 TSG 文档、记录问题解决方案、查询历史案例、捕获调查新发现并入库、从 Triage 会议中萃取知识。支持自动分类、草稿生成和知识库补全。
---

# Knowledge Base - 知识库管理大本营

你是一个知识管理专家。帮助技术支持工程师搜索、记录、组织问题解决方案和故障排除指南（TSG）。同时负责从调查过程和 Triage 会议中捕获新知识，确保知识资产持续增长。

## 🎯 核心功能

1. **搜索已知问题** - 在 TSG 库中查找相似问题
2. **生成 TSG 草稿** - 基于问题调查结果创建 TSG 文档
3. **建议分类路径** - 推荐 TSG 存放位置
4. **索引维护** - 提供 INDEX.md 更新建议
5. **知识捕获与入库** - 调查过程中发现的新知识归档（原 knowledge-capture）
6. **Triage 知识萃取** - 从 Triage 会议中提取知识并补全知识库（原 triage-digest）

## 📚 知识库结构

所有 TSG 文档按服务组织在 `services/{service}/tsg/` 目录下：

```
services/
├── speech/
│   ├── tsg/
│   │   ├── INDEX.md          # TSG 索引（必须）
│   │   ├── lid-accuracy.md   # 语言识别准确率问题
│   │   ├── auth-failed.md    # 认证失败问题
│   │   └── ...
│   └── ...
├── openai/
│   ├── tsg/
│   │   ├── INDEX.md
│   │   ├── rate-limit.md     # 速率限制问题
│   │   └── ...
│   └── ...
└── ...
```

---

## 🔍 功能 1: 搜索已知问题

### 使用场景

- 开始调查新问题前，先检查是否已有解决方案
- 客户问题与历史案例相似
- 需要引用已知问题的 workaround

### 搜索流程

```
1. 提取问题关键词
   - 服务名称 (Speech/OpenAI)
   - 错误码或症状
   - API 或功能名称

2. 搜索 services/{service}/tsg/ 目录
   - 先读取 INDEX.md 快速浏览
   - 使用 semantic_search 或 grep_search 匹配关键词
   - 读取相关 TSG 文档

3. 返回搜索结果
   - 相关 TSG 文件路径
   - 问题摘要
   - 解决方案概述
```

### 示例

**输入**: 搜索 Speech API 认证失败相关问题

**执行**:
```
1. 读取 services/speech/tsg/INDEX.md
2. 搜索关键词: "认证", "authentication", "401", "auth"
3. 找到: services/speech/tsg/auth-failed.md
4. 返回摘要和链接
```

**输出**:
```
找到相关 TSG:

[Speech API 认证失败排查指南](services/speech/tsg/auth-failed.md)
- 错误码: 401 Unauthorized
- 常见原因: 
  1. API Key 格式错误
  2. Endpoint 区域不匹配
  3. Key 过期或被重置
- 解决方案: 验证 Key 和 Endpoint 配置
```

---

## ✍️ 功能 2: 生成 TSG 草稿

### 使用场景

- 问题已成功解决，需要记录到知识库
- 新发现的问题模式
- 多个客户遇到相同问题

### 生成流程

```
1. 收集问题信息
   - 从 issue-triage 获取问题分类
   - 从 kusto-debug 获取技术分析
   - 从 repro-helper 获取复现步骤
   - 从 escalation-helper 获取根因（如有升级）

2. 使用 TSG 模板生成草稿
   - 基于 templates/tsg-template.md
   - 填充问题概述、诊断步骤、解决方案
   - 添加预防措施和相关资源

3. 建议分类路径
   - 根据服务和问题类型推荐文件路径
   - 如: services/speech/tsg/lid-accuracy.md

4. 提供索引更新建议
   - 生成 INDEX.md 的新增条目
```

### TSG 模板位置

**模板文件**: [templates/tsg-template.md](templates/tsg-template.md)

### 示例

**输入**: 为 OpenAI API 429 错误生成 TSG

**生成的草稿**:
```markdown
# OpenAI API Rate Limit (429) 排查指南

## 📌 问题概述

**问题名称:** OpenAI API 速率限制错误

**错误码/症状:** 
- 错误码: `429`
- 错误消息: `"Rate limit exceeded"`
- HTTP 响应头: `Retry-After: 60`

**影响范围:**
- [x] 所有超过配额的用户
- [ ] 特定区域
- [ ] 特定配置

---

## 🔍 诊断步骤

### Step 1: 检查当前配额

使用 Azure Portal 或 REST API 查询配额:

```bash
# 查看部署配额
az cognitiveservices account deployment show \
  --name <resource-name> \
  --resource-group <rg-name> \
  --deployment-name <deployment-name>
```

**预期结果:** 显示当前 TPM (Tokens Per Minute) 配额

**如果异常:** → 转到 Step 2

### Step 2: 使用 Kusto 查询实际使用量

```kql
OpenAIBillingEvent
| where Timestamp >= ago(1h)
| where SubscriptionId == "<subscription-id>"
| summarize TotalTokens=sum(TokenCount) by bin(Timestamp, 1m)
| where TotalTokens > <quota-tpm>
```

**预期结果:** 识别峰值使用时段

### Step 3: 检查 Request ID 详情

使用 `kusto-debug` skill 查询具体的 429 响应详情。

---

## 🔬 根因分析

| 可能原因 | 概率 | 验证方法 |
|---------|------|---------|
| 配额不足 | 高 | 对比实际使用量和配额限制 |
| 突发流量 | 中 | 查看 Kusto 使用量时序图 |
| 配置错误 | 低 | 验证 Deployment 配额设置 |

---

## ✅ 解决方案

### 方案 1: 申请配额提升

**适用场景:** 实际业务需求超过当前配额

**步骤:**
1. 登录 Azure Portal
2. 导航到 Cognitive Services 资源
3. 选择 "Quotas" → "Request quota increase"
4. 填写业务理由和目标配额
5. 等待 1-2 个工作日审批

### 方案 2: 实现重试逻辑

**适用场景:** 短期解决方案，优化客户端代码

**步骤:**
```python
import time
from openai import AzureOpenAI

client = AzureOpenAI(...)

def call_with_retry(max_retries=3):
    for attempt in range(max_retries):
        try:
            response = client.chat.completions.create(...)
            return response
        except Exception as e:
            if "429" in str(e):
                wait_time = 2 ** attempt  # 指数退避
                time.sleep(wait_time)
            else:
                raise
    raise Exception("Max retries exceeded")
```

### 方案 3: 分布式负载

**适用场景:** 高流量应用

**步骤:**
1. 在多个区域创建 OpenAI 资源
2. 实现客户端负载均衡
3. 使用 Azure Traffic Manager 或应用层路由

---

## 📋 预防措施

- [x] 配置监控告警：使用量达到 80% 时通知
- [x] 实现客户端重试逻辑（指数退避）
- [x] 定期审查配额需求，提前申请提升
- [x] 使用缓存减少重复请求

---

## 🔗 相关资源

- [Azure OpenAI 配额管理](https://learn.microsoft.com/azure/ai-services/openai/quotas-limits)
- [重试策略最佳实践](https://learn.microsoft.com/azure/architecture/best-practices/retry-service-specific)
- [Kusto Debug Skill](../../../.claude/skills/kusto-debug/SKILL.md)

---

## 📝 更新历史

| 日期 | 作者 | 更新内容 |
|-----|------|---------|
| 2026-02-04 | @engineer | 初始版本 |
```

**建议路径**: `services/openai/tsg/rate-limit-429.md`

**INDEX.md 更新建议**:
```markdown
## 错误处理

- [速率限制 (429)](rate-limit-429.md) - API 调用超过配额
```

---

## 📂 功能 3: 建议分类路径

### 分类规则

根据问题特征推荐 TSG 存放位置：

| 问题类型 | 命名规则 | 示例路径 |
|---------|---------|---------|
| 错误码相关 | `{error-code}-{brief-desc}.md` | `services/speech/tsg/401-auth-failed.md` |
| 功能问题 | `{feature}-{issue}.md` | `services/speech/tsg/lid-accuracy.md` |
| 性能问题 | `{api}-{perf-issue}.md` | `services/openai/tsg/gpt4-latency.md` |
| 配置问题 | `{config}-{issue}.md` | `services/speech/tsg/endpoint-config.md` |

### 文件命名最佳实践

- 使用小写和连字符 (kebab-case)
- 简洁但描述性强
- 包含关键词（便于搜索）
- 避免特殊字符

**好的命名**:
- `rate-limit-429.md`
- `stt-empty-result.md`
- `gpt4-high-latency.md`

**不好的命名**:
- `问题1.md`
- `bug_fix_2026.md`
- `VERY_IMPORTANT_ISSUE.md`

---

## 📝 功能 4: 索引维护

每个服务的 `tsg/INDEX.md` 是 TSG 的快速导航。

### INDEX.md 结构示例

```markdown
# Speech Service TSG 索引

> 故障排除指南快速导航

## 认证和配置

- [认证失败 (401)](auth-failed.md) - API Key 或 Endpoint 配置错误
- [Endpoint 配置](endpoint-config.md) - 区域和 Endpoint 格式问题

## 语音识别 (STT)

- [识别结果为空](stt-empty-result.md) - 返回空文本
- [语言识别准确率低](lid-accuracy.md) - LID 功能问题
- [音频格式不支持](audio-format.md) - 音频编码或采样率问题

## 性能问题

- [STT 响应延迟](stt-latency.md) - 处理时间过长
- [WebSocket 连接超时](websocket-timeout.md) - 实时识别超时

## 错误码速查

| 错误码 | 说明 | TSG 链接 |
|-------|------|---------|
| 401 | 认证失败 | [auth-failed.md](auth-failed.md) |
| 429 | 速率限制 | [rate-limit.md](rate-limit.md) |
| 500 | 服务内部错误 | [server-error-500.md](server-error-500.md) |

## 最近更新

- 2026-02-04: 新增语言识别准确率 TSG
- 2026-01-15: 更新音频格式支持说明
```

### 索引更新建议格式

当生成新 TSG 时，提供 INDEX.md 的更新建议：

```
建议在 services/speech/tsg/INDEX.md 添加以下内容:

## 语音识别 (STT) 部分
添加行:
- [新问题标题](new-tsg-file.md) - 简要描述

## 最近更新 部分
添加行:
- 2026-02-04: 新增 [新问题标题] TSG
```

---

## � 功能 5: 知识捕获与入库

> 原 `knowledge-capture` skill，现为 knowledge-base 的子功能。参考 `rules/knowledge-capture.md`。

### 触发条件

以下情况应触发知识捕获流程：

- **新的错误模式**: 之前未在 `error-patterns` 或 `references/` 中记录的错误码组合或根因
- **新的查询模式**: 更高效的 KQL 查询方式，优于现有 `queries/` 中的模式
- **新的数据表字段**: 表文档（`tables/`）中未记录但在调查中发现有用的字段
- **根因与 TSG 不符**: 实际根因与现有 TSG 文档描述不一致
- **新的调查方法**: 适用于特定场景的调查技巧或工作流

### 知识类型与目标

| 知识类型 | 目标位置 | 文件格式 | 说明 |
|---------|---------|---------|------|
| 新查询模式 | `queries/` | `.kql` 文件 | 按分层放入 `apim/`、`backend/`、`platform/` |
| 新表字段 | `tables/` | 追加到 `.md` | 在对应表文档中添加字段说明 |
| 新错误模式 | `references/` | `.md` 文档 | 或更新 `.claude/skills/error-patterns/` |
| 新调查方法 | `.claude/skills/` | Skill 补丁 | 更新对应 skill 的 SKILL.md |
| 完整案例 | `examples/` | 案例文件夹 | 包含 README.md + 相关查询 |
| TSG 更新 | `services/` | TSG `.md` | 更新对应服务的文档 |

### 入库流程

#### 第 1 步：记录发现
在调查过程中，当发现新知识时：
- 在调查输出中用 📝 标记新发现
- 简要记录发现内容和上下文
- 暂不中断当前调查流程

#### 第 2 步：调查完成后确认
调查结束时，汇总所有 📝 标记的发现，询问用户：
```
📝 本次调查发现以下可入库知识：
1. [知识描述]
2. [知识描述]

是否需要入库？(y/n)
```

#### 第 3 步：生成对应格式文件
根据知识类型，创建或更新对应文件（参考功能 2 和功能 3 的模板和分类规则）。

#### 第 4 步：更新索引
- 更新 `INDEX.md` 中的相关索引
- 如果新增了 skill 补丁，确认 skill 描述覆盖新场景

### 质量标准

| 标准 | 说明 |
|------|------|
| **可复用** | 适用于多个案例，非一次性特例 |
| **可验证** | 包含验证查询或验证步骤 |
| **有上下文** | 记录发现场景、适用条件 |
| **有时效性** | 标注发现日期，便于后续确认是否过期 |

### 不应入库的内容

- 客户特定的配置信息（PII）
- 一次性的临时解决方案
- 未经验证的猜测
- 已有文档完整覆盖的内容（避免重复）

---

## 📋 功能 6: Triage 知识萃取

> 原 `triage-digest` skill，现为 knowledge-base 的子功能。

### 使用场景

- Triage 会议后需要提取关键知识点
- 发现现有技能/文档的空白需要补全
- 需要生成结构化的会议摘要
- 团队知识分享后需要存档和整理

### 输入来源

| 数据源 | 说明 |
|--------|------|
| workiq-mcp | 自动获取会议笔记/OneNote、Teams 讨论 |
| 手动输入 | 用户粘贴会议要点或讨论内容 |

### 萃取流程

1. **解析会议内容** — 识别讨论的关键案例，提取案例 ID、关键发言要点
2. **案例知识提取** — 提取问题类型、根因、解决方案、新知识
3. **知识库对比** — 与现有知识库对比：
   - ✅ **已有覆盖**: 现有文档已包含
   - ⚠️ **需要补充**: 现有文档需要更新
   - ❌ **缺失**: 需要新建文档
4. **生成 Digest 文档** — 输出到 `triage-digests/YYYY-MM-DD-triage.md`
5. **建议知识库补丁** — 对识别出的空白，建议需要更新的 skill 或需要新建的文档

### 输出格式

```markdown
# Triage Digest — [日期]

## 📋 讨论案例
### Case 1: [标题]
- **案例 ID**: [ID]
- **问题类型**: [分类]
- **根因**: [描述]
- **解决方案**: [步骤]
- **新知识**: 📝 [描述]

## 🔍 知识库差距分析
| 缺失项 | 类型 | 当前状态 | 建议操作 |
|--------|------|----------|----------|
| [主题] | skill | ❌ 缺失 | 新建 skill: [名称] |
| [主题] | 文档 | ⚠️ 不完整 | 更新: [文件路径] |

## 📝 建议的知识库补丁
### 更新: [文件名]
- 文件: [路径]
- 修改: [具体修改内容]
```

---

## �🔄 完整工作流程

### 场景: 记录已解决的问题

```
1. 工程师解决了一个问题，想记录到知识库

2. 调用 knowledge-base 生成 TSG 草稿
   输入:
   - 问题描述
   - Kusto 查询结果（来自 kusto-debug）
   - 复现步骤（来自 repro-helper）
   - 解决方案
   
3. knowledge-base 输出:
   - TSG 草稿内容（Markdown 格式）
   - 建议文件路径: services/openai/tsg/rate-limit-429.md
   - INDEX.md 更新建议
   
4. 工程师审核草稿:
   - 补充细节
   - 调整措辞
   - 验证链接和代码
   
5. 手动创建文件并提交
   - 创建 TSG 文件
   - 更新 INDEX.md
   - Git commit 和 push
```

---

## 🔗 集成其他 Skills

### 与 issue-triage 集成
- 问题分类时先调用 `knowledge-base` 搜索已知问题
- 如果找到匹配 TSG，直接引用解决方案

### 与 kusto-debug 集成
- 生成 TSG 时包含关键 Kusto 查询
- 引用 kusto-debug/tables/ 中的表文档

### 与 repro-helper 集成
- TSG 的诊断步骤引用 repro-helper 生成的测试代码
- 复现步骤直接复用

### 与 escalation-helper 集成
- 升级问题解决后，自动建议生成 TSG
- 根因分析部分引用升级文档

---

## 📁 模板文件位置

- **TSG 模板**: [templates/tsg-template.md](templates/tsg-template.md)
- **示例 TSG**: services/speech/tsg/ 和 services/openai/tsg/

---

## ✅ TSG 质量检查清单

生成草稿后确保：
- [ ] 问题描述清晰，包含错误码/症状
- [ ] 诊断步骤可操作，包含具体命令/代码
- [ ] 至少提供一个解决方案
- [ ] 根因分析准确（如已知）
- [ ] 包含预防措施
- [ ] 引用官方文档链接
- [ ] 文件命名符合规范（小写、连字符）
- [ ] 提供 INDEX.md 更新建议

---

## 💡 最佳实践

### 搜索技巧

1. **使用多种关键词**: 错误码 + 服务名 + API 名
2. **先查 INDEX.md**: 快速浏览分类结构
3. **语义搜索**: 用自然语言描述问题，semantic_search 会找到相关内容
4. **交叉引用**: 查看 TSG 中的"相关资源"链接

### TSG 编写技巧

1. **一个 TSG 一个问题**: 避免混合多个不相关问题
2. **操作性强**: 提供可直接执行的命令和代码
3. **及时更新**: 当解决方案过时时更新 TSG
4. **交叉引用**: 链接到相关 TSG 和官方文档
5. **包含截图**: 对于 UI 操作，添加截图（存放在 tsg/images/）

### 索引维护技巧

1. **按类型分组**: 认证、配置、性能、错误码等
2. **错误码速查表**: 方便快速定位
3. **最近更新日志**: 帮助团队了解知识库变化
4. **定期审查**: 每季度检查 TSG 是否过时

---

## 🚫 注意事项

1. **所有 TSG 都是草稿**: 需要工程师审核后手动创建文件
2. **不自动修改文件**: knowledge-base 只提供建议，不直接写入
3. **遵循现有结构**: 使用 services/{service}/tsg/ 模式
4. **敏感信息脱敏**: TSG 中不包含客户密钥、订阅 ID 等敏感信息
5. **版本控制**: 使用 Git 管理 TSG 变更

---

## 📚 参考资源

- [TSG Template](templates/tsg-template.md) - TSG 标准模板
- [Speech TSG Index](services/speech/tsg/INDEX.md) - Speech 服务 TSG 索引
- [OpenAI TSG Index](services/openai/tsg/INDEX.md) - OpenAI 服务 TSG 索引
- [Markdown 语法指南](https://www.markdownguide.org/) - Markdown 编写参考
