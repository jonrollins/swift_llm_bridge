import Foundation
import SwiftUI
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

struct ChatMessage: Identifiable {
    let id: Int
    let content: String
    let isUser: Bool
    let timestamp: Date
    let image: PlatformImage?
    let engine: String
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd, HH:mm"
        return formatter.string(from: timestamp)
    }
    
    init(id: Int = 0, content: String, isUser: Bool, timestamp: Date, image: PlatformImage? = nil, engine: String) {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
        self.image = image
        self.engine = engine
    }
} 
