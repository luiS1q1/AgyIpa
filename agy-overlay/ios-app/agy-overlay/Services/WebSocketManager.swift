import Foundation

struct LogPayload: Decodable {
    let type: String
    let content: String?
    let tool: String?
}

class WebSocketManager {
    private var webSocketTask: URLSessionWebSocketTask?
    private let appState: AppState
    
    init(appState: AppState) {
        self.appState = appState
    }
    
    func connect(sessionId: String) {
        guard let url = URL(string: "ws://\(appState.macServerIP):8080/v1/stream/\(sessionId)") else { 
            print("Ungültige WebSocket-URL")
            return 
        }
        webSocketTask = URLSession.shared.webSocketTask(with: url)
        webSocketTask?.resume()
        
        DispatchQueue.main.async { 
            self.appState.isConnected = true 
        }
        listen()
    }
    
    func startSessionAndConnect(sessionId: String, isDirectChat: Bool) {
        if !isDirectChat {
            self.connect(sessionId: sessionId)
            return
        }
        
        guard let url = URL(string: "http://\(appState.macServerIP):8080/v1/trigger") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"session_id\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(sessionId)\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("Fehler beim Initialisieren der Chat-Session: \(error.localizedDescription)")
                return
            }
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                DispatchQueue.main.async {
                    self?.connect(sessionId: sessionId)
                }
            } else {
                print("Server-Fehler bei Initialisierung.")
            }
        }.resume()
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        DispatchQueue.main.async {
            self.appState.isConnected = false
        }
    }
    
    private func listen() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                print("WebSocket-Fehler beim Empfangen: \(error)")
                DispatchQueue.main.async { 
                    self.appState.isConnected = false 
                }
            case .success(let msg):
                if case .string(let text) = msg { 
                    self.parse(text: text) 
                }
                self.listen()
            }
        }
    }
    
    private func parse(text: String) {
        guard let data = text.data(using: .utf8) else { return }
        if let p = try? JSONDecoder().decode(LogPayload.self, from: data) {
            DispatchQueue.main.async {
                let sender = MessageSender(rawValue: p.type) ?? .systemError
                
                // Stream-Antworten des Assistenten zusammenführen, falls nacheinander gesendet
                if sender == .assistant, 
                   let last = self.appState.chatMessages.indices.last, 
                   self.appState.chatMessages[last].sender == .assistant {
                    let old = self.appState.chatMessages[last]
                    self.appState.chatMessages[last] = Message(
                        sender: .assistant, 
                        content: old.content + (p.content ?? ""), 
                        toolName: nil, 
                        timestamp: Date()
                    )
                } else {
                    self.appState.chatMessages.append(
                        Message(
                            sender: sender, 
                            content: p.content ?? "", 
                            toolName: p.tool, 
                            timestamp: Date()
                        )
                    )
                }
            }
        }
    }
}
