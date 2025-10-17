//
//  MainChatView.swift
//  macollama
//
//  Created by Assistant on 1/30/25.
//

import SwiftUI
import MarkdownUI

struct MainChatView: View {
    @Binding var selectedModel: String?
    @Binding var selectedProvider: LLMProvider
    @Binding var models: [String]
    @Binding var isLoadingModels: Bool
    @StateObject private var viewModel = ChatViewModel.shared
    @Namespace private var bottomID
    @State private var isGenerating = false
    @State private var responseStartTime: Date?
    @State private var tokenCount: Int = 0
    
    let onProviderChange: () async -> Void
    let onModelRefresh: () async -> Void
    let onCopyAllMessages: () -> Void
    
    var body: some View {
        mainContent
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onChange(of: selectedProvider) { _, newProvider in
                handleProviderChange(newProvider)
            }
            .onChange(of: selectedModel) { _, newModel in
                handleModelChange(newModel)
            }
            .onChange(of: viewModel.chatId) { _, _ in
                handleChatIdChange()
            }
            .onAppear {
                handleViewAppear()
            }
    }
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            headerSection
            
            Divider()
            
            chatMessagesSection
            
            Divider()
            
            inputSection
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: selectedProvider) { _, newProvider in
            if newProvider != viewModel.chatProvider {
                viewModel.updateProviderAndModel(newProvider, selectedModel)
            }
        }
        .onChange(of: selectedModel) { _, newModel in
            if newModel != viewModel.chatModel {
                viewModel.updateProviderAndModel(selectedProvider, newModel)
            }
        }
        .onChange(of: viewModel.chatId) { _, _ in
            // When a different chat is loaded, prefer its saved provider/model
            // Only update if different to prevent feedback loops
            if selectedProvider != viewModel.chatProvider {
                selectedProvider = viewModel.chatProvider
            }
            if let cm = viewModel.chatModel, selectedModel != cm {
                selectedModel = cm
            }
        }
        .onAppear {
            // Only update if different to prevent feedback loops
            if selectedProvider != viewModel.chatProvider || selectedModel != viewModel.chatModel {
                viewModel.updateProviderAndModel(selectedProvider, selectedModel)
            }
            // Align bindings with the chat’s saved values if present
            if selectedProvider != viewModel.chatProvider {
                selectedProvider = viewModel.chatProvider
            }
            if let cm = viewModel.chatModel, selectedModel != cm {
                selectedModel = cm
            }
        }
    }
    
    // MARK: - View Components
    private var headerSection: some View {
        modelSelectionHeader
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(headerBackground)
    }
    
    private var headerBackground: some View {
        Group {
            if #available(macOS 15, *) {
                Color.clear
                    .modifier(GlassEffectModifier())
            } else {
                Color.gray.opacity(0.05)
            }
        }
    }
    
    private var chatMessagesSection: some View {
        ScrollViewReader { proxy in
            ScrollView {
                messagesContent
                    .padding()
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                // Immediate scroll for new messages
                withAnimation(.easeOut(duration: 0.3)) {
                    proxy.scrollTo(bottomID, anchor: .bottom)
                }
            }
            .onChange(of: viewModel.messages.last?.content) { _, _ in
                // Always scroll when content changes, with different animations based on state
                if isGenerating {
                    // Fast scroll during streaming
                    withAnimation(.linear(duration: 0.1)) {
                        proxy.scrollTo(bottomID, anchor: .bottom)
                    }
                } else {
                    // Smooth scroll when not generating (final updates)
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(bottomID, anchor: .bottom)
                    }
                }
            }
            .onAppear {
                // Small delay on appear to ensure layout is ready
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(bottomID, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    private var messagesContent: some View {
        Group {
            if #available(macOS 15, *) {
                modernMessagesLayout
            } else {
                legacyMessagesLayout
            }
        }
    }
    
    private var modernMessagesLayout: some View {
        GlassEffectContainer(spacing: 24) {
            LazyVStack(spacing: 20) {
                ForEach(viewModel.messages) { message in
                    VStack(alignment: HorizontalAlignment.trailing, spacing: 4) {
                        MessageBubble(message: message)
                    }
                    .id(message.id)
                }
                Color.clear
                    .frame(height: 1)
                    .id(bottomID)
            }
        }
    }
    
    private var legacyMessagesLayout: some View {
        LazyVStack(spacing: 20) {
            ForEach(viewModel.messages) { message in
                VStack(alignment: HorizontalAlignment.trailing, spacing: 4) {
                    MessageBubble(message: message)
                }
                .id(message.id)
            }
            Color.clear
                .frame(height: 1)
                .id(bottomID)
        }
    }
    
    private var inputSection: some View {
        MessageInputView(
            viewModel: viewModel,
            selectedModel: $selectedModel,
            isGenerating: $isGenerating,
            isLoadingModels: $isLoadingModels,
            onSendMessage: { Task { await sendMessage() } },
            onCancelGeneration: {
                LLMService.shared.cancelGeneration()
                isGenerating = false
            }
        )
        .padding(8)
        .modifier(GlassEffectModifier())
        .background(inputBackground)
        .padding([.leading, .trailing])
        .padding(.bottom, 8)
    }
    
    private var inputBackground: some View {
        Group {
            if #available(macOS 15, *) { 
                Color.clear 
            } else { 
                Color.gray.opacity(0.08) 
            }
        }
    }
    
    // MARK: - Model Selection Header
    private var modelSelectionHeader: some View {
        HStack {
            ModelSelectionMenu(
                selectedModel: $selectedModel,
                selectedProvider: $selectedProvider,
                models: $models,
                isLoadingModels: $isLoadingModels,
                onProviderChange: onProviderChange,
                onModelRefresh: onModelRefresh,
                onCopyAllMessages: onCopyAllMessages
            )
        }
    }
    
    // MARK: - Helper Methods
    private func scrollToBottomAsync(proxy: ScrollViewProxy) {
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.3)) {
                proxy.scrollTo(bottomID, anchor: .bottom)
            }
        }
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        DispatchQueue.main.async {
            withAnimation(.none) {
                proxy.scrollTo(bottomID, anchor: UnitPoint.bottom)
            }
        }
    }
    
    private func handleProviderChange(_ newProvider: LLMProvider) {
        if newProvider != viewModel.chatProvider {
            viewModel.updateProviderAndModel(newProvider, selectedModel)
        }
    }
    
    private func handleModelChange(_ newModel: String?) {
        if newModel != viewModel.chatModel {
            viewModel.updateProviderAndModel(selectedProvider, newModel)
        }
    }
    
    private func handleChatIdChange() {
        // When a different chat is loaded, prefer its saved provider/model
        // Only update if different to prevent feedback loops
        if selectedProvider != viewModel.chatProvider {
            selectedProvider = viewModel.chatProvider
        }
        if let cm = viewModel.chatModel, selectedModel != cm {
            selectedModel = cm
        }
    }
    
    private func handleViewAppear() {
        // Only update if different to prevent feedback loops
        if selectedProvider != viewModel.chatProvider || selectedModel != viewModel.chatModel {
            viewModel.updateProviderAndModel(selectedProvider, selectedModel)
        }
        // Align bindings with the chat's saved values if present
        if selectedProvider != viewModel.chatProvider {
            selectedProvider = viewModel.chatProvider
        }
        if let cm = viewModel.chatModel, selectedModel != cm {
            selectedModel = cm
        }
    }
    
    private func sendMessage() async {
        guard let selectedModel = selectedModel,
              !viewModel.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        let currentText = viewModel.messageText
        let currentImage = viewModel.selectedImage
        
        // Clear input and set generating state first
        viewModel.messageText = ""
        viewModel.selectedImage = nil
        isGenerating = true
        responseStartTime = Date()
        tokenCount = 0

        // Add user message
        let userMessage = ChatMessage(
            id: viewModel.messages.count * 2,
            content: currentText,
            isUser: true,
            timestamp: Date(),
            image: currentImage,
            engine: selectedModel
        )
        viewModel.messages.append(userMessage)

        // Add waiting message
        let waitingMessage = ChatMessage(
            id: viewModel.messages.count * 2 + 1,
            content: "...",
            isUser: false,
            timestamp: Date(),
            image: nil,
            engine: selectedModel
        )
        viewModel.messages.append(waitingMessage)
        
        // Small delay to ensure UI updates and scrolling happen
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        do {
            var fullResponse = ""
            var updateCounter = 0
            let stream = try await LLMService.shared.generateResponse(
                prompt: currentText,
                image: currentImage,
                model: selectedModel
            )
            
            for try await response in stream {
                fullResponse += response
                tokenCount += response.count
                updateCounter += 1
                
                // Update UI every 5 tokens or on longer delays to reduce flicker
                if updateCounter % 5 == 0 || response.count > 10 {
                    await MainActor.run {
                        if let index = viewModel.messages.lastIndex(where: { !$0.isUser }) {
                            let updatedMessage = ChatMessage(
                                id: viewModel.messages[index].id,
                                content: fullResponse,
                                isUser: false,
                                timestamp: viewModel.messages[index].timestamp,
                                image: nil,
                                engine: selectedModel
                            )
                            viewModel.messages[index] = updatedMessage
                        }
                    }
                }
            }
            
            // Create final message with stats in one update to prevent blank view
            var statsMessage = ""
            if let startTime = responseStartTime {
                let elapsedTime = Date().timeIntervalSince(startTime)
                let tokensPerSecond = Double(tokenCount) / elapsedTime
                statsMessage = "\n\n---\n [\(selectedModel)] \(String(format: "%.1f", tokensPerSecond)) tokens/sec"
            }
            
            // Single final update with complete content including stats
            await MainActor.run {
                if let index = viewModel.messages.lastIndex(where: { !$0.isUser }) {
                    let finalMessage = ChatMessage(
                        id: viewModel.messages[index].id,
                        content: fullResponse + statsMessage,
                        isUser: false,
                        timestamp: viewModel.messages[index].timestamp,
                        image: nil,
                        engine: selectedModel
                    )
                    viewModel.messages[index] = finalMessage
                }
            }
            
            try DatabaseManager.shared.insert(
                groupId: viewModel.chatId.uuidString,
                instruction: UserDefaults.standard.string(forKey: "llmInstruction") ?? "",
                question: currentText,
                answer: fullResponse + statsMessage,
                image: currentImage,
                engine: selectedModel,
                provider: viewModel.chatProvider.rawValue,
                model: viewModel.chatModel ?? selectedModel
            )
            
            SidebarViewModel.shared.refresh()
            
        } catch {
            if let index = viewModel.messages.lastIndex(where: { !$0.isUser }) {
                let errorMessage = ChatMessage(
                    id: viewModel.messages[index].id,
                    content: "\(error.localizedDescription)",
                    isUser: false,
                    timestamp: Date(),
                    image: nil,
                    engine: selectedModel
                )
                viewModel.messages[index] = errorMessage
            }
        }
        
        isGenerating = false
        responseStartTime = nil
        tokenCount = 0
    }
}

