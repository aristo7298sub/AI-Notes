---
title: "OpenClaw 底层技术架构深度解析：一只龙虾是怎么变成 AI 助手的"
date: 2026-03-19
category: deep-dive
tags: [openclaw, agent, architecture, function-calling, gateway, personal-ai]
---

# OpenClaw 底层技术架构深度解析：一只龙虾是怎么变成 AI 助手的

> 一句话摘要：拆解 OpenClaw 从消息收发到 LLM 推理再到工具执行的完整技术链路，用类比帮你搞懂一个 324k Star 的开源 AI 助手是怎么运转的。

## 目录

- [背景](#背景)
- [核心概念](#核心概念)
- [深入分析](#深入分析)
  - [第一层：Gateway — 总机接线员](#第一层gateway--总机接线员)
  - [第二层：Agent Loop — 大脑的思考循环](#第二层agent-loop--大脑的思考循环)
  - [第三层：System Prompt — 出厂说明书](#第三层system-prompt--出厂说明书)
  - [第四层：Tool Use — LLM 的手和脚](#第四层tool-use--llm-的手和脚)
  - [第五层：Session — 记忆管理](#第五层session--记忆管理)
  - [第六层：Memory — 永久记忆](#第六层memory--永久记忆)
  - [第七层：Streaming & Queue — 消息流水线](#第七层streaming--queue--消息流水线)
- [实践要点](#实践要点)
- [总结](#总结)
- [参考链接](#参考链接)

---

## 背景

2026 年 3 月，一个叫 OpenClaw（🦞）的开源项目在 GitHub 上积累了 324k Star、1240+ 贡献者。它的定位是**个人 AI 助手** — 你在自己的设备上跑一个服务，然后通过 WhatsApp、Telegram、Slack、Discord、iMessage、微信等**你已经在用的聊天工具**跟 AI 对话。

这不是一个简单的"套壳 ChatGPT"。OpenClaw 有自己的 Gateway 控制面、Agent 运行时、工具系统、会话管理、流式推送……是一个完整的 **Agent 基础设施**。

本文的目标：**像拆一台机器一样，一层一层打开 OpenClaw，看懂每个零件的作用和它们之间的配合。**

---

## 核心概念

先建立词汇表。如果你已经熟悉这些概念，可以直接跳到深入分析。

| 术语                        | 含义                                         | 类比                               |
| --------------------------- | -------------------------------------------- | ---------------------------------- |
| **Gateway**                 | 长驻后台的 WebSocket 服务，所有消息的集散地  | 酒店前台/电话总机                  |
| **Agent Loop**              | 一次完整的"收消息→思考→调工具→回消息"循环    | 厨师接到订单后做菜的全流程         |
| **pi-agent-core**           | 底层 LLM 推理运行时（源自 pi-mono）          | 厨师的核心手艺                     |
| **Tool / Function Calling** | LLM 输出结构化指令让程序执行操作             | 厨师对助手说"帮我拿 3 号调料"      |
| **Skill**                   | 教 Agent 使用特定工具的说明书（SKILL.md）    | 菜谱                               |
| **Session**                 | 一段持续的对话上下文                         | 和同一个人的微信聊天窗口           |
| **Compaction**              | 把过长的对话历史压缩成摘要                   | 会议纪要（把 3 小时的会压成 1 页） |
| **Node**                    | 连接到 Gateway 的设备端（macOS/iOS/Android） | 分店（可以帮总店干活）             |
| **Bootstrap Files**         | 注入到 Agent 的人格/身份/工具指南文件        | 员工入职培训资料                   |

---

## 深入分析

### 第一层：Gateway — 总机接线员

**它做什么：** Gateway 是 OpenClaw 的中枢——一个长驻运行的 WebSocket 服务。所有消息（来自 WhatsApp、Telegram、Discord 等）都先到 Gateway，由它路由给 Agent 处理，再把回复发回去。

**它怎么做：**

想象一个老式酒店的前台总机：

```
WhatsApp ──┐
Telegram ──┤
Slack    ──┤     ┌─────────────────────────────┐
Discord  ──┼────▶│         Gateway              │
Signal   ──┤     │   (ws://127.0.0.1:18789)    │
iMessage ──┤     └──────────┬──────────────────┘
WebChat  ──┘                │
                            ├── Pi Agent (LLM 推理)
                            ├── CLI (命令行)
                            ├── WebChat UI
                            ├── macOS App
                            └── iOS / Android Nodes
```

技术细节：

- **传输协议**：WebSocket，JSON 文本帧。第一帧必须是 `connect`（握手），之后走请求-响应模式
- **帧格式**：请求 `{type:"req", id, method, params}` → 响应 `{type:"res", id, ok, payload|error}`
- **事件推送**：`{type:"event", event, payload}` — 用于 agent 流式输出、在线状态、健康检查等
- **安全**：支持 Token 认证、设备配对（pairing）、挑战签名（challenge nonce）
- **TypeBox 类型系统**：协议用 TypeBox 定义 Schema → 自动生成 JSON Schema → 自动生成 Swift 模型（给 macOS/iOS 用）

**为什么这样做：** 为什么不直接每个频道各自跑一个 bot？因为 Gateway 架构有三个好处：

1. **单一状态源**：所有 Session、配置、工具状态集中管理，不会出现"WhatsApp 那边聊的 Telegram 不知道"
2. **热插拔频道**：加一个新聊天平台只需要写一个 channel adapter，不影响核心逻辑
3. **设备解耦**：Gateway 可以跑在 Linux 服务器上，iOS/macOS 只是连上来的"终端节点"

> 🦞 类比：Gateway 就像你家的 Wi-Fi 路由器——所有设备通过它上网，但路由器本身不产生内容，它只是确保数据到达正确的地方。

---

### 第二层：Agent Loop — 大脑的思考循环

**它做什么：** 每当收到一条消息，Agent Loop 负责完整的处理流程：组装上下文 → 调用 LLM → 执行工具 → 整理回复 → 发出去。

**它怎么做：**

这是 OpenClaw 最核心的流程，分 5 步：

```
1. agent RPC 进来
   │  验证参数、找到/创建 Session、返回 { runId, acceptedAt }
   ▼
2. agentCommand 启动
   │  解析模型配置 + thinking/verbose 开关
   │  加载 Skills 快照
   │  调用 runEmbeddedPiAgent（pi-agent-core 运行时）
   ▼
3. runEmbeddedPiAgent 执行
   │  按 Session 排队（一个 Session 同一时间只有一个 Run）
   │  解析模型 + 认证配置
   │  构建 System Prompt
   │  启动 LLM 推理循环 ←─── 重点在这里
   ▼
4. LLM 推理循环（while not done）
   │  ┌─ LLM 返回文本 → 流式输出
   │  └─ LLM 返回 tool_call → 执行工具 → 把结果喂回 LLM → 继续
   ▼
5. 结束
   │  组装最终回复、触发 lifecycle end 事件
   │  Session 持久化到 JSONL
```

几个关键设计决策：

- **序列化执行**：同一个 Session 的 Agent Run 严格排队执行（不并行），避免竞态
- **全局并发上限**：`agents.defaults.maxConcurrent` 控制整个 Gateway 的并行 Agent Run 数量
- **超时保护**：默认 600 秒，超时自动 abort
- **事件流**：整个过程通过 `lifecycle` / `assistant` / `tool` 三个事件流实时推送给客户端

> 🦞 类比：Agent Loop 就像餐厅的出菜流程——服务员（Gateway）接单，交给厨师（LLM），厨师可能需要助手帮忙拿食材（tool call），菜做好后传菜（streaming），最终端上桌（channel send）。同一桌的菜不能两个厨师同时做（序列化），但不同桌可以并行。

---

### 第三层：System Prompt — 出厂说明书

**它做什么：** 每次 Agent Run 开始时，OpenClaw 自动组装一份 System Prompt 发给 LLM，告诉它"你是谁、能做什么、该怎么做"。

**它怎么做：**

System Prompt 由以下模块拼接而成：

```
┌─────────────────────────────────────────┐
│              System Prompt              │
│                                         │
│  ① Tooling: 可用工具列表 + 简介        │
│  ② Safety: 安全护栏提醒                │
│  ③ Skills: 可用技能列表（XML 格式）    │
│  ④ Workspace: 工作目录路径             │
│  ⑤ Documentation: 本地文档路径          │
│  ⑥ Sandbox: 沙箱环境说明（如果启用）   │
│  ⑦ Current Date & Time: 时区           │
│  ⑧ Runtime: 主机/OS/模型/thinking 级别 │
│  ⑨ Bootstrap 文件注入:                 │
│     - AGENTS.md (操作指南)              │
│     - SOUL.md (人格设定)                │
│     - TOOLS.md (工具使用备注)           │
│     - IDENTITY.md (名字/风格)           │
│     - USER.md (用户档案)                │
│     - MEMORY.md (持久记忆)              │
└─────────────────────────────────────────┘
```

工具呈现方式（**回答本文最初的问题：是 Function Calling 吗？**）：

> Tools are exposed in two parallel channels:
> 1. **System prompt text**: a human-readable list + guidance
> 2. **Tool schema**: the structured function definitions sent to the model API

翻译：工具同时以两种形式告诉 LLM——

1. **人话版**：在 System Prompt 里列出"你有哪些工具、怎么用"
2. **机器版**：在 API 调用时附上工具的 JSON Schema（名称、参数类型、描述）

这就是标准的 **Function Calling / Tool Use** 模式。LLM 看到工具定义后，如果判断需要用某个工具，就输出结构化的调用意图（工具名 + 参数 JSON），OpenClaw 负责实际执行。

**Skills 的巧妙设计**：OpenClaw 不把所有 Skill 的完整内容塞进 Prompt（太浪费 token），而是只注入一个紧凑的列表：

```xml
<available_skills>
  <skill>
    <name>image-lab</name>
    <description>Generate or edit images...</description>
    <location>/path/to/skills/image-lab/SKILL.md</location>
  </skill>
</available_skills>
```

LLM 看到列表后，需要某个 Skill 时会先用 `read` 工具读取 SKILL.md，再按里面的指示操作。**相当于给了 LLM 一个技能目录，用到哪个再翻哪个，而不是一次性把整本百科全书背下来。**

**Bootstrap 文件的 Token 控制**：

- 单文件上限：`bootstrapMaxChars` 默认 20,000 字符
- 总量上限：`bootstrapTotalMaxChars` 默认 150,000 字符
- 超出自动截断并标注警告

**Prompt 模式**：子 Agent 用 `minimal` 模式，只保留工具、安全、工作目录等核心信息，砍掉 Skills、记忆、自更新等，保持子任务的上下文精简。

> 🦞 类比：System Prompt 就像新员工的入职手册——告诉你公司叫什么（Identity）、你的性格是什么（Soul）、你有哪些工具可以用（Tools）、你的老板是谁（User）。但手册不会把公司所有操作手册都印上去，而是告诉你"需要查某个流程的时候去哪个文件柜找"（Skills 列表 + read 工具）。

---

### 第四层：Tool Use — LLM 的手和脚

**它做什么：** LLM 本身只能"想"（生成文本），工具让它能"做"——执行命令、浏览网页、发消息、控制设备。

**它怎么做：**

OpenClaw 的工具严格通过 Function Calling 机制驱动。流程是：

```
LLM: "我需要查一下今天的天气"
  │
  ▼ 输出 tool_call: { name: "web_search", params: { query: "weather today" } }
  │
  ▼ OpenClaw 执行 web_search 工具
  │
  ▼ 把结果作为 tool_result 喂回 LLM
  │
  ▼ LLM: "今天多云，23°C，建议带伞"
```

OpenClaw 内置的工具按功能分组：

| 工具组             | 包含工具                               | 作用                         |
| ------------------ | -------------------------------------- | ---------------------------- |
| `group:runtime`    | `exec`, `bash`, `process`              | 执行终端命令                 |
| `group:fs`         | `read`, `write`, `edit`, `apply_patch` | 文件读写                     |
| `group:sessions`   | `sessions_list/history/send/spawn`     | 跨 Session 通信              |
| `group:web`        | `web_search`, `web_fetch`              | 搜索和抓取网页               |
| `group:ui`         | `browser`, `canvas`                    | 浏览器控制、画布             |
| `group:messaging`  | `message`                              | 跨平台发消息                 |
| `group:nodes`      | `nodes`                                | 设备控制（摄像头/通知/位置） |
| `group:automation` | `cron`, `gateway`                      | 定时任务、网关控制           |

**工具控制的三层防线**：

OpenClaw 不是无脑把所有工具都给 LLM 用。它有精细的控制层：

```
第 1 层：Tool Profile（预设集）
  ├── minimal: 只能看 session 状态
  ├── coding: 文件 + 终端 + session + 图片
  ├── messaging: 消息 + session 查看
  └── full: 全部工具

第 2 层：Allow / Deny 黑白名单
  ├── tools.allow: ["group:fs", "browser"]
  └── tools.deny: ["exec"]  ← deny 永远优先

第 3 层：按模型提供商限制
  └── tools.byProvider:
        "google-antigravity": { profile: "minimal" }
        # 不信任的模型只给最少工具
```

**循环检测（Loop Detection）**：如果 LLM 陷入"调同一个工具 → 得到相同结果 → 再调一次"的死循环，OpenClaw 可以检测并中断：

- `genericRepeat`: 检测完全相同的调用模式
- `knownPollNoProgress`: 检测轮询无进展
- `pingPong`: 检测 A→B→A→B 的交替死循环

**Plugin Hook 拦截**：通过 `before_tool_call` / `after_tool_call` 钩子，插件可以在工具执行前修改参数或在执行后处理结果。

> 🦞 类比：想象你是一个经理（OpenClaw），你手下有一个超级聪明但什么都没干过的实习生（LLM）。你不会直接给他公司信用卡和所有系统的 root 密码。你会给他一个清单列出他能用的工具（Tool Profile），再设置一些禁区（Deny list），还有一个监控系统确保他不会反复做无用功（Loop Detection）。

---

### 第五层：Session — 记忆管理

**它做什么：** 管理"和谁在聊什么"——每段对话的历史、状态、隔离。

**它怎么做：**

Session 的关键设计：

**1. Session Key — 每段对话一个唯一标识**

```
直接聊天: agent:<agentId>:main           # 所有 DM 共用一个（默认）
         agent:<agentId>:telegram:direct:12345  # 按渠道+发送者隔离
群聊:    agent:<agentId>:discord:group:98765
```

`dmScope` 是一个关键开关：
- `main`（默认）：所有 DM 共享同一个 Session。适合单人用
- `per-channel-peer`：按渠道 + 发送者隔离。适合多人用（防止 Alice 的隐私被 Bob 看到）

**2. 对话持久化**

每个 Session 的完整对话记录存为 JSONL 文件：
```
~/.openclaw/agents/<agentId>/sessions/<SessionId>.jsonl
```

一行一条消息/工具调用/结果，完整且可审计。

**3. Compaction — 记忆压缩**

这是 OpenClaw 处理"LLM 上下文窗口有限"问题的方案。

想象你和朋友微信聊了 3 个月，现在问他"上次说的那个餐厅叫什么"。人脑会自动做压缩——记住关键信息，忘记细节。Compaction 就是让 AI 做同样的事：

```
               对话开始          ···         快满了
                 │                             │
   ┌─────────── ─┤                             │
   │ Msg 1       │   ← 这些被压缩成摘要 ─┐    │
   │ Msg 2       │                        │    │
   │ Tool call   │                        │    │
   │ Tool result │                        ▼    │
   │ Msg 3       │   [Compaction Summary]      │
   ├─────────────┤                             │
   │ Msg 47      │   ← 这些保持原样            │
   │ Msg 48      │                             │
   │ Msg 49      │   (最近的消息)               │
   └─────────────┘
```

工作方式：
- **自动压缩**：Session 上下文接近模型限制时自动触发
- **手动压缩**：发 `/compact` 命令强制压缩
- **压缩前记忆刷盘**：在压缩前先运行一个"静默记忆转存"，让 LLM 把重要信息写到磁盘（MEMORY.md），避免压缩时丢失关键内容
- **可配置压缩模型**：可以用一个便宜的模型专门做摘要，主聊天继续用贵的模型

Session Pruning（修剪）与 Compaction 不同：
- **Compaction**：总结历史，写入 JSONL，永久改变
- **Pruning**：只是在发给 LLM 前裁掉旧的 tool result，不改 JSONL 原文

> 🦞 类比：Compaction 像是写日记 — 把一整天的经历浓缩成几句话，原始经历可能模糊了，但关键信息被保留。Pruning 像是出门前整理背包 — 把不需要的工具放回柜子，但柜子里东西还在。

---

### 第六层：Memory — 永久记忆

前面的 Session 和 Compaction 解决了"这轮对话里记得住"的问题。但一旦对话重置（`/new`）或 Compaction 压缩后，细节就可能丢失。**Memory 系统解决的是跨对话、跨时间的永久记忆问题。**

**它做什么：** 让 AI 跨对话保持人格、记住事实、回忆历史。

**它怎么做：**

#### 0. Bootstrap 文件 — 记忆的"基因"

在讲具体的记忆机制之前，先补上一个容易被忽视的"永久记忆"来源：**Bootstrap 文件**。它们不属于"记忆系统"（memory 模块），但效果和记忆一样——每轮对话都注入，跨 Session 永久生效。

```
~/.openclaw/workspace/
├── AGENTS.md       ← 操作指南（"你怎么干活"）
├── SOUL.md         ← 人格灵魂（"你是谁"）
├── IDENTITY.md     ← 名字/风格/emoji
├── USER.md         ← 用户档案（"你的主人是谁"）
├── TOOLS.md        ← 工具使用备注
├── MEMORY.md       ← 长期事实记忆
└── memory/         ← 日记和专题记忆
```

其中 **`SOUL.md`** 最值得单独说——它定义了 AI 的**人格、行为边界、说话风格**。比如：

```markdown
# Soul

你是 Molty，一只友善但直率的太空龙虾助手。
- 说话简洁，不废话
- 遇到不确定的事情直说"我不确定"，不编造
- 用户让你做危险操作时礼貌拒绝
- 偶尔加点幽默（但不要尬）
```

为什么这也是"永久记忆"？因为**人的性格本质就是一种记忆**——你为什么知道自己是内向还是外向？因为过去的经历沉淀为稳定的行为模式。`SOUL.md` 就是 AI 的"性格记忆"，它和事实记忆（MEMORY.md）一起构成了 AI 的完整"自我认知"。

把所有每轮注入的 Bootstrap 文件和记忆系统放在一起看：

| 文件 | 作用 | 人脑类比 |
|------|------|----------|
| `SOUL.md` | 人格、边界、说话风格 | 性格 — "我是什么样的人" |
| `IDENTITY.md` | 名字、emoji | 自我认知 — "我叫什么" |
| `USER.md` | 用户信息 | 社会关系 — "我的主人是谁" |
| `AGENTS.md` | 操作指南和工作习惯 | 职业技能 — "我怎么干活" |
| `TOOLS.md` | 工具使用偏好和注意事项 | 肌肉记忆 — "用这个工具时要注意什么" |
| `MEMORY.md` | 事实、偏好、决策 | 陈述性记忆 — "我知道的事情" |

**这些文件全部每轮注入 System Prompt**，所以它们共同构成了 AI"永远不会忘记"的核心自我。然而，它们也有代价——每个文件都消耗 token，总量上限 150,000 字符。

下面聚焦到专门的记忆存储和检索机制。

#### 1. 两层 Markdown 文件 — 记忆的"硬盘"

OpenClaw 的记忆不是什么花哨的数据库，就是**纯 Markdown 文件**。分两层：

```
~/.openclaw/workspace/
├── MEMORY.md                    ← 长期记忆（精炼版，每轮注入 Prompt）
└── memory/
    ├── 2026-03-17.md            ← 日记（3天前）
    ├── 2026-03-18.md            ← 日记（昨天）
    ├── 2026-03-19.md            ← 日记（今天）
    └── projects.md              ← 专题记忆（不按日期）
```

| 文件                   | 作用                       | 注入方式                       | 类比                   |
| ---------------------- | -------------------------- | ------------------------------ | ---------------------- |
| `MEMORY.md`            | 精炼的长期事实、偏好、决策 | **每轮自动注入** System Prompt | 你脑子里"就是知道"的事 |
| `memory/YYYY-MM-DD.md` | 每天的流水账笔记           | **按需搜索**（不自动注入）     | 你的日记本             |
| `memory/xxx.md`        | 专题笔记（不按日期）       | **按需搜索**                   | 你的专题笔记本         |

关键区别：
- `MEMORY.md` **每次对话都会被读取并塞进 Prompt**，所以它消耗 token，必须保持精简
- `memory/` 目录下的日记文件**不会自动注入**，只有 AI 主动用 `memory_search` 搜索时才会被召回

这就像人脑的两种记忆：
- **工作记忆**（MEMORY.md）：随时可用，但容量有限——你知道自己叫什么名字、住在哪个城市
- **长期存储**（memory/*.md）：海量信息存着，需要时"回想"才能调出来——去年暑假去了哪个餐厅

#### 2. 两个工具 — 记忆的"读写接口"

AI 通过两个 Function Call 工具操作记忆：

| 工具            | 作用                               | 类比                                 |
| --------------- | ---------------------------------- | ------------------------------------ |
| `memory_search` | 语义搜索所有记忆文件，返回相关片段 | "我好像在哪里记过这个……"（大脑回忆） |
| `memory_get`    | 精确读取某个记忆文件的特定行       | 翻开日记找到具体那页                 |

而**写入记忆**则直接用通用的 `write` / `edit` 工具往 Markdown 文件里写——没有专门的"记忆写入"工具，因为记忆就是普通文件。

一个典型的记忆工作流：

```
用户: "记住我老婆的生日是 6月15号"
  │
  ▼ LLM 决定调用 write 工具
     tool_call: { name: "write", params: {
       path: "MEMORY.md",
       content: "- 老婆的生日：6月15号"
     }}
  │
  ▼ 下次对话（哪怕几个月后）
     MEMORY.md 被注入到 System Prompt
     LLM 自然就"知道"了
```

#### 3. 向量搜索 — 记忆的"联想能力"

人类的记忆不是精确查找（数据库 WHERE 匹配），而是**联想**——"这个好像和那个有关"。OpenClaw 的 `memory_search` 也是这样工作的。

底层实现是一套**混合搜索（Hybrid Search）**系统：

```
搜索请求: "之前配的那个路由器"
         │
    ┌────┴────┐
    ▼         ▼
  向量搜索   BM25关键词搜索
  (语义匹配)  (精确匹配)
    │         │
    └────┬────┘
         ▼
    加权合并
    finalScore = 0.7 × vectorScore + 0.3 × textScore
         │
         ▼
    时间衰减（可选）
    最近的记忆得分更高
         │
         ▼
    MMR 去重（可选）
    去掉内容重复的片段
         │
         ▼
    返回 Top-K 片段
```

**为什么需要两种搜索？**

| 搜索类型    | 擅长                | 不擅长              | 例子                                               |
| ----------- | ------------------- | ------------------- | -------------------------------------------------- |
| 向量搜索    | 意思相近但措辞不同  | 精确的 ID、代码符号 | "Mac 上跑网关" ≈ "the machine running the gateway" |
| BM25 关键词 | 精确匹配 ID、错误码 | 同义词、不同说法    | 搜 "a828e60" 只有精确匹配才找得到                  |

两者合体 = 既能"联想"又能"精确召回"。

**向量搜索的技术栈**：
- 把 Markdown 文件切成约 400 token 的小块，80 token 重叠
- 用 Embedding 模型（支持 OpenAI、Gemini、Voyage、Mistral、本地 GGUF）将文本转为向量
- 存入 SQLite（可选 sqlite-vec 加速）
- 搜索时同样将 query 向量化，做余弦相似度匹配
- 通过 `memory.qmd.*` 还可以接入 QMD（BM25 + 向量 + reranking 的本地搜索引擎）

**时间衰减（Temporal Decay）— 记忆的"遗忘曲线"**：

```
衰减公式: decayedScore = score × e^(-λ × ageInDays)

默认半衰期 30 天：
  今天的记忆   → 得分 × 100%
  7天前       → 得分 × 84%
  30天前      → 得分 × 50%
  90天前      → 得分 × 12.5%
  180天前     → 得分 × 1.6%
```

**但 `MEMORY.md` 和非日期文件永远不衰减**——它们是"常识"，不应该被遗忘。只有 `memory/YYYY-MM-DD.md` 格式的日记文件才会随时间淡化。

> 这就像人的记忆：昨天中午吃了什么你记得很清楚，三个月前的某个周二中午吃了什么就模糊了——但"家里 Wi-Fi 密码"不会因为时间久就忘掉。

**MMR 去重 — 避免"说了三遍同一件事"**：

如果你每天日记都写"今天又给路由器改了 VLAN 配置"，搜"路由器配置"时可能返回 5 条几乎一样的结果。MMR（Maximal Marginal Relevance）会自动去重，保证结果多样性。

#### 4. 自动记忆刷盘 — 压缩前的抢救

前面讲过 Compaction 会压缩对话历史。一个潜在的问题是：Compaction 压缩时，那些"还没来得及记下来"的重要信息可能被摘要丢掉。

OpenClaw 的解决方案很巧妙：

```
对话进行中...
    │
    ▼ token 数接近上下文窗口上限
    │
    ▼ 触发 Memory Flush（静默的一轮对话）
       System Prompt 追加: "Session nearing compaction. Store durable memories now."
       User Prompt: "Write any lasting notes to memory/YYYY-MM-DD.md; reply with NO_REPLY."
    │
    ▼ LLM 把重要信息写到记忆文件
    ▼ 回复 NO_REPLY（用户看不到这轮对话）
    │
    ▼ 然后才执行 Compaction 压缩
```

**用户完全感知不到这个过程**——它是一个"静默的"额外对话轮次，LLM 用 `NO_REPLY` 回复所以不会在聊天里显示。相当于在搬家前先把重要文件锁进保险柜，然后再开始打包。

#### 5. 全景图 — 记忆的完整生命周期

把以上所有机制串起来：

```
┌────────────────────────────────────────────────────────────┐
│                   OpenClaw 记忆全景                        │
│                                                            │
│  ┌──────────────┐                 ┌──────────────┐        │
│  │  SOUL.md     │   每轮注入     │              │        │
│  │  IDENTITY.md │ ──────────────▶│ System Prompt │        │
│  │  USER.md     │   ("基因")     │              │        │
│  │  AGENTS.md   │                │              │        │
│  └──────────────┘                │              │        │
│  ┌──────────────┐   每轮注入     │              │        │
│  │  MEMORY.md   │ ──────────────▶│              │        │
│  │  (精炼长记忆) │   ("事实")     │              │        │
│  └──────┬───────┘                └──────────────┘        │
│         │ write/edit                      ▲               │
│         │                                 │ memory_search  │
│  ┌──────┴───────┐    向量索引     ┌───────┴──────┐        │
│  │ memory/*.md  │ ─────────────▶ │  SQLite/QMD  │        │
│  │ (每日日记)    │                │ (Hybrid 搜索) │        │
│  └──────────────┘                └──────────────┘        │
│                                                            │
│  Session 对话 ──── Memory Flush ────▶ memory/YYYY-MM-DD.md│
│  (即将压缩时)     (静默写入)                               │
│                                                            │
│  Session 对话 ──── Compaction ────▶ [压缩摘要]            │
│  (压缩后)        (细节可能丢失，但记忆已保存)              │
└────────────────────────────────────────────────────────────┘
```

> 🦞 类比：把 OpenClaw 的记忆系统想象成一个人的记忆方式——
> - **SOUL.md** = 性格和三观（你是什么样的人，不需要"想起来"，就是你自己）
> - **MEMORY.md** = 脑子里随时能想起来的事实（家人生日、公司地址）
> - **memory/日记.md** = 日记本，需要翻才能找到（上周三的会议纪要）
> - **memory_search** = 大脑的联想能力（"这个让我想起了……"）
> - **Memory Flush** = 入睡前的记忆巩固（睡眠阶段大脑整理白天经历，把重要的转为长期记忆）
> - **时间衰减** = 自然遗忘曲线（近期的清晰，远期的模糊，但"常识"不会忘）

---

### 第七层：Streaming & Queue — 消息流水线

**它做什么：** 控制消息如何"一点点"显示在聊天界面上，以及多条消息同时涌入时怎么排队。

**Streaming — 两层流式输出：**

OpenClaw 有两个独立的流式输出层：

```
Layer 1: Block Streaming — 把回复分块发出
  ├── text_end 模式: 边写边发（像打字一样）
  └── message_end 模式: 写完再一次性发（可能分多条）

Layer 2: Preview Streaming — 在聊天里显示"正在输入…"的预览
  ├── Telegram: sendMessage + editMessageText
  ├── Discord: send + edit
  └── Slack: chat.startStream / append / stop
```

Block Streaming 的分块算法很精致：
- 有最小字符数（别发太碎）和最大字符数（别发太长）
- 断点偏好：优先在段落处断 → 换行处断 → 句子处断 → 空格处断 → 硬切
- **代码块保护**：永远不在代码块中间切断；如果被迫切，会自动关闭并重新打开代码围栏
- 还可加"人类节奏感"（`humanDelay`）：800-2500ms 的随机停顿，让多条消息的发送节奏更自然

**Queue — 消息排队机制：**

当你连续发了 5 条消息，AI 还在处理第 1 条时，后面的怎么办？

```
消息 1 ─── Agent 正在处理 ─── ✅ 回复
消息 2 ─┐
消息 3 ─┤  排队中...
消息 4 ─┤
消息 5 ─┘
```

四种队列模式：

| 模式            | 行为                                    | 适用场景                 |
| --------------- | --------------------------------------- | ------------------------ |
| `collect`       | 攒起来，当前 Run 结束后一起处理（默认） | 大多数场景               |
| `steer`         | 立即注入当前 Run，中断后续 tool call    | 需要实时纠正 AI 方向     |
| `followup`      | 排队等当前 Run 结束后逐条处理           | 严格按顺序               |
| `steer-backlog` | 立即注入 + 保留消息给下一轮             | 既要即时反馈又要不丢消息 |

还有防洪设计：
- `debounceMs`：等一会儿再开始处理（防止"继续，继续"狂发）
- `cap`：队列最大 20 条
- `drop: "summarize"`：超出上限的消息被压缩成一个摘要注入

> 🦞 类比：Streaming 像一个逐字打字机 vs 一次性打印全文的区别。Queue 像排队买奶茶——`collect` 是让你把所有加料需求一次说完再做，`steer` 是做到一半你喊"冰去掉！"店员立刻改。

---

## 实践要点

**1. OpenClaw 的安全模型是"分层信任"**

- 主 Session（你自己的 DM）：默认拥有所有工具权限，包括宿主机终端
- 群聊/ Channel Session：建议开沙箱（`sandbox.mode: "non-main"`），让 bash 在 Docker 容器里跑
- 工具黑名单 > 白名单 > Profile > 按模型限制：deny 永远优先
- DM 默认走 pairing 模式，陌生人需要通过配对码才能和你的 AI 聊天

**2. Token 开销的隐藏来源**

- Bootstrap 文件（AGENTS.md / SOUL.md / MEMORY.md）**每轮都注入**，字越多越烧钱
- Skills 列表每个约 24+ token，10 个 Skill ≈ 240+ token 的固定开销
- `MEMORY.md` 会随使用增长，需要定期精简
- 用 `/context list` 查看各注入文件的 token 消耗占比

**3. 性能调优的几个关键旋钮**

| 配置                             | 作用                  | 建议                    |
| -------------------------------- | --------------------- | ----------------------- |
| `agents.defaults.maxConcurrent`  | 全局并行 Agent Run 数 | 单用户 4 就够           |
| `agents.defaults.timeoutSeconds` | 单次 Run 超时         | 默认 600s，复杂任务可加 |
| `compaction.model`               | 压缩用的模型          | 用便宜模型省钱          |
| `session.maintenance.mode`       | Session 清理策略      | 生产环境用 `enforce`    |
| `tools.loopDetection.enabled`    | 工具调用死循环检测    | 建议开启                |

**4. 它和"套壳 ChatGPT"的本质区别**

| 维度 | 套壳 ChatGPT     | OpenClaw                                 |
| ---- | ---------------- | ---------------------------------------- |
| 数据 | 存在厂商服务器   | 本地 JSONL 文件                          |
| 模型 | 固定一家         | 随时切换（OpenAI/Anthropic/Google/本地） |
| 渠道 | 只有一个网页界面 | 20+ 聊天平台                             |
| 工具 | API 厂商控制     | 自定义 + Plugin + Skill                  |
| 记忆 | 黑盒             | 透明的文件系统                           |
| 并发 | 无               | 多 Agent、多 Session、跨设备             |

---

## 总结

1. **Gateway 是总机**：一个 WebSocket 服务统一管理所有聊天渠道和设备连接，是整个系统的控制面
2. **底层确实是 Function Calling**：LLM 通过标准的工具 Schema 决定"调什么"，OpenClaw 执行并返回结果，形成推理-行动循环
3. **System Prompt 是动态组装的**：每次 Agent Run 都根据当前配置、Skills、Bootstrap 文件、沙箱状态重新拼装，而非一个固定的字符串
4. **Session 设计保证了隔离和记忆**：通过 Session Key 路由实现多用户/多渠道隔离，通过 Compaction 解决上下文窗口限制
5. **永久记忆 = Markdown + 向量搜索 + 自动刷盘**：用最简单的文件格式存储记忆，用混合搜索（向量+关键词）实现"联想"，用 Memory Flush 确保压缩前不丢关键信息
6. **控制层比推理层更复杂**：OpenClaw 的大部分工程量不在"调 LLM API"上，而在排队调度、流式分块、工具管控、安全沙箱、记忆检索、设备协同这些 Agent 基础设施上

一句话总结：**OpenClaw 证明了一个观点——做一个真正有用的 AI 助手，LLM 只是引擎，围绕引擎的控制面、管道系统和安全机制才是真正的工程量。**

---

## 参考链接

- [OpenClaw GitHub](https://github.com/openclaw/openclaw)
- [OpenClaw Docs — Architecture](https://docs.openclaw.ai/concepts/architecture)
- [OpenClaw Docs — Agent Runtime](https://docs.openclaw.ai/concepts/agent)
- [OpenClaw Docs — Agent Loop](https://docs.openclaw.ai/concepts/agent-loop)
- [OpenClaw Docs — System Prompt](https://docs.openclaw.ai/concepts/system-prompt)
- [OpenClaw Docs — Tools](https://docs.openclaw.ai/tools)
- [OpenClaw Docs — Skills](https://docs.openclaw.ai/tools/skills)
- [OpenClaw Docs — Session Management](https://docs.openclaw.ai/concepts/session)
- [OpenClaw Docs — Memory](https://docs.openclaw.ai/concepts/memory)
- [OpenClaw Docs — Compaction](https://docs.openclaw.ai/concepts/compaction)
- [OpenClaw Docs — Streaming & Chunking](https://docs.openclaw.ai/concepts/streaming)
- [OpenClaw Docs — Command Queue](https://docs.openclaw.ai/concepts/queue)
- [ClawHub — Skills Registry](https://clawhub.com/)
