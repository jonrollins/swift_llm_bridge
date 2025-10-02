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
        VStack(spacing: 0) {
            // Model Selection Header
            modelSelectionHeader
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(
                    Group {
                        if #available(macOS 15, *) {
                            Color.clear
                                .modifier(GlassEffectModifier())
                        } else {
                            Color.gray.opacity(0.05)
                        }
                    }
                )
            
            Divider()
            
            // Chat Messages Area
            ScrollViewReader { proxy in
                ScrollView {
                    Group {
                        if #available(macOS 15, *) {
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
                        } else {
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
                    .padding()
                }
                .onChange(of: viewModel.messages.count) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        scrollToBottom(proxy: proxy)
                    }
                }
                .onChange(of: viewModel.messages.last?.content) {
                    withAnimation(.easeOut(duration: 0.2)) {
                        scrollToBottom(proxy: proxy)
                    }
                }
                .onReceive(viewModel.$messages) { _ in
                    if isGenerating {
                        withAnimation(.easeOut(duration: 0.1)) {
                            scrollToBottom(proxy: proxy)
                        }
                    }
                }
            }
            
            Divider()
            
            // Message Input Area
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
            .background(
                Group {
                    if #available(macOS 15, *) { Color.clear } else { Color.gray.opacity(0.08) }
                }
            )
            .padding([.leading, .trailing])
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: selectedProvider) {
            viewModel.updateProviderAndModel(selectedProvider, selectedModel)
        }
        .onChange(of: selectedModel) {
            viewModel.updateProviderAndModel(selectedProvider, selectedModel)
        }
        .onAppear {
            viewModel.updateProviderAndModel(selectedProvider, selectedModel)
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
    private func scrollToBottom(proxy: ScrollViewProxy) {
        proxy.scrollTo(bottomID, anchor: UnitPoint.bottom)
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
        
        do {
            var fullResponse = ""
            let stream = try await LLMService.shared.generateResponse(
                prompt: currentText,
                image: currentImage,
                model: selectedModel
            )
            
            for try await response in stream {
                fullResponse += response
                tokenCount += response.count
                if let index = viewModel.messages.lastIndex(where: { !$0.isUser }) {
                    let updatedMessage = ChatMessage(
                        id: viewModel.messages[index].id,
                        content: fullResponse,
                        isUser: false,
                        timestamp: viewModel.messages[index].timestamp,
                        image: nil,
                        engine: selectedModel
                    )
                    await MainActor.run {
                        viewModel.messages[index] = updatedMessage
                    }
                }
            }
            
            var statsMessage = ""
            if let startTime = responseStartTime {
                let elapsedTime = Date().timeIntervalSince(startTime)
                let tokensPerSecond = Double(tokenCount) / elapsedTime
                statsMessage = "\n\n---\n [\(selectedModel)] \(String(format: "%.1f", tokensPerSecond)) tokens/sec"
                
                if let index = viewModel.messages.lastIndex(where: { !$0.isUser }) {
                    let updatedMessage = ChatMessage(
                        id: viewModel.messages[index].id,
                        content: fullResponse + statsMessage,
                        isUser: false,
                        timestamp: viewModel.messages[index].timestamp,
                        image: nil,
                        engine: selectedModel
                    )
                    await MainActor.run {
                        viewModel.messages[index] = updatedMessage
                    }
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
