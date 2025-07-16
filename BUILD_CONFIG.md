# Configurazione Build - AgentChat

## Destinazione Predefinita
**IMPORTANTE**: Compilare sempre per iPhone 16 come destinazione predefinita.

### Comando di Build Raccomandato
```bash
xcodebuild -project AgentChat.xcodeproj -scheme AgentChat -destination 'platform=iOS Simulator,name=iPhone 16' build
```

### Note
- Utilizzare sempre iPhone 16 come simulatore di riferimento
- Questo garantisce compatibilità con le versioni più recenti di iOS
- Il simulatore iPhone 16 offre le migliori prestazioni per i test

### Ultima Modifica
Data: $(date)
Motivo: Promemoria per utilizzare sempre iPhone 16 come destinazione di build