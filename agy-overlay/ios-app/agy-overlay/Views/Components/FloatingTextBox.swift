import SwiftUI

struct FloatingTextBox: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        // Design Token Colors
        let textColor = colorScheme == .dark ? Color(red: 229/255, green: 226/255, blue: 225/255) : Color(red: 26/255, green: 26/255, blue: 26/255)
        let borderColor = colorScheme == .dark ? Color(red: 34/255, green: 34/255, blue: 34/255) : Color(red: 229/255, green: 229/255, blue: 229/255)
        let containerBg = colorScheme == .dark ? Color(red: 14/255, green: 14/255, blue: 14/255) : Color(red: 249/255, green: 249/255, blue: 251/255)
        
        VStack(spacing: 4) {
            HStack(spacing: 0) {
                // Monospaced text input area with sharp edges
                TextField("Prompt an Antigravity...", text: $appState.currentInputText, axis: .vertical)
                    .font(.system(.body, design: .monospaced))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.clear)
                    .lineLimit(1...5)
                    .disabled(appState.isWaitingForResponse)
                
                // Solid, sharp SENDEN_ Button
                Button(action: {
                    let prompt = appState.currentInputText.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !prompt.isEmpty {
                        appState.currentInputText = ""
                        // Append locally immediately for instant feedback
                        appState.chatMessages.append(Message(sender: .user, content: prompt, toolName: nil, timestamp: Date()))
                        sendPromptToServer(prompt: prompt)
                    }
                }) {
                    HStack(spacing: 4) {
                        if appState.isWaitingForResponse {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: colorScheme == .dark ? .black : .white))
                                .scaleEffect(0.8)
                        } else {
                            Text("SENDEN_")
                                .font(.system(.caption, design: .monospaced))
                                .fontWeight(.bold)
                            Image(systemName: "arrow.up")
                                .font(.system(size: 12, weight: .bold))
                        }
                    }
                    .foregroundColor(colorScheme == .dark ? .black : .white)
                    .frame(maxHeight: .infinity)
                    .padding(.horizontal, 16)
                    .background(colorScheme == .dark ? Color.white : Color.black)
                }
                .disabled(appState.isWaitingForResponse || appState.currentInputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .frame(height: 48)
            .background(containerBg)
            .overlay(
                Rectangle()
                    .stroke(borderColor, lineWidth: 1)
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
            
            // Minimal disclaimer text at the very bottom
            Text("Antigravity AI kann Fehler machen. Überprüfen Sie wichtige Informationen.")
                .font(.system(size: 8, design: .monospaced))
                .foregroundColor(.secondary)
                .padding(.bottom, 12)
        }
        .background(Color.clear)
    }
    
    private func sendPromptToServer(prompt: String) {
        guard let sessionId = appState.currentSessionId else { 
            print("Keine aktive Session-ID")
            return 
        }
        guard let url = URL(string: "http://\(appState.macServerIP):8080/v1/send") else { return }
        
        appState.isWaitingForResponse = true
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // session_id
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"session_id\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(sessionId)\r\n".data(using: .utf8)!)
        
        // prompt
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"prompt\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(prompt)\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                appState.isWaitingForResponse = false
            }
            
            if let error = error {
                print("Fehler beim Senden des Prompts: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    appState.chatMessages.append(
                        Message(
                            sender: .systemError, 
                            content: "Senden fehlgeschlagen: \(error.localizedDescription)", 
                            toolName: nil, 
                            timestamp: Date()
                        )
                    )
                }
                return
            }
            
            // Backend-Antwort prüfen
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                DispatchQueue.main.async {
                    appState.chatMessages.append(
                        Message(
                            sender: .systemError, 
                            content: "Fehler vom Server: Statuscode \(httpResponse.statusCode)", 
                            toolName: nil, 
                            timestamp: Date()
                        )
                    )
                }
            }
        }.resume()
    }
}

struct FloatingTextBox_Previews: PreviewProvider {
    static var previews: some View {
        FloatingTextBox()
            .environmentObject(AppState())
            .background(Color(red: 15/255, green: 15/255, blue: 15/255))
    }
}
