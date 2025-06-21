//
//  ContentView.swift
//  myollama
//
//  Created by rtlink on 6/12/25.
//

import SwiftUI
import Toasts

struct ChatTitle: Identifiable, Equatable, Hashable {
    let id: Int
    let groupId: String
    let question: String
    let answer: String?
    let created: String
    let engine: String
    let image: String?
    
    var formattedDate: String {
        let dateFormatter = ISO8601DateFormatter()
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        if let date = dateFormatter.date(from: created) {
            return outputFormatter.string(from: date)
        }
        return created
    }
    
    static func == (lhs: ChatTitle, rhs: ChatTitle) -> Bool {
        return lhs.id == rhs.id &&
               lhs.groupId == rhs.groupId &&
               lhs.question == rhs.question &&
               lhs.answer == rhs.answer &&
               lhs.created == rhs.created &&
               lhs.engine == rhs.engine &&
               lhs.image == rhs.image
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(groupId)
        hasher.combine(question)
        hasher.combine(answer)
        hasher.combine(created)
        hasher.combine(engine)
        hasher.combine(image)
    }
}

struct ContentView: View {
    @Environment(\.presentToast) var presentToast
    @ObservedObject private var viewModel = SidebarViewModel.shared
    @StateObject private var chatViewModel = ChatViewModel.shared
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var showSearchBar = false
    @State private var navigationPath = NavigationPath()
    
    private func newChat() {
        chatViewModel.startNewChat()
        navigationPath.append("newChat")
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 20) {
                        Image("mainicon")
                            .resizable()
                            .frame(width: 100, height: 100)
                            .foregroundStyle(Color.appPrimary)
                        
                        Button(action: {
                            newChat()
                        }) {
                            Text("l_new_conversation".localized)
                                .padding(10)
                                .background(Color.appPrimary)
                                .foregroundColor(Color(UIColor.systemBackground))
                                .cornerRadius(10)
                                .font(.headline)
                        }
                    }
                    
                    Divider()
                    
                    VStack(spacing: 0) {
                        if showSearchBar {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.gray)
                                TextField("l_search_conversations".localized, text: $searchText)
                                    .textFieldStyle(.roundedBorder)
                                    .onChange(of: searchText) { newValue in
                                        isSearching = !newValue.isEmpty
                                        Task {
                                            if newValue.isEmpty {
                                                await viewModel.loadChatTitles()
                                            } else {
                                                await viewModel.searchChatTitles(keyword: newValue)
                                            }
                                        }
                                    }
                                
                                if isSearching {
                                    Button(action: {
                                        searchText = ""
                                        isSearching = false
                                        Task {
                                            await viewModel.loadChatTitles()
                                        }
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        if (viewModel.chatTitles.isEmpty) {
                            Text("l_no_saved_conv".localized)
                                .foregroundColor(.gray)
                                .font(.system(size: 16))
                                .padding()
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            LazyVStack(spacing: 8) {
                                ForEach(viewModel.chatTitles) { chat in
                                    ChatRowView(chat: chat, onTap: {
                                        navigationPath.append("chat:\(chat.groupId)")
                                    }, onDelete: {
                                        Task {
                                            try? await viewModel.deleteChat(groupId: chat.groupId)
                                            if chatViewModel.chatId.uuidString == chat.groupId {
                                                chatViewModel.startNewChat()
                                            }
                                        }
                                    })
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                }
            }
            .refreshable {
                await viewModel.loadChatTitles()
            }
            .navigationTitle("llm_bridge".localized)
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: String.self) { destination in
                if destination == "SettingsView" {
                    SettingsView()
                } else if destination == "newChat" {
                    ChatDetailView()
                } else if destination.hasPrefix("chat:") {
                    let groupId = String(destination.dropFirst(5))
                    ChatDetailView()
                        .onAppear {
                            chatViewModel.loadChat(groupId: groupId)
                        }
                } else {
                    ChatDetailView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showSearchBar = !showSearchBar
                    }) {
                        Image(systemName: "magnifyingglass")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        newChat()
                    }) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .resizable()
                            .frame(width: 28, height: 24)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        navigationPath.append("SettingsView")
                    }) {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .task {
                await viewModel.loadChatTitles()
                if let firstChat = viewModel.chatTitles.first {
                    chatViewModel.loadChat(groupId: firstChat.groupId)
                }
            }

        }
    }
}

// 채팅 행 컴포넌트
struct ChatRowView: View {
    let chat: ChatTitle
    let onTap: () -> Void
    let onDelete: () -> Void
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        HStack(spacing: 12) {
            // 이미지 표시
            if let imageBase64 = chat.image,
               let imageData = Data(base64Encoded: imageBase64),
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "bubble.left.and.bubble.right")
                            .foregroundColor(.gray)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(chat.question)
                    .font(.subheadline)
                    .lineLimit(1)
                    .multilineTextAlignment(.leading)

                if chat.answer != nil {
                    Text(chat.answer ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                Text(chat.engine)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 1)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(4)
            }
            
            Spacer()
            
            // 삭제 버튼
            Button(action: {
                showDeleteConfirmation = true
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .font(.system(size: 16))
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .alert("l_delete".localized, isPresented: $showDeleteConfirmation) {
            Button("l_cancel".localized, role: .cancel) { }
            Button("l_delete".localized, role: .destructive) {
                onDelete()
            }
        } message: {
            Text("l_del_question".localized)
        }
    }
}
