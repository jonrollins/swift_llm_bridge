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
                    image: result.image,
                    title: result.title,
                    provider: result.provider,
                    model: result.model
                )
                return chatTitle
            }
        } catch {
        }
    }
    
    func deleteChat(groupId: String) async throws {
        try DatabaseManager.shared.deleteGroupChats(groupId: groupId)
        await loadChatTitles()
    }
    
    func renameChat(groupId: String, newName: String) async throws {
        do {
            try DatabaseManager.shared.updateChatName(groupId: groupId, newName: newName)
            await loadChatTitles()
        } catch {
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
                    image: result.image,
                    title: result.title,
                    provider: result.provider,
                    model: result.model
                )
            }
        } catch {
        }
    }
} 

