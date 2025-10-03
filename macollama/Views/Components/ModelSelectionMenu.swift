import SwiftUI

struct ModelSelectionMenu: View {
    @Binding var selectedModel: String?
    @Binding var selectedProvider: LLMProvider
    @Binding var models: [String]
    @Binding var isLoadingModels: Bool
    let onProviderChange: () async -> Void
    let onModelRefresh: () async -> Void
    let onCopyAllMessages: () -> Void
    
    @State private var availableProviders: [LLMProvider] = []
    
    private func updateAvailableProviders() {
        availableProviders = LLMProvider.allCases.filter { provider in
            switch provider {
            case .ollama:
                return UserDefaults.standard.bool(forKey: "showOllama")
            case .lmstudio:
                return UserDefaults.standard.bool(forKey: "showLMStudio")
            case .claude:
                return UserDefaults.standard.bool(forKey: "showClaude")
            case .openai:
                return UserDefaults.standard.bool(forKey: "showOpenAI")
            }
        }
        
        
        if !availableProviders.contains(selectedProvider),
           let firstProvider = availableProviders.first {
            selectedProvider = firstProvider
            LLMService.shared.refreshForProviderChange()
            Task {
                await onProviderChange()
            }
        }
    }
    
    var body: some View {
        HStack {
            if availableProviders.count > 1 {
                Menu {
                    ForEach(availableProviders, id: \.self) { provider in
                        Button(action: {
                            selectedProvider = provider
                            LLMService.shared.refreshForProviderChange()
                            Task { await onProviderChange() }
                        }) {
                            HStack {
                                Text(provider.displayName)
                                if selectedProvider == provider {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Text("Provider: \(selectedProvider.displayName)")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .fixedSize(horizontal: true, vertical: false)
                }
                .frame(minWidth: 240, alignment: .leading)
                .menuStyle(.borderedButton)
            } else {
                // Single provider configured; show label and name without dropdown
                HStack(spacing: 6) {
                    Text("Provider:")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .layoutPriority(1)
                    Text(selectedProvider.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .layoutPriority(2)
                        .fixedSize(horizontal: true, vertical: false)
                }
                .frame(minWidth: 220, maxWidth: 400, alignment: .leading)
            }
            
            Menu {
                ForEach(models, id: \.self) { model in
                    Button(action: {
                        selectedModel = model
                    }) {
                        Text(model)
                    }
                }
                Divider()
                Button(action: { Task { await onModelRefresh() } }) {
                    HStack {
                        if isLoadingModels {
                            ProgressView()
                                .scaleEffect(0.7)
                        }
                        Label("l_refresh".localized, systemImage: "arrow.clockwise")
                    }
                }
                .disabled(isLoadingModels)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "cpu")
                        .symbolRenderingMode(.hierarchical)
                    if isLoadingModels {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("l_loading".localized)
                    } else {
                        Text(selectedModel ?? "l_select_model".localized)
                    }
                }
            }
            .frame(width: 300)
            .disabled(isLoadingModels)

            Spacer()
            HoverImageButton(
                imageName: "document.on.document"
            ) {
                onCopyAllMessages()
            }
        }
        .onAppear {
            updateAvailableProviders()
        }
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
            updateAvailableProviders()
        }
    }
} 
