//
//  ContentView.swift
//  macollama
//
//  Created by BillyPark on 1/29/25.
//

import SwiftUI

struct ContentView: View {
    @State private var columnVisibility = NavigationSplitViewVisibility.automatic
    @State private var showingSettings = false
    @State private var models: [String] = []
    @State private var isLoadingModels = false
    @AppStorage("selectedModel") private var selectedModel: String?
    @AppStorage("selectedProvider") private var selectedProvider: LLMProvider = .ollama
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var showCopyAlert = false
    
    private let chatViewModel = ChatViewModel.shared
    
    
    private var toolbarContent: some View {
        HStack {
            HoverImageButton(imageName: "plus") {
                chatViewModel.startNewChat()
            }
            HoverImageButton(imageName: "gearshape") {
                showingSettings = true
            }
        }
    }
    
    var body: some View {
        HSplitView {
            SidebarView()
                .toolbar {
                    ToolbarItem(placement: .automatic) {
                        toolbarContent
                    }
                }
                .frame(minWidth: 260, maxWidth: 400)
                
            MainChatView(
                selectedModel: $selectedModel,
                selectedProvider: $selectedProvider,
                models: $models,
                isLoadingModels: $isLoadingModels,
                onProviderChange: { await loadModels() },
                onModelRefresh: { await loadModels() },
                onCopyAllMessages: { copyAllMessages() }
            )
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(
                isPresented: $showingSettings,
                onReloadModels: { await loadModels() }
            )
        }
        .task {
            await loadModels()
        }
        .alert("l_model_load_fail".localized, isPresented: $showingError) {
            Button("l_settings".localized) {
                showingSettings = true
            }
            Button("l_retry".localized) {
                Task {
                    await loadModels()
                }
            }
        } message: {
            Text("l_set_url".localized)
        }
        .overlay {
            if showCopyAlert {
                GeometryReader { geometry in
                    CenterAlertView(message: "l_copied".localized)
                        .position(
                            x: geometry.size.width / 2,
                            y: geometry.size.height / 2
                        )
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showCopyAlert)
        .background(Color(NSColor.windowBackgroundColor))
        .onReceive(chatViewModel.$chatProvider) { provider in
            selectedProvider = provider
        }
        .onReceive(chatViewModel.$chatModel) { model in
            if let model = model {
                selectedModel = model
            }
        }
        .onChange(of: selectedProvider) {
            // Update ChatViewModel when user changes provider in UI
            chatViewModel.updateProviderAndModel(selectedProvider, selectedModel)
            // Save to database if this is an existing chat
            if chatViewModel.chatId != UUID() {
                chatViewModel.saveProviderAndModel()
            }
        }
        .onChange(of: selectedModel) {
            // Update ChatViewModel when user changes model in UI
            chatViewModel.updateProviderAndModel(selectedProvider, selectedModel)
            // Save to database if this is an existing chat
            if chatViewModel.chatId != UUID() {
                chatViewModel.saveProviderAndModel()
            }
        }
    }
    
    @MainActor
    func loadModels() async {
        isLoadingModels = true
        
        models = []
        selectedModel = nil
        UserDefaults.standard.removeObject(forKey: "selectedModel")
        
        // Check if current provider is available
        if !LLMProvider.availableProviders.contains(selectedProvider) {
            selectedProvider = LLMProvider.availableProviders.first ?? .ollama
        }
        
        do {
            let newModels = try await LLMService.shared.listModels()
            models = newModels
            
            if newModels.isEmpty {
                selectedModel = nil
            } else if selectedModel == nil || !newModels.contains(selectedModel!) {
                selectedModel = newModels.first
            }
        } catch {
            DispatchQueue.main.async {
                self.models = []
                self.selectedModel = nil
                UserDefaults.standard.removeObject(forKey: "selectedModel")
            }
            showError("l_error2".localized)
        }
        
        isLoadingModels = false
    }
    
    @MainActor
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
    
    private func copyAllMessages() {
        let messages = chatViewModel.messages
        var content = ""
        
        for i in stride(from: 0, to: messages.count, by: 2) {
            if i + 1 < messages.count {
                content += """
                [Q]:
                \(messages[i].content)
                
                [A]:
                \(messages[i + 1].content)
                
                ----------------
                
                """
            }
        }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(content, forType: .string)
        
        withAnimation {
            showCopyAlert = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showCopyAlert = false
            }
        }
    }
}

