---
title: "Designing AI-Resistant Technical Evaluations | 设计抗 AI 的技术面试"
date: 2026-01-21
category: commentary
tags: [Anthropic, AI-Interview, Performance-Engineering, Claude, Hiring]
source: "https://www.anthropic.com/engineering/AI-resistant-technical-evaluations"
author: "Tristan Hume"
---

# Designing AI-Resistant Technical Evaluations | 设计抗 AI 的技术面试

> **Author / 作者**: Tristan Hume (Lead, Performance Optimization Team @ Anthropic)
> **Published / 发布日期**: January 21, 2026
> **Source / 来源**: https://www.anthropic.com/engineering/AI-resistant-technical-evaluations
> **Reading Time / 阅读时间**: ~12 mins

---

## §1 Introduction — The Arms Race Between Interviews and Models | 引言——面试题与模型之间的军备竞赛

### 原文 / Original

> Evaluating technical candidates becomes harder as AI capabilities improve. A take-home that distinguishes well between human skill levels today may be trivially solved by models tomorrow—rendering it useless for evaluation.
>
> Since early 2024, our performance engineering team has used a take-home test where candidates optimize code for a simulated accelerator. Over 1,000 candidates have completed it, and dozens now work here, including engineers who brought up our Trainium cluster and shipped every model since Claude 3 Opus.
>
> But each new Claude model has forced us to redesign the test. When given the same time limit, Claude Opus 4 outperformed most human applicants. That still allowed us to distinguish the strongest candidates—but then Claude Opus 4.5 matched even those. Humans can still outperform models when given unlimited time, but under the constraints of the take-home test, we no longer had a way to distinguish between the output of our top candidates and our most capable model.
>
> I've now iterated through three versions of our take-home in an attempt to ensure it still carries signal. Each time, I've learned something new about what makes evaluations robust to AI assistance and what doesn't.
>
> This post describes the original take-home design, how each Claude model defeated it, and the increasingly unusual approaches I've had to take to ensure our test stays ahead of our top model's capabilities. While the work we do has evolved alongside our models, we still need more strong engineers—just increasingly creative ways to find them.
>
> To that end, we're releasing the original take-home as an open challenge, since with unlimited time the best human performance still exceeds what Claude can achieve. If you can best Opus 4.5, we'd love to hear from you—details are at the bottom of this post.

### 翻译

随着 AI 能力的提升，评估技术候选人变得越来越难。一道今天能有效区分人类能力水平的 take-home 题，明天可能被模型轻松解决——从而失去筛选价值。

自 2024 年初以来，我们的性能工程团队一直使用一道 take-home 测试，候选人需为一个模拟加速器优化代码。超过 1,000 名候选人完成了这道题，其中数十人现在在这里工作，包括帮我们启用 Trainium 集群并交付自 Claude 3 Opus 以来每一个模型的工程师。

但每个新的 Claude 模型都迫使我们重新设计测试。在相同时间限制下，Claude Opus 4 的表现超过了大多数人类候选人。这仍然能让我们区分最强的候选人——但随后 Claude Opus 4.5 连最强的人类也追平了。人类在无限时间下仍能超越模型，但在 take-home 的时间约束下，我们已经无法区分顶尖候选人和我们最强模型的产出。

我已经迭代了三个版本的 take-home，试图确保它仍然有区分度。每一次，我都学到了一些新东西——什么让评估对 AI 辅助具有鲁棒性，什么不行。

本文描述了原始 take-home 的设计、每个 Claude 模型如何击败它，以及我不得不采取的越来越"非常规"的方法来确保测试领先于我们最强模型的能力。虽然我们的工作已随模型一起演变，但我们仍然需要更多优秀的工程师——只是需要越来越有创意的方式来找到他们。

为此，我们将原始 take-home 作为公开挑战发布，因为在无限时间下，人类的最佳表现仍然超过 Claude 的成绩。如果你能击败 Opus 4.5，我们很乐意听到你的消息——细节在本文末尾。

<kbd>💬A: </kbd>

### 💡 解析

这段引言透露了一个深刻的悖论：**Anthropic 正在做的事情（构建更强的 AI）正在摧毁他们做另一件事情（招人）的基础设施。** 这不是修辞，而是组织层面的实体冲突——你的产品强到了让你自己的招聘流程失效的地步。

"Over 1,000 candidates... dozens now work here" 这个数据很诚实——千中取几十，录取率约 2-5%，说明筛选确实严格。但更值得注意的是，他把 take-home 直接与商业成果挂钩（"shipped every model since Claude 3 Opus"），这是在为 take-home 这种在业界争议较大的面试形式背书。

从叙事策略看，Tristan 一上来就把结论摆出来了：**人类在有限时间内已经无法与模型区分**。这种坦率的自我暴露对 Anthropic 的品牌有双重作用——一方面证明 Claude 的能力（产品营销），另一方面展示团队的透明文化（雇主品牌）。这篇文章本身就是一篇高级招聘广告。

---

## §2 The Origin — Why a Take-Home | 起源——为什么选择 Take-Home

### 原文 / Original

> In November 2023, we were preparing to train and launch Claude Opus 3. We'd secured new TPU and GPU clusters, our large Trainium cluster was coming, and we were spending considerably more than we had in the past on accelerators, but we didn't have enough performance engineers for our new scale. I posted on Twitter asking people to email us, which brought in more promising candidates than we could evaluate through our standard interview pipeline, a process that consumes significant time for staff and candidates.
>
> We needed a way to evaluate candidates more efficiently. So, I took two weeks to design a take-home test that could adequately capture the demands of the role and identify the most capable applicants.

### 翻译

2023 年 11 月，我们正准备训练和发布 Claude Opus 3。我们已拿下新的 TPU 和 GPU 集群，大型 Trainium 集群也即将到来，我们在加速器上的支出远超以往，但却没有足够的性能工程师来匹配新的规模。我在 Twitter 上发帖请人发简历，结果涌入了超过标准面试流程所能消化的候选人——这个流程会消耗面试官和候选人大量时间。

我们需要一种更高效的候选人评估方式。所以，我花了两周时间设计了一道 take-home 测试，以充分捕捉该角色的要求并识别最有能力的申请者。

<kbd>💬A: </kbd>

### 💡 解析

这段话的信息密度很高。"Spending considerably more than we had in the past on accelerators" 间接透露了 Anthropic 在 2023 年底的资本支出量级跳跃——这正是 AI 公司从"研究实验室"转向"基础设施公司"的典型信号。

"Posted on Twitter asking people to email us" 这种招聘方式在硅谷顶级团队中并不罕见（Karpathy 也这么做过），但它暴露了一个有趣的供需矛盾：**性能工程是一个极度稀缺的人才市场**。能写 CUDA kernel、理解加速器内存层次、做 profiling 的工程师，全球可能不超过几千人。Twitter 招聘之所以有效，是因为这个圈子小到可以靠信号传播触达。

"Two weeks to design" 值得注意——这不是 HR 驱动的标准化流程，而是一个技术负责人亲自花两周打造的评估工具。这种投入程度说明他们对这个岗位的选人标准有多认真。

---

## §3 Design Goals | 设计目标

### 原文 / Original

> Take-homes have a bad reputation. Usually they're filled with generic problems which engineers find boring, and which make for poor filters. My goal was different: create something genuinely engaging that would make candidates excited to participate and allow us to capture their technical skills at a high-level of resolution.
>
> The format also offers advantages over live interviews for evaluating performance engineering skills:
>
> **Longer time horizon**: Engineers rarely face deadlines of less than an hour when coding. A 4-hour window (later reduced to 2 hours) better reflects the actual nature of the job. It's still shorter than most real tasks, but we need to balance that with how onerous it is.
>
> **Realistic environment**: No one watching or expecting narration. Candidates work in their own editor without distraction.
>
> **Time for comprehension and tooling**: Performance optimization requires understanding existing systems and sometimes building debugging tools. Both are hard to realistically evaluate in a normal 50 minute interview.
>
> **Compatibility with AI assistance**: Anthropic's general candidate guidance asks candidates to complete take-homes without AI unless indicated otherwise. For this take-home, we explicitly indicate otherwise. Longer-horizon problems are harder for AI to solve completely, so candidates can use AI tools (as they would on the job) while still needing to demonstrate their own skills.
>
> Beyond these format-specific goals, I applied the same principles I use when designing any interview to make the take-home:
>
> **Representative of real work**: The problem should give candidates a taste of what the job actually involves.
>
> **High signal**: The take-home should avoid problems that hinge on a single insight and ensure candidates have many chances to show their full abilities — leaving as little as possible to chance. It should also have a wide scoring distribution, and ensure enough depth that even strong candidates don't finish everything.
>
> **No specific domain knowledge**: People with good fundamentals can learn specifics on the job. Requiring narrow expertise unnecessarily limits the candidate pool.
>
> **Fun**: Fast development loops, interesting problems with depth, and room for creativity.

### 翻译

Take-home 测试名声不好。通常它们充斥着通用问题，工程师觉得无聊，筛选效果也差。我的目标不同：创造一个真正引人入胜的东西，让候选人乐于参与，同时以高分辨率捕捉他们的技术能力。

这种形式在评估性能工程技能方面比现场面试有优势：

**更长的时间跨度**：工程师很少面临不到一小时的编码截止时间。4 小时窗口（后来缩至 2 小时）更能反映工作的真实性质。虽然仍比大多数真实任务短，但我们需要在此与负担之间取得平衡。

**真实的环境**：没人看着你，也不需要解说。候选人在自己的编辑器中不受干扰地工作。

**理解和工具化的时间**：性能优化需要理解现有系统，有时需要构建调试工具。这两者都很难在常规 50 分钟面试中真实评估。

**与 AI 辅助的兼容性**：Anthropic 的通用候选人指南要求在未特别说明时不使用 AI 完成 take-home。对于这道 take-home，我们明确表示允许。更长时间跨度的问题对 AI 来说更难完全解决，因此候选人可以使用 AI 工具（如同在工作中一样），同时仍需展示自身能力。

除了这些格式特定的目标，我还应用了设计任何面试时的通用原则：

**代表真实工作**：问题应让候选人体验到工作的实际内容。

**高信号**：避免依赖单一灵感的问题，确保候选人有多次机会展示全部能力——尽可能减少运气成分。同时要有宽广的分数分布，确保足够的深度让强候选人也无法全部完成。

**不要求特定领域知识**：基础扎实的人可以在工作中学习细节。要求狭窄的专业知识会不必要地限制候选人池。

**有趣**：快速的开发循环、有深度的有趣问题、以及创造力的发挥空间。

<kbd>💬A: </kbd>

### 💡 解析

这一段是面试设计方法论的精华。几个关键设计原则值得展开：

**"Compatibility with AI assistance"** 是最前瞻的一条。在 2023 年底，大多数公司还在纠结"要不要禁止 AI"，Tristan 已经想清楚了：**与其禁止，不如设计成 AI 无法完全解决的问题**。这个思路后来被现实验证是对的——禁止 AI 不可执法，而且与实际工作脱节。

**"High signal"** 中 "avoid problems that hinge on a single insight" 是一个非常成熟的面试设计原则。太多面试题本质上是"你知不知道这个 trick"——IQ test 式的一锤定音。好的面试题应该像打分项目赛而非淘汰赛。

**"Fun"** 被单独列出，这不是装饰。性能工程候选人是稀缺资源，一个无聊的 take-home 会把最好的人筛掉——因为他们有多个 offer，他们会选择不做你的题。把面试本身做成有吸引力的体验，是一种人才市场的竞争策略。

| 设计原则   | 传统面试的问题  | Tristan 的方案               |
| ---------- | --------------- | ---------------------------- |
| 时间跨度   | 50 分钟白板     | 4 小时（后 2 小时）take-home |
| 环境真实性 | 有人看着 + 解说 | 自己的编辑器                 |
| AI 策略    | 禁止或忽略      | 明确允许，靠问题深度抵抗     |
| 分数分布   | pass/fail 二元  | 连续分数，顶尖候选人也做不完 |

---

## §4 The Simulated Machine | 模拟机器

### 原文 / Original

> I built a Python simulator for a fake accelerator with characteristics that resemble TPUs. Candidates optimize code running on this machine, using a hot-reloading Perfetto trace that shows every instruction, similar to the tooling we have on Trainium.
>
> The machine includes features that make accelerator optimization interesting: manually managed scratchpad memory (unlike CPUs, accelerators often require explicit memory management), VLIW (multiple execution units running in parallel each cycle, requiring efficient instruction packing), SIMD (vector operations on many elements per instruction), and multicore (distributing work across cores).
>
> The task is a parallel tree traversal, deliberately not deep learning flavored, since most performance engineers hadn't worked on deep learning yet and could learn domain specifics on the job. The problem was inspired by branchless SIMD decision tree inference, a classical ML optimization challenge as a nod to the past, which only a few candidates had encountered before.
>
> Candidates start with a fully serial implementation and progressively exploit the machine's parallelism. The warmup is multicore parallelism, then candidates choose whether to tackle SIMD vectorization or VLIW instruction packing. The original version also included a bug that candidates needed to debug first, exercising their ability to build tooling.

### 翻译

我用 Python 构建了一个假加速器的模拟器，其特性类似于 TPU。候选人在这台机器上优化代码，使用一个热重载的 **Perfetto** 跟踪界面，可查看每一条指令，类似于我们在 Trainium 上使用的工具。

这台机器包含了使加速器优化有趣的特性：**手动管理的暂存内存**（Scratchpad memory，与 CPU 不同，加速器通常需要显式内存管理）、**VLIW**（每个周期多个执行单元并行运行，需要高效的指令打包）、**SIMD**（每条指令对多个元素进行向量运算）、以及**多核**（将工作分布到多个核心）。

任务是**并行树遍历**，刻意不使用深度学习风格，因为大多数性能工程师还没有深度学习经验，可以在工作中学习领域细节。这个问题受无分支 SIMD 决策树推理启发——一个经典 ML 优化挑战，向过去致敬，只有少数候选人之前遇到过。

候选人从一个完全串行的实现开始，逐步利用机器的并行性。热身是多核并行，然后候选人可以选择处理 SIMD 向量化还是 VLIW 指令打包。原始版本还包含一个需要调试的 bug，考验候选人构建工具的能力。

<kbd>💬A: </kbd>

### 💡 解析

这个设计极其精巧。几个要点：

**用模拟器而非真实硬件**，这一决策同时解决了多个问题：(1) 保密——不暴露 Anthropic 的实际硬件配置；(2) 公平——所有候选人面对完全相同的确定性环境；(3) 可控——可以精确调整难度曲线；(4) AI-resistant——模拟器是定制的，训练数据中不存在。

**"Deliberately not deep learning flavored"** 这一选择反映了一个重要的招聘哲学：好的性能工程师的核心能力是**底层优化直觉**，而非特定领域知识。一个能高效利用 SIMD 和 VLIW 的人，给他三个月可以成为深度学习编译器专家。反过来不一定。

**"Progressively exploit parallelism"** 的渐进式设计确保了宽广的分数分布——这正是 §3 中 "high signal" 原则的具体体现。每一层并行利用都是一个独立的信号维度。

值得注意的是，Perfetto 是 Google 的开源性能分析工具。用它来做可视化说明 Tristan 追求的不是"能不能写代码"，而是"能不能像真正的性能工程师一样工作"——看 trace、找热点、做优化。

---

## §5 Early Results — Validation | 早期结果——有效性验证

### 原文 / Original

> The initial take-home worked well. One person from the Twitter batch scored substantially higher than everyone else. He started in early February, two weeks after our first hires through the standard pipeline. The test proved predictive: He immediately began optimizing kernels and found a workaround for a launch-blocking compiler bug involving tensor indexing math overflowing 32 bits.
>
> Over the next year and a half, about 1,000 candidates completed the take-home, and it helped us hire most of our current performance engineering team. It proved especially valuable for candidates with limited experience on paper: several of our highest-performing engineers came directly from undergrad but showed enough skill on the take-home for us to hire confidently.
>
> Feedback was positive. Many candidates worked past the 4-hour limit because they were enjoying themselves. The strongest unlimited-time submissions included full optimizing mini-compilers and several clever optimizations I hadn't anticipated.

### 翻译

最初的 take-home 效果很好。Twitter 那批候选人中有一个人的得分远超其他所有人。他在二月初入职，比我们通过标准流程的首批录用者晚两周。测试证明了其预测性：他一入职就开始优化 kernel，并找到了一个涉及张量索引数学溢出 32 位的 launch-blocking 编译器 bug 的 workaround。

在接下来的一年半里，约 1,000 名候选人完成了 take-home，它帮助我们招到了当前性能工程团队的大部分成员。它对纸面经验有限的候选人尤其有价值：我们表现最好的几位工程师直接从本科毕业，但在 take-home 中展示了足够的能力，让我们有信心录用。

反馈是正面的。许多候选人在超过 4 小时限制后仍继续工作，因为他们乐在其中。最强的无限时间提交中包含了完整的优化小型编译器以及几个我没有预料到的巧妙优化。

<kbd>💬A: </kbd>

### 💡 解析

这段隐藏着一个对传统招聘的有力批判：**"Several of our highest-performing engineers came directly from undergrad."** 如果用传统简历筛选——年资、名校、大厂——这些人可能连面试机会都没有。Take-home 提供了一种**绕过信号噪声的通道**，让真实能力直接表达。

"Many candidates worked past the 4-hour limit because they were enjoying themselves" 这个信号表明面试设计成功了——它变成了一种**自选择机制**：真正热爱性能优化的人会不由自主地深入下去。这比任何 "passion" 面试问题都有效。

"Full optimizing mini-compilers" 作为超额作答出现，说明问题空间设计得足够开放，没有人为的天花板。这与 LeetCode 式的"标准答案"形成鲜明对比——后者的最优解通常大家都一样，而这道题允许无限创造力，本质上更接近科研而非考试。

---

## §6 Then Claude Opus 4 Defeated It | Claude Opus 4 击败了它

### 原文 / Original

> By May 2025, Claude 3.7 Sonnet had already crept up to the point where over 50% of candidates would have been better off delegating to Claude Code entirely. I then tested a pre-release version of Claude Opus 4 on the take-home. It came up with a more optimized solution than almost all humans did within the 4-hour limit.
>
> This wasn't my first interview defeated by a Claude model. I'd designed a live interview question in 2023 specifically because our questions at the time were based around common tasks that early Claude models had lots of knowledge of and so could solve easily. I tried to design a question that required more problem solving skill than knowledge, still based on a real (but niche) problem I'd solved at work. Claude 3 Opus beat part 1 of that question; Claude 3.5 Sonnet beat part 2. We still use it because our other live questions aren't AI-resistant either.
>
> For the take-home, there was a straightforward fix. The problem had far more depth than anyone could explore in 4 hours, so I used Claude Opus 4 to identify where it started struggling. That became the new starting point for version 2. I wrote cleaner starter code, added new machine features for more depth, and removed multicore (which Claude had already solved, and which only slowed down development loops without adding signal).
>
> I also shortened the time limit from 4 hours to 2 hours. I'd originally chosen 4 hours based on candidate feedback preferring less risk of getting sunk if they got stuck for a bit on a bug or confusion, but the scheduling overhead was causing multi-week delays in our pipeline. Two hours is much easier to fit into a weekend.
>
> Version 2 emphasized clever optimization insights over debugging and code volume. It served us well—for several months.

### 翻译

到 2025 年 5 月，Claude 3.7 Sonnet 已经强到超过 50% 的候选人本可以把整个任务委托给 Claude Code 来获得更好的结果。之后我在一个预发布版本的 Claude Opus 4 上测试了这道 take-home。它在 4 小时限制内给出了比几乎所有人类都更优化的方案。

这不是我的面试题第一次被 Claude 模型击败。2023 年我设计了一道现场面试题，正是因为当时的题目是基于常见任务，早期 Claude 模型拥有大量相关知识因而能轻松解决。我试图设计一道需要更多**问题解决能力**而非知识的题目，仍然基于我在工作中解决的一个真实（但小众的）问题。Claude 3 Opus 击败了该问题的第一部分；Claude 3.5 Sonnet 击败了第二部分。我们仍在使用它，因为我们的其他现场面试题也不具备 AI 抗性。

对于 take-home，有一个直接的修复方案。问题拥有远超任何人在 4 小时内能探索的深度，所以我用 Claude Opus 4 来确定它开始力不从心的位置。那就成了版本 2 的新起点。我编写了更干净的起始代码，新增了机器特性以增加深度，并移除了多核（Claude 已经解决了多核，而且它只会拖慢开发循环而不增加信号）。

我还将时间限制从 4 小时缩短到 2 小时。我最初选择 4 小时是基于候选人的反馈——他们更希望减少在 bug 或困惑上卡住的风险——但调度开销导致流程出现数周延迟。2 小时更容易安排在一个周末。

版本 2 强调巧妙的优化洞察而非调试和代码量。它为我们服务了好几个月。

<kbd>💬A: </kbd>

### 💡 解析

**"Over 50% of candidates would have been better off delegating to Claude Code entirely"** 这句话是全文最触目惊心的数据点。它意味着在 2025 年 5 月，对于一道为性能工程专家设计的 take-home，过半的申请者——注意这些不是随机路人，而是认为自己有资格申请 Anthropic 性能工程的人——不如直接让 AI 做。

Tristan 应对方法的精髓在于：**用 AI 来测试 AI 的边界，然后把人类起跑线设在 AI 的终点之后**。这是一个自我迭代的设计方法论——从 Claude 开始挣扎的地方开始出题。但这也隐含一个递归问题：如果下一代模型的"挣扎起点"又往后推了怎么办？

"We still use it because our other live questions aren't AI-resistant either" 这句话意味着这不只是一道题的问题，而是**整个技术面试体系的系统性崩溃**。如果连 Anthropic 这种最有动机、最有能力设计抗 AI 面试的公司都承认自己的现场面试题也沦陷了，那么其他公司的处境可想而知。

"Served us well—for several months" 末尾那个破折号读起来像叹息。几个月。上一版本用了一年半。AI 能力增长正在压缩每一版面试题的有效寿命。

---

## §7 Then Claude Opus 4.5 Defeated That | Claude Opus 4.5 又击败了它

### 原文 / Original

> When I tested a pre-release Claude Opus 4.5 checkpoint, I watched Claude Code work on the problem for 2 hours, gradually improving its solution. It solved the initial bottlenecks, implemented all the common micro-optimizations, and met our passing threshold in under an hour.
>
> Then it stopped, convinced it had hit an insurmountable memory bandwidth bottleneck. Most humans reach the same conclusion. But there are clever tricks that exploit the problem structure to work around that bottleneck. When I told Claude the cycle count it was possible to achieve, it thought for a while and found the trick. It then debugged, tuned, and implemented further optimizations. By the 2-hour mark, its score matched the best human performance within that time limit—and that human had made heavy use of Claude 4 with steering.
>
> We tried it out in our internal test-time compute harness for more rigor and confirmed it could both beat humans in 2 hours and continue climbing with time. Post-launch we even improved our harness in a generic way and got a higher score.
>
> I had a problem. We were about to release a model where the best strategy on our take-home would be delegating to Claude Code.

### 翻译

当我测试 Claude Opus 4.5 的一个预发布 checkpoint 时，我看着 Claude Code 在这个问题上工作了 2 小时，逐步改善它的解决方案。它在不到一小时内解决了初始瓶颈，实现了所有常见的微优化，并达到了我们的通过阈值。

然后它停下来了，认为自己遇到了不可逾越的**内存带宽瓶颈**。大多数人类也会得出同样的结论。但有一些巧妙的技巧可以利用问题结构来绕过那个瓶颈。当我告诉 Claude 可以达到的 cycle 数时，它思考了一会儿并找到了那个技巧。然后它进行了调试、调优，并实现了进一步的优化。在 2 小时的时间节点上，它的得分与在相同时间限制内人类的最佳表现持平——而那位人类还大量使用了 Claude 4 进行引导。

我们在内部的 test-time compute harness 中进行了更严格的测试，确认它在 2 小时内能击败人类并且随时间继续提升。发布后我们甚至以通用方式改进了 harness 并获得了更高分数。

我遇到了一个难题。我们即将发布一个模型，而在我们的 take-home 上的最佳策略将是把它委托给 Claude Code。

<kbd>💬A: </kbd>

### 💡 解析

这段描述中最引人深思的细节是：**Claude 和人类犯了一样的错误——认为内存带宽瓶颈不可逾越**。然后，当给出一个提示（可达到的 cycle 数），Claude 就能找到突破口。这说明当前模型的局限性不在于"不会做"，而在于**不知道还能更好**——它缺乏的是对"可能性边界"的直觉。

"That human had made heavy use of Claude 4 with steering" 暗示了一个新的评估维度：**人类 + AI 协作的上限** vs **AI 独立运作的上限**。当最强的人类已经依赖 AI 辅助，而纯 AI 又追平了人类+AI 的组合，等式就变成了：Claude 4.5 ≈ Best Human + Claude 4。下一步呢？

"The best strategy on our take-home would be delegating to Claude Code" 这句话的潜台词是：**面试题要求的能力已经完全落入 AI 的能力覆盖范围**。这不是 AI 作弊，而是 AI 确实具备了这个层次的性能优化能力。

---

## §8 Considering the Options | 考虑各种方案

### 原文 / Original

> Some colleagues suggested banning AI assistance. I didn't want to do this. Beyond the enforcement challenges, I had a sense that given people continue to play a vital role in our work, I should be able to figure out some way for them to distinguish themselves in a setting with AI—like they'd have on the job. I didn't want to give in yet to the idea that humans only have an advantage on tasks longer than a few hours.
>
> Others suggested raising the bar to "substantially outperform what Claude Code achieves alone." The concern here was that Claude works fast. Humans typically spend half the 2 hours reading and understanding the problem before they start optimizing. A human trying to steer Claude would likely be constantly behind, understanding what Claude did only after the fact. The dominant strategy might become sitting back and watching.
>
> Nowadays performance engineers at Anthropic still have lots of work to do, but it looks more like tough debugging, systems design, performance analysis, figuring out how to verify the correctness of our systems, and figuring out how to make Claude's code simpler and more elegant. Unfortunately these things are tough to test in an objective way without a lot of time or common context. It's always been hard to design interviews that represent the job, but now it's harder than ever.
>
> But I also worried if I invested in designing a new take-home, either Claude Opus 4.5 would solve that too, or it would become so challenging that it would be impossible for humans to complete in two hours.

### 翻译

一些同事建议禁止 AI 辅助。我不想这么做。除了执法方面的挑战之外，我有一种直觉：既然人类在我们的工作中仍然扮演着至关重要的角色，我应该能找到一种方式让他们在有 AI 的环境中脱颖而出——就像在工作中一样。我还不想向"人类只在超过几个小时的任务上才有优势"这个观点投降。

其他人建议提高标准到"大幅超越 Claude Code 独立完成的水平"。这里的顾虑是 Claude 工作速度快。人类通常会花 2 小时中的一半来阅读和理解问题，然后才开始优化。一个试图引导 Claude 的人可能会一直落后——只能在事后理解 Claude 做了什么。主导策略可能变成坐着看。

如今 Anthropic 的性能工程师仍然有很多工作要做，但看起来更像是**困难的调试、系统设计、性能分析、搞清如何验证系统正确性、以及搞清如何让 Claude 的代码更简洁优雅**。不幸的是，这些东西很难在没有大量时间或共同上下文的情况下以客观方式测试。设计代表实际工作的面试一直很难，但现在比以往任何时候都更难。

但我也担心，如果我投入精力设计一道新的 take-home，要么 Claude Opus 4.5 也能解决它，要么它会变得太有挑战性以至于人类在两小时内无法完成。

<kbd>💬A: </kbd>

### 💡 解析

这一段是全文思想密度最高的部分，Tristan 在这里暴露了一个**三难困境（trilemma）**：

1. **禁止 AI** → 不可执法 + 脱离实际工作
2. **提高标准** → 人类可能退化为"看 AI 做题的旁观者"
3. **设计新题** → 可能太难人类做不了，或者又被 AI 秒杀

"The dominant strategy might become sitting back and watching" 是一个深刻的洞察。当 AI 做得比你引导它更好时，**最优策略是不介入**。这与"AI 增强人类"的悦耳叙事直接冲突。

但最值得关注的是他对性能工程师实际工作变化的描述：从"写优化代码"变成了"调试、系统设计、验证正确性、让 Claude 的代码更优雅"。这是一个关于**所有**工程角色未来的预言——人类的工作重心从"生产"转向"审计和设计"。

| 方案     | 优点               | 致命缺陷               |
| -------- | ------------------ | ---------------------- |
| 禁止 AI  | 简单直接           | 无法执法；脱离实际工作 |
| 提高标准 | 仍允许 AI 辅助     | 人类可能变成旁观者     |
| 设计新题 | 有可能找到 AI 盲区 | 可能太难或还是被解决   |

---

## §9 Attempt 1: A Different Optimization Problem | 尝试 1：换一个优化问题

### 原文 / Original

> I realized Claude could help me implement whatever I designed quickly, which motivated me to try developing a harder take-home. I chose a problem based on one of the trickier kernel optimizations I'd done at Anthropic: an efficient data transposition on 2D TPU registers while avoiding bank conflicts. I distilled it into a simpler problem on a simulated machine and had Claude implement the changes in under a day.
>
> Claude Opus 4.5 found a great optimization I hadn't even thought of. Through careful analysis, it realized it could transpose the entire computation rather than figuring out how to transpose the data, and it rewrote the whole program accordingly.
>
> In my real case, this wouldn't have worked, so I patched the problem to remove that approach. Claude then made progress but couldn't find the most efficient solution. It seemed like I had my new problem, now I just had to hope human candidates could get it fast enough. But I had some nagging doubt, so I double-checked using Claude Code's "ultrathink" feature with longer thinking budgets ... and it solved it. It even knew the tricks for fixing bank conflicts.
>
> In hindsight, this wasn't the right problem to try. Engineers across many platforms have struggled with data transposition and bank conflicts, so Claude has substantial training data to draw on. While I'd found my solution from first principles, Claude could draw on a larger toolbox of experience.

### 翻译

我意识到 Claude 可以快速帮我实现我设计的任何东西，这激发了我去尝试开发一道更难的 take-home。我选了一个基于我在 Anthropic 做过的最棘手的 kernel 优化之一的问题：在 2D TPU 寄存器上进行高效的数据**转置**（transposition），同时避免 **bank conflict**。我把它精简为模拟机器上的一个更简单的问题，让 Claude 在不到一天内实现了改动。

Claude Opus 4.5 找到了一个连我都没想到的优雅优化。通过仔细分析，它意识到可以**转置整个计算**而不是想办法转置数据，并据此重写了整个程序。

在我的实际案例中，这种方法行不通，所以我修补了问题以移除这种方法。Claude 随后取得了进展但未能找到最优解。看起来我有了新题目，现在只要寄望人类候选人能足够快地解出来。但我有一些挥之不去的疑虑，所以我用 Claude Code 的 "ultrathink" 功能和更长的思考预算进行了复查……它解出来了。它甚至知道修复 bank conflict 的技巧。

事后看来，这不是正确的问题选择。各个平台上的工程师都曾对数据转置和 bank conflict 深感头疼，因此 Claude 有大量训练数据可以借鉴。虽然我是从第一性原理出发找到解决方案的，但 Claude 可以调用更大的经验工具箱。

<kbd>💬A: </kbd>

### 💡 解析

"Claude could transpose the entire computation rather than transposing the data" ——这是一个人类可能做出的创造性飞跃，但 Claude 做到了。这类洞察通常被视为需要"真正的理解"，但实际上它更可能是**模式匹配**的结果：在大量代码库中，"与其搬数据不如改计算"是一种已知的优化范式。

关键教训在最后一句：**问题的 AI 抗性取决于它与训练数据的距离，而不是它对人类的绝对难度**。一个对人类很难但在 Stack Overflow / GPU 优化论坛 / 编译器论文中广泛讨论过的问题，对 AI 来说可能出奇地容易。这颠覆了"难题 = AI 做不了"的直觉。

"Ultrathink" 的出现也值得注意。给模型更多思考时间就能找到解法，这说明瓶颈不在"知识"而在"搜索空间"。test-time compute 的提升正在系统性地消除 AI 在复杂推理上的劣势。

---

## §10 Attempt 2: Going Weirder | 尝试 2：走向"更奇怪"

### 原文 / Original

> I needed a problem where human reasoning could win over Claude's larger experience base: something sufficiently out of distribution. Unfortunately, this conflicted with my goal of being recognizably like the job.
>
> I thought about the most unusual optimization problems I'd enjoyed and landed on Zachtronics games. These programming puzzle games use unusual, highly constrained instruction sets that force you to program in unconventional ways. For example, in Shenzhen I/O, programs are split across multiple communicating chips that each hold only about 10 instructions with one or two state registers. Clever optimization often involves encoding state into the instruction pointer or branch flags.
>
> I designed a new take-home consisting of puzzles using a tiny, heavily constrained instruction set, optimizing solutions for minimal instruction count. I implemented one medium-hard puzzle and tested it on Claude Opus 4.5. It failed. I filled out more puzzles and had colleagues verify that people less steeped in the problem than me could still outperform Claude.
>
> Unlike Zachtronics games, I intentionally provided no visualization or debugging tools. The starter code only checks whether solutions are valid. Building debugging tools is part of what's being tested: you can either insert well-crafted print statements or ask a coding model to generate an interactive debugger in a few minutes. Judgment about how to invest in tooling is part of the signal.
>
> I'm reasonably happy with the new take-home. It might have lower variance than the original because it comprises more independent sub-problems. Early results are promising: scores correlate well with the caliber of candidates' past work, and one of my most capable colleagues scored higher than any candidate so far.
>
> I'm still sad to have given up the realism and varied depth of the original. But realism may be a luxury we no longer have. The original worked because it resembled real work. The replacement works because it simulates novel work.

### 翻译

我需要一个**人类推理能力可以胜过 Claude 更大经验库**的问题：某种足够**超出分布**（out of distribution）的东西。不幸的是，这与我"贴近真实工作"的目标相冲突。

我想了想我享受过的最不寻常的优化问题，最终选定了 **Zachtronics 游戏**。这些编程解谜游戏使用不寻常的、高度受限的指令集，迫使你以非常规方式编程。例如在《深圳 I/O》中，程序被分割到多个相互通讯的芯片上，每个芯片只能容纳约 10 条指令和一两个状态寄存器。巧妙的优化通常涉及将状态编码到指令指针或分支标志中。

我设计了一道由一系列谜题组成的新 take-home，使用一个微小的、高度受限的指令集，以最少指令数优化解决方案。我实现了一个中等难度的谜题，在 Claude Opus 4.5 上测试。它失败了。我填充了更多谜题，并让同事验证那些不像我那么深入了解问题的人仍能超越 Claude。

与 Zachtronics 游戏不同，我故意不提供可视化或调试工具。起始代码只检查解决方案是否有效。构建调试工具本身就是测试的一部分：你可以插入精心设计的 print 语句，或者让编码模型在几分钟内生成一个交互式调试器。**对工具投资的判断**是信号的一部分。

我对新的 take-home 还算满意。它可能比原版方差更低，因为它包含更多独立的子问题。早期结果令人鼓舞：分数与候选人过去工作水准的相关性良好，我的一位最有能力的同事得分高于迄今为止所有候选人。

我仍然惋惜不得不放弃原版的真实性和丰富层次。但**真实性可能是我们已经负担不起的奢侈品**。原版有效是因为它像真实工作。替代版有效是因为它模拟的是**新颖的工作**。

<kbd>💬A: </kbd>

### 💡 解析

**"Realism may be a luxury we no longer have"** ——这是全文最深刻的一句话。它的意义远超面试设计：当 AI 能做所有"像真实工作"的事情时，评估人类的唯一方式就是用"不像任何已知工作"的东西。这是一个关于人类价值定位的哲学陈述。

Zachtronics 游戏的选择极其聪明。原因：

1. **极低的训练数据密度**——Zachtronics 是小众独立游戏，相关讨论在整个互联网上的份量微乎其微
2. **极高的推理密度**——用 10 条指令解决问题需要的是组合创造力，不是模式匹配
3. **高度受限的搜索空间**——看似矛盾，但极端约束反而产生更大的区分度——因为"暴力搜索"行不通

"Building debugging tools is part of what's being tested" 这个设计选择揭示了一个更深层的能力维度：**元认知**——你不仅要解题，还要决定什么时候停下来为自己造工具。这种"投资判断"正是 AI 目前还不擅长的——AI 不会自发决定"我需要先造一个调试器"。

最后的对比值得深思：

| 维度        | 原版 take-home     | 新版 take-home       |
| ----------- | ------------------ | -------------------- |
| 设计哲学    | 模拟真实工作       | 模拟新颖工作         |
| 有效机制    | 经验深度           | 推理创造力           |
| AI 抗性来源 | 问题深度（已失效） | 分布外 + 低训练数据  |
| 人类优势    | 领域专长           | 小空间内的组合探索   |
| 风险        | 被 AI 追平         | 可能不够贴近实际工作 |

---

## §11 The Open Challenge — Benchmarks | 公开挑战——基准数据

### 原文 / Original

> We're releasing the original take-home for anyone to try with unlimited time. Human experts retain an advantage over current models at sufficiently long time horizons. The fastest human solution ever submitted substantially exceeds what Claude has achieved even with extensive test-time compute.
>
> The released version starts from scratch (like version 1) but uses version 2's instruction set and single-core design, so cycle counts are comparable to version 2.
>
> Performance benchmarks (measured in clock cycles from the simulated machine):
>
> • 2164 cycles: Claude Opus 4 after many hours in the test-time compute harness
> • 1790 cycles: Claude Opus 4.5 in a casual Claude Code session, approximately matching the best human performance in 2 hours
> • 1579 cycles: Claude Opus 4.5 after 2 hours in our test-time compute harness
> • 1548 cycles: Claude Sonnet 4.5 after many more than 2 hours of test-time compute
> • 1487 cycles: Claude Opus 4.5 after 11.5 hours in the harness
> • 1363 cycles: Claude Opus 4.5 in an improved test time compute harness after many hours
>
> If you optimize below 1487 cycles, beating Claude's best performance at launch, email us at performance-recruiting@anthropic.com with your code and a resume.
>
> Or you can apply through our typical process, which uses our (now) Claude-resistant take-home. We're curious how long it lasts.

### 翻译

我们将原始 take-home 发布供任何人以无限时间尝试。在足够长的时间跨度下，人类专家仍优于当前模型。有史以来最快的人类提交大幅超过了 Claude 即使在大量 test-time compute 下的成绩。

发布版本从零开始（如版本 1），但使用版本 2 的指令集和单核设计，因此 cycle 数与版本 2 可比。

性能基准（以模拟机器的时钟周期计）：

- **2164 cycles**：Claude Opus 4 在 test-time compute harness 中运行数小时后
- **1790 cycles**：Claude Opus 4.5 的一次随意 Claude Code 会话，大致与人类 2 小时最佳表现持平
- **1579 cycles**：Claude Opus 4.5 在 test-time compute harness 中 2 小时后
- **1548 cycles**：Claude Sonnet 4.5 在远超 2 小时的 test-time compute 后
- **1487 cycles**：Claude Opus 4.5 在 harness 中 11.5 小时后
- **1363 cycles**：Claude Opus 4.5 在改进的 test-time compute harness 中数小时后

如果你优化到低于 1487 cycles，击败 Claude 在发布时的最佳表现，请将你的代码和简历发送至 performance-recruiting@anthropic.com。

或者你可以通过我们的正常流程申请，该流程使用我们（现在的）Claude 抗性 take-home。我们也好奇它能撑多久。

<kbd>💬A: </kbd>

### 💡 解析

这段数据提供了一份难得的 **AI vs 人类性能优化能力的定量对照表**。几个观察：

**Opus 4 → Opus 4.5 的跳跃**：2164 → 1790 cycles（在随意会话中），性能提升约 17%。这个代际提升的幅度与 Anthropic 在其他 benchmark 上展示的一致。

**Test-time compute 的收益递减**：Opus 4.5 从 2 小时（1579）到 11.5 小时（1487）只多优化了约 6%。从 11.5 小时到"many hours in improved harness"（1363）又多了约 8%。搜索空间的效率在下降，但改进 harness 可以重新激活搜索。

**Sonnet 4.5 vs Opus 4.5**：有趣的是，Sonnet 4.5 在"远超 2 小时"后达到 1548 cycles，介于 Opus 4.5 的 2 小时（1579）和 11.5 小时（1487）之间。这暗示模型的"大小"和 test-time compute 之间存在可替代关系。

**"We're curious how long it lasts"** 是全文最妙的结尾。这不是谦虚——这是对自己产品发展速度的一种苦笑式承认。Tristan 知道新的 take-home 终将被击败，问题只是"几个月还是更短"。

这也是一封精心包装的**招聘帖**：用公开数据展示 Anthropic 的技术实力，用无限时间挑战吸引全球最好的性能工程师，同时把选拔过程做成了公开的竞赛——传播效果远超任何招聘广告。

---

## 总结 / Summary

### 1. 核心论点

技术面试正经历一场与 AI 能力增长的**不对称军备竞赛**。传统面试设计原则（"贴近真实工作"、"考察领域知识"）已经失效，因为 AI 正是在"已知的、真实的、有大量先例的"任务上表现最强。唯一仍对人类有利的维度是**新颖性**——足够超出分布的问题。

### 2. 作者的立场与动机

Tristan 的立场清晰且诚实：他不是在抱怨 AI，也不是在鼓吹人类无用。他是一个实际面对问题的工程负责人，在坦诚记录自己的迭代过程。但这篇文章同时也是一份精心设计的品牌内容——它同时服务于三个目标：

- **产品营销**：Claude 强到连自家的专家面试题都能解
- **雇主品牌**：展示 Anthropic 的技术深度和透明文化
- **主动招聘**：公开挑战 + 数据基准 = 面向全球最好的性能工程师的邀请函

### 3. 对行业的实际影响

- **面试设计**必须将 AI 辅助作为默认假设，而非例外情况
- **"AI-resistant" 的核心** = out-of-distribution，而非"更难"
- **性能工程师的角色演变**：从"写优化代码"到"调试/验证/设计 AI 无法独立完成的高层决策"
- Take-home 面试的"有效保质期"正在显著缩短（18 个月 → 数月 → ?）

### 4. 需要持续观察的点

- 新的 Zachtronics 风格 take-home 能撑多久？下一代 Claude 或 o3 会解决它吗？
- 当所有"标准"面试形式都被 AI 击败后，行业会收敛到什么样的评估范式？（可能回归长周期试用/实习？）
- **"人类在足够长时间跨度上仍占优"** 这个论点的时间窗口还有多宽？METR 的研究显示该交叉点正在缩短
- 如果面试必须"不像真实工作"才能有效，那面试结果还能预测工作表现吗？这是一个根本性的**效度悖论**
