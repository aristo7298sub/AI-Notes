---
title: "NemoClaw 安全架构深度解析：NVIDIA 如何让 AI Agent 不再'裸奔'"
date: 2026-03-19
category: deep-dive
tags: [AI Agent, NemoClaw, OpenShell, sandbox, security, NVIDIA, Landlock, seccomp]
---

# NemoClaw 安全架构深度解析：NVIDIA 如何让 AI Agent 不再"裸奔"

> 一句话摘要：NemoClaw 通过四层纵深防御（Filesystem / Network / Process / Inference）将 AI Agent 关进内核级沙箱，实现"默认拒绝、显式授权"的安全模型。

> **给非技术读者**：想象你雇了一个超级能干的实习生（AI Agent），但你第一天不会给他公司所有房间的钥匙、管理员密码、和公司信用卡。NemoClaw 做的就是这件事——给 AI 一间专属办公室、一份严格的工作清单，AI 只能做清单上的事。想做清单外的事？必须打电话请示老板。

## 目录

- [NemoClaw 安全架构深度解析：NVIDIA 如何让 AI Agent 不再"裸奔"](#nemoclaw-安全架构深度解析nvidia-如何让-ai-agent-不再裸奔)
  - [目录](#目录)
  - [背景](#背景)
  - [核心概念](#核心概念)
  - [深入分析](#深入分析)
    - [第一层：文件系统隔离 — Landlock LSM](#第一层文件系统隔离--landlock-lsm)
    - [第二层：进程隔离 — seccomp + 特权分离](#第二层进程隔离--seccomp--特权分离)
    - [第三层：网络隔离 — Network Namespace + L7 Proxy](#第三层网络隔离--network-namespace--l7-proxy)
      - [3a. Network Namespace — 物理隔离](#3a-network-namespace--物理隔离)
      - [3b. HTTP CONNECT Proxy — 策略执行点](#3b-http-connect-proxy--策略执行点)
      - [3c. 临时 CA + TLS 检查](#3c-临时-ca--tls-检查)
    - [第四层：推理隔离 — Inference Routing](#第四层推理隔离--inference-routing)
    - [Policy Engine：OPA/Rego 声明式策略](#policy-engineoparego-声明式策略)
    - [供应链安全：Blueprint 摘要验证](#供应链安全blueprint-摘要验证)
    - [操作员审批流：Human-in-the-Loop](#操作员审批流human-in-the-loop)
  - [与其他方案的对比](#与其他方案的对比)
  - [实践要点](#实践要点)
    - [1. 安全边界的真正价值在于"默认拒绝"](#1-安全边界的真正价值在于默认拒绝)
    - [2. 每一层都独立生效](#2-每一层都独立生效)
    - [3. TOFU 二进制验证的巧妙设计](#3-tofu-二进制验证的巧妙设计)
    - [4. SSRF 防护是必须的](#4-ssrf-防护是必须的)
    - [5. 当前局限性](#5-当前局限性)
  - [总结](#总结)
  - [参考链接](#参考链接)

---

## 背景

自主 AI Agent（如 OpenClaw/Claude Code/Codex）正在从"交互式问答"走向"持续自主执行"——它们可以读写文件、执行命令、调用 API、发起网络请求。但能力越大，风险越大：

| 风险类型   | 具体场景                                                    | 通俗理解                              |
| ---------- | ----------------------------------------------------------- | ------------------------------------- |
| 数据外泄   | Agent 读取 ~/.ssh/id_rsa 并通过 HTTP 发送到外部服务器       | 实习生偷拍公司机密文件发给竞争对手    |
| 权限提升   | Agent 执行 `sudo` 或创建 raw socket 绕过网络控制            | 实习生自己配了一把万能钥匙            |
| 供应链攻击 | Agent 安装恶意 npm 包或 pip 包，执行任意代码                | 实习生从不明渠道带了个U盘插进公司电脑 |
| 成本失控   | Agent 无限调用付费推理 API，账单爆炸                        | 实习生拿公司信用卡疯狂消费            |
| SSRF       | Agent 通过 DNS rebinding 访问云元数据端点 (169.254.169.254) | 实习生绕道从后门进入了服务器机房      |

传统做法是"信任 Agent，事后审计"。NVIDIA 的方案是反过来——**默认拒绝一切，逐项显式授权**。

NemoClaw 是 NVIDIA 开源的 Agent 安全运行栈，底层依赖 **OpenShell**（Rust 实现的 Agent 沙箱运行时）。NemoClaw 本身是 OpenShell 的一个 Plugin + Blueprint，专门为 OpenClaw Agent 提供开箱即用的安全配置。

## 核心概念

| 术语                  | 含义                                                  | 技术类比                            | 生活类比                                         |
| --------------------- | ----------------------------------------------------- | ----------------------------------- | ------------------------------------------------ |
| **OpenShell**         | NVIDIA 的 Agent 安全运行时，用 Rust 编写的沙箱引擎    | "Agent 的 Docker"                   | 一栋配有门禁、监控、保安的办公大楼               |
| **NemoClaw**          | OpenShell 之上的 Plugin，为 OpenClaw 提供一键安全部署 | "Docker Compose for Agent security" | 大楼的"拎包入住"套餐——安保系统预装好             |
| **Blueprint**         | 版本化的 Python 编排器，定义沙箱创建、策略和推理配置  | "Helm Chart"                        | 办公室的装修图纸，精确到哪里装锁、哪里装摄像头   |
| **Sandbox**           | 隔离的容器环境，Agent 在其中运行                      | "隔离容器"                          | Agent 的专属办公室，门窗都有锁                   |
| **Policy**            | YAML 声明式安全策略，定义文件/网络/进程权限           | "防火墙规则"                        | 贴在墙上的《员工行为准则》——白纸黑字列明能做什么 |
| **Gateway**           | 控制面 API 服务，管理沙箱生命周期                     | "K8s API Server"                    | 大楼的物业管理中心                               |
| **Operator Approval** | 人工审批未授权请求的 TUI 流程                         | "sudo 提示"                         | 实习生想做规则之外的事，必须打电话请示主管       |

整体架构：

```
┌─────────────────────────────────────────────────────────────┐
│  Host                                                        │
│  ┌─────────┐    ┌──────────┐    ┌─────────────────────────┐ │
│  │nemoclaw │───▶│Blueprint │───▶│ OpenShell Gateway (K3s) │ │
│  │  CLI    │    │ (Python) │    │  gRPC + HTTP + SSH      │ │
│  └─────────┘    └──────────┘    └──────────┬──────────────┘ │
│                                             │                │
│  ┌──────────────────────────────────────────▼──────────────┐ │
│  │  Sandbox Container (OCI)                                │ │
│  │  ┌────────────┐  ┌─────────┐  ┌─────────────────────┐  │ │
│  │  │ Supervisor │  │  Proxy  │  │  Agent (OpenClaw)    │  │ │
│  │  │ (root)     │  │  (L7)   │  │  (unprivileged user) │  │ │
│  │  └────────────┘  └────┬────┘  └──────────────────────┘  │ │
│  │                       │                                  │ │
│  │  Landlock + seccomp + netns + OPA/Rego Policy           │ │
│  └──────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼ (via Gateway)
                   NVIDIA Cloud Inference
                   (build.nvidia.com)
```

## 深入分析

NemoClaw 的安全不是某一个银弹，而是 **四层独立防御** 的叠加——任何一层被突破，其他层仍然有效。这是经典的纵深防御 (Defense in Depth) 策略。

> **类比：银行金库的安全**
> 银行不会只靠一把锁保护金库。它有：围墙（文件系统隔离）、安检门禁（进程隔离）、武装押运（网络隔离）、金库密码只有行长知道（推理隔离）。小偷要同时搞定围墙+门禁+押运+密码才能得手——这就是为什么四层比一层安全得多。

### 第一层：文件系统隔离 — Landlock LSM

> **🏨 类比：酒店房卡系统**
> 你入住酒店，房卡只能开你自己的房间。你刷不了别人的房间，也刷不了员工通道。Landlock 就是这张房卡——Agent 只能进入 `/sandbox`（自己的房间）和 `/tmp`（公共休息区），其他房间的门根本打不开。而且这张房卡是前台在你入住时就设定好的，你自己改不了权限。

**它做什么**：限制 Agent 只能读写特定目录，其他一切禁止。

**它怎么做**：使用 Linux 内核的 **Landlock LSM**（Linux Security Module）在内核态实施文件系统访问控制。

```yaml
# 文件系统策略（从 openclaw-sandbox.yaml 提取）
filesystem:
  read-write:
    - /sandbox    # Agent 的工作区
    - /tmp        # 临时文件
    - /dev/null   # 标准黑洞
  read-only:
    - /usr        # 系统二进制
    - /lib        # 共享库
    - /proc       # 进程信息
    - /dev/urandom # 随机数
    - /app        # 应用目录
    - /etc        # 配置文件
    - /var/log    # 日志
```

**为什么这样做**：

1. **内核态执行**：Landlock 不是在应用层做检查（可以被绕过），而是在 Linux 内核的安全模块层面进行拦截。即使 Agent 通过 shellcode 获得了代码执行，也无法读取 `/home`、`~/.ssh`、`~/.aws` 等敏感目录。

2. **创建时锁定**：文件系统策略在沙箱创建时设定，运行时无法修改（"Locked at sandbox creation"），排除了 Agent 动态提权的可能。

3. **专用用户**：沙箱进程以独立的 `sandbox` 用户和组运行，双重保障。

> **关键设计**：Landlock 是 Linux 5.13+ 的内核特性（2021 年引入），它独特之处在于**非特权进程也能给自己设定限制**——Supervisor 以 root 身份给 Agent 子进程设好 Landlock 围栏后，Agent 无法解除。

### 第二层：进程隔离 — seccomp + 特权分离

> **🔧 类比：受限工具箱**
> 你给实习生一个工具箱干活，但里面只有螺丝刀和扳手——没有电钻、没有焊枪、更没有炸药。seccomp 就是这个"受限工具箱"：Agent 可以用正常的系统功能（读文件、跑程序），但"造一条秘密网络通道"、"偷看管理员在干什么"这些危险工具被直接从箱子里拿掉了。同时，Agent 只是"实习生"身份（非特权用户），而"管理层"（Supervisor）才有完整权限。

**它做什么**：阻止 Agent 执行危险的系统调用，并以最低权限运行。

**它怎么做**：

1. **seccomp BPF 过滤器**：阻止 Agent 创建 raw socket（防止绕过网络代理）、阻止 `ptrace`（防止调试 Supervisor）等危险 syscall。

2. **特权分离**（Privilege Separation）：沙箱内运行两个进程——Supervisor（特权）和 Agent（非特权）：

```
沙箱容器
├── Supervisor (root) ─── 管理沙箱、注入凭据、维护策略
└── Agent (sandbox user) ─── 实际执行 AI 任务，最低权限
```

**为什么这样做**：

- **seccomp 阻断绕过路径**：如果只靠 Network Namespace 隔离网络，Agent 仍可通过 `socket(AF_PACKET, ...)` 创建原始套接字来绕过。seccomp 在 syscall 层面直接禁止这类调用。
- **特权分离限制爆炸半径**：即使 Agent 进程被攻破，攻击者也没有 root 权限，无法修改 Supervisor、读取其他进程的内存、或修改安全策略。

### 第三层：网络隔离 — Network Namespace + L7 Proxy

> **📬 类比：监狱的邮件收发室**
> 在监狱里，犯人不能自己跑去邮局寄信。所有信件必须交给收发室，狱警会拆开检查——看你写给谁、写了什么内容。违规的信直接扣留，合规的才帮你寄出去。NemoClaw 的网络隔离就是这个"收发室"：Agent 完全没有直接上网的能力，所有网络请求必须经过一个"检查站"（Proxy），Proxy 会检查你要联系谁、用什么方式、信里写了什么。

这是 NemoClaw 安全设计中最精彩的部分。分三个子层：

#### 3a. Network Namespace — 物理隔离

**它做什么**：Agent 进程运行在独立的 Linux Network Namespace 中。

**关键效果**：Agent **在物理上无法直接发送任何网络包到互联网**。它的网络世界里，唯一能到达的目的地就是本地代理（Proxy）。这不是软件层面的拦截——是内核网络栈层面的隔离。

> 通俗说：Agent 的"网线"只连接到 Proxy，Proxy 再决定是否帮它连到外面。就像犯人的电话线只接到狱警值班室——你不能直接拨外线。

#### 3b. HTTP CONNECT Proxy — 策略执行点

**它做什么**：所有网络请求必须经过 Proxy，Proxy 逐一裁决放行或拒绝。

**它怎么做**（6 步决策链）：

> **通俗版**：每次 Agent 想上网，Proxy 都会执行一套"六重盘问"——你是谁？你没被掉包吧？你有权限联系这个人吗？这个地址不是假的吧？你想干什么？好，过/不过。

```
Agent 发起请求
    │
    ▼
① 识别调用者：通过 /proc 检查发起连接的是哪个二进制文件
   → 类比：「是谁在寄这封信？出示你的工牌」
    │
    ▼
② 验证二进制完整性：Trust-on-First-Use (TOFU) 模型
   首次见到的二进制 → 记录 SHA256 哈希
   后续请求 → 校验哈希是否一致（防篡改）
   → 类比：「你的工牌照片和你本人对得上吗？没被人冒名顶替吧？」
    │
    ▼
③ OPA 策略评估：基于 (目标主机, 端口, 请求二进制) 三元组查询 Rego 策略
   → 类比：「查一下员工手册——你这个岗位允许联系这个供应商吗？」
    │
    ▼
④ SSRF 防护：DNS 解析后检查目标 IP，阻止访问：
   - 127.0.0.0/8 (localhost)
   - 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16 (RFC 1918)
   - 169.254.169.254 (云元数据端点)
   → 类比：「这个收件地址看着是外部的，但查了一下其实是公司内部地址——拒绝！防止有人冒充外部地址偷偷联系内部」
    │
    ▼
⑤ L7 协议检查（可选）：对特定端点终止 TLS，检查 HTTP 方法 + 路径
   例：GitHub API 只允许 GET，不允许 POST（防止代码提交）
   → 类比：「你可以去图书馆看书（GET），但不能往里面塞私货（POST）」
    │
    ▼
⑥ 放行或拒绝
```

**实际策略示例**（来自 `openclaw-sandbox.yaml`）：

| 端点组          | 允许的主机             | 允许的二进制              | 允许的方法                    |
| --------------- | ---------------------- | ------------------------- | ----------------------------- |
| github          | github.com:443         | /usr/bin/gh, /usr/bin/git | All                           |
| github_rest_api | api.github.com:443     | /usr/bin/gh               | GET, POST, PATCH, PUT, DELETE |
| npm_registry    | registry.npmjs.org:443 | openclaw, npm             | **GET only**                  |
| openclaw_docs   | docs.openclaw.ai:443   | openclaw                  | **GET only**                  |
| telegram        | api.telegram.org:443   | Any                       | GET, POST on /bot*/**         |

注意 npm_registry 只允许 **GET**——Agent 可以下载包，但不能 publish 包。这就是 L7 检查的精细度。

> **通俗说**：这不只是"你可以去超市"这种粗粒度许可，而是精确到"你可以去超市**看商品和买东西**，但不能**把自己的东西摆上货架卖**"这种程度的管控。

#### 3c. 临时 CA + TLS 检查

**它做什么**：Proxy 在启动时生成一个临时 Certificate Authority，注入到沙箱的信任存储中。

**为什么需要**：如果只允许 HTTP CONNECT tunnel，Proxy 只能看到 SNI（目标主机名）。要做 L7 检查（HTTP 方法、路径、请求体），必须终止 TLS 连接并解密内容。临时 CA 使这成为可能，同时确保 CA 私钥不会泄露到沙箱外。

### 第四层：推理隔离 — Inference Routing

> **🔑 类比：公司礼宾台代叫出租车**
> 实习生想叫出租车（调用 AI 模型），但公司不给他出租车公司的电话号码和公司账号。他只需要走到大楼礼宾台说"我要叫车"，礼宾台用公司账号帮他叫，实习生坐上车就行——全程不知道公司的约车账号密码。这样即使实习生嘴巴不严（被 prompt injection），也泄露不了公司的付费账号。

**它做什么**：Agent 的推理请求永远不直接离开沙箱。

**它怎么做**：

```
Agent 调用 inference.local
    │ (HTTPS CONNECT)
    ▼
Proxy 拦截 → 绕过 OPA → TLS 终止 → 解析 HTTP 请求
    │
    ▼
检测推理 API 模式：
  - POST /v1/chat/completions (OpenAI)
  - POST /v1/messages (Anthropic)
  - GET /v1/models (模型发现)
    │
    ▼
openshell-router 转发到真正的后端 (build.nvidia.com)
  - 替换 Auth Header（Agent 永远看不到真正的 API Key）
  - 注入特定 Provider 的 Header（如 anthropic-version）
  - 覆写请求体中的 model 字段
```

**为什么这样做**：

1. **凭据隔离**：Agent 永远看不到真正的 NVIDIA API Key。Supervisor 从 Gateway 获取凭据，Proxy 在转发时注入。即使 Agent 的代码被注入恶意 prompt，也无法泄露 API Key。

2. **零代码修改**：Agent 只需要把 SDK 指向 `https://inference.local`，标准的 OpenAI/Anthropic SDK 调用就能正常工作——Proxy 透明处理一切。

3. **运行时切换**：推理路由支持热重载，可以在不重启沙箱的情况下切换模型或 Provider。

4. **非推理请求拒绝**：任何发往 `inference.local` 但不匹配已知推理 API 模式的请求，直接返回 403。

### Policy Engine：OPA/Rego 声明式策略

> **📋 类比：公司合规手册**
> 好的公司不会让保安凭记忆决定谁能进谁不能进，而是有一本白纸黑字的《访客管理制度》。OPA/Rego 就是这本制度——用清晰的文字写明"谁、在什么条件下、可以做什么"。制度可以随时修订（热重载），每次修订都有记录可查（Git 追踪），不同部门可以有不同版本（per-sandbox 策略）。

NemoClaw 没有硬编码安全规则，而是采用 **Open Policy Agent (OPA)** 和 **Rego 策略语言** 抽象出了一个通用策略引擎。

策略以 YAML 编写、由 OPA 引擎（嵌入在 Rust 代码中）以 Rego 评估。这意味着：

- **声明式**：写"允许什么"，不写"怎么拦截"
- **可审计**：策略文件就是安全规范，Git 追踪变更
- **可定制**：不同沙箱可以有不同策略
- **热重载**：网络和推理策略支持运行时更新（`openshell policy set`），无需重启沙箱

```yaml
# 策略结构概念示例
network:
  - name: github_rest_api
    endpoints:
      - host: api.github.com
        port: 443
    binaries:
      - /usr/bin/gh
    rules:
      - methods: [GET, POST, PATCH, PUT, DELETE]
        paths: ["/**"]
```

### 供应链安全：Blueprint 摘要验证

> **📦 类比：药品防伪封签**
> 你买药时会检查包装有没有被拆过、防伪码对不对。Blueprint 摘要验证做的是同样的事——每份"装修图纸"（Blueprint）都有唯一的数字指纹（SHA 摘要），下载后先核对指纹，确认没被篡改才执行。

Blueprint（编排逻辑）本身也是一个安全目标。NemoClaw 的设计：

1. **不可变 Artifact**：Blueprint 版本化发布,每个版本 immutable
2. **摘要验证**：Plugin 下载 Blueprint 后，先验证其 SHA 摘要，再执行
3. **兼容性检查**：Blueprint 声明 `min_openshell_version` 和 `min_openclaw_version`，不兼容则拒绝执行
4. **可复现部署**：相同 Blueprint + 相同 Policy = 相同沙箱环境

```
Blueprint Lifecycle:
  resolve → verify digest → plan → apply → status
```

### 操作员审批流：Human-in-the-Loop

> **📞 类比：幼儿园的接送制度**
> 幼儿园只允许登记在册的家长接孩子。如果来了一个没登记的人（未授权的网络请求），老师不会直接放行，也不会默默赶走——而是打电话给家长确认："有个叫张三的人说要接你家孩子，你同意吗？"同意就这次放行，但**下次来还得再确认**（会话结束后重置）。

当 Agent 试图访问未授权的端点时，NemoClaw **不是默默失败**，而是：

1. OpenShell 拦截请求并记录日志
2. TUI（Terminal UI）实时显示被阻止的请求（主机、端口、发起二进制）
3. 操作员在 TUI 中审批或拒绝
4. 审批后，端点在当前会话中被加入运行策略
5. **会话结束后重置**——审批不会自动写入基线策略

这是经典的 Human-in-the-Loop 设计，给操作员最大的可见性和控制权。

## 与其他方案的对比

| 维度     | 传统 Docker 隔离           | 普通 Agent Sandbox | NemoClaw + OpenShell                                   |
| -------- | -------------------------- | ------------------ | ------------------------------------------------------ |
| 文件系统 | 容器级隔离                 | 应用层检查         | Landlock 内核级，per-path 粒度                         |
| 网络控制 | iptables/网络策略          | 域名白名单         | Network Namespace + L7 Proxy + Binary 验证 + SSRF 防护 |
| 进程安全 | 容器 root 隔离             | 无特别措施         | seccomp + 特权分离 + TOFU 二进制验证                   |
| 推理安全 | N/A                        | API Key 传入 Agent | Agent 完全看不到真实 Key，Proxy 透明注入               |
| 策略管理 | 硬编码或 K8s NetworkPolicy | 配置文件           | OPA/Rego 声明式，可审计，热重载                        |
| 实时监控 | 需要额外工具               | 有限日志           | 内置 TUI，实时看到每个网络请求                         |
| 人工审批 | 无                         | 无                 | 内置 Operator Approval 流                              |
| 实现语言 | Go (containerd)            | 各异               | Rust（性能 + 内存安全）                                |

## 实践要点

### 1. 安全边界的真正价值在于"默认拒绝"

NemoClaw 最核心的设计不是"有四层防御"，而是**默认状态下什么都不许做**。这与传统安全模型（默认允许，黑名单拒绝）完全相反。代价是初始配置更繁琐，但对于自主运行的 Agent，这个权衡绝对值得。

### 2. 每一层都独立生效

这不是"一层 OK 就全部 OK"，而是"一层被突破，其他层仍然有效"：
- 即使 Agent 突破了 Landlock → seccomp 仍然禁止创建 raw socket → Network Namespace 仍然只能走 Proxy → Proxy 仍然检查策略
- 攻击者需要**同时突破所有层**才能完全逃逸，大幅提高攻击成本

### 3. TOFU 二进制验证的巧妙设计

Proxy 不是简单地检查"请求来自 `/usr/bin/git`"（这个路径可以被替换为恶意二进制），而是在首次请求时记录该二进制的 **SHA256 哈希**。后续请求比对哈希——如果有人替换了 `git` 二进制，Proxy 会拒绝请求。

### 4. SSRF 防护是必须的

即使策略允许 `example.com`，Proxy 在 DNS 解析后仍会检查目标 IP。如果 `example.com` 的 DNS 被操纵指向 `169.254.169.254`（云元数据端点），Proxy 会拒绝连接。这防止了 DNS rebinding 攻击。

### 5. 当前局限性

- **Alpha 阶段**：接口和行为可能随时变化
- **Landlock best-effort**：官方文档称 Landlock 在某些环境下是"best-effort"，可能在旧内核上降级
- **本地推理实验性**：Ollama/vLLM 本地推理仍处于实验阶段
- **仅 Linux**：核心安全机制（Landlock、seccomp、netns）是 Linux 特有的；macOS/Windows 支持有限

## 总结

1. **纵深防御，非单点方案**：NemoClaw 的安全来自 Landlock（文件）+ seccomp（进程）+ netns + L7 Proxy（网络）+ Inference Routing（推理）四层独立防御的叠加，而非单一机制。
   > *通俗说：不是一把锁，而是围墙+门禁+安检+保险柜四层，小偷必须全部突破才能得手。*

2. **默认拒绝 > 默认允许**：Agent 默认什么都不能做，必须通过声明式 YAML 策略显式授权——这是对自主 Agent 最负责任的安全姿态。
   > *通俗说：新员工第一天没有任何权限，需要什么权限逐项申请——而不是给全部权限再一项项收回。*

3. **内核态执行是硬道理**：应用层检查可以被绕过，Landlock 和 seccomp 在 Linux 内核直接执行——这是硬隔离，不是软约束。
   > *通俗说：不是靠"请勿进入"的牌子（软件拦截），而是真的把门焊死了（硬件级别限制）。*

4. **凭据与 Agent 物理隔离**：Agent 永远看不到真正的 API Key，Proxy 在转发时才注入。这彻底消除了 prompt injection 导致凭据泄露的风险。
   > *通俗说：实习生永远拿不到公司信用卡号——他只能说"帮我买这个"，由财务代刷。*

5. **Human-in-the-Loop 补完自动化**：对于无法提前预知的合法请求，操作员审批流提供了安全的运行时扩展机制，同时保证审批不会持久化为策略——每次会话从干净基线开始。
   > *通俗说：规则覆盖不到的情况，打电话请示老板。老板同意也只管这一次，下次还得重新请示。*

## 参考链接

- [NemoClaw GitHub](https://github.com/NVIDIA/NemoClaw) — 项目主仓库
- [OpenShell GitHub](https://github.com/NVIDIA/OpenShell) — 底层安全运行时（Rust）
- [NemoClaw Architecture 官方文档](https://docs.nvidia.com/nemoclaw/latest/reference/architecture.html)
- [NemoClaw Network Policies 官方文档](https://docs.nvidia.com/nemoclaw/latest/reference/network-policies.html)
- [OpenShell 架构文档](https://github.com/NVIDIA/OpenShell/tree/main/architecture) — 最详细的技术设计
- [Landlock LSM — Linux 内核文档](https://docs.kernel.org/userspace-api/landlock.html)
- [seccomp BPF — Linux 内核文档](https://docs.kernel.org/userspace-api/seccomp_filter.html)
- [Open Policy Agent (OPA)](https://www.openpolicyagent.org/) — 策略引擎
