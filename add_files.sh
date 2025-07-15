#!/bin/bash

XCODEPROJ_PATH="/Users/mariomoschetta/Documents/AgentChat/AgentChat.xcodeproj"

# Aggiungi i nuovi modelli
xcodeproj-add-files --project "$XCODEPROJ_PATH" --group "AgentChat/Models" "AgentChat/Models/Chat.swift" "AgentChat/Models/Message.swift" "AgentChat/Models/AgentType.swift"

# Aggiungi i nuovi servizi
xcodeproj-add-files --project "$XCODEPROJ_PATH" --group "AgentChat/Services" "AgentChat/Services/ChatService.swift" "AgentChat/Services/OpenAIService.swift" "AgentChat/Services/AnthropicService.swift" "AgentChat/Services/MistralService.swift" "AgentChat/Services/PerplexityService.swift" "AgentChat/Services/CustomProviderService.swift"