//
//  MessageBubbleView.swift
//  myollama
//
//  Created by rtlink on 6/12/25.
//

import SwiftUI
import MarkdownUI

// 커스텀 Markdown 테마
extension Theme {
    static let customSmall = Theme()
        .text {
            FontSize(16)
        }
        .code {
            FontFamilyVariant(.normal)
            FontSize(16)
        }
        .heading1 { configuration in
            configuration.label
                .markdownTextStyle {
                    FontSize(20)
                    FontWeight(.bold)
                }
        }
        .heading2 { configuration in
            configuration.label
                .markdownTextStyle {
                    FontSize(18)
                    FontWeight(.semibold)
                }
        }
}


struct MessageBubbleView: View {
    let message: ChatMessage
    @State private var showingShareSheet = false
    
    var body: some View {
        VStack(alignment: message.isUser ? .trailing : .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 8) {
                if let image = message.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .cornerRadius(8)
                        .padding(10)
                }
                
                if !message.isUser && message.content.trimmingCharacters(in: .whitespacesAndNewlines) == "..." {
                    HStack {
                        ProgressView()
                            .controlSize(.small)
                        Text("Thinking...")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                    .frame(height: 20)
                    .padding(10)
                } else {
                    Markdown(message.content)
                        .markdownTheme(.customSmall)
                        .padding(12)
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding(4)
            .background(message.isUser ? Color.gray.opacity(0.2) : Color.gray.opacity(0.2))
            .foregroundColor(message.isUser ? .white : Color(.systemGray2))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .contextMenu {
                Button(action: {
                    UIPasteboard.general.string = message.content
                }) {
                    Label("l_message_copy".localized, systemImage: "doc.on.doc")
                }
                
                Button(action: {
                    showingShareSheet = true
                }) {
                    Label("l_message_share_qa".localized, systemImage: "square.and.arrow.up")
                }                
            }
            
            Text(message.formattedTime)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: message.isUser ? .trailing : .leading)
        .sheet(isPresented: $showingShareSheet) {
            ActivityView(activityItems: [message.content])
        }
    }
}

struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
} 
