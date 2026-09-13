# Free Models Reference

Complete list of all free models available in YogeeshCode, their sources, limits, and auth requirements.

## Model Discovery

YogeeshCode automatically discovers free models from two sources:

1. **models.dev** — Open-source model database (https://models.dev). Refreshes every 12h.
2. **OpenCode Zen** — OpenCode's built-in provider with 31 free models ( Anthropic, OpenAI, Google, etc. via Zen tier)

Both are queried at runtime and merged into the ranked list.

## Categories

### Tier 1: No Auth Required (Truly Free)

| Provider | Models | Limits | Best For |
|---|---|---|---|
| Pollinations | GPT-4o, Claude, Llama, Mistral, etc. | Fair use (rate-limited but no key) | Default fallback, keyless |

### Tier 2: Free Tier (Auth Required)

All use device OAuth via `yogeeshcode auth login` — no API key needed.

| Provider | Key Source | Best Free Models | Context | Rate Limits |
|---|---|---|---|---|
| **Gemini** (AI Studio) | `aistudio.google.com` | 2.5 Flash, 2.0 Flash, 2.5 Pro | 1M | ~15 RPM, ~1500 req/day |
| **OpenRouter :free** | `openrouter.ai` | Nex N2.5 Pro, Qwen3 Coder, DeepSeek V3/R1, Llama 3.3 70B | 80K-262K | 50 req/day (1000 if $10+ credits) |
| **Groq** | `console.groq.com` | Llama 3.3 70B, QwQ 32B, Llama 3.1 8B | 128K | ~30 RPM, ~14K req/day |
| **Cerebras** | `cloud.cerebras.ai` | Llama 3.1 70B/8B | 8K | ~30 RPM, 1M tokens/day |
| **Mistral** | `console.mistral.ai` | Mistral Small 3.x, Codestral | 32K | ~1 RPS, 500K tokens/min |
| **HuggingFace** | `hf.co/settings/tokens` | Qwen2.5-Coder 32B, Llama 3.1 70B, DeepSeek R1 Distill | 128K | Small monthly credits |
| **Cloudflare** | `dash.cloudflare.com` | Llama 3.3 70B, Qwen, Phi | 128K | 10K neurons/day |
| **Together** | `together.ai` | Llama 3.3 70B Turbo, Qwen2.5 Coder 32B | 128K | Free tier credits |
| **DeepSeek** | `deepseek.com` | V3, R1 | 128K | Free tier |
| **GitHub Models** | GitHub PAT | GPT-4o mini, Llama, Phi, DeepSeek-R1 | varies | By account tier |
| **NVIDIA NIM** | `build.nvidia.com` | Llama 3.1 405B, DeepSeek-R1, Nemotron | varies | ~1000 free credits |
| **Zhipu GLM** | `open.bigmodel.cn` | GLM-4-Flash (100% free), GLM-4.5-Flash | 128K | Free flagship |
| **Cohere** | `dashboard.cohere.com` | Command R/R+ | 128K | 20 RPM, 1000 calls/month |
| **ModelScope** | `modelscope.cn` | Qwen2.5/3 family | 128K | 2000 calls/day |
| **Perplexity** | `perplexity.ai` | Llama 3.1 Sonar Large/Small | 128K | Free tier |

### Tier 3: Local (Unlimited, Your Hardware)

| Tool | Best Models | RAM Needed |
|---|---|---|
| Ollama | Qwen2.5-Coder 14B, Qwen3-Coder 30B, DeepSeek-R1 8B | 8-32GB |
| LM Studio | Same GGUF models | 8-64GB |
| vLLM | Any open model | 16GB+ GPU |

## Default Ranking

```
1. gemini-free/gemini-2.5-flash     (1M ctx, best planner)
2. openrouter-free/nex-n2.5-pro:free (262K, agentic)
3. openrouter-free/nex-n2.5-mini:free (262K, fast)
4. openrouter-free/qwen3-coder:free  (128K, coder)
5. openrouter-free/deepseek-chat:free (128K, executor)
6. openrouter-free/llama-3.3-70b:free (80K, general)
7. groq-free/llama-3.3-70b-versatile (fast)
8. groq-free/qwen-qwq-32b           (reasoning)
9. groq-free/llama-3.1-70b-versatile
10. groq-free/llama-3.1-8b-instant  (fastest)
11. deepseek-direct/deepseek-chat
12. deepseek-direct/deepseek-reasoner
13. mistral-direct/mixtral-8x7b-instruct
14. mistral-direct/mistral-7b-instruct
15. huggingface/Qwen2.5-Coder-32B-Instruct
16. huggingface/DeepSeek-R1-Distill-Llama-70B
17. huggingface/Llama-3.1-70B-Instruct
18. huggingface/Qwen2.5-72B-Instruct
19. together/Llama-3.3-70B-Instruct-Turbo
20. together/Qwen2.5-Coder-32B-Instruct
21. together/DeepSeek-R1-Distill-Llama-70B
22-30. [more openrouter-free models]
31-40. [cloudflare, cerebras, perplexity, github, nvidia, zhipu, cohere, modelscope]
41-50. [ollama local models]
```

## Adding a New Provider

1. Add to `yogeeshcode.json.example` under `provider`
2. Add model ID to `yogeeshcode.model_ranker.order`
3. Add to `model-fallthrough.ts` DEFAULT_RANKED_FREE_MODELS if needed
4. Test: `script/yogeesh-test.sh`
5. Release: `script/release.sh --publish`

## Removing a Provider

1. Remove from `yogeeshcode.json.example`
2. Remove from `model_ranker.order`
3. Test + release
