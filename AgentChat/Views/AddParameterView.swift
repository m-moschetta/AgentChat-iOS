//
//  AddParameterView.swift
//  AgentChat
//
//  Created by Mario Moschetta on 04/07/25.
//

import SwiftUI

struct AddParameterView: View {
    @Environment(\.dismiss) private var dismiss
    
    let onSave: (N8NParameter) -> Void
    
    @State private var name = ""
    @State private var description = ""
    @State private var type: ParameterType = .text
    @State private var placeholder = ""
    @State private var isRequired = false
    @State private var selectOptions: [String] = []
    @State private var newOption = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    private var isFormValid: Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasValidName = !trimmedName.isEmpty
        
        if type == .select {
            return hasValidName && !selectOptions.isEmpty
        }
        
        return hasValidName
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Sezione Informazioni Base
                Section("Informazioni Parametro") {
                    TextField("Nome parametro", text: $name)
                        .autocorrectionDisabled()
                    
                    TextField("Descrizione (opzionale)", text: $description)
                        .lineLimit(4)
                    
                    Picker("Tipo", selection: $type) {
                        ForEach(ParameterType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }

                }
                
                // Sezione Configurazione
                Section("Configurazione") {
                    TextField("Placeholder (opzionale)", text: $placeholder)
                        .autocorrectionDisabled()
                    
                    Toggle("Parametro obbligatorio", isOn: $isRequired)
                }
                
                // Sezione Opzioni Select (solo per tipo select)
                if type == .select {
                    Section {
                        ForEach(selectOptions, id: \.self) { option in
                            HStack {
                                Text(option)
                                Spacer()
                                Button(action: {
                                    selectOptions.removeAll { $0 == option }
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        
                        HStack {
                            TextField("Nuova opzione", text: $newOption)
                            
                            Button(action: addSelectOption) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                            }
                            .disabled(newOption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    } header: {
                        Text("Opzioni di Selezione")
                    } footer: {
                        if selectOptions.isEmpty {
                            Text("Aggiungi almeno un'opzione per il parametro di tipo selezione")
                                .font(.caption)
                        } else {
                            Text("\(selectOptions.count) opzioni configurate")
                                .font(.caption)
                        }
                    }
                }
                
                // Sezione Anteprima
                Section("Anteprima") {
                    ParameterPreviewView(
                        name: name.isEmpty ? "Nome parametro" : name,
                        type: type,
                        placeholder: placeholder,
                        isRequired: isRequired,
                        selectOptions: selectOptions
                    )
                }
            }
            .navigationTitle("Nuovo Parametro")
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button("Annulla") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("Salva") {
                        saveParameter()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
        .alert("Errore", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            updatePlaceholderForType(type)
        }
    }
    
    // MARK: - Private Methods
    
    private func addSelectOption() {
        let trimmedOption = newOption.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedOption.isEmpty else { return }
        
        if selectOptions.contains(trimmedOption) {
            alertMessage = "Questa opzione è già presente nella lista"
            showingAlert = true
            return
        }
        
        selectOptions.append(trimmedOption)
        newOption = ""
    }
    
    private func updatePlaceholderForType(_ parameterType: ParameterType) {
        if placeholder.isEmpty {
            switch parameterType {
            case .text:
                placeholder = "Inserisci testo..."
            case .number:
                placeholder = "Inserisci numero..."
            case .boolean:
                placeholder = "true/false"
            case .select:
                placeholder = "Seleziona un'opzione..."
            case .multiline:
                placeholder = "Inserisci testo multiriga..."
            }
        }
    }
    
    private func saveParameter() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Validazione finale
        guard !trimmedName.isEmpty else {
            alertMessage = "Il nome del parametro è obbligatorio"
            showingAlert = true
            return
        }
        
        if type == .select && selectOptions.isEmpty {
            alertMessage = "Aggiungi almeno un'opzione per il parametro di tipo selezione"
            showingAlert = true
            return
        }
        
        let parameter = N8NParameter(
            id: UUID().uuidString,
            name: trimmedName,
            type: type,
            isRequired: isRequired,
            placeholder: placeholder.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            selectOptions: type == .select ? selectOptions : nil
        )
        
        onSave(parameter)
        dismiss()
    }
}

// MARK: - Parameter Preview View
struct ParameterPreviewView: View {
    let name: String
    let type: ParameterType
    let placeholder: String
    let isRequired: Bool
    let selectOptions: [String]
    
    @State private var previewValue = ""
    @State private var previewBoolValue = false
    @State private var previewSelectValue = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(name)
                    .font(.headline)
                
                if isRequired {
                    Text("*")
                        .foregroundColor(.red)
                        .font(.headline)
                }
                
                Spacer()
                
                Text(type.displayName)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(4)
            }
            
            // Preview del campo input
            switch type {
            case .text:
                TextField(placeholder, text: $previewValue)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(true)
                    
            case .number:
                 TextField(placeholder, text: $previewValue)
                     .textFieldStyle(RoundedBorderTextFieldStyle())
                     .disabled(true)
                    
            case .boolean:
                Toggle(placeholder.isEmpty ? "Attiva/Disattiva" : placeholder, isOn: $previewBoolValue)
                    .disabled(true)
                    
            case .select:
                if !selectOptions.isEmpty {
                    Picker(placeholder, selection: $previewSelectValue) {
                        Text("Seleziona...").tag("")
                        ForEach(selectOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .disabled(true)
                } else {
                    Text("Nessuna opzione configurata")
                        .foregroundColor(.secondary)
                        .italic()
                }
                    
            case .multiline:
                TextField(placeholder, text: $previewValue)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(6)
                    .disabled(true)
            }
            
            Text("Anteprima di come apparirà il parametro nell'interfaccia")
                .font(.caption2)
                .foregroundColor(.secondary)
                .italic()
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Extensions

// MARK: - Preview
#Preview {
    AddParameterView { parameter in
        print("Saved parameter: \(parameter.name)")
    }
}

#Preview("Parameter Preview") {
    ParameterPreviewView(
        name: "Titolo del Post",
        type: .text,
        placeholder: "Inserisci il titolo...",
        isRequired: true,
        selectOptions: []
    )
    .padding()
}