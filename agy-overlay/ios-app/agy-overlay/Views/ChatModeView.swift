import SwiftUI

struct ChatModeView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    @State private var wsManager: WebSocketManager?
    
    let suggestions = [
        (label: "SCRIPTING_", text: "Schreibe ein Python-Skript_"),
        (label: "PHYSICS_", text: "Erkläre Quantenphysik_"),
        (label: "ANALYSIS_", text: "Analysiere den Code_")
    ]
    
    var body: some View {
        // Theme Colors
        let bgCanvas = colorScheme == .dark ? Color(red: 19/255, green: 19/255, blue: 19/255) : Color(red: 249/255, green: 249/255, blue: 251/255)
        let textColor = colorScheme == .dark ? Color(red: 229/255, green: 226/255, blue: 225/255) : Color(red: 26/255, green: 26/255, blue: 26/255)
        let borderColor = colorScheme == .dark ? Color(red: 34/255, green: 34/255, blue: 34/255) : Color(red: 229/255, green: 229/255, blue: 229/255)
        let containerBg = colorScheme == .dark ? Color(red: 27/255, green: 28/255, blue: 28/255) : Color(red: 240/255, green: 240/255, blue: 242/255)
        
        NavigationView {
            ZStack {
                bgCanvas.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom Header Info Bar with 1px Bottom Border
                    HStack {
                        Circle()
                            .fill(appState.isConnected ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        Text(appState.isConnected ? "Verbunden" : "Verbindung getrennt")
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if let sessionId = appState.currentSessionId {
                            Text("Session: \(sessionId)")
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(bgCanvas)
                    .border(width: 1, edges: [.bottom], color: borderColor)
                    
                    // Main Chat Area
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(alignment: .leading, spacing: 24) {
                                if appState.chatMessages.isEmpty {
                                    // Gorgeous Welcome Empty State
                                    VStack(spacing: 24) {
                                        Spacer()
                                            .frame(height: 40)
                                        
                                        // Square Box Sparkles Icon
                                        VStack {
                                            Image(systemName: "sparkles")
                                                .font(.system(size: 32))
                                                .foregroundColor(textColor)
                                                .frame(width: 64, height: 64)
                                                .background(containerBg)
                                                .overlay(
                                                    Rectangle()
                                                        .stroke(borderColor, lineWidth: 1)
                                                )
                                        }
                                        
                                        VStack(spacing: 8) {
                                            Text("Wie kann ich dir helfen?")
                                                .font(.custom("Georgia", size: 24))
                                                .fontWeight(.bold)
                                                .foregroundColor(textColor)
                                            
                                            Text("SYSTEM_READY // AWAITING_INPUT // MODEL: AG-1_")
                                                .font(.system(.caption, design: .monospaced))
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                            .frame(height: 16)
                                        
                                        // Quick Suggestions (Sharp Corners, 1px borders)
                                        VStack(spacing: 12) {
                                            ForEach(suggestions, id: \.label) { suggestion in
                                                Button(action: {
                                                    // Strip trailing underscore if present
                                                    var text = suggestion.text
                                                    if text.endsWith("_") {
                                                        text = String(text.dropLast())
                                                    }
                                                    appState.currentInputText = text
                                                }) {
                                                    HStack {
                                                        VStack(alignment: .leading, spacing: 4) {
                                                            Text(suggestion.label)
                                                                .font(.system(.caption2, design: .monospaced))
                                                                .fontWeight(.bold)
                                                                .foregroundColor(.purple)
                                                            
                                                            Text(suggestion.text)
                                                                .font(.custom("Georgia", size: 16))
                                                                .foregroundColor(textColor)
                                                        }
                                                        Spacer()
                                                        Image(systemName: "arrow.right")
                                                            .font(.footnote)
                                                            .foregroundColor(.secondary)
                                                    }
                                                    .padding(16)
                                                    .background(containerBg)
                                                    .overlay(
                                                        Rectangle()
                                                            .stroke(borderColor, lineWidth: 1)
                                                    )
                                                }
                                                .padding(.horizontal, 20)
                                            }
                                        }
                                        
                                        Spacer()
                                    }
                                    .frame(maxWidth: .infinity)
                                } else {
                                    // Chat messages log
                                    TranscriptStreamView()
                                }
                            }
                            .padding(.vertical)
                        }
                        .onChange(of: appState.chatMessages) { _ in
                            if let lastMessage = appState.chatMessages.last {
                                withAnimation {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                    .onTapGesture {
                        dismissKeyboard()
                    }
                    
                    // Input Textbox at bottom
                    FloatingTextBox()
                }
            }
            .navigationTitle("ANTIGRAVITY_")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        startNewChat()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 11, weight: .bold))
                            Text("NEUER_CHAT_")
                                .font(.system(.caption, design: .monospaced))
                                .fontWeight(.bold)
                        }
                        .foregroundColor(textColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(containerBg)
                        .overlay(
                            Rectangle()
                                .stroke(borderColor, lineWidth: 1)
                        )
                    }
                }
                
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("FERTIG_") {
                        dismissKeyboard()
                    }
                    .font(.system(.footnote, design: .monospaced))
                    .foregroundColor(.purple)
                }
            }
            .onAppear {
                self.wsManager = WebSocketManager(appState: appState)
                if appState.currentSessionId == nil {
                    startNewChat()
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func startNewChat() {
        let newSessionId = String(Int.random(in: 100000...999999))
        appState.currentSessionId = newSessionId
        appState.chatMessages.removeAll()
        appState.screenshotImage = nil
        
        wsManager?.disconnect()
        wsManager?.startSessionAndConnect(sessionId: newSessionId, isDirectChat: true)
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// Extension helper for String drops
extension String {
    func endsWith(_ suffix: String) -> Bool {
        return self.hasSuffix(suffix)
    }
}

struct ChatModeView_Previews: PreviewProvider {
    static var previews: some View {
        ChatModeView()
            .environmentObject(AppState())
    }
}
