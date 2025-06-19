//
//  LLMProvider.swift
//  macollama
//
//  Created by rtlink on 6/11/25.
//
import SwiftUI


enum LLMProvider: String, CaseIterable {
    case ollama = "Ollma"
    case lmstudio = "LMStudio"
    case claude = "Claude"
    case openai = "OpenAI"
    
    var displayName: String {
        switch self {
        case .ollama:
            return "Ollama Server"
        case .lmstudio:
            return "LMStudio"
        case .claude:
            return "Claude API"
        case .openai:
            return "OpenAI API"
        }
    }
    
    static var availableProviders: [LLMProvider] {
        Self.allCases.filter { provider in
            switch provider {
            case .ollama:
                return UserDefaults.standard.bool(forKey: "showOllama")
            case .lmstudio:
                return UserDefaults.standard.bool(forKey: "showLMStudio")
            case .claude:
                return UserDefaults.standard.bool(forKey: "showClaude")
            case .openai:
                return UserDefaults.standard.bool(forKey: "showOpenAI")
            }
        }
    }
    
}
