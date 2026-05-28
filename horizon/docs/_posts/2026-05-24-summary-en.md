---
layout: default
title: "Horizon Summary: 2026-05-24 (EN)"
date: 2026-05-24
lang: en
---

> From 11 items, 7 important content pieces were selected

---

1. [Inaudible Audio Commands Hijack AI Voice Assistants](#item-1) ⭐️ 8.0/10
2. [PapersWithCode Revival Adds Multi-Metric Leaderboards](#item-2) ⭐️ 7.0/10
3. [DeepSeek Reasonix: Native Coding Agent with High Caching](#item-3) ⭐️ 6.0/10
4. [Mastering Dyalog APL Now Available as Jupyter Notebooks](#item-4) ⭐️ 6.0/10
5. [Qwen3.6-35B-A3B vs Gemma4-26B-A4B: Community Comparison](#item-5) ⭐️ 6.0/10
6. [Nostalgic Tales of First Computing Experiences](#item-6) ⭐️ 5.0/10
7. [Data Scientists Must Embrace APIs and Documentation](#item-7) ⭐️ 4.0/10

---

<a id="item-1"></a>
## [Inaudible Audio Commands Hijack AI Voice Assistants](https://cybernews.com/security/ai-voice-bots-hidden-audio-hijack-attacks/) ⭐️ 8.0/10

Researchers have discovered a new class of 'auditory prompt injection' attacks where inaudible audio commands can be hidden in YouTube videos, podcasts, or music to secretly trigger AI voice assistants into executing unauthorized actions without the user's knowledge. This attack vector poses a significant security risk to widely-used AI voice assistants like Siri, Alexa, and Google Assistant, potentially allowing attackers to control smart home devices, make purchases, or leak personal data without user consent. The attack exploits the fact that voice assistants process audio frequencies beyond human hearing, and uses audio compression codecs that may preserve these inaudible signals. The researchers demonstrated that commands can survive compression and playback through standard speakers and microphones.

reddit · r/singularity · Distinct-Question-16 · May 24, 12:44 · [Discussion](https://www.reddit.com/r/singularity/comments/1tmb7mz/inaudible_sounds_to_humans_can_be_hidden_in/)

**Background**: Prompt injection attacks are a known security threat to large language models (LLMs), where attackers craft inputs to manipulate model outputs. Previous research has shown that voice assistants can be triggered by inaudible commands using ultrasonic frequencies. This new 'auditory prompt injection' combines both concepts, hiding malicious prompts in audio media that are imperceptible to humans but executable by AI systems.

<details><summary>References</summary>
<ul>
<li><a href="https://www.schneier.com/blog/archives/2018/05/sending_inaudib.html">Sending Inaudible Commands to Voice Assistants - Schneier on</a></li>
<li><a href="https://www.schneier.com/blog/archives/2017/09/hacking_voice_a.html">Hacking Voice Assistant Systems with Inaudible Voice Commands -</a></li>

</ul>
</details>

**Discussion**: Community comments express skepticism about the feasibility of the attack, citing limitations of microphone frequency response, speaker capabilities, and audio compression codecs that typically remove imperceptible data. Some suggest that the problem could be solved by training neural networks to detect and ignore inaudible frequencies.

**Tags**: `#AI security`, `#voice assistants`, `#adversarial attacks`, `#prompt injection`, `#audio processing`

---

<a id="item-2"></a>
## [PapersWithCode Revival Adds Multi-Metric Leaderboards](https://www.reddit.com/r/MachineLearning/comments/1tmawv5/paperswithcode_new_features_week_1_p/) ⭐️ 7.0/10

NielsRogge from Hugging Face announced new features for the revived PapersWithCode platform, including support for multiple metrics per benchmark (e.g., WER and RTFx for ASR, mAP and FPS for object detection) and the ability to submit papers from sources beyond Arxiv. This revival restores a widely-used platform for tracking state-of-the-art AI research, and the new features address long-standing community requests for richer leaderboards and broader paper submission options, potentially increasing reproducibility and discoverability. The platform now supports lineage tracking, which documents the successor relationships between papers, and allows submissions from GitHub, blog posts, BiorXiv, etc., with AI auto-enrichment for tasks, methods, and evaluations.

reddit · r/MachineLearning · NielsRogge · May 24, 12:31

**Background**: PapersWithCode was originally a popular platform that connected research papers with their code implementations and tracked state-of-the-art results on benchmarks. After being acquired and then neglected, Hugging Face's open-source team revived it as paperswithcode.co. Multi-metric leaderboards allow comparing models on multiple performance dimensions, while lineage tracking helps researchers understand the evolution of methods.

<details><summary>References</summary>
<ul>
<li><a href="https://aitoptools.com/tool/papers-with-code/">Papers with Code Reviews 2026: Details, Pricing, & Features</a></li>
<li><a href="https://mlops-coding-course.fmind.dev/7.+Observability/7.3.+Lineage.html">7.3. Lineage - MLOps Coding Course</a></li>
<li><a href="https://labs.scale.com/leaderboard">AI Model Leaderboards & Benchmarks | Scale Labs</a></li>

</ul>
</details>

**Discussion**: The community response is overwhelmingly positive, with users praising the work and requesting features like a paper claiming mechanism for editing metadata, and expressing that lineage tracking is more useful than leaderboards for decision-making. Some users also suggested sharing the backend database as a dataset and asked about the advantages over Hugging Face's daily papers section.

**Tags**: `#AI`, `#Open Source`, `#Leaderboards`, `#PapersWithCode`, `#Hugging Face`

---

<a id="item-3"></a>
## [DeepSeek Reasonix: Native Coding Agent with High Caching](https://esengine.github.io/DeepSeek-Reasonix/) ⭐️ 6.0/10

DeepSeek Reasonix is an open-source, DeepSeek-native AI coding agent that runs in the terminal, designed to leverage DeepSeek's prefix-caching to reduce latency and API costs for coding tasks. By optimizing caching for long coding sessions, Reasonix can significantly lower token costs and improve response times, making AI-assisted coding more affordable and efficient for developers. The agent features a cache-first loop, flash-first cost control, and automatic tool-call repair, and it communicates directly with DeepSeek's API without a translation shim.

hackernews · Alifatisk · May 24, 13:02 · [Discussion](https://news.ycombinator.com/item?id=48256953)

**Background**: LLM-based coding agents often incur high costs and latency due to repeated token processing. DeepSeek's prefix-caching mechanism stores previously computed key-value cache entries, so repeated prefixes are served from cache, reducing both cost and latency. Reasonix is built specifically to maximize this caching benefit for coding workflows.

<details><summary>References</summary>
<ul>
<li><a href="https://api-docs.deepseek.com/quick_start/agent_integrations/reasonix">Integrate with Reasonix | DeepSeek API Docs</a></li>
<li><a href="https://esengine.github.io/DeepSeek-Reasonix/">Reasonix — DeepSeek-native AI coding agent for your terminal</a></li>

</ul>
</details>

**Discussion**: Community comments are mixed: some users question the necessity of a dedicated agent for caching, noting that a simple bridge can achieve similar cache hit rates. Others criticize the website's UX, while a few express interest in the caching strategy's handling of context invalidation across files.

**Tags**: `#AI coding agent`, `#DeepSeek`, `#caching`, `#cost optimization`, `#LLM`

---

<a id="item-4"></a>
## [Mastering Dyalog APL Now Available as Jupyter Notebooks](https://mastering.dyalog.com/README.html) ⭐️ 6.0/10

The free interactive book 'Mastering Dyalog APL' by Bernard Legrand has been released as Jupyter Notebooks, allowing readers to run and modify APL code interactively. This makes learning APL more accessible and hands-on, as Jupyter Notebooks provide an interactive environment that helps build muscle memory with APL's unique symbols. The original book was already a well-regarded introduction to APL, and the Jupyter Notebook format enhances the learning experience with live code execution.

hackernews · tosh · May 24, 11:42 · [Discussion](https://news.ycombinator.com/item?id=48256475)

**Background**: APL is a programming language from the 1960s centered on multidimensional arrays, known for its concise code using special symbols. Dyalog APL is a modern, proprietary implementation under an enterprise license. Jupyter Notebooks are web-based interactive computing platforms that combine code, text, and visualizations.

<details><summary>References</summary>
<ul>
<li><a href="https://en.wikipedia.org/wiki/Dyalog_APL">Dyalog APL</a></li>
<li><a href="https://www.dyalog.com/mastering-dyalog-apl.htm">Mastering Dyalog APL by Bernard Legrand - Dyalog</a></li>
<li><a href="https://jupyter.org/">Project Jupyter | Home</a></li>

</ul>
</details>

**Discussion**: Commenters noted the irony of a niche language like APL having a proprietary enterprise implementation, but appreciated the interactive Jupyter format for learning. Some shared alternative resources and personal experiences translating APL to NumPy or writing Emacs modes for Dyalog APL.

**Tags**: `#APL`, `#programming language`, `#tutorial`, `#Jupyter`

---

<a id="item-5"></a>
## [Qwen3.6-35B-A3B vs Gemma4-26B-A4B: Community Comparison](https://www.reddit.com/r/LocalLLaMA/comments/1tmbola/qwen3635ba3b_vs_gemma426ba4b/) ⭐️ 6.0/10

A Reddit discussion compares the Qwen3.6-35B-A3B and Gemma4-26B-A4B models, with users reporting that Gemma runs faster locally but Qwen excels in tool calls and general tasks. This comparison helps local LLM users choose between two competitive small MoE models, highlighting trade-offs in speed, tool use, and task specialization. Both models use Mixture-of-Experts (MoE) architecture: Qwen3.6-35B-A3B has 35B total parameters with 3B active, while Gemma4-26B-A4B has 26B total with 4B active. Users noted Gemma runs faster on a Radeon 9070 XT with llama.cpp.

reddit · r/LocalLLaMA · MarcCDB · May 24, 13:05

**Background**: Mixture-of-Experts (MoE) models activate only a subset of parameters per token, enabling larger total capacity with lower computational cost. Qwen3.6 is Alibaba's multimodal hybrid-thinking model, while Gemma4 is Google's multimodal model supporting text, image, and audio input.

<details><summary>References</summary>
<ul>
<li><a href="https://medium.com/data-science-in-your-pocket/qwen3-6-35b-a3b-the-tiny-active-open-model-that-thinks-codes-and-agents-like-a-much-bigger-one-486d535e372e">Qwen 3 . 6 – 35 B - A 3 B : The Tiny-Active Open Model That... | Medium</a></li>
<li><a href="https://lmstudio.ai/models/google/gemma-4-26b-a4b">google/gemma-4-26b-a4b • LM Studio</a></li>
<li><a href="https://github.com/QwenLM/Qwen3.6">GitHub - QwenLM/ Qwen 3 . 6 : Qwen 3 . 6 is the large language model ...</a></li>

</ul>
</details>

**Discussion**: Users generally agree that Qwen is better for tool calls and general tasks, while Gemma excels in role-playing (RP) and linguistics. One user humorously summarized: 'Love with your Gemma, use your Qwen for everything else.'

**Tags**: `#LLM`, `#model comparison`, `#local LLM`, `#MoE`

---

<a id="item-6"></a>
## [Nostalgic Tales of First Computing Experiences](https://susam.net/childhood-computing.html) ⭐️ 5.0/10

A collection of personal anecdotes from individuals about their first computing experiences, spanning from teletypes in the 1970s to Windows 95 and RPG Maker, has been shared online. These stories highlight the rapid evolution of personal computing and evoke nostalgia, reminding us how far technology has come and how early experiences shaped many careers. The anecdotes include using a teletype with a 300 baud acoustic modem in 1978, a 166 MHz Pentium with Windows 95 costing $3500-4000 in 1995, and a child understanding variables through RPG Maker.

hackernews · blenderob · May 24, 12:07 · [Discussion](https://news.ycombinator.com/item?id=48256597)

**Background**: Teletypes were electromechanical devices used as computer terminals in the 1960s-1970s, printing output on paper. RPG Maker is a series of software that allows users to create role-playing games without programming knowledge, first released for Windows in 1995 as RPG Maker 95.

<details><summary>References</summary>
<ul>
<li><a href="https://en.wikipedia.org/wiki/Teletype_Model_33">Teletype Model 33 - Wikipedia</a></li>
<li><a href="https://en.wikipedia.org/wiki/RPG_Maker">RPG Maker - Wikipedia</a></li>

</ul>
</details>

**Discussion**: Commenters shared nostalgic memories, with one noting the simplicity of early graphics programming where drawn elements persisted on screen, contrasting with modern libraries that require redrawing each frame.

**Tags**: `#nostalgia`, `#computing history`, `#personal stories`

---

<a id="item-7"></a>
## [Data Scientists Must Embrace APIs and Documentation](https://towardsdatascience.com/beyond-the-model-why-data-scientists-must-embrace-apis-and-api-documentation/) ⭐️ 4.0/10

A recent opinion article argues that data scientists need to learn APIs and API documentation to effectively deploy machine learning models into production. This highlights a growing need for data scientists to bridge the gap between model development and deployment, ensuring their work delivers real-world impact. The article is a generic opinion piece with minimal technical depth, scoring only 4.0/10 on relevance and novelty.

rss · Towards Data Science · May 24, 13:00

**Background**: APIs (Application Programming Interfaces) allow different software systems to communicate. For data scientists, APIs are essential for serving model predictions to applications. Good API documentation helps other developers use the model effectively.

**Tags**: `#API`, `#data science`, `#software engineering`

---