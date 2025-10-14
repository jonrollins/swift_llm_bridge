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
                    ThinkingIndicatorView()
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

struct ThinkingIndicatorView: View {
    @State private var animationOffset: CGFloat = 0
    @State private var dotOpacities: [Double] = [1.0, 0.5, 0.3]
    
    var body: some View {
        HStack(spacing: 4) {
            // Animated thinking dots
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                        .opacity(dotOpacities[index])
                        .animation(
                            Animation.easeInOut(duration: 0.6)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                            value: dotOpacities[index]
                        )
                }
            }
            
            // Thinking text
            Text("AI is thinking...")
                .foregroundColor(.gray)
                .font(.caption)
                .opacity(0.8)
        }
        .frame(height: 20)
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        withAnimation {
            for index in 0..<dotOpacities.count {
                dotOpacities[index] = [0.3, 1.0, 0.5][index]
            }
        }
        
        Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { _ in
            withAnimation {
                let temp = dotOpacities[0]
                dotOpacities[0] = dotOpacities[1]
                dotOpacities[1] = dotOpacities[2]
                dotOpacities[2] = temp
            }
        }
    }
} 
