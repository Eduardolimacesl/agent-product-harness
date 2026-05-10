## THE LAST HARNESS YOU'LL EVER BUILD

Haebin Seong Sylph.AI

Li Yin Sylph.AI

Haoran Zhang Sylph.AI

## ABSTRACT

AI agents are increasingly deployed on complex, domain-specific workflowsnavigating enterprise web applications that require dozens of clicks and form fills, orchestrating multi-step research pipelines that span search, extraction, and synthesis, automating code review across unfamiliar repositories, and handling customer escalations that demand nuanced domain knowledge. Each new task domain requires painstaking, expert-driven harness engineering : designing the prompts, tools, orchestration logic, and evaluation criteria that make a foundation model effective. We present a two-level framework that automates this process. At the first level, the Harness Evolution Loop optimizes a worker agent's harness H for a single task: a Worker Agent W H executes the task, an Evaluator Agent V adversarially diagnoses failures and scores performance, and an Evolution Agent E modifies the harness based on the full history of prior attempts. At the second level, the Meta-Evolution Loop optimizes the evolution blueprint Λ = ( W H , H (0) , V, E ) itself across diverse tasks, learning a blueprint Λ ( best ) that enables rapid harness convergence on any new task-so that adapting an agent to a novel domain requires no human harness engineering at all. We formalize the correspondence to meta-learning and present both algorithms. The framework shifts manual harness engineering into automated harness engineering , and takes one step furtherautomating the design of the automation itself .

## 1 INTRODUCTION

Recent work on harness engineering has demonstrated that carefully designed scaffoldingexecution environments, feedback loops, evaluation criteria, and context management-can dramatically amplify what agents achieve (Lopopolo, 2026; Rajasekaran, 2026). However, these harnesses are themselves products of highly intensive, specialized human engineering . Lopopolo (2026) describe building custom linters, repository-local observability stacks (logs, metrics, traces), Chrome DevTools integration, and structured documentation hierarchies-all hand-crafted to make the codebase legible to the agent. Rajasekaran (2026) report iterating through multiple rounds of evaluator prompt calibration with few-shot examples, designing four grading criteria for subjective design quality, and building a three-agent planner-generator-evaluator architecture with sprint contracts negotiated between agents. In both cases, the harness required deep domain expertise to construct and significant iteration to tune. The harness improves the agent, but improving the harness still requires substantial human expertise applied to each specific task domain. While automated prompt optimization methods such as LLM-AutoDiff (Yin &amp; Wang, 2025) can tune individual components, they do not address the full harness-the tools, orchestration logic, infrastructure, and their interactions.

We propose a two-level framework that automates this improvement cycle. At the first level, the Harness Evolution Loop optimizes a worker agent's harness H for a single task through a closedloop cycle of three agents:

1. A Worker Agent W H -the agent under optimization-parameterized by its harness H , which executes a task and produces an execution trace.
2. An Evaluator Agent V that adversarially verifies task outcomes, diagnoses failure modes, and scores performance.

Zhan Shi Sylph.AI

Figure 1: System architecture. The Meta-Evolution Loop (green, outer) optimizes the evolution blueprint Λ by running the Harness Evolution Loop (blue, inner) across diverse training tasks t 1 , t 2 , . . . , t n . Each inner loop instance optimizes a worker harness H for a single task through iterative cycles of execution (Worker), evaluation (Evaluator), and code modification (Evolution Agent). The meta-evolution agent aggregates scores across all tasks and modifies the evolution blueprint, feeding the updated blueprint back for the next round. The output is the best-performing evolution blueprint Λ ( best ) .

<!-- image -->

3. An Evolution Agent E that analyzes the full evolution history and modifies the harnessprompts, tools, orchestration logic, observations, and model configuration-to address diagnosed failure patterns.

Starting from an initial harness H (0) -which may be a generic, untuned agent scaffold-the loop iterates for K steps: at each step, the worker executes the task, the evaluator diagnoses and scores the result, and the evolution agent produces an improved harness based on the full history of prior attempts, ultimately returning the best-performing harness H ( best ) . Together, these components form an evolution blueprint Λ = ( W H , H (0) , V, E ) that fully specifies how the harness is evolved.

At the second level, a Meta-Evolution Loop optimizes Λ itself across diverse tasks, learning an evolution blueprint Λ ( best ) that enables rapid harness convergence on any new task-transforming not just harness engineering, but the design of the harness engineering process itself, into an automated optimization problem.

## 2 THE HARNESS EVOLUTION LOOP

Wefirst formally define the notion of an agent harness, then describe the system's components-task definition, task execution, evaluation, and evolution-and how they are orchestrated in the harness evolution loop. The four components are orchestrated by a continuous automation loop, shown in Algorithm 1.

## Algorithm 1 The Harness Evolution Loop

```
Require: Task t , Worker Agent W H , initial worker harness H (0) , Evaluator Agent V , Evolution Agent E , iterations K 1: H ( best ) ←H (0) ; best score ←-∞ 2: history ← [ ] { Log of ( H ( k ) , report, score, verdict) per iteration } 3: for k = 1 , 2 , . . . , K do 4: Rebuild W H ( k -1) from H ( k -1) 5: Prepare target environment; reset to clean state 6: trace ← W H ( k -1) . execute ( t ) { Worker runs task } 7: ( report , score ) ← V. evaluate ( trace , t ) { Evaluator diagnoses and scores } 8: if score > best score then 9: verdict ← IMPROVED; H ( best ) ←H ( k -1) ; best score ← score 10: else 11: verdict ← REGRESSED 12: end if 13: history ← history ∪ { ( H ( k -1) , report , score , verdict ) } 14: H ( k ) ← E. evolve ( history , H ( best ) ) { Evolve from best harness } 15: end for 16: return H ( best ) , best score , history
```

## Algorithm 2 The Meta-Evolution Loop

```
Require: Meta-train tasks T train , Meta-Evolution Agent E meta , initial evolution blueprint Λ (0) , inner-loop budget K 1: Λ ( best ) ← Λ (0) ; best meta score ←-∞ 2: meta history ← [ ] 3: for j = 0 , 1 , 2 , . . . do 4: task results ← [ ] 5: for each task t i ∈ T train do 6: H ( best ) i , best score i , history i ← HARNESSEVOLUTIONLOOP ( t i , Λ ( j ) , K ) { Alg. 1 } 7: task results ← task results ∪ { ( t i , best score i , history i ) } 8: end for 9: meta score ← Aggregate ( task results ) { Mean score across tasks } 10: if meta score > best meta score then 11: verdict ← IMPROVED; Λ ( best ) ← Λ ( j ) ; best meta score ← meta score 12: else 13: verdict ← REGRESSED 14: end if 15: meta history ← meta history ∪ { (Λ ( j ) , task results , meta score , verdict ) } 16: Λ ( j +1) ← E meta . evolve ( meta history , Λ ( best ) ) { Evolve from best blueprint } 17: end for 18: return Λ ( best ) , best meta score , meta history
```

## 2.1 DEFINING THE AGENT HARNESS

A raw model is not an agent. Following Trivedy (2026), we adopt the formulation: Agent = Model + Harness . A harness is every piece of code, configuration, and execution logic that is not the model itself -it is the system that makes the model's intelligence useful. A harness can take many forms; popular categories of harness components include:

- System prompts and task prompts : system-level instructions that define the agent's identity and constraints, and task-level prompts that specify goals, success criteria, and incontext examples.
- Tools, skills, and their descriptions : the capabilities the agent can invoke to act on its environment (e.g., file editing, shell execution, UI interaction, web search, MCP servers).

- Bundled infrastructure : the execution environment provided to the agent (filesystem, sandboxes, browsers, observability stacks).
- Orchestration logic : the control flow that structures the agent's interaction loop (subagent spawning, handoffs, model routing, feedback loops, and continuation patterns such as the Ralph Loop).
- Hooks and middleware : deterministic execution guarantees injected around the model (compaction, continuation, lint checks, verification loops).
- Model configurations : the choice of underlying model, inference parameters (temperature, sampling strategy, token limits), and model routing rules that determine which model handles which subtask.

Harnesses appear throughout the agent ecosystem. AdaL (SylphAI, 2026), Claude Code (Anthropic, 2025), and Codex (OpenAI, 2025) are harnesses for general-purpose software engineering-they wrap LLMs with filesystem access, shell execution, web search, and multi-file editing. OpAgent (Guo et al., 2026) is a harness for autonomous web navigation, combining a Planner, Grounder, Reflector, and Summarizer into a multi-agent pipeline that achieved state-of-the-art results on WebArena (Zhou et al., 2024). In every case, the harness-not the model-determines what the agent can perceive, how it acts, and how its work is orchestrated and verified.

## 2.2 TASK DEFINITIONS

A task t = ( I, S ) consists of:

- Instructions I : a concrete goal for the worker agent.
- Success criteria S = { s 1 , s 2 , . . . , s m } : a checklist of verifiable conditions the evaluator uses to judge completion.

## 2.3 WORKER AGENT

The Worker Agent W H is the agent under optimization-parameterized by its harness H . It exposes a single interface W H . execute ( t ) : given a task t , the worker receives the instructions I , interacts with the target environment through a tool interface, and produces an execution trace τ containing environment observations, action logs, and timing information for each step.

The harness-based agents described in Section 2.1-AdaL, Claude Code, Codex, and OpAgentcan all be set as worker agents W H , each attempting to solve a task using a specific harness configuration.

## 2.4 EVALUATOR AGENT

The Evaluator Agent V is a separate, adversarial reviewer. It exposes the interface V. evaluate ( τ, t ) → ( report , score ) : given an execution trace τ and the original task t = ( I, S ) , it produces a structured diagnostic report and a numerical score. The evaluator performs four functions:

1. State verification : Cross-references the worker's observations in τ with ground-truth environment state to confirm the agent actually perceived what it claims, detecting hallucinated or misinterpreted states.
2. Criteria checking : Evaluates the worker's final state against each success criterion s i ∈ S , producing a pass/fail verdict per criterion.
3. Performance auditing : Decomposes total execution time into LLM time (model inference latency) versus tool time (environment interaction latency), identifying whether bottlenecks are computational or behavioral.
4. Scoring : Computes a two-tier metric-first by pass/fail (whether the task was completed successfully), then by execution time as a tiebreaker. This ranking determines whether a code change represents a net improvement or a regression.

## 2.5 EVOLUTION AGENT

The Evolution Agent E is the evolutionary driver of the system. It exposes the interface E. evolve ( history , H ( best ) ) → H ′ : given the full evolution history and the best-performing harness, it produces a modified harness H ′ . It operates as a senior engineer that:

1. Aggregates diagnostics : Reads the full evolution history-including what harness variants were tried, their evaluator reports, scores, and whether each change improved or regressed performance. This historical context prevents the evolution agent from repeating unsuccessful strategies and enables it to build on prior insights.
2. Identifies failure patterns : Classifies failures into recurring categories (e.g., incorrect tool usage, reasoning loops, misinterpreted environment state, excessive latency).
3. Modifies the harness : Based on the diagnosed failure patterns, the evolution agent edits the worker's harness H -every piece of code and configuration that constitutes the agent except the model's parameters-including tool implementations, system prompts, orchestration logic, observation structure, or model configuration to address root causes.

## 3 META-EVOLUTION: LEARNING TO EVOLVE HARNESSES

The Harness Evolution Loop as described optimizes the worker harness H for a single fixed task. But the harness evolution loop itself-the evaluator prompt, the evolution agent's diagnostic strategy, the scoring function, the observation structure, and the orchestration logic-is also a harness, which we denote Λ . Formally:

<!-- formula-not-decoded -->

where W H is the worker agent, H (0) is the initial worker harness, V is the evaluator agent, and E is the evolution agent. Together, these components define how the loop operates. In the current system, Λ is designed by human engineers and remains fixed throughout the evolution process. We now describe a natural generalization: a Meta-Evolution Agent that optimizes Λ itself, so that the inner harness evolution loop converges faster and more reliably to high-performing worker harnesses across diverse tasks.

## 3.1 THE HARNESS EVOLUTION LOOP AS A HARNESS

Observe that Λ has exactly the same structure as any other harness: it consists of prompts (the evaluator and evolution agent instructions), tools (the scoring function, version control operations, code editing capabilities), observations (what telemetry and traces are surfaced from the worker, evaluator, and evolution agent), and orchestration logic (how many iterations to run, when to commit or revert, how tasks are selected and ordered). Optimizing Λ is therefore harness optimization at a higher level of abstraction.

The components of Λ that the Meta-Evolution Agent can modify include:

- Evaluator agent prompt -what failure modes to look for, how to grade, what evidence to require.
- Evolution agent prompt -howto diagnose failure patterns, what code changes to prioritize, how aggressively to modify the worker.
- Worker observation structure -what telemetry, traces, and intermediate state to surface from the worker's execution.
- Evaluator and evolution agent observations -what information flows between agents at each step.
- Scoring function design -the metric structure (e.g., two-tier vs. multi-dimensional), thresholds, and tiebreakers.
- Loop hyperparameters -number of iterations, parallelism, revert thresholds, and stopping criteria.

## 3.2 A META-LEARNING FORMULATION

This two-level optimization maps directly onto the meta-learning framework (Thrun &amp; Pratt, 1998). Let T train = { t 1 , t 2 , . . . , t n } be a set of meta-train tasks , each representing a different agent task from potentially different domains. Let T test be a held-out set of meta-test tasks used to evaluate generalization.

The two loops operate as follows:

- Inner loop (the Harness Evolution): Given a fixed harness evolution blueprint Λ and a single task t i , run the harness evolution loop for K iterations to produce an optimized worker harness H ( K ) . Measure the convergence trajectory: how quickly and how well the worker improves on this task.
- Outer loop (the Meta-Evolution): Across multiple tasks t i ∈ T train, evaluate how effectively the current Λ drives the inner loop. Modify Λ to improve the speed of adaptation -the rate at which the inner loop converges to high performance on any single task.

The objective of the outer loop is to find a harness evolution blueprint Λ ( best ) that maximizes task performance across training tasks:

<!-- formula-not-decoded -->

where HARNESSEVOLUTIONLOOP ( t i , Λ , K ) runs Algorithm 1 for K iterations, returning the bestperforming harness H ( best ) , its score, and the full evolution history. The evolution blueprint Λ is judged solely by the final best score achieved on each task-not by intermediate progress.

This formulation is shown in Algorithm 2, and mirrors meta-learning, with the correspondence shown in Table 1.

Table 1: Correspondence between meta-learning and meta-evolution

| Meta-Learning                                                                                                                                                                                                                  | Meta-Evolution                                                                                                                                                                                                                                                                |
|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Parameters being adapted: θ Adaptation procedure ( θ (0) , optimizer, loss) Inner loop: gradient updates on task t i Outer loop: meta-gradient update Meta-train tasks Meta-test tasks Objective: fast adaptation to new tasks | Harness being evolved: H Evolution blueprint Λ = ( W H , H (0) ,V,E ) Inner loop: HARNESSEVOLUTIONLOOP ( t i , Λ ,K ) Outer loop: E meta . evolve ( meta history , Λ ( best ) ) Training tasks T train Held-out tasks T test Objective: fast harness convergence on new tasks |

## 3.3 EVALUATION PROTOCOL

Generalization is evaluated on T test: given a new, unseen task, how quickly does the inner harness evolution loop-configured with the learned Λ ( best ) -produce a high-performing worker harness? The key metrics are:

- Convergence speed : number of inner-loop iterations to reach a target performance threshold.
- Final performance : task pass rate after a fixed number of iterations.
- Robustness : variance in convergence speed across different meta-test tasks.

A well-optimized Λ ( best ) should enable the harness evolution loop to rapidly adapt to any novel task-producing effective worker harnesses with fewer iterations and less compute than a manually designed harness evolution loop.

## 4 CONCLUSION

We presented the Harness Evolution Loop , a closed-loop architecture that automatically optimizes an AI agent's harness H -the prompts, tools, orchestration logic, and infrastructure that surround a foundation model-through repeated task execution, adversarial evaluation, and code modification. The system formalizes the agent as W H , separates evaluation ( V ) from evolution ( E ), and iteratively improves H while tracking the full convergence history.

We then introduced the Meta-Evolution Loop , which optimizes the evolution blueprint Λ = ( W H , H (0) , V, E ) itself across diverse tasks. By running the inner harness evolution loop on each training task t i ∈ T train and measuring convergence, the meta-evolution agent E meta learns a blueprint Λ ( best ) that enables rapid adaptation to unseen tasks. This two-level formulation mirrors metalearning: the inner loop adapts the harness to a single task, while the outer loop optimizes the adaptation procedure for generalization.

Where harness engineering has traditionally required deep human expertise applied to each specific task domain, the Harness Evolution Loop automates this process entirelytransforming manual harness engineering into automated harness engineering . The Meta-Evolution Loop takes this one step further: it automates the design of the automation itself , learning how to evolve harnesses rather than evolving any single harness.

We plan to follow up with empirical results on diverse workflows that have resisted easy automation even with state-of-the-art agents and harnesses -from complex customized customer workflows to domain-specific enterprise processes-demonstrating that the framework can crack open task categories previously considered too brittle or too specialized for autonomous agents. Ultimately, we will release a product built on the learned evolution blueprint Λ ( best ) : a system where any user can point a general-purpose agent at a new task domain and have it automatically evolve into a specialized, high-performing agent -no harness engineering expertise required.

## REFERENCES

- Anthropic. Claude code: Best practices for agentic coding. https://www.anthropic.com/ engineering/claude-code-best-practices , 2025. Anthropic Engineering Blog.
- Yuyu Guo, Wenjie Yang, Siyuan Yang, Ziyang Liu, Cheng Chen, Yuan Wei, Yun Hu, Yang Huang, Guoliang Hao, Dongsheng Yuan, et al. OpAgent: Operator agent for web navigation. arXiv preprint arXiv:2602.13559 , 2026.
- Ryan Lopopolo. Harness engineering: leveraging Codex in an agent-first world. https: //openai.com/index/harness-engineering/ , 2026. OpenAI Engineering Blog.
- OpenAI. Introducing Codex. https://openai.com/index/introducing-codex/ , 2025. OpenAI Blog.
- Prithvi Rajasekaran. Harness design for long-running application development. https://www. anthropic.com/engineering/harness-design-long-running-apps , 2026. Anthropic Engineering Blog.
- SylphAI. AdaL: The self-evolving AI coding agent. https://sylph.ai/ , 2026.
- Sebastian Thrun and Lorien Pratt. Learning to Learn . Springer Science &amp; Business Media, 1998.
- Vivek Trivedy. The anatomy of an agent harness. https://www.langchain.com/blog/ the-anatomy-of-an-agent-harness , 2026. LangChain Blog.
- Li Yin and Zhangyang Wang. LLM-AutoDiff: Auto-differentiate any LLM workflow, 2025.
- Shuyan Zhou, Frank F Xu, Hao Zhu, Xuhui Zhou, Robert Lo, Abishek Sridhar, Xianyi Cheng, Tianyue Ou, Yonatan Bisk, Daniel Fried, Uri Alon, and Graham Neubig. WebArena: A realistic web environment for building autonomous agents. In International Conference on Learning Representations (ICLR) , 2024.