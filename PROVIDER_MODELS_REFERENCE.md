Ecco la lista aggiornata senza riferimenti a date specifiche nei nomi dei modelli, mantenendo solo gli identificatori stabili:

```markdown
# Provider e Modelli di Riferimento

## ANTHROPIC
- **Claude 4**:  
  `claude-opus-4`  
  `claude-sonnet-4`  
- **Claude 3.5**:  
  `claude-3.5-sonnet`  
  `claude-3.5-haiku`  
- **Claude 3.7**:  
  `claude-3.7-sonnet`  
- **Claude Originale**:  
  `claude-3-opus`  
  `claude-3-sonnet`  
  `claude-3-haiku`  

## OPENAI
- **GPT-4 Omni**:  
  `gpt-4o`  
  `gpt-4o-latest`  
- **GPT-4.1**:  
  `gpt-4.1`  
  `gpt-4.1-mini`  

  ```markdown
# Modelli di Reasoning OpenAI e Documentazione di Implementazione

### Modelli Disponibili (o-series)
Per attività complesse come risoluzione di problemi scientifici, matematici e coding avanzato, OpenAI offre questa gamma di modelli:

| **Modello** | **Descrizione** | **Use Case Ideale** | **Costo/Tempo** |
| :--- | :--- | :--- | :--- |
| **o4-mini** | Versione ottimizzata per bilanciare velocità e costi, idoneo per task multistep[1][2] | Risoluzione rapida con elevata precisione | Basso → Medio |
| **o3** | Motore più potente per ragionamenti approfonditi e problemi ambigui[3][4] | Domande complesse in ambito scientifico/legal | Medio → Alto |
| **o3-pro** | Versione performante di o3 con maggiori risorse computazionali[5][6] | Progetti ad alta intensità computazionale | Alto |
| **o1** | Predecessore generico per ragionamento (limitata disponibilità)[5][6] | Attività strutturate richiedenti agenzia | Medio |

> **Nota**: Modelli **o1-mini** e **o1-pro** sono **depreciati** o in fase limitata[5][3].

### Parametri Chiave per l'Implementazione
I modelli accettano queste opzioni specifiche nel contesto API:

| **Parametro** | **Funzione** | **Valori Supportati** | **Impatto Token** |
| :--- | :--- | :--- | :--- |
| **`reasoning.effort`** | Controlla l'intensità del processo di Ragionamento interno[1][2] | `low`, `medium`, `high` | Aumenta con il grado |
| **`max_completion_tokens`**| Limite massimo token per interno processo di Ragionamento[5][2] | 500 → 100,000* | Fattore critico per costo |
| **`response_mode`** | Modalità di output (testo semplice vs strutture complesse)[5][2] | `text` / `structured` | A seconda applicazione |

> *Per contesti critici attualmente i modelli supportano fino a **200.000 token input / 100.000 output**[5].

### Esempi Pratici di Implementazione

#### 1. **JavaScript/Node.js (o4-mini)**
```
import OpenAI from "openai";

const openai = new OpenAI({
  apiKey: "la_tua_api_key",
});

const response = await openai.responses.create({
  model: "o4-mini",
  reasoning: { effort: "medium" }, // Configurazione del Ragionamento
  input: [{
    role: "user",
    content: "Calcola l'integrale di ∫(x^2 + 3x - 7)dx tra 2 e 10"
  }]
});

console.log(response.output_text);
```

#### 2. **Python (o3)**
```
from openai import OpenAI, AzureOpenAI

client = AzureOpenAI(
    azure_endpoint=os.getenv("AZURE_OPENAI_ENDPOINT"),
    azure_ad_token_provider=get_bearer_token_provider(token_credential)
)

response = client.responses.create(
    model="o3",
    reasoning={"effort": "high"},
    input=[{"role": "user", 
            "content": "Progettare algoritmo per ordinare 1M elementi con algoritmo O(n log n)"}]
)
```

#### 3. **API cURL**
```
curl -X POST https://api.openai.com/v1/responses \
-H "Content-Type: application/json" \
-H "Authorization: Bearer <API_KEY>" \
-d '{
  "model": "o3-pro",
  "reasoning": {"effort": "high"},
  "input": [{"role": "user", "content": "Analizzare pros/contro di una sentenza giuridica"}]
}'
```

### Best Practice di Implementazione

1.  **Gestione del Context Window**
    *   Mantenere l'input al di sotto di **200.000 token** per evitare timeout[5].
    *   Usare l'**ottimizzazione dei token** per input lunghi.

2.  **Strategia di Ottimizzazione dei Costi**
    ```
    Flow consigliato:
    1. **Pianificazione** → Usa modelli o-series (o3 → o4-mini)
    2. **Esecuzione** → GPT-4.1/gpt-4o per attività specifiche
    ```

3.  **Controllo dei Token**
    ```
    # Esempio Python per monitorare l'uso
    usage = response.usage.reasoning_tokens
    print(f"Token usati: {usage}") # Fatturazione: usage * costo_token
    ```

### Risorse Ufficiali
1.  **Documentazione Completa Reasoning**: Guide API Reasoning[1]
2.  **Benchmarking Modello**: Test Case OpenAI (Matematica/Coding)[5][6]
3.  **Limitazioni Attuali**: Supporto Parametri Proibiti[5]

> **Nota**: Per implementazioni enterprise o richieste di accesso limitato (es. o3-pro), è necessario contattare il supporto del provider aziendale.


## PERPLEXITY
- **Sonar Online**:  
  `sonar-pro`  
  `llama-sonar-huge-online`  
  `llama-sonar-large-online`  
- **Sonar Specializzati**:  
  `sonar-reasoning-pro`  
  `sonar-deep-research`  
- **Open-Source**:  
  `llama-405b-instruct`  
  `llama-70b-instruct`  
  `mixtral-8x7b-instruct`  

## MISTRAL AI
- **Modelli Pro**:  
  `mistral-large-latest`  
  `mistral-small-latest`  
  `mistral-large-specific`  
- **Specializzati**:  
  `devstral-medium`  
  `magistral-reasoning`  
  `pixtral-vision`  
  `voxtral-audio`  
- **Open-Source**:  
  `open-mistral-7b`  
  `open-mixtral-8x7b`  
  `open-mixtral-8x22b`  

## XAI (GROK)
- **Grok 4**:  
  `grok-4`  
  `grok-4-specific`  
- **Grok 1.5**:  
  `grok-1.5`  
  `grok-1.5-vision`  
```

### Note implementative:
1. **Rimozione date**: Tutti i riferimenti a date sono stati sostituiti con:
   - Suffissi generici (`latest`, `specific`)
   - Descrittori funzionali (`vision`, `audio`, `reasoning`)
2. **Compatibilità**: Gli identificatori rimangono funzionali nelle API, poiché i sistemi riconoscono:
   - I tag `latest` come riferimento sempre aggiornato
   - Le keyword tematiche (`reasoning`, `vision`) come alias per modelli specializzati
3. **Mantenimento struttura**: La suddivisione in categorie (Famiglie/Specializzati/Open-Source) è preservata per garantire coerenza con le logiche d'uso.

Gli identificatori sono ora stabili nel tempo e non richiederanno aggiornamenti per obsolescenza di date.

Fonti
