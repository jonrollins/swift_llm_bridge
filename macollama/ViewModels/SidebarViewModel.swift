import Foundation

@MainActor
class SidebarViewModel: ObservableObject {
    static let shared = SidebarViewModel() 
    
    @Published var chatTitles: [ChatTitle] = []
    
    func loadChatTitles() async {
        do {
            let results = try DatabaseManager.shared.fetchTitles()
            chatTitles = results.map { result in
                let chatTitle = ChatTitle(
                    id: result.id,
                    groupId: result.groupId,
                    question: result.question,
                    answer: result.answer,
                    created: result.created,
                    engine: result.engine,
                    image: result.image
                )
                print("Loaded chat: ID=\(result.id), GroupId=\(result.groupId), Question='\(result.question)', Date=\(result.created)")
                return chatTitle
            }
        } catch {
            print("Failed to load chat titles: \(error)")
        }
    }
    
    func deleteChat(groupId: String) async throws {
        try DatabaseManager.shared.deleteGroupChats(groupId: groupId)
        await loadChatTitles()
    }
    
    func renameChat(groupId: String, newName: String) async throws {
        do {
            try DatabaseManager.shared.updateChatName(groupId: groupId, newName: newName)
            print("Successfully renamed chat \(groupId) to '\(newName)'")
            await loadChatTitles()
        } catch {
            print("Failed to rename chat: \(error)")
            throw error
        }
    }
    
    func refresh() {
        Task {
            await loadChatTitles()
        }
    }
    
    func searchChatTitles(keyword: String) async {
        do {
            let results = try DatabaseManager.shared.searchMessages(keyword: keyword)
            chatTitles = results.map { result in
                ChatTitle(
                    id: result.id,
                    groupId: result.groupId,
                    question: result.question,
                    answer: result.answer,
                    created: result.created,
                    engine: result.engine,
                    image: result.image
                )
            }
        } catch {
            print("Failed to search chat titles: \(error)")
        }
    }
} 
