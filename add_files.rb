require 'xcodeproj'

project_path = '/Users/mariomoschetta/Documents/AgentChat/AgentChat.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Trova il target principale
target = project.targets.first

# Aggiungi i file di modello al target
['Chat.swift', 'Message.swift', 'AgentType.swift'].each do |file_name|
  file_path = "AgentChat/Models/#{file_name}"
  file_ref = project.main_group.new_file(file_path)
  target.add_file_references([file_ref])
end

# Aggiungi i file di servizio al target
['ChatService.swift', 'OpenAIService.swift', 'AnthropicService.swift', 'MistralService.swift', 'PerplexityService.swift', 'CustomProviderService.swift'].each do |file_name|
  file_path = "AgentChat/Services/#{file_name}"
  file_ref = project.main_group.new_file(file_path)
  target.add_file_references([file_ref])
end

project.save
puts "Files added successfully to the project!"