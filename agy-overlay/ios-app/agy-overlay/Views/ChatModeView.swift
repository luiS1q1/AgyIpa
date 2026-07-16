import SwiftUI

struct ChatModeView: View {
    @EnvironmentObject var appState: AppState
    @State private var wsManager: WebSocketManager?
    
    let suggestions = [
        "Schreibe ein Python-Skript",
        "Erkläre Quantenphysik",
        "Analysiere den Code"
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Premium Dark Gradient Background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 10/255, green: 10/255, blue: 22/255),
                        Color(red: 22/255, green: 15/255, blue: 38/255),
                        Color(red: 12/255, green: 8/255, blue: 24/255)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom Header Info
                    HStack {
                        Circle()
                            .fill(appState.isConnected ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                            .shadow(color: appState.isConnected ? .green : .red, radius: 4)
                        Text(appState.isConnected ? "Verbunden" : "Verbindung getrennt")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if let sessionId = appState.currentSessionId {
                            Text("Session: \(sessionId)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.2))
                    
                    // Main Chat Area
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(alignment: .leading, spacing: 14) {
                                if appState.chatMessages.isEmpty {
                                    // Gorgeous Welcome Empty State
                                    VStack(spacing: 24) {
                                        Spacer()
                                            .frame(height: 40)
                                        
                                        ZStack {
                                            Circle()
                                                .fill(
                                                    LinearGradient(
                                                        colors: [.purple.opacity(0.2), .blue.opacity(0.1)],
                                                        startPoint: .top,
                                                        endPoint: .bottom
                                                    )
                                                )
                                                .frame(width: 100, height: 100)
                                            
                                            Image(systemName: "sparkles")
                                                .font(.system(size: 44, weight: .semibold))
                                                .foregroundStyle(
                                                    LinearGradient(
                                                        colors: [.purple, .blue],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                        }
                                        
                                        VStack(spacing: 8) {
                                            Text("Wie kann ich dir helfen?")
                                                .font(.title2)
                                                .fontWeight(.bold)
                                                .foregroundColor(.white)
                                            
                                            Text("Antigravity steht bereit, um dich beim Coden und Denken zu unterstützen.")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                                .multilineTextAlignment(.center)
                                                .padding(.horizontal, 32)
                                        }
                                        
                                        Spacer()
                                            .frame(height: 20)
                                        
                                        // Quick Suggestions
                                        VStack(spacing: 12) {
                                            ForEach(suggestions, id: \.self) { suggestion in
                                                Button(action: {
                                                    appState.currentInputText = suggestion
                                                }) {
                                                    HStack {
                                                        Text(suggestion)
                                                            .font(.body)
                                                            .foregroundColor(.white.opacity(0.9))
                                                        Spacer()
                                                        Image(systemName: "chevron.right")
                                                            .font(.footnote)
                                                            .foregroundColor(.secondary)
                                                    }
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 14)
                                                    .background(Color.white.opacity(0.06))
                                                    .cornerRadius(14)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 14)
                                                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                                    )
                                                }
                                                .padding(.horizontal, 16)
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
            .navigationTitle("Antigravity Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        startNewChat()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .bold))
                            Text("Neuer Chat")
                                .font(.footnote)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.purple)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.purple.opacity(0.15))
                        .cornerRadius(12)
                    }
                }
                
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Fertig") {
                        dismissKeyboard()
                    }
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

struct ChatModeView_Previews: PreviewProvider {
    static var previews: some View {
        ChatModeView()
            .environmentObject(AppState())
    }
}
