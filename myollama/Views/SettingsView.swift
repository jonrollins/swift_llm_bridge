//
//  SettingsView.swift
//  myollama
//
//  Created by rtlink on 6/12/25.
//

import SwiftUI
import Toasts


struct SettingsView: View {
    @Environment(\.presentToast) var presentToast
    @Environment(\.dismiss) private var dismiss
    @State private var serverAddress: String = UserDefaults.standard.string(forKey: "ollama_base_url") ?? "http://localhost:11434"
    @State private var lmStudioAddress: String = UserDefaults.standard.string(forKey: "lmStudioAddress") ?? "http://localhost:1234"
    @State private var claudeApiKey: String = UserDefaults.standard.string(forKey: "claudeApiKey") ?? ""
    @State private var openaiApiKey: String = UserDefaults.standard.string(forKey: "openaiApiKey") ?? ""
    @AppStorage("selectedProvider") private var selectedProvider: LLMProvider = .ollama
    @State private var llmInstruction: String = UserDefaults.standard.string(forKey: "llmInstruction") ?? "You are a helpful assistant."
    @State private var temperature: Double = UserDefaults.standard.double(forKey: "temperature")
    @State private var topP: Double = UserDefaults.standard.double(forKey: "topP") != 0 ? UserDefaults.standard.double(forKey: "topP") : 0.9
    @State private var topK: Double = UserDefaults.standard.double(forKey: "topK") != 0 ? UserDefaults.standard.double(forKey: "topK") : 40
    @State private var showingDeleteAlert = false
    @State private var isTestingConnection = false
    @State private var connectionTestResult: String?
    @State private var isTestingLMStudioConnection = false
    @State private var lmStudioConnectionTestResult: String?
    
    @State private var appVersion = ""
    @State private var buildNumber = ""

    
    private func changeProvider() {
        LLMService.shared.refreshForProviderChange()
        NotificationCenter.default.post(
            name: Notification.Name("ReloadModelNotification"),
            object: nil
        )
    }
    
    private func showToast(_ message: String) {
        presentToast(
            ToastValue(
                icon: Image(systemName: "info.circle"), message: message
            )
        )
    }
    
    var body: some View {
        Form {
                // LLM Servers Section
                Section("l_llm_servers".localized) {
                    // Ollama Server
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Button(action: {
                                selectedProvider = .ollama
                                changeProvider()
                            }) {
                                HStack {
                                    Image(systemName: selectedProvider == .ollama ? "largecircle.fill.circle" : "circle")
                                        .foregroundColor(.blue)
                                    Text("Ollama")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                }
                            }
                            .buttonStyle(.plain)
                            Spacer()
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            TextField("Server Address", text: $serverAddress, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.URL)
                                .lineLimit(2...4)
                            
                            HStack {
                                Button(action: testConnection) {
                                    HStack {
                                        if isTestingConnection {
                                            ProgressView()
                                                .controlSize(.small)
                                        } else {
                                            Image(systemName: "network")
                                        }
                                        Text("l_test_connection".localized)
                                            .font(.footnote)
                                    }
                                }
                                .buttonStyle(.bordered)
                                .disabled(isTestingConnection)
                                
                                Spacer()
                            }
                            
                            if let result = connectionTestResult {
                                Text(result)
                                    .font(.caption)
                                    .foregroundColor(result.contains("Success") ? .green : .red)
                            }
                        }
                    }
                    
                    // LMStudio Server
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Button(action: {
                                selectedProvider = .lmstudio
                                changeProvider()
                            }) {
                                HStack {
                                    Image(systemName: selectedProvider == .lmstudio ? "largecircle.fill.circle" : "circle")
                                        .foregroundColor(.blue)
                                    Text("LMStudio")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            TextField("LMStudio Address", text: $lmStudioAddress, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.URL)
                                .lineLimit(2...4)
                            
                            HStack {
                                Button(action: testLMStudioConnection) {
                                    HStack {
                                        if isTestingLMStudioConnection {
                                            ProgressView()
                                                .controlSize(.small)
                                        } else {
                                            Image(systemName: "network")
                                        }
                                        Text("l_test_connection".localized)
                                            .font(.footnote)
                                    }
                                }
                                .buttonStyle(.bordered)
                                .disabled(isTestingLMStudioConnection)
                            }
                            
                            if let result = lmStudioConnectionTestResult {
                                Text(result)
                                    .font(.caption)
                                    .foregroundColor(result.contains("Success") ? .green : .red)
                            }
                        }
                    }
                    
                    // Claude API
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Button(action: {
                                if !claudeApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    selectedProvider = .claude
                                    changeProvider()
                                } else {
                                    showToast("Please enter a valid API key.")
                                }
                            }) {
                                HStack {
                                    Image(systemName: selectedProvider == .claude ? "largecircle.fill.circle" : "circle")
                                        .foregroundColor(claudeApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .blue)
                                    Text("Claude API")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                }
                            }
                            .buttonStyle(.plain)
                            Spacer()
                        }
                        
                        TextField("Claude API Key", text: $claudeApiKey, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(2...4)
                            .onChange(of: claudeApiKey) { newValue in
                                let trimmedValue = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                                if trimmedValue.isEmpty && selectedProvider == .claude {
                                    selectedProvider = .ollama
                                }
                            }
                    }
                    
                    // OpenAI API
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Button(action: {
                                if !openaiApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    selectedProvider = .openai
                                    changeProvider()
                                } else {
                                    showToast("Please enter a valid API key.")
                                }
                            }) {
                                HStack {
                                    Image(systemName: selectedProvider == .openai ? "largecircle.fill.circle" : "circle")
                                        .foregroundColor(openaiApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .blue)
                                    Text("OpenAI API")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                }
                            }
                            .buttonStyle(.plain)
                            Spacer()
                        }
                        
                        TextField("OpenAI API Key", text: $openaiApiKey, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(2...4)
                            .onChange(of: openaiApiKey) { newValue in
                                let trimmedValue = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                                if trimmedValue.isEmpty && selectedProvider == .openai {
                                    selectedProvider = .ollama
                                }
                            }
                    }
                }
                
                // LLM Settings Section
                Section("l_llm_settings".localized) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("l_llm_inst".localized)
                            .font(.headline)
                        
                        TextField("l_llm_inst_placeholder".localized, text: $llmInstruction, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(4...8)
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("l_model_parameters".localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        // Temperature
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Temperature")
                                    .font(.subheadline)
                                Spacer()
                                Text(String(format: "%.1f", temperature))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Slider(value: $temperature, in: 0.1...2.0, step: 0.1) {
                                Text("Temperature")
                            } minimumValueLabel: {
                                Text("0.1")
                                    .font(.caption)
                            } maximumValueLabel: {
                                Text("2.0")
                                    .font(.caption)
                            }
                            
                            Text("l_temperature_desc".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Top P
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Top P")
                                    .font(.subheadline)
                                Spacer()
                                Text(String(format: "%.1f", topP))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Slider(value: $topP, in: 0.1...1.0, step: 0.1) {
                                Text("Top P")
                            } minimumValueLabel: {
                                Text("0.1")
                                    .font(.caption)
                            } maximumValueLabel: {
                                Text("1.0")
                                    .font(.caption)
                            }
                            
                            Text("l_top_p_desc".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Top K
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Top K")
                                    .font(.subheadline)
                                Spacer()
                                Text(String(format: "%.0f", topK))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Slider(value: $topK, in: 1...100, step: 1) {
                                Text("Top K")
                            } minimumValueLabel: {
                                Text("1")
                                    .font(.caption)
                            } maximumValueLabel: {
                                Text("100")
                                    .font(.caption)
                            }
                            
                            Text("l_top_k_desc".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Divider()
                            
                            Button("l_reset_llm_settings".localized) {
                                UserDefaults.standard.set("http://192.168.1.100:11434", forKey: "ollama_base_url")
                                UserDefaults.standard.set("http://192.168.1.100:1234", forKey: "lmStudioAddress")
                                UserDefaults.standard.set("", forKey: "claudeApiKey")
                                UserDefaults.standard.set("", forKey: "openaiApiKey")
                                UserDefaults.standard.set("You are a helpful assistant.", forKey: "llmInstruction")
                                UserDefaults.standard.set(0.7, forKey: "temperature")
                                UserDefaults.standard.set(0.9, forKey: "topP")
                                UserDefaults.standard.set(40.0, forKey: "topK")
                                UserDefaults.standard.synchronize()
                                
                                serverAddress = "http://192.168.1.100:11434"
                                lmStudioAddress = "http://192.168.1.100:1234"
                                claudeApiKey = ""
                                openaiApiKey = ""
                                llmInstruction = "You are a helpful assistant."
                                temperature = 0.7
                                topP = 0.9
                                topK = 40.0
                                
                                selectedProvider = .ollama
                                changeProvider()                                
                            }
                            .buttonStyle(.borderedProminent)
                            .foregroundColor(.white)

                        }
                    }
                }
            

                
                // Help Section
                Section("Help") {
                    Link(destination: URL(string: "http://practical.kr/?p=828")!) {
                        HStack {
                            Image(systemName: "questionmark.circle")
                                .foregroundColor(.blue)
                            Text("l_ollama_method".localized)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    Link(destination: URL(string: "http://practical.kr/?p=848")!) {
                        HStack {
                            Image(systemName: "questionmark.circle")
                                .foregroundColor(.blue)
                            Text("l_lmstudio_method".localized)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    Button(action: {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        }
                    }) {
                        HStack {
                            Image(systemName: "gearshape")
                                .foregroundColor(.blue)
                            Text("l_app_settings".localized)
                                .foregroundColor(AppColor.link)
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                    }
                }
                
                // About Section
                Section("About") {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text("l_version".localized)
                        Spacer()
                        Text("\(appVersion) (\(buildNumber))")
                            .foregroundColor(.secondary)
                    }
                }
                
                // Danger Zone
                Section("Danger Zone") {
                    Button(action: {
                        showingDeleteAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                            Text("l_delete_all".localized)
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                }
        }
        .navigationTitle("l_settings".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("l_save".localized) {
                    saveSettings()
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .keyboard) {
                Button("Done") {
                    hideKeyboard()
                }
            }
        }
        .alert("l_delete_all_question".localized, isPresented: $showingDeleteAlert) {
            Button("l_cancel".localized, role: .cancel) { }
            Button("l_delete".localized, role: .destructive) {
                deleteAllData()
            }
        } message: {
            Text("l_delete_all_warning".localized)
        }
        .onAppear {
            loadAppVersion()
        }
    }
    
    private func loadAppVersion() {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            self.appVersion = version
        }
        
        if let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            self.buildNumber = build
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func saveSettings() {
        UserDefaults.standard.set(serverAddress, forKey: "ollama_base_url")
        UserDefaults.standard.set(lmStudioAddress, forKey: "lmStudioAddress")
        UserDefaults.standard.set(claudeApiKey, forKey: "claudeApiKey")
        UserDefaults.standard.set(openaiApiKey, forKey: "openaiApiKey")
        UserDefaults.standard.set(llmInstruction, forKey: "llmInstruction")
        UserDefaults.standard.set(temperature, forKey: "temperature")
        UserDefaults.standard.set(topP, forKey: "topP")
        UserDefaults.standard.set(topK, forKey: "topK")
        UserDefaults.standard.synchronize()
    }
    
    private func deleteAllData() {
        Task {
            do {
                try DatabaseManager.shared.deleteAllData()
                await SidebarViewModel.shared.refresh()
                ChatViewModel.shared.startNewChat()
                dismiss()
            } catch {
                // Removed print statement as requested
            }
        }
    }
    
    private func testConnection() {
        isTestingConnection = true
        connectionTestResult = nil
        
        Task {
            do {
                guard let url = URL(string: serverAddress) else {
                    connectionTestResult = "Invalid URL"
                    isTestingConnection = false
                    return
                }
                
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                request.timeoutInterval = 10.0
                
                let (_, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        connectionTestResult = "l_connection_success".localized
                    } else {
                        connectionTestResult = "l_connection_fail".localized
                    }
                }
            } catch {
                connectionTestResult = "l_connection_fail".localized
            }
            
            isTestingConnection = false
        }
    }
    
    private func testLMStudioConnection() {
        isTestingLMStudioConnection = true
        lmStudioConnectionTestResult = nil
        
        Task {
            do {
                guard let url = URL(string: lmStudioAddress) else {
                    lmStudioConnectionTestResult = "Invalid URL"
                    isTestingLMStudioConnection = false
                    return
                }
                
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                request.timeoutInterval = 10.0
                
                let (_, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        lmStudioConnectionTestResult = "l_connection_success".localized
                    } else {
                        lmStudioConnectionTestResult = "l_connection_fail".localized
                    }
                }
            } catch {
                lmStudioConnectionTestResult = "l_connection_fail".localized
            }
            
            isTestingLMStudioConnection = false
        }
    }
} 

