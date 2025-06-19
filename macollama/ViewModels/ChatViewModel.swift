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
    
    private init() {}
    
    func startNewChat() {
        messages.removeAll()
        selectedImage = nil
        messageText = ""
        chatId = UUID()
        shouldFocusTextField = true
    }
    
    @MainActor
    func loadChat(groupId: String) {
        do {
            let results = try DatabaseManager.shared.fetchQuestionsByGroupId(groupId)
            messages = []
            
            let dateFormatter = ISO8601DateFormatter()
            
            for result in results {
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
            
            chatId = UUID(uuidString: groupId) ?? UUID()
        } catch {
            print("Failed to load chat: \(error)")
        }
    }
} 
