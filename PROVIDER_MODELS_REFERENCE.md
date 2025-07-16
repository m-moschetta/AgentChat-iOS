# Provider e Modelli di Riferimento

**IMPORTANTE: Utilizzare SEMPRE questi modelli - sono i più recenti e aggiornati. NON modificare mai questi riferimenti.**

## OpenAI

### Modelli Chat
- `gpt-4o` - Modello più avanzato (multimodale)
- `gpt-4o-mini` - Versione più veloce ed economica
- `gpt-4-turbo` - Modello turbo precedente
- `gpt-4` - Modello base GPT-4
- `gpt-3.5-turbo` - Modello legacy

### Modelli Embedding
- `text-embedding-3-large` - Embedding più potente
- `text-embedding-3-small` - Embedding più veloce
- `text-embedding-ada-002` - Modello legacy

## Anthropic (Claude)

### Modelli Disponibili
- `claude-3-5-sonnet-20241022` - Ultimo modello Sonnet (più recente)
- `claude-3-5-sonnet-20240620` - Sonnet precedente
- `claude-3-opus-20240229` - Modello più potente
- `claude-3-sonnet-20240229` - Bilanciato
- `claude-3-haiku-20240307` - Più veloce

## Perplexity

### Modelli Disponibili
- `llama-3.1-sonar-large-128k-online` - Modello più potente con ricerca web
- `llama-3.1-sonar-small-128k-online` - Modello veloce con ricerca web
- `llama-3.1-sonar-large-128k-chat` - Solo chat, senza web
- `llama-3.1-sonar-small-128k-chat` - Chat veloce
- `llama-3.1-8b-instruct` - Modello base
- `llama-3.1-70b-instruct` - Modello più grande

## Mistral AI

### Modelli Disponibili
- `mistral-large-latest` - Modello più potente
- `mistral-medium-latest` - Bilanciato
- `mistral-small-latest` - Più veloce
- `open-mistral-7b` - Open source
- `open-mixtral-8x7b` - Mixture of Experts
- `open-mixtral-8x22b` - Versione più grande

## Grok (xAI)

### Modelli Disponibili
- `grok-beta` - Modello principale
- `grok-vision-beta` - Con capacità visive

## Configurazioni Consigliate

### Per Uso Generale
- **OpenAI**: `gpt-4o-mini` (veloce ed economico)
- **Anthropic**: `claude-3-5-sonnet-20241022` (più recente)
- **Perplexity**: `llama-3.1-sonar-large-128k-online` (con ricerca web)

### Per Compiti Complessi
- **OpenAI**: `gpt-4o` (multimodale)
- **Anthropic**: `claude-3-opus-20240229` (più potente)
- **Mistral**: `mistral-large-latest`

### Per Velocità
- **OpenAI**: `gpt-3.5-turbo`
- **Anthropic**: `claude-3-haiku-20240307`
- **Perplexity**: `llama-3.1-sonar-small-128k-online`

## Note Implementative

1. **Sempre verificare la disponibilità** dei modelli tramite le API dei provider
2. **Gestire i rate limits** appropriatamente per ogni provider
3. **Implementare fallback** su modelli alternativi in caso di errori
4. **Monitorare i costi** soprattutto per i modelli più potenti
5. **Aggiornare regolarmente** questo file quando escono nuovi modelli

## Endpoint API

- **OpenAI**: `https://api.openai.com/v1/chat/completions`
- **Anthropic**: `https://api.anthropic.com/v1/messages`
- **Perplexity**: `https://api.perplexity.ai/chat/completions`
- **Mistral**: `https://api.mistral.ai/v1/chat/completions`
- **Grok**: `https://api.x.ai/v1/chat/completions`

---

**Data ultimo aggiornamento**: Dicembre 2024
**Fonte**: Documentazione ufficiale dei provider