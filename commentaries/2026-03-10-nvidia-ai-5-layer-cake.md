---
title: "AI Is a 5-Layer Cake | AI 是一块五层蛋糕"
date: 2026-03-10
category: commentary
tags: [NVIDIA, AI-Infrastructure, Jensen-Huang, GPU]
source: "https://blogs.nvidia.com/blog/ai-5-layer-cake/"
author: "Jensen Huang"
---
# AI Is a 5-Layer Cake | AI 是一块五层蛋糕

> **Author / 作者**: Jensen Huang (NVIDIA Founder & CEO)
> **Published / 发布日期**: March 10, 2026
> **Source / 来源**: https://blogs.nvidia.com/blog/ai-5-layer-cake/
> **Reading Time / 阅读时间**: ~4 mins

---

## §1 Opening — AI as Infrastructure | 开篇——AI 即基础设施

### 原文 / Original

> AI is one of the most powerful forces shaping the world today. It is not a clever app or a single model; it is essential infrastructure, like electricity and the internet.
>
> AI runs on real hardware, real energy and real economics. It takes raw materials and converts them into intelligence at scale. Every company will use it. Every country will build it.

### 翻译

AI 是当今塑造世界的最强大力量之一。它不是一个巧妙的应用或一个单一的模型——它是**基础设施**，如同电力和互联网一样不可或缺。

AI 运行在真实的硬件、真实的能源和真实的经济学之上。它将原材料转化为大规模的智能。每家公司都会使用它，每个国家都会建设它。

### 💡 解析

开篇第一句话就完成了**定义权的争夺**。当大众还在讨论"AI 是不是泡沫"、"哪个模型更强"时，Jensen 直接把讨论拉到了：AI = 基础设施，如同电力和互联网。

"real hardware, real energy and real economics" 三连击是刻意的——这是在对资本市场喊话：**AI 不是空中楼阁，它有物理实体，有成本结构，有经济学逻辑**。这为后文的"万亿美元基建"叙事铺路。

"Every company will use it. Every nation will build it." 两个短句，节奏铿锵，这是典型的 Jensen 演讲风格——用最简单的句式传递最大的确定性。

---

## §2 From Prerecorded Software to Real-Time Intelligence | 从"预录制软件"到"实时智能"

### 原文 / Original

> To understand why AI is unfolding this way, it helps to reason from first principles and look at what has fundamentally changed in computing.
>
> For most of computing history, software was prerecorded. Humans described an algorithm. Computers executed it. Data had to be carefully structured, stored into tables and retrieved through precise queries. SQL became indispensable because it made that world workable.
>
> AI breaks that model.
>
> For the first time, we have a computer that can understand unstructured information. It can see images, read text, hear sound and understand meaning. It can reason about context and intent. Most importantly, it generates intelligence in real time.
>
> Every response is newly created. Every answer depends on the context you provide. This is not software retrieving stored instructions. This is software reasoning and generating intelligence on demand.
>
> Because intelligence is produced in real time, the entire computing stack beneath it had to be reinvented.

### 翻译

要理解 AI 为何以这种方式展开，需要从第一性原理出发，审视计算领域发生了什么根本性变化。

在计算历史的大部分时间里，软件是"预录制"的。人类描述一个算法，计算机执行它。数据必须被精心结构化，存入表格并通过精确的查询来检索。SQL 之所以不可或缺，正是因为它让这个世界变得可用。

**AI 打破了这个模式。**

我们第一次拥有了能够理解非结构化信息的计算机。它能看懂图像、阅读文本、听懂声音并理解含义。它能对上下文和意图进行推理。最重要的是，它**实时生成智能**。

每一个回应都是全新创建的。每一个答案都取决于你提供的上下文。这不是在检索存储的指令，而是软件在按需推理和生成智能。

正因为智能是实时产生的，其下方的整个计算堆栈都必须被重新发明。

### 💡 解析

**"Prerecorded vs Real-time"** 是这篇文章中最精彩的概念对比。

把传统软件比作"预录制"（prerecorded），把 AI 比作"实时生成"（real-time intelligence），这比学术界常用的"规则驱动 vs 数据驱动"、"传统编程 vs 机器学习"要好得多。它一下子点出了本质差异：

| 维度     | 传统软件（预录制） | AI（实时智能）     |
| -------- | ------------------ | ------------------ |
| 本质     | 确定性的           | 概率性的           |
| 数据     | 结构化、表格化     | 非结构化、多模态   |
| 执行     | 检索存储的指令     | 根据上下文实时推理 |
| 输出     | 每次相同           | 每次新生成         |
| 底层需求 | 存储 + 检索        | 大规模实时计算     |

最后一句 "the entire computing stack beneath it had to be reinvented" 是关键过渡句——**正因为范式变了，所以下面的基础设施全部要重建**。这就自然地引出了"五层蛋糕"。

这个类比也暗含 Jensen 想传递的另一层意思：SQL 时代的基础设施（Oracle、传统数据中心）已经不够用了，新时代需要新的基础设施供应商——也就是 NVIDIA。

---

## §3 Layer 1: Energy | 第一层：能源

### 原文 / Original

> At the foundation is energy. Intelligence generated in real time requires power generated in real time. Every token produced is the result of electrons moving, heat being managed and energy being converted into computation. There is no abstraction layer beneath this. Energy is the first principle of AI infrastructure and the binding constraint on how much intelligence the system can produce.

### 翻译

最底层是**能源**。实时生成的智能需要实时产生的电力。每一个 token 的生成，背后都是电子的流动、热量的管理和能源向计算的转化。在这之下不存在抽象层。能源是 AI 基础设施的第一性原理，也是系统能产生多少智能的**约束瓶颈**。

### 💡 解析

"Every token produced is the result of electrons moving" ——这句话把 AI 的抽象概念拉回到了**最朴素的物理现实**。每一次你和 ChatGPT 对话，每一个 token 背后都是真实的电力消耗。

"There is no abstraction layer beneath this" 是一句极妙的话。在软件工程中我们习惯了层层抽象，但能源是最终的物理底座，你没法再往下抽象了。Jensen 用这句话确立了"能源优先"的思维框架。

将能源放在第一层而非芯片，这个排序是刻意的——**它把 AI 行业的叙事从"谁的模型强"转向了"谁有电"**。这也解释了为什么微软投资核电、亚马逊收购数据中心旁的发电站、各大科技巨头都在疯抢电力资源。

但值得注意的是，**文章没有讨论能源的可持续性问题**。AI 算力的碳排放和对电网的压力是现实挑战，Jensen 在这里选择性地回避了。

---

## §4 Layer 2: Chips | 第二层：芯片

### 原文 / Original

> Above energy are the chips. These are processors designed to transform energy into computation efficiently at massive scale. AI workloads require enormous parallelism, high-bandwidth memory and fast interconnects. Progress at the chip layer determines how fast AI can scale and how affordable intelligence becomes.

### 翻译

能源之上是**芯片**。这些是为了在大规模下高效地将能源转化为计算而设计的处理器。AI 工作负载需要巨大的并行性、高带宽内存和快速互连。芯片层的进步决定了 AI 扩展的速度以及智能变得多么可负担。

### 💡 解析

注意 Jensen 对芯片的定义方式——不是"执行指令的处理器"，而是 **"将能源转化为计算的转化器"**。这个说法直接把芯片和第一层（能源）串联起来了，强化了"五层蛋糕"层层依赖的叙事。

"enormous parallelism, high-bandwidth memory and fast interconnects" 三个关键词恰好是 NVIDIA GPU 相比 CPU 的核心优势所在：
- **并行性**：GPU 天生就是大规模并行架构
- **高带宽内存**：HBM（高带宽存储器）是 NVIDIA 与 SK 海力士等合作的核心
- **快速互连**：NVLink、NVSwitch 是 NVIDIA 的独家技术

所以这段话表面上是在描述行业需求，实际上是在**精确描述 NVIDIA 的产品优势**。这是一篇典型的"定义品类以定义自己"的策略文章。

竞争格局方面，AMD MI300/MI400、Google TPU v5/v6、Intel Gaudi 以及各种 AI ASIC 初创公司（Cerebras、Groq 等）都在追赶，但 CUDA 生态的惯性使得短期内这一层仍是 NVIDIA 的主场。

---

## §5 Layer 3: Infrastructure | 第三层：基础设施

### 原文 / Original

> Above chips is infrastructure. This includes land, power delivery, cooling, construction, networking and the systems that orchestrate tens of thousands of processors into one machine. These systems are AI factories. They are not designed to store information. They are designed to manufacture intelligence.

### 翻译

芯片之上是**基础设施**。这包括土地、电力输送、冷却、建设、网络以及将数万个处理器编排成一台机器的系统。这些系统是 **AI 工厂**。它们不是为了存储信息而设计的，而是为了**制造智能**。

### 💡 解析

**"AI Factory" vs "Data Center"** ——这个命名替换是整篇文章中最重要的战略叙事之一。

| 概念       | 数据中心 (Data Center) | AI 工厂 (AI Factory)         |
| ---------- | ---------------------- | ---------------------------- |
| 核心隐喻   | 仓库（存储和检索）     | 工厂（原材料进去，产品出来） |
| 输入       | 数据                   | 能源                         |
| 输出       | 数据的检索结果         | 智能                         |
| 给人的联想 | IT 设施                | 工业制造                     |
| 政策框架   | 科技行业               | 制造业 + 基建                |

为什么这个替换如此重要？
1. **对政策制定者**：把 AI 投入框定为"制造业基建"，就能类比修路、建电站——创造蓝领就业、拉动上下游经济，政治上更容易获得支持
2. **对投资者**：不再是"科技股的估值故事"，而是"万亿级别基础设施投资机会"
3. **对 NVIDIA 自己**：NVIDIA 不只是卖芯片，而是卖 AI 工厂的核心生产设备——"卖铲子给淘金者"的叙事

同时，"orchestrate tens of thousands of processors into one machine" 这句话暗指 NVIDIA 的 DGX SuperPOD / DGX Cloud 等系统级产品——他不只卖 GPU，他卖整套工厂。

---

## §6 Layer 4: Models | 第四层：模型

### 原文 / Original

> Above infrastructure are the models. AI models understand many kinds of information: language, biology, chemistry, physics, finance, medicine and the physical world itself. Language models are only one category. Some of the most transformative work is happening in protein AI, chemical AI, physical simulation, robotics and autonomous systems.

### 翻译

基础设施之上是**模型**。AI 模型理解多种信息：语言、生物学、化学、物理学、金融、医学以及物理世界本身。语言模型只是其中一个类别。一些最具变革性的工作正在蛋白质 AI、化学 AI、物理模拟、机器人和自主系统领域发生。

### 💡 解析

这一段暗含一个关键论点：**LLM 不是 AI 的全部，甚至不是最重要的部分。**

Jensen 故意在列举中把 "language" 只是放在一长串列表的第一个，然后专门强调 "Language models are only one category"。这是在拓宽 AI 的定义——把蛋白质折叠（如 AlphaFold）、分子设计、物理仿真（如 NVIDIA Omniverse/Cosmos）、机器人等全部纳入。

为什么要这样做？
- **降低对 LLM 的依赖叙事**：如果 AI = LLM，那 AI 的需求天花板就是文本/对话场景。但如果 AI = 理解整个物理世界的通用智能，那需求就是无穷的
- **强化 NVIDIA 的跨领域价值**：NVIDIA 的 GPU 不只跑 ChatGPT，还跑 AlphaFold、跑自动驾驶仿真、跑机器人训练。每个新领域都是一个新的算力需求来源
- **NVIDIA 有对应产品线**：BioNeMo（生物 AI）、Omniverse（物理仿真）、DRIVE（自动驾驶）、Isaac（机器人）——每个"模型类别"几乎都映射到 NVIDIA 的一条产品线

---

## §7 Layer 5: Applications + 劳动力与生产力 | 第五层：应用 + 就业与增长

### 原文 / Original

> At the top are applications, where economic value is created. Drug discovery platforms. Industrial robotics. Legal copilots. Self-driving cars. A self-driving car is an AI application embodied in a machine. A humanoid robot is an AI application embodied in a body. Same stack. Different outcomes.
>
> That is the five-layer cake:
>
> **Energy → chips → infrastructure → models → applications.**
>
> Every successful application pulls on every layer beneath it, all the way down to the power plant that keeps it alive.
>
> We have only just begun this buildout. We are a few hundred billion dollars into it. Trillions of dollars of infrastructure still need to be built.
>
> Around the world, we are seeing chip factories, computer assembly plants and AI factories being constructed at unprecedented scale. This is becoming the largest infrastructure buildout in human history.
>
> The labor required to support this buildout is enormous. AI factories need electricians, plumbers, pipefitters, steelworkers, network technicians, installers and operators. These are skilled, well-paid jobs, and they are in short supply. You do not need a PhD in computer science to participate in this transformation.
>
> At the same time, AI is driving productivity across the knowledge economy. Consider radiology. AI now assists with reading scans, but demand for radiologists continues to grow. That is not a paradox.
>
> A radiologist's purpose is to care for patients. Reading scans is one task along the way. When AI takes on more of the routine work, radiologists can focus on judgment, communication and care. Hospitals become more productive. They serve more patients. They hire more people.
>
> Productivity creates capacity. Capacity creates growth.

### 翻译

最顶层是**应用**——经济价值在此产生。药物发现平台、工业机器人、法律 Copilot、自动驾驶汽车。自动驾驶汽车是嵌入机器的 AI 应用；人形机器人是嵌入身体的 AI 应用。同一套技术栈，不同的成果。

这就是五层蛋糕：

**能源 → 芯片 → 基础设施 → 模型 → 应用。**

每一个成功的应用都会拉动其下方的每一层，一直到维持它存活的发电厂。

我们才刚刚开始这场建设。目前的投入还只有几千亿美元。仍需建设数万亿美元的基础设施。

在全球范围内，我们正在看到芯片工厂、计算机组装厂和 AI 工厂以前所未有的规模建设。这正在成为**人类历史上最大的基础设施建设**。

支撑这场建设所需的劳动力是巨大的。AI 工厂需要电工、管道工、钢铁工人、网络技术人员、安装人员和操作人员。这些都是高技能、高薪的工作，目前供不应求。**参与这场变革不需要计算机科学博士学位。**

与此同时，AI 正在推动知识经济的生产力增长。以放射科为例：AI 现在辅助阅读扫描影像，但对放射科医生的需求仍在增长。这并不矛盾。

放射科医生的使命是照顾病人。阅读影像只是过程中的一项任务。当 AI 承担更多常规工作时，放射科医生可以专注于判断、沟通和关怀。医院变得更加高效，服务更多患者，雇用更多人。

**生产力创造产能。产能创造增长。**

### 💡 解析

这是全文最长的一节，因为它承载了三个不同的论述任务：

**a) "Same stack. Different outcomes."**
"自动驾驶汽车是嵌入机器的 AI 应用；人形机器人是嵌入身体的 AI 应用"——这个平行句式很精巧。它把看似完全不同的产品（汽车和机器人）统一到同一个技术栈下，暗示 NVIDIA 的平台（DRIVE + Isaac）正是它们共享的底层。

**b) "Trillions of dollars" —— 为资本支出辩护**
"目前几千亿，未来需要万亿"——这是在给整个行业的巨额资本支出（CapEx）提供合理性。2025-2026 年，微软、谷歌、Meta、亚马逊的 AI 基建支出引发了投资者对"过度投资"的担忧。Jensen 的回应是：不是投太多了，而是**才刚开始**。

**c) 放射科案例——回应"AI 抢工作"焦虑**
这是文章中最面向大众的段落。Jensen 的论证链条是：

> AI 提高效率 → 单位产出成本降低 → 机构能服务更多客户 → 机构扩张 → 雇更多人

这是经济学中经典的 **Jevons 悖论**（杰文斯悖论）：技术提高了效率，但总需求反而增长了，最终消耗的资源比以前更多。历史案例包括：ATM 出现后银行网点反而增加了（因为开设成本降低），Excel 出现后会计师反而更多了。

不过需要客观指出：**这个逻辑在宏观级别和长期回看时成立，但在微观层面和短期内，转型阵痛是真实的**。不是所有放射科医生都能顺利转向"判断和沟通"——这需要组织级别的变革。

"You do not need a PhD in computer science to participate" 这句话是在拓宽 AI 受益者的范围，面向蓝领工人和政策制定者。

---

## §8 What Changed in the Last Year? | 过去一年发生了什么变化？

### 原文 / Original

> In the past year, AI crossed an important threshold. Models became good enough to be useful at scale. Reasoning improved. Hallucinations dropped. Grounding improved dramatically. For the first time, applications built on AI began generating real economic value.
>
> Applications in drug discovery, logistics, customer service, software development and manufacturing are already showing strong product-market fit. These applications pull hard on every layer beneath them.
>
> Open source models play a critical role here. Most of the world's models are free. Researchers, startups, enterprises and entire nations rely on open models to participate in advanced AI. When open models reach the frontier, they do not just change software. They activate demand across the entire stack.
>
> DeepSeek-R1 was a powerful example of this. By making a strong reasoning model widely available, it accelerated adoption at the application layer and increased demand for training, infrastructure, chips and energy beneath it.

### 翻译

在过去一年中，AI 跨过了一个重要门槛。模型已经足够好，可以大规模使用。推理能力提升了。幻觉减少了。**接地能力（Grounding）显著改善。** 第一次，构建在 AI 之上的应用开始产生真正的经济价值。

药物发现、物流、客户服务、软件开发和制造领域的应用已经展现出强劲的产品-市场契合度。这些应用有力地拉动了其下方的每一层。

开源模型在此发挥了关键作用。世界上大多数模型都是免费的。研究人员、初创企业、大型企业和整个国家都依赖开源模型来参与先进 AI。**当开源模型到达前沿时，它们不仅仅改变了软件——它们激活了整个技术栈的需求。**

DeepSeek-R1 就是一个有力的例子。通过广泛提供一个强大的推理模型，它加速了应用层的采用，并增加了对其下方训练、基础设施、芯片和能源的需求。

### 💡 解析

**这是全文最具"危机公关"性质的一节。**

2025 年初 DeepSeek-R1 发布后，市场叙事一度变成"中国团队用极少的算力做出了顶级模型 → AI 不需要那么多 GPU → NVIDIA 要完了"，NVIDIA 股价一天内蒸发数千亿美元市值。

Jensen 在这里的回应策略极其巧妙——他没有否认 DeepSeek-R1 的成就，反而**拥抱它**，然后把它重新框定为"需求催化剂"：

> 开源模型降低门槛 → 更多人用 AI → 应用层爆发 → 对底层算力的**总需求反而增大**

这又是 Jevons 悖论的另一个应用。就像便宜的手机让更多人上网，最终让全球互联网基础设施的总投资暴增——便宜的模型会让更多人用 AI，最终让 GPU 总需求暴增。

"Reasoning improved. Hallucinations dropped. Grounding improved dramatically." 这三个短句节奏急促，传递的信息是：**AI 已经从"玩具"变成了"工具"**，拐点已到。这为"应用层开始创造真实经济价值"提供了前提。

---

## §9 What This Means | 这意味着什么

### 原文 / Original

> When you see AI as essential infrastructure, the implications become clear.
>
> AI starts with a transformer LLM. But it's much more. It is an industrial transformation that reshapes how energy is produced and consumed, how factories are built, how work is organized and how economies grow.
>
> AI factories are being built because intelligence is now generated in real time. Chips are being redesigned because efficiency determines how fast intelligence can scale. Energy becomes central because it sets the ceiling on how much intelligence can be produced at all. Applications accelerate because the models beneath them have crossed a threshold where they are finally useful at scale.
>
> Every layer reinforces the others.
>
> This is why the buildout is so large. This is why it touches so many industries at once. And this is why it will not be confined to a single country or a single sector. Every company will use AI. Every nation will build it.
>
> We are still early. Much of the infrastructure does not yet exist. Much of the workforce has not yet been trained. Much of the opportunity has not yet been realized.
>
> But the direction is clear.
>
> AI is becoming the foundational infrastructure of the modern world. And the choices we make now, how fast we build, how broadly we participate and how responsibly we deploy it, will shape what this era becomes.

### 翻译

当你将 AI 视为基础设施时，其影响就变得清晰了。

AI 始于 Transformer LLM，但远不止于此。它是一场**工业变革**，重塑了能源的生产和消耗方式、工厂的建造方式、工作的组织方式和经济的增长方式。

AI 工厂之所以被建设，是因为智能现在是实时生成的。芯片之所以被重新设计，是因为效率决定了智能扩展的速度。能源变得核心，因为它设定了能生产多少智能的上限。应用加速发展，因为其下方的模型已经跨过了大规模可用的门槛。

**每一层互相增强。**

这就是为什么这场建设如此庞大。这就是为什么它同时触及如此多的行业。这也是为什么它不会局限于一个国家或一个行业。每家公司都会使用 AI。每个国家都会建设它。

我们仍处于早期。大量基础设施尚未建成。大量劳动力尚未培训。大量机会尚未实现。

但方向是明确的。

**AI 正在成为现代世界的基础设施。** 而我们现在做出的选择——建设的速度、参与的广度、部署的责任——将塑造这个时代的最终面貌。

### 💡 解析

结尾回归到全文核心论点，并用排比句式强化记忆：

> "This is why... This is why... And this is why..."

"Every layer reinforces the others" 是全文最重要的一句总结。五层蛋糕不是静态堆叠，而是**正反馈飞轮**：更好的芯片 → 更强的模型 → 更多的应用 → 更大的需求 → 更多的能源 + 基建投资 → 更好的芯片... 这个飞轮一旦转动，就会自我加速。

"We are still early" 这三个字价值千金——这是 Jensen 对华尔街说的：**不要因为已经投了几千亿就觉得到头了，这才是开始**。

最后的 "how responsibly we deploy it" 是唯一提到"责任"的地方，一笔带过。这反映了 NVIDIA 作为 AI 基建供应商的立场——推动建设 > 讨论限制。

---

## 📊 全文总评

### 文章定位

这篇文章是 Jensen Huang 在 2026 年初（很可能是 CES/达沃斯演讲的书面版）为 AI 产业定调的**纲领性文献**。它的目标受众不是技术人员，而是**政策制定者、投资者和广义的商界领袖**。

### 核心洞见

1. **AI = 实时生成智能**：打破了传统软件"预录制执行"的范式，因此需要全新的基础设施栈
2. **五层蛋糕框架**（能源 → 芯片 → 基础设施 → 模型 → 应用）：层层依赖，每层互相增强
3. **人类历史上最大基建**：万亿级别投资，创造大量蓝领和白领岗位
4. **开源 = 需求催化剂**：效率提升不减少总需求，反而扩大市场（Jevons 悖论）

### 需要补充的批判性视角

| 文章回避的问题   | 现实情况                                                       |
| ---------------- | -------------------------------------------------------------- |
| 能源可持续性     | AI 算力的碳排放和电网压力是严峻挑战                            |
| 芯片竞争格局     | AMD MI400、Google TPU、自研芯片（AWS Trainium）正加速分食市场  |
| 万亿投资的回报率 | 历史上有大量基建泡沫的先例（铁路泡沫、光纤泡沫）               |
| 地缘政治         | 芯片出口管制让 "Every nation will build it" 远比文章暗示的复杂 |
| 短期就业冲击     | 宏观上"生产力创造增长"成立，但微观上的转型阵痛被轻描淡写       |

### 一句话总结

> 五层蛋糕框架将 AI 从一个"模型好不好用"的技术话题，提升为一个"电厂够不够、工厂建了没"的工业基建话题——这既是 Jensen Huang 最深刻的洞察，也是 NVIDIA 最强大的商业叙事。

