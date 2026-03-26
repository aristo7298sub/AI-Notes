---
title: "Harness Design for Long-Running Application Development | 长时运行应用开发的 Harness 设计"
date: 2026-03-24
category: commentary
tags: [Anthropic, Agent-Harness, Multi-Agent, GAN-Pattern, Claude-Opus, Evaluator-Agent, Agentic-Coding]
source: "https://www.anthropic.com/engineering/harness-design-long-running-apps"
author: "Prithvi Rajasekaran"
---

# Harness Design for Long-Running Application Development | 长时运行应用开发的 Harness 设计

> **Author / 作者**: Prithvi Rajasekaran (Anthropic Labs team)
> **Published / 发布日期**: March 24, 2026
> **Source / 来源**: https://www.anthropic.com/engineering/harness-design-long-running-apps
> **Reading Time / 阅读时间**: ~15 mins

> [!NOTE]
> **什么是 Harness？** 本文中的 Harness 指围绕 LLM 构建的**编排框架/脚手架**——不是模型本身，而是控制模型如何被调用、如何协作、如何迭代的整套外部机制。它包括 Agent 角色编排（Planner → Generator → Evaluator）、上下文管理策略（Reset vs Compaction）、任务分解机制（Sprint 结构）、评估反馈循环（Playwright 实测）、Prompt 工程和 Agent 间通信协议等。Harness 的每个组件都编码了一个"模型当前做不到什么"的假设——模型越强，harness 可以越简。

---

## §1 Opening — GAN-Inspired Multi-Agent Architecture | 开篇——受 GAN 启发的多智能体架构

### 原文 / Original

> Over the past several months I've been working on two interconnected problems: getting Claude to produce high-quality frontend designs, and getting it to build complete applications without human intervention. This work originated with earlier efforts on our frontend design skill and long-running coding agent harness, where my colleagues and I were able to improve Claude's performance well above baseline through prompt engineering and harness design—but both eventually hit ceilings.
>
> To break through, I sought out novel AI engineering approaches that held across two quite different domains, one defined by subjective taste, the other by verifiable correctness and usability. Taking inspiration from Generative Adversarial Networks (GANs), I designed a multi-agent structure with a generator and evaluator agent. Building an evaluator that graded outputs reliably—and with taste—meant first developing a set of criteria that could turn subjective judgments like "is this design good?" into concrete, gradable terms.
>
> I then applied these techniques to long-running autonomous coding, carrying over two lessons from our earlier harness work: decomposing the build into tractable chunks, and using structured artifacts to hand off context between sessions. The final result was a three-agent architecture—planner, generator, and evaluator—that produced rich full-stack applications over multi-hour autonomous coding sessions.

### 翻译

在过去几个月里，我一直在研究两个相互关联的问题：让 Claude 产出高质量的前端设计，以及让它在无人干预的情况下构建完整应用。这项工作源于我们此前在前端设计技能和长时运行编码 Agent Harness 上的探索，通过 prompt 工程和 harness 设计，我们将 Claude 的性能大幅提升至基线之上——但两者最终都触及了天花板。

为了突破，我寻找了在两个截然不同领域——一个由主观审美定义，另一个由可验证的正确性和可用性定义——都适用的新型 AI 工程方法。受**生成对抗网络 (GAN)** 的启发，我设计了一个包含 **Generator（生成器）** 和 **Evaluator（评估器）** 的多智能体结构。构建一个能够可靠评分——且有品味地评分——的 Evaluator，意味着首先要开发一套能将"这个设计好不好？"这类主观判断转化为具体、可评分条款的标准。

然后我将这些技术应用到长时运行的自主编码中，延续了早期 harness 工作中的两条经验：将构建分解为可处理的块，以及使用结构化产物在会话间传递上下文。最终结果是一个**三智能体架构——Planner（规划者）、Generator（生成器）和 Evaluator（评估器）**——能在数小时的自主编程会话中产出丰富的全栈应用。

<kbd>💬A: </kbd>

### 💡 解析

开篇值得注意的修辞策略：Anthropic 选择了 **GAN** 这个类比来框定整篇文章。GAN 在深度学习史上代表了一种"对抗式训练让两个网络都变强"的范式，用它来包装"Generator + Evaluator"的多智能体协作，既准确又有学术感。但本质上，这不是真正的 GAN——没有反向传播、没有参数更新，只是借鉴了"生成-判别分离"的结构思想。Anthropic 很聪明地没有过度类比，用了"Taking inspiration from"而非"We built a GAN"。

更根本的洞察是：**单个 Agent 存在系统性的自我评估偏差**。这是一个在 LLM Agent 领域被反复验证的现象：模型倾向于对自己的输出给出正面评价。将生成和评估分离成两个独立角色，是当前最实用的工程解决方案。

**三智能体架构（Planner-Generator-Evaluator）** 实际上映射的是软件工程中早已成熟的角色分工：

| 角色      | 软件工程        | Harness 中                     |
| --------- | --------------- | ------------------------------ |
| Planner   | 产品经理/架构师 | 将一句话 prompt 扩展为完整规格 |
| Generator | 开发工程师      | 按 sprint 实现功能             |
| Evaluator | QA 工程师       | 用 Playwright 实际测试应用     |

---

## §2 Why Naive Implementations Fall Short | 天真实现为何行不通

### 原文 / Original

> We've previously shown that harness design has a substantial impact on the effectiveness of long running agentic coding. In an earlier experiment, we used an initializer agent to decompose a product spec into a task list, and a coding agent that implemented the tasks one feature at a time before handing off artifacts to carry context across sessions. The broader developer community has converged on similar insights, with approaches like the "Ralph Wiggum" method using hooks or scripts to keep agents in continuous iteration cycles.
>
> But some problems remained persistent. For more complex tasks, the agent still tends to go off the rails over time. While decomposing this issue, we observed two common failure modes with agents executing these sorts of tasks.
>
> First is that models tend to lose coherence on lengthy tasks as the context window fills. Some models also exhibit "context anxiety," in which they begin wrapping up work prematurely as they approach what they believe is their context limit. Context resets—clearing the context window entirely and starting a fresh agent, combined with a structured handoff that carries the previous agent's state and the next steps—addresses both these issues.
>
> This differs from compaction, where earlier parts of the conversation are summarized in place so the same agent can keep going on a shortened history. While compaction preserves continuity, it doesn't give the agent a clean slate, which means context anxiety can still persist. A reset provides a clean slate, at the cost of the handoff artifact having enough state for the next agent to pick up the work cleanly.

### 翻译

我们此前已经展示过 harness 设计对长时运行 Agentic 编码效率有显著影响。在早期实验中，我们使用一个初始化 Agent 将产品规格分解为任务列表，然后由编码 Agent 逐个功能实现，并在会话间通过产物传递上下文。更广泛的开发者社区也汇聚到了类似的认知上，如 **"Ralph Wiggum" 方法** 使用钩子或脚本让 Agent 保持在持续迭代循环中。

但一些问题始终存在。对于更复杂的任务，Agent 仍然会随时间推移而"脱轨"。分解这个问题后，我们观察到了 Agent 执行此类任务时的两种常见失效模式。

第一是模型在上下文窗口填满时倾向于**丧失连贯性**。一些模型还表现出 **"上下文焦虑"**（context anxiety），即当它们认为接近上下文限制时，会过早地开始收尾工作。**上下文重置**（Context Resets）——完全清空上下文窗口并启动新 Agent，配合携带前一个 Agent 状态和后续步骤的结构化交接——解决了这两个问题。

这与**压缩（Compaction）** 不同。压缩是将对话的早期部分原地摘要，从而让同一个 Agent 在缩短的历史上继续工作。虽然压缩保留了连续性，但不能给 Agent 一个全新起点，这意味着上下文焦虑仍可能持续。重置提供了全新起点，代价是交接产物必须携带足够的状态让下一个 Agent 能顺利接手。

<kbd>💬A: </kbd>

### 💡 解析

这一段提出了两个极重要的概念，值得深入拆解：

**1. "Context Anxiety"（上下文焦虑）** —— 这是一个极具解释力的概念。Claude Sonnet 4.5 在上下文接近填满时会**主动收尾**，而非继续深入工作。这不是 bug，更像是模型在训练中学到的"对话礼仪"——对话应该有结尾。但在长时运行编码场景中，这恰恰是灾难性的。

**2. Context Reset vs Compaction 的本质区别：**

| 维度     | Compaction（压缩）           | Context Reset（重置）    |
| -------- | ---------------------------- | ------------------------ |
| 机制     | 摘要替换早期对话             | 清空一切，全新 Agent     |
| 连续性   | 保留（同一 Agent）           | 丢失（不同 Agent）       |
| 焦虑问题 | 不解决（Agent 知道历史很长） | 解决（Agent 认为刚开始） |
| 信息传递 | 隐式（摘要中）               | 显式（交接产物）         |
| 风险     | 摘要丢失细节                 | 交接产物不完整           |

值得注意的是，Anthropic 在这里微妙地承认了自家模型的弱点：Sonnet 4.5 的上下文焦虑"严重到压缩alone不够用"。这种坦诚反而增强了技术可信度。

"Ralph Wiggum" 方法的提及也很有趣——这来自独立开发者社区，Anthropic 没有回避外部贡献，而是主动引用。

---

## §3 The Self-Evaluation Problem | 自我评估问题

### 原文 / Original

> A second issue, which we haven't previously addressed, is self-evaluation. When asked to evaluate work they've produced, agents tend to respond by confidently praising the work—even when, to a human observer, the quality is obviously mediocre. This problem is particularly pronounced for subjective tasks like design, where there is no binary check equivalent to a verifiable software test. Whether a layout feels polished or generic is a judgment call, and agents reliably skew positive when grading their own work.
>
> However, even on tasks that do have verifiable outcomes, agents still sometimes exhibit poor judgment that impedes their performance while completing the task. Separating the agent doing the work from the agent judging it proves to be a strong lever to address this issue. The separation doesn't immediately eliminate that leniency on its own; the evaluator is still an LLM that is inclined to be generous towards LLM-generated outputs. But tuning a standalone evaluator to be skeptical turns out to be far more tractable than making a generator critical of its own work, and once that external feedback exists, the generator has something concrete to iterate against.

### 翻译

第二个我们此前未解决的问题是**自我评估**。当被要求评估自己的输出时，Agent 倾向于自信地赞美自己的工作——即使对人类观察者来说，质量明显平庸。这个问题在设计等主观任务中尤为突出，因为没有等同于可验证软件测试的二元检查。一个布局感觉是精致还是泛泛，属于主观判断，而 Agent 在评价自己的工作时系统性地正面偏移。

然而，即使在有可验证结果的任务上，Agent 有时仍表现出妨碍其完成任务的糟糕判断力。将**执行工作的 Agent** 和**评判工作的 Agent** 分离被证明是解决此问题的强力杠杆。这种分离本身不会立即消除宽大倾向——Evaluator 仍然是一个倾向于对 LLM 生成输出慷慨以待的 LLM。但**调教一个独立的 Evaluator 使其持怀疑态度**，比让一个 Generator 对自已的工作保持批判性要容易得多。一旦外部反馈存在，Generator 就有了具体的迭代目标。

<kbd>💬A: </kbd>

### 💡 解析

这段揭示了 LLM 的一个深层特性：**系统性的正面偏差**（systematic positive bias）。模型在 RLHF 训练中被优化为"有帮助的"，这意味着它天然倾向赞同而非否定。当这个特性遇到自我评估场景时，问题被放大——模型不仅倾向赞同，还在赞同**自己**的产出。

Anthropic 这里的工程洞察非常精辟：**让 Evaluator 变得严格** 远比 **让 Generator 自我批判** 容易。这背后有一个不对称性——

- Generator 需要同时做两件矛盾的事：创造性地建设 + 批判性地审视
- Evaluator 只需做一件事：挑毛病

这与人类团队管理中的经验一致：让开发者做出好的代码自审很难，但训练一个独立的 QA 团队相对容易。

另一个隐含但未被讨论的问题是：**Evaluator 和 Generator 使用同一个基础模型**。它们的偏差根源相同，只是通过 prompt 工程制造了角色差异。这意味着这种方法的上限取决于 prompt 工程能在多大程度上覆盖模型的内在偏差——一个值得关注的天花板。

---

## §4 Frontend Design: Grading Criteria | 前端设计：将审美评分化

### 原文 / Original

> I started by experimenting on frontend design, where the self-evaluation issue was most visible. Absent any intervention, Claude normally gravitates toward safe, predictable layouts that are technically functional but visually unremarkable.
>
> Two insights shaped the harness I built for frontend design. First, while aesthetics can't be fully reduced to a score—and individual tastes will always vary—they can be improved with grading criteria that encode design principles and preferences. "Is this design beautiful?" is hard to answer consistently, but "does this follow our principles for good design?" gives Claude something concrete to grade against. Second, by separating frontend generation from frontend grading, we can create a feedback loop that drives the generator toward stronger outputs.
>
> With this in mind, I wrote four grading criteria that I gave to both the generator and evaluator agents in their prompts:
>
> • Design quality: Does the design feel like a coherent whole rather than a collection of parts?
> • Originality: Is there evidence of custom decisions, or is this template layouts, library defaults, and AI-generated patterns?
> • Craft: Technical execution: typography hierarchy, spacing consistency, color harmony, contrast ratios.
> • Functionality: Usability independent of aesthetics.

### 翻译

我从前端设计入手，因为这里的自我评估问题最为突出。在没有任何干预的情况下，Claude 通常倾向于安全、可预测的布局——技术上能用但视觉上毫无特色。

两条洞察塑造了我为前端设计构建的 harness。第一，虽然审美不能完全被还原为分数——且个人品味总会不同——但可以通过编码设计原则和偏好的**评分标准**来改善。"这个设计美吗？"很难一致地回答，但"**这个设计是否遵循了我们的好设计原则？**"给了 Claude 具体的评分依据。第二，通过将前端生成和前端评分分离，我们可以创建一个驱动 Generator 产出更强输出的反馈循环。

基于此，我编写了四条评分标准，同时提供给 Generator 和 Evaluator：

- **设计质量**（Design quality）：设计感觉是一个连贯的整体，还是各部分的拼凑？
- **原创性**（Originality）：是否有自定义决策的证据，还是模板布局、库默认值和 AI 生成模式？
- **工艺**（Craft）：技术执行——字体层级、间距一致性、配色和谐度、对比度。
- **功能性**（Functionality）：独立于审美的可用性。

<kbd>💬A: </kbd>

### 💡 解析

这四条标准的设计本身就值得学习。注意其权重结构：**设计质量和原创性被刻意加重，工艺和功能性被降权**。原因是 Claude 在工艺和功能性上本就表现不错，瓶颈在审美和创造力上。

更有趣的是"原创性"标准中的一个细节——它明确**惩罚"AI 味"**（"telltale signs of AI generation like purple gradients over white cards"）。这是 Anthropic 在承认一个有趣的事实：**AI 生成的设计有可辨识的视觉指纹**，就像过去"stock photo 味"一样。紫色渐变 + 白色卡片 = AI 生成的设计标配。

这让人想到一个更大的问题：**当 AI 根据自己的训练数据生成设计时，它倾向于回归到数据中最常见的模式——也就是其他 AI 生成的设计模式**。这是一种"审美近亲繁殖"。评分标准通过显式惩罚这种模式来打破循环。

从方法论角度看，"将主观判断转化为结构化标准"这个思路在很多领域都有应用价值——代码质量、文案风格、推理深度。核心原则是一致的：**不要问"好不好"，要问"在具体维度上得几分"**。

---

## §5 The Generator-Evaluator Loop in Practice | 前端 Generator-Evaluator 循环实践

### 原文 / Original

> I built the loop on the Claude Agent SDK, which kept the orchestration straightforward. A generator agent first created an HTML/CSS/JS frontend based on a user prompt. I gave the evaluator the Playwright MCP, which let it interact with the live page directly before scoring each criterion and writing a detailed critique. In practice, the evaluator would navigate the page on its own, screenshotting and carefully studying the implementation before producing its assessment. That feedback flowed back to the generator as input for the next iteration. I ran 5 to 15 iterations per generation, with each iteration typically pushing the generator in a more distinctive direction as it responded to the evaluator's critique. Because the evaluator was actively navigating the page rather than scoring a static screenshot, each cycle took real wall-clock time. Full runs stretched up to four hours. I also instructed the generator to make a strategic decision after each evaluation: refine the current direction if scores were trending well, or pivot to an entirely different aesthetic if the approach wasn't working.

### 翻译

我在 **Claude Agent SDK** 上构建了这个循环，使编排保持简洁。一个 Generator Agent 首先根据用户 prompt 创建 HTML/CSS/JS 前端。我给 Evaluator 提供了 **Playwright MCP**，让它在打分和撰写详细批评之前，能直接与运行中的页面交互。实践中，Evaluator 会自主导航页面，截图并仔细研究实现，然后产出评估。该反馈流回 Generator 作为下一轮迭代的输入。我每次生成运行 5 到 15 轮迭代，每轮通常在 Evaluator 批评的推动下将 Generator 推向更具特色的方向。因为 Evaluator 是在实际导航页面而非对静态截图打分，每个循环需要真实的时钟时间。完整运行长达**四个小时**。我还指示 Generator 在每次评估后做出战略决策：如果分数趋势良好则细化当前方向，如果方法不奏效则**彻底转向一种完全不同的审美风格**。

<kbd>💬A: </kbd>

### 💡 解析

几个值得关注的技术细节：

**1. Evaluator 使用 Playwright 实际交互页面**，而非看截图。这意味着 Evaluator 能发现滚动行为、悬停效果、响应式布局等静态图片无法捕捉的问题。这是一个关键的工程决策——成本更高但信息量更大。

**2. "Pivot or refine" 的战略选择机制**。这模拟了人类设计师的决策过程：如果当前方向有潜力就打磨，如果方向本身就错了就推翻重来。这个机制直接导致了后文提到的"博物馆网站第 10 轮迭代从暗色主题跳转到 3D 空间体验"的戏剧性转变。

**3. 四小时、5-15 轮迭代的成本结构**。文章没有给出具体数字，但结合后文全栈应用的 $200 成本，前端设计循环大概也在几十到上百美元。这意味着这种方法目前只适用于**产出物价值远高于计算成本的场景**——企业级 UI、商业产品设计等。

作者没有讨论的一个问题：**迭代并非线性改善**。后文也承认"我经常看到中间某轮迭代比最后一轮更好"。这暗示这个循环可能有过拟合评分标准的倾向——在后期，Generator 可能为了提高分数而牺牲了整体协调性。

---

## §6 The Dutch Museum — A Creative Leap | 荷兰博物馆——一次创造性飞跃

### 原文 / Original

> In one notable example, I prompted the model to create a website for a Dutch art museum. By the ninth iteration, it had produced a clean, dark-themed landing page for a fictional museum. The page was visually polished but largely in line with my expectations. Then, on the tenth cycle, it scrapped the approach entirely and reimagined the site as a spatial experience: a 3D room with a checkered floor rendered in CSS perspective, artwork hung on the walls in free-form positions, and doorway-based navigation between gallery rooms instead of scroll or click. It was the kind of creative leap that I hadn't seen before from a single-pass generation.

### 翻译

在一个显著的例子中，我给模型的 prompt 是创建一个荷兰艺术博物馆的网站。到第九轮迭代，它产出了一个干净的深色主题虚构博物馆登陆页。页面视觉效果精致，但基本在我的预期范围内。然后，在第十轮循环中，它**彻底抛弃了这个方案**，将网站重新想象为一个空间体验：一个用 CSS 透视渲染的棋盘格地板的 3D 房间，艺术品以自由位置挂在墙上，用**门廊式导航**在画廊房间之间穿行，而非滚动或点击。这是我从未在单次生成中见过的那种**创造性飞跃**。

<kbd>💬A: </kbd>

### 💡 解析

这是全文中最具说服力的案例。一个纯 CSS 渲染的 3D 虚拟画廊，用门廊导航替代传统的滚动/点击——这不是"更好的同类输出"，而是**范式级的创意跳跃**。

但需要冷静审视：这个飞跃是因为 harness 设计的功劳，还是模型本身就有这种能力，只是之前没有被"逼"到第 10 轮？换个角度想——如果一个人类设计师被要求推翻前 9 稿重来，他也很可能尝试一些激进的不同方向。harness 做的事情本质上是**创造了足够多的迭代空间和"不满意就推翻"的机制**，让模型有机会探索到更远的设计空间。

这也引出一个实际问题：**如何知道哪一轮是最好的？** 作者也承认"我经常偏好中间轮而非最后一轮"。一个改进方向可能是引入**选择机制**——保留每轮的输出，最后让人类或另一个 Agent 从所有版本中挑选最佳。

---

## §7 Scaling to Full-Stack: The Three-Agent Architecture | 扩展到全栈：三智能体架构

### 原文 / Original

> For this work I built on the foundation from the original harness with a three-agent system, with each agent addressing a specific gap I'd observed in prior runs. The system contained the following agent personas:
>
> Planner: Our previous long-running harness required the user to provide a detailed spec upfront. I wanted to automate that step, so I created a planner agent that took a simple 1-4 sentence prompt and expanded it into a full product spec. I prompted it to be ambitious about scope and to stay focused on product context and high level technical design rather than detailed technical implementation.
>
> Generator: The one-feature-at-a-time approach from the earlier harness worked well for scope management. I applied a similar model here, instructing the generator to work in sprints, picking up one feature at a time from the spec. Each sprint implemented the app with a React, Vite, FastAPI, and SQLite (later PostgreSQL) stack.
>
> Evaluator: Applications from earlier harnesses often looked impressive but still had real bugs when you actually tried to use them. To catch these, the evaluator used the Playwright MCP to click through the running application the way a user would, testing UI features, API endpoints, and database states.

### 翻译

我在原始 harness 的基础上构建了一个三智能体系统，每个 Agent 针对我在之前运行中观察到的特定缺口：

**Planner（规划者）**：之前的 harness 需要用户预先提供详细规格。我想自动化这一步，因此创建了一个将 1-4 句话的简单 prompt 扩展为完整产品规格的 Planner Agent。我引导它在范围上要有**雄心**，聚焦于产品上下文和高层技术设计，而非详细的技术实现。

**Generator（生成器）**：之前 harness 中的逐功能实现方式在范围管理上效果良好。我在这里采用了类似模型，指示 Generator 以 **Sprint** 方式工作，从规格中逐个拾取功能。每个 Sprint 使用 React、Vite、FastAPI 和 SQLite（后改为 PostgreSQL）技术栈实现应用。

**Evaluator（评估器）**：早期 harness 产出的应用看起来常常令人印象深刻，但实际使用时仍有真实的 Bug。为了捕获这些，Evaluator 使用 **Playwright MCP** 像用户一样点击运行中的应用，测试 UI 功能、API 端点和数据库状态。

<kbd>💬A: </kbd>

### 💡 解析

三个设计决策值得深入分析：

**1. Planner 刻意不做详细技术设计。** 原因是"如果 Planner 预先指定了颗粒度过高的技术细节并且搞错了，错误会级联到下游实现"。这反映了一个软件工程中被反复验证的教训：**过早细化是架构设计的大敌**。保持高层约束、推迟具体实现决策——这是好的架构思维。

**2. Sprint 合同机制（Sprint Contract）。** Generator 和 Evaluator 在每个 Sprint 开始前**协商一份合同**——定义"完成"意味着什么。这解决了一个关键问题：Planner 产出的规格是高层级的，但 Evaluator 需要具体的验收标准。Sprint 合同弥合了这个差距。令人惊讶的是，这竟然在 Agent 之间有效——两个 LLM 能够就测试标准达成有意义的"协议"。

**3. 通过文件通信。** Agent 间不是通过 API 调用或结构化消息传递，而是通过**读/写文件**来沟通。这是一个极其务实的选择——文件是最简单、最可调试、最透明的通信机制。任何人都可以打开文件看到两个 Agent 在"说什么"。

---

## §8 Solo vs Harness: The Retro Game Maker | Solo vs Harness：复古游戏制作器对比

### 原文 / Original

> For the first version of this harness, I used Claude Opus 4.5, running user prompts against both the full harness and a single-agent system for comparison. I wrote the following prompt to generate a retro video game maker:
>
> "Create a 2D retro game maker with features including a level editor, sprite editor, entity behaviors, and a playable test mode."
>
> | Harness | Duration | Cost |
> | Solo | 20 min | $9 |
> | Full harness | 6 hr | $200 |
>
> The harness was over 20x more expensive, but the difference in output quality was immediately apparent.

### 翻译

作为这个 harness 的第一个版本，我使用 Claude Opus 4.5，将同一个 prompt 分别在完整 harness 和单 Agent 系统上运行以作对比。用于生成复古游戏制作器的 prompt 是：

"创建一个 2D 复古游戏制作器，功能包括关卡编辑器、精灵编辑器、实体行为和可玩的测试模式。"

| Harness 类型     | 时长    | 成本 |
| ---------------- | ------- | ---- |
| Solo（单 Agent） | 20 分钟 | $9   |
| 完整 Harness     | 6 小时  | $200 |

Harness 的成本超过了 20 倍，但输出质量差异一目了然。

<kbd>💬A: </kbd>

### 💡 解析

**20 分钟/$9 vs 6 小时/$200** —— 这组数字的呈现方式非常值得推敲。

Anthropic 选择展示的是一个**成本差异巨大但质量差异更大的案例**。Solo 版本的核心功能（游戏运行）是**完全损坏的**——"实体出现在屏幕上但不响应任何输入"——而 Harness 版本虽然有物理引擎的粗糙边缘，但**核心可用**。这不是 80 分 vs 95 分的差距，而是 **"不能用" vs "能用"** 的差距。

从经济学角度看，$200 的成本在商业软件开发中微不足道——一个中级开发者的日薪就远超这个数字。但 6 小时的运行时间才是真正的约束。如果一个团队需要一天内快速迭代多个原型，这个时间成本可能比美元成本更关键。

**未被讨论的关键问题**：这 $200 中有多少是"浪费的"？Evaluator 拒绝了多少个 Sprint？如果某个 Sprint 被反复拒绝再重做，这些重试的 token 成本是否值得？文章没有给出 Generator-Evaluator 循环中的失败率和重试率。

---

## §9 The Evaluator's Real Value — Specific Bug Reports | Evaluator 的真正价值——具体的 Bug 报告

### 原文 / Original

> Reading through the logs, it was clear that the evaluator kept the implementation in line with the spec. Each sprint, it walked through the sprint contract's test criteria and exercised the running application through Playwright, filing bugs against anything that diverged from expected behavior. The contracts were granular—Sprint 3 alone had 27 criteria covering the level editor—and the evaluator's findings were specific enough to act on without extra investigation.
>
> | Contract criterion | Evaluator finding |
> | Rectangle fill tool allows click-drag to fill a rectangular area with selected tile | FAIL — Tool only places tiles at drag start/end points instead of filling the region. fillRectangle function exists but isn't triggered properly on mouseUp. |
> | User can select and delete placed entity spawn points | FAIL — Delete key handler at LevelEditor.tsx:892 requires both selection and selectedEntityId to be set, but clicking an entity only sets selectedEntityId. Condition should be selection \|\| (selectedEntityId && activeLayer === 'entity'). |
> | User can reorder animation frames via API | FAIL — PUT /frames/reorder route defined after /{frame_id} routes. FastAPI matches 'reorder' as a frame_id integer and returns 422. |

### 翻译

阅读日志后可以清楚看到，Evaluator 使实现保持与规格一致。每个 Sprint，它遍历 Sprint 合同的测试标准，通过 Playwright 对运行中的应用进行测试，对任何偏离预期行为的地方提交 Bug。合同非常细致——仅 Sprint 3 就有 **27 条标准**覆盖关卡编辑器——Evaluator 的发现足够具体，无需额外调查即可直接行动。

| 合同标准                                   | Evaluator 发现                                                                                                                                                                                         |
| ------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 矩形填充工具允许拖拽用选定瓦片填充矩形区域 | **失败** — 工具仅在拖拽起止点放置瓦片，而非填充区域。fillRectangle 函数存在但未在 mouseUp 时正确触发。                                                                                                 |
| 用户可选择和删除放置的实体生成点           | **失败** — LevelEditor.tsx:892 的删除键处理器要求同时设置 selection 和 selectedEntityId，但点击实体仅设置 selectedEntityId。条件应为 `selection \|\| (selectedEntityId && activeLayer === 'entity')`。 |
| 用户可通过 API 重新排序动画帧              | **失败** — PUT /frames/reorder 路由定义在 /{frame_id} 路由之后。FastAPI 将 'reorder' 匹配为 frame_id 整数并返回 422。                                                                                  |

<kbd>💬A: </kbd>

### 💡 解析

这三个 Bug 报告是全文中最让人信服的证据。特别是第三个——**FastAPI 路由顺序问题**——这是一个真实的、有具体根因的工程问题。Evaluator 不仅发现了 422 错误，还准确定位到了原因：`/frames/reorder` 被 `/{frame_id}` 路由抢先匹配。这种水平的 Bug Report 在很多人类 QA 工程师那里也不常见。

但正如作者坦承的：**"开箱即用的 Claude 是一个糟糕的 QA Agent。"** 在早期运行中，它会发现合法问题，然后**说服自己这些问题没什么大不了的**，然后通过审核。这需要多轮调教才能让 Evaluator 的判断与人类工程师对齐。

这引出一个更根本的问题：**Evaluator 的校准是人工的、一次性的**。换一个完全不同类型的应用，之前调教出的评判标准可能不再适用。harness 的可迁移性是一个值得观察的限制。

---

## §10 Iterating on the Harness — Model Improvements Change Everything | 迭代 Harness——模型进步改变一切

### 原文 / Original

> The first set of harness results was encouraging, but it was also bulky, slow, and expensive. The logical next step was to find ways to simplify the harness without degrading its performance. This was partly common sense and partly a function of a more general principle: every component in a harness encodes an assumption about what the model can't do on its own, and those assumptions are worth stress testing, both because they may be incorrect, and because they can quickly go stale as models improve.
>
> As I was going through these iteration cycles, we also released Opus 4.6, which provided further motivation to reduce harness complexity. There was good reason to expect 4.6 would need less scaffolding than 4.5 did. From our launch blog: "[Opus 4.6] plans more carefully, sustains agentic tasks for longer, can operate more reliably in larger codebases, and has better code review and debugging skills to catch its own mistakes."

### 翻译

第一组 harness 结果令人鼓舞，但也笨重、缓慢且昂贵。合乎逻辑的下一步是找到在不降低性能的前提下简化 harness 的方法。这部分是常识，部分源于一条更普遍的原则：**harness 中的每个组件都编码了一个关于"模型自身做不到什么"的假设，而这些假设值得压力测试**——既因为它们可能本来就不正确，也因为随着模型进步它们会迅速过时。

在我进行这些迭代循环的同时，我们也发布了 **Opus 4.6**，这进一步推动了减少 harness 复杂性的动力。有充分理由相信 4.6 需要比 4.5 更少的脚手架。引用我们的发布博客："[Opus 4.6] 规划更审慎，更持久地执行 Agentic 任务，在大型代码库中运行更可靠，并拥有更好的代码审查和调试技能来发现自身的错误。"

<kbd>💬A: </kbd>

### 💡 解析

这段话包含了全文中最重要的方法论洞察：

> **"harness 中的每个组件都编码了一个关于模型不能做什么的假设。"**

这句话应该被刻在每个 AI 工程师的办公桌上。它意味着：

1. **Harness 是模型能力的补集**——模型做不好的事情，harness 来补
2. **模型每次升级，都应该重新审视 harness**——哪些组件不再需要？
3. **过度设计的 harness 等于在给模型套枷锁**——不必要的约束可能反而限制了模型

这与 Anthropic 早期发表的 *Building Effective Agents* 一脉相承："找到最简可行方案，只在需要时增加复杂性。"

**Opus 4.6 的发布直接改变了 harness 设计**：上下文焦虑"基本上不再是问题"，这意味着 Context Reset 可以被移除，Sprint 分解也可以被简化。这是一个完美的案例，说明**模型进步和工程优化是协同进化的——不是此消彼长**。

---

## §11 Removing the Sprint Construct | 移除 Sprint 构造

### 原文 / Original

> I started by removing the sprint construct entirely. The sprint structure had helped to decompose work into chunks for the model to work coherently. Given the improvements in Opus 4.6, there was good reason to believe that the model could natively handle the job without this sort of decomposition.
>
> I kept both the planner and evaluator, as each continued to add obvious value. Without the planner, the generator under-scoped: given the raw prompt, it would start building without first speccing its work, and end up creating a less feature-rich application than the planner did.
>
> With the sprint construct removed, I moved the evaluator to a single pass at the end of the run rather than grading per sprint. Since the model was much more capable, it changed how load-bearing the evaluator was for certain runs, with its usefulness depending on where the task sat relative to what the model could do reliably on its own.

### 翻译

我首先完全移除了 Sprint 构造。Sprint 结构此前帮助将工作分解为模型能够连贯处理的块。鉴于 Opus 4.6 的改进，有充分理由相信模型能够原生处理这项工作，无需这种分解。

我保留了 Planner 和 Evaluator，因为两者都继续提供明显的价值。没有 Planner 时，Generator 会**范围不足**：面对原始 prompt，它会不先做规格就直接开始构建，最终创造出功能远不如 Planner 版本丰富的应用。

移除 Sprint 构造后，我将 Evaluator 改为在运行结束时**一次性通过**，而非逐 Sprint 评分。由于模型能力大幅增强，这改变了 Evaluator 对不同运行的承重程度——其有用性取决于任务处于模型单独可靠完成的范围之内还是之外。

<kbd>💬A: </kbd>

### 💡 解析

从 v1 到 v2 的简化路径非常清晰：

| 组件          | v1 (Opus 4.5)          | v2 (Opus 4.6)                |
| ------------- | ---------------------- | ---------------------------- |
| Context Reset | 必需（解决上下文焦虑） | 移除（模型不再焦虑）         |
| Sprint 分解   | 必需（保持连贯性）     | 移除（模型能长时间连贯工作） |
| Planner       | 有                     | 保留（仍有不可替代价值）     |
| Evaluator     | Per-Sprint 评审        | 改为最后一次性评审           |
| Compaction    | 无（用 Reset 代替）    | 自动（Agent SDK 内置）       |

一个值得深思的判断：**Evaluator 的价值取决于任务是否处于模型能力的边界**。对于模型游刃有余的任务，Evaluator 是多余的开销。但对于推动模型极限的任务，Evaluator 是不可或缺的安全网。这意味着**随着模型不断进步，Evaluator 的"有用区间"也在不断外移**——今天需要 Evaluator 的任务，明天可能不需要了。

Planner 被保留的原因也很有意思——模型在**没有明确指引时倾向于保守行事**。这不是能力问题，而是意愿问题。Planner 的角色本质上是给模型"许可"去做更宏大的事情。

---

## §12 Results — The Browser DAW | 结果——浏览器内数字音频工作站

### 原文 / Original

> To put the updated harness to the test, I used the following prompt to generate a Digital Audio Workstation (DAW), a music production program for composing, recording, and mixing songs:
>
> "Build a fully featured DAW in the browser using the Web Audio API."
>
> The run was still lengthy and expensive, at about 4 hours and $124 in token costs. Most of the time went to the builder, which ran coherently for over two hours without the sprint decomposition that Opus 4.5 had needed.
>
> The app is far from a professional music production program, and the agent's song composition skills could clearly use a lot of work. Additionally, Claude can't actually hear, which made the QA feedback loop less effective with respect to musical taste. But the final app had all the core pieces of a functional music production program: a working arrangement view, mixer, and transport running in the browser.

### 翻译

为了测试更新后的 harness，我使用以下 prompt 生成一个**数字音频工作站 (DAW)**——一个用于作曲、录音和混音的音乐制作程序：

"使用 Web Audio API 在浏览器中构建一个功能齐全的 DAW。"

运行仍然耗时且昂贵——大约 **4 小时，$124 token 成本**。大部分时间花在了构建器上，它**连贯运行超过两个小时**，无需 Opus 4.5 所需的 Sprint 分解。

该应用远非专业音乐制作程序，Agent 的作曲技能显然也需要大量工作。此外，**Claude 无法真正"听到"**，这使得 QA 反馈循环在音乐品味方面效果打折。但最终应用拥有功能性音乐制作程序的所有核心组件：在浏览器中运行的编排视图、混音器和播放传输。

<kbd>💬A: </kbd>

### 💡 解析

从 v1 到 v2 的成本变化：

| 维度         | v1 (游戏制作器, Opus 4.5) | v2 (DAW, Opus 4.6) |
| ------------ | ------------------------- | ------------------ |
| 成本         | $200                      | $124               |
| 时长         | 6 小时                    | ~4 小时            |
| Sprint 结构  | 有                        | 无                 |
| 连续编码时长 | 按 Sprint 切分            | 一次连贯 2+ 小时   |

成本降低了 38%，时长减少了 33%，同时任务复杂度（DAW 比复古游戏制作器更复杂）可能是增加的。这直接证明了**更强的模型 + 更简的 harness = 更高的性价比**。

"Claude 无法真正听到"这一坦承揭示了一个根本限制：**当任务的质量评估需要模型不具备的感知能力时，Evaluator 的有效性会大幅下降**。这在音乐领域是"听觉"，在其他领域可能是"触觉反馈"、"性能感知"、"真实用户情感反应"等。Evaluator 模式的适用边界取决于 LLM 的感知边界。

另一个幽默但深刻的细节："你可以说它还没有达到完美音准（pitch-perfect），但正在接近。" ——这个双关语（pitch 在音乐中是音准）暗示了 Anthropic 对未来能力的自信。

---

## §13 What Comes Next | 展望

### 原文 / Original

> As models continue to improve, we can roughly expect them to be capable of working for longer, and on more complex tasks. In some cases, that will mean the scaffold surrounding the model matters less over time, and developers can wait for the next model and see certain problems solve themselves. On the other hand, the better the models get, the more space there is to develop harnesses that can achieve complex tasks beyond what the model can do at baseline.
>
> From this work, my conviction is that the space of interesting harness combinations doesn't shrink as models improve. Instead, it moves, and the interesting work for AI engineers is to keep finding the next novel combination.

### 翻译

随着模型不断进步，我们大致可以预期它们能够工作更长时间、处理更复杂的任务。在某些情况下，这意味着环绕模型的脚手架随时间推移重要性降低，开发者可以等待下一个模型，看某些问题自行解决。另一方面，模型越强，开发能实现超越模型基线的复杂任务的 harness 的空间就越大。

通过这项工作，我的信念是：**有趣的 harness 组合空间不会随着模型进步而缩小。相反，它在移动。** AI 工程师的有趣工作在于不断发现下一个新颖的组合。

<kbd>💬A: </kbd>

### 💡 解析

这个结论精练且深刻，它回应了 AI 领域最常见的一个焦虑：**"如果模型越来越强，AI 工程师的价值在哪里？"**

Anthropic 的回答是：工程价值的空间不会缩小，只会**移动**。今天的 harness 解决上下文焦虑和自我评估问题；明天这些问题被模型自身解决后，新的更复杂的问题（也许是多模态协同、跨日持续构建、与人类设计师实时协作）会出现，需要新的 harness 组合。

这与技术史上的规律一致：

- 编译器优化消除了手写汇编的需求，但创造了更高层级的编程工作
- 云计算消除了运维细节，但创造了云架构师的角色
- 每一层抽象的提升，不是消灭了工程师，而是将他们推向更有价值的问题

但需注意，这也是 Anthropic 作为模型提供商的**利益所在**——他们希望开发者相信"围绕我们的模型构建复杂系统是值得的"。因此这个结论既是技术洞察，也是商业叙事。

---

## 总结 / Summary

### 核心论点

文章提出了一个受 GAN 启发的多智能体 harness 架构，通过将 **Planner（规划）、Generator（生成）、Evaluator（评估）** 三个角色分离，显著提升了 LLM 在长时运行自主编码任务中的输出质量。关键工程洞察包括：

1. **上下文焦虑（Context Anxiety）** 和 **自我评估偏差** 是长时运行 Agent 的两大系统性失效模式
2. **分离生成与评估** 比让同一 Agent 自我批判更可行——调教 Evaluator 变得严格远比让 Generator 自我批判容易
3. **将主观判断（如审美）转化为结构化评分标准** 是让 LLM 产出高质量设计的关键
4. **Harness 的每个组件都编码了一个关于模型不能做什么的假设**——随着模型进步，这些假设需要被持续重新验证

### 作者立场与动机

Prithvi Rajasekaran 来自 Anthropic Labs，文章的直接目的是展示 Claude（特别是 Opus 4.5/4.6）在复杂 agentic 场景中的能力。但这不是一篇纯营销文——大量工程细节的公开（包括失败案例和模型弱点）表明 Anthropic 正在将"技术透明度"作为品牌策略。文章也巧妙地为 Claude Agent SDK、Playwright MCP 等产品做了原生推广。

### 对行业的实际影响

- **多智能体协作的具体工程范式**（比空泛地谈"multi-agent"有用得多）
- **Evaluator Agent 的校准方法论**（few-shot 示例 + 迭代调教）可被直接复用
- **"harness 组件 = 模型能力补集"** 这一思维框架值得所有 AI 工程师内化

### 需要持续观察的点

1. **成本结构**：$124-$200 的单次运行成本在什么场景下有经济性？
2. **Evaluator 的可迁移性**：针对游戏制作器调教的 Evaluator 是否适用于其他应用类型？
3. **非线性改善问题**：中间轮迭代可能优于最后一轮——如何系统性地解决"过拟合评分标准"？
4. **感知边界**：当任务质量评估需要模型不具备的感知能力（如听觉）时，Evaluator 模式如何适应？
5. **模型进步的速度**：如果 Opus 5 解决了 Evaluator 要解决的问题，这个 harness 的哪些部分还有价值？
