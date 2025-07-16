# Build Configuration Notes

## Important Build Settings

**SEMPRE COMPILARE PER iPhone 16**

Quando si compila il progetto AgentChat, utilizzare sempre:
- Target: iPhone 16
- Comando: `xcodebuild -project AgentChat.xcodeproj -scheme AgentChat -destination 'platform=iOS Simulator,name=iPhone 16' build`

## Note di Sviluppo

- Questo progetto è ottimizzato per iPhone 16
- Utilizzare sempre iPhone 16 come dispositivo di destinazione per i test
- Le configurazioni di build sono specifiche per iPhone 16

## Ultimo Aggiornamento

Data: $(date)
Note: Configurazione build standardizzata per iPhone 16