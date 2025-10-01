import Foundation
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

class ChatViewModel: ObservableObject {
    static let shared = ChatViewModel()
    
    @Published var messages: [ChatMessage] = []
    @Published var selectedImage: PlatformImage?
    @Published var messageText: String = ""
    @Published var chatId = UUID()
    @Published var shouldFocusTextField: Bool = false
    @Published var chatProvider: LLMProvider = .ollama
    @Published var chatModel: String? = nil
    
    private init() {}
    
    func startNewChat() {
        messages.removeAll()
        selectedImage = nil
        messageText = ""
        chatId = UUID()
        shouldFocusTextField = true
        // Note: Keep the current chatProvider and chatModel for the new chat
    }
    
    func updateProviderAndModel(_ provider: LLMProvider, _ model: String?) {
        self.chatProvider = provider
        self.chatModel = model
    }
    
    func saveProviderAndModel() {
        guard chatId != UUID() else { return }
        
        Task {
            do {
                try DatabaseManager.shared.updateChatProviderAndModel(
                    groupId: chatId.uuidString,
                    provider: chatProvider.rawValue,
                    model: chatModel
                )
                print("Saved provider: \(chatProvider.rawValue), model: \(chatModel ?? "none") for chat: \(chatId.uuidString)")
            } catch {
                print("Failed to save provider and model: \(error)")
            }
        }
    }
    
    @MainActor
    func loadChat(groupId: String) {
        do {
            print("Loading chat for groupId: \(groupId)")
            let results = try DatabaseManager.shared.fetchQuestionsByGroupId(groupId)
            print("Found \(results.count) message pairs for groupId: \(groupId)")
            
            messages = []
            
            let dateFormatter = ISO8601DateFormatter()
            
            for (index, result) in results.enumerated() {
                print("Processing message pair \(index): id=\(result.id), question='\(result.question.prefix(50))...', answer='\(result.answer.prefix(50))...'")
                
                var image: PlatformImage? = nil
                if let imageBase64 = result.image,
                   let imageData = Data(base64Encoded: imageBase64) {
                    #if os(macOS)
                    image = NSImage(data: imageData)
                    #elseif os(iOS)
                    image = UIImage(data: imageData)
                    #endif
                }
                
                let timestamp = dateFormatter.date(from: result.created) ?? Date()
                
                messages.append(ChatMessage(
                    id: result.id * 2,
                    content: result.question,
                    isUser: true,
                    timestamp: timestamp,
                    image: image,
                    engine: result.engine
                ))
                
                messages.append(ChatMessage(
                    id: result.id * 2 + 1,
                    content: result.answer,
                    isUser: false,
                    timestamp: timestamp,
                    image: nil,
                    engine: result.engine
                ))
            }
            
            print("Final message count: \(messages.count)")
            chatId = UUID(uuidString: groupId) ?? UUID()
            
            // Load provider and model settings for this chat
            do {
                let (provider, model) = try DatabaseManager.shared.getChatProviderAndModel(groupId: groupId)
                if let providerString = provider, let providerEnum = LLMProvider(rawValue: providerString) {
                    self.chatProvider = providerEnum
                    print("Loaded provider: \(providerString) for chat: \(groupId)")
                }
                if let model = model {
                    self.chatModel = model
                    print("Loaded model: \(model) for chat: \(groupId)")
                }
            } catch {
                print("Failed to load provider and model for chat: \(error)")
            }
        } catch {
            print("Failed to load chat: \(error)")
        }
    }
} 
