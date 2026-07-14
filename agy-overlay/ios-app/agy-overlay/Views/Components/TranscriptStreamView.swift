import SwiftUI

struct TranscriptStreamView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if appState.chatMessages.isEmpty {
                        VStack(spacing: 12) {
                            Spacer()
                            Image(systemName: "cpu")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            Text("Warte auf Log-Stream...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, minHeight: 300)
                    } else {
                        ForEach(appState.chatMessages) { message in
                            messageRow(for: message)
                                .id(message.id)
                        }
                    }
                }
                .padding()
            }
            .onChange(of: appState.chatMessages) { _ in
                if let lastMessage = appState.chatMessages.last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func messageRow(for message: Message) -> some View {
        switch message.sender {
        case .user:
            HStack {
                Spacer()
                Text(message.content)
                    .font(.body)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(18)
                    .frame(maxWidth: 280, alignment: .trailing)
            }
            
        case .assistant:
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.footnote)
                    .foregroundColor(.purple)
                    .padding(8)
                    .background(Color.purple.opacity(0.15))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Assistent")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    Text(message.content)
                        .font(.body)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color(.secondarySystemBackground).opacity(0.8))
                        .cornerRadius(16)
                }
                Spacer()
            }
            
        case .tool:
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "hammer.fill")
                    .font(.footnote)
                    .foregroundColor(.orange)
                    .padding(8)
                    .background(Color.orange.opacity(0.15))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tool-Aufruf: \(message.toolName ?? "Unbekannt")")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                    
                    Text(message.content)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary)
                        .padding(10)
                        .background(Color.orange.opacity(0.08))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                        )
                }
                Spacer()
            }
            
        case .toolResponse:
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "doc.text.fill")
                    .font(.footnote)
                    .foregroundColor(.green)
                    .padding(8)
                    .background(Color.green.opacity(0.15))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tool-Antwort")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                    
                    Text(message.content)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.primary)
                        .padding(10)
                        .background(Color.green.opacity(0.05))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.green.opacity(0.2), lineWidth: 1)
                        )
                }
                Spacer()
            }
            
        case .systemError:
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundColor(.red)
                    .padding(8)
                    .background(Color.red.opacity(0.15))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Fehler")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                    
                    Text(message.content)
                        .font(.body)
                        .foregroundColor(.red)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(16)
                }
                Spacer()
            }
        }
    }
}

struct TranscriptStreamView_Previews: PreviewProvider {
    static var previews: some View {
        let appState = AppState()
        appState.chatMessages = [
            Message(sender: .user, content: "Kompiliere das Projekt bitte.", toolName: nil, timestamp: Date()),
            Message(sender: .tool, content: "xcodebuild -workspace ios-app.xcworkspace", toolName: "run_command", timestamp: Date()),
            Message(sender: .toolResponse, content: "Build Succeeded.", toolName: nil, timestamp: Date()),
            Message(sender: .assistant, content: "Der Build war erfolgreich!", toolName: nil, timestamp: Date())
        ]
        return TranscriptStreamView()
            .environmentObject(appState)
            .background(Color.black.opacity(0.8))
    }
}
