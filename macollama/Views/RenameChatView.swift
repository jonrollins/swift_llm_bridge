import SwiftUI

struct RenameChatView: View {
    let currentName: String
    let onRename: (String) -> Void
    let onCancel: () -> Void
    
    @State private var newName: String
    @Environment(\.dismiss) private var dismiss
    
    init(currentName: String, onRename: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
        self.currentName = currentName
        self.onRename = onRename
        self.onCancel = onCancel
        self._newName = State(initialValue: currentName)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Rename Chat")
                .font(.headline)
                .padding(.top)
            
            TextField("Chat name", text: $newName)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
            
            HStack(spacing: 12) {
                Button("Cancel") {
                    onCancel()
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Button("Rename") {
                    onRename(newName.trimmingCharacters(in: .whitespacesAndNewlines))
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.bottom)
        }
        .frame(width: 300, height: 150)
        .onAppear {
            // Select all text when the view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // Focus on the text field
            }
        }
    }
}

#Preview {
    RenameChatView(
        currentName: "Sample Chat",
        onRename: { newName in
            print("Renamed to: \(newName)")
        },
        onCancel: {
            print("Cancelled")
        }
    )
}