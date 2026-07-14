import SwiftUI

struct FloatingTextBox: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack {
            HStack(spacing: 12) {
                TextField("Prompt an Antigravity...", text: $appState.currentInputText, axis: .vertical)
                    .font(.body)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemBackground).opacity(0.9))
                    .cornerRadius(24)
                    .lineLimit(1...5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.primary.opacity(0.15), lineWidth: 1)
                    )
                    .disabled(appState.isWaitingForResponse)
                
                Button(action: {
                    let prompt = appState.currentInputText.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !prompt.isEmpty {
                        appState.currentInputText = ""
                        sendPromptToServer(prompt: prompt)
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(appState.isWaitingForResponse ? Color.secondary : Color.blue)
                            .frame(width: 48, height: 48)
                        
                        if appState.isWaitingForResponse {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .disabled(appState.isWaitingForResponse || appState.currentInputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                VisualEffectBlur(material: .systemChromeMaterial, blendingMode: .withinWindow)
                    .cornerRadius(32)
                    .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
            )
        }
        .padding(.horizontal)
        .padding(.bottom, 16)
    }
    
    private func sendPromptToServer(prompt: String) {
        guard let sessionId = appState.currentSessionId else { 
            print("Keine aktive Session-ID")
            return 
        }
        guard let url = URL(string: "http://\(appState.macServerIP):8000/v1/send") else { return }
        
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

// SwiftUI-Hilfsklasse für UIVisualEffectView (Blur-Effekt)
struct VisualEffectBlur: UIViewRepresentable {
    var material: UIBlurEffect.Material
    var blendingMode: UIVisualEffectView.BlendingMode
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: material))
        return view
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: material)
    }
}
