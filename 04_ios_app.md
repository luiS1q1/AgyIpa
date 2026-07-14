# 04. iOS SwiftUI App

### Models/AppState.swift
import SwiftUI
class AppState: ObservableObject {
    @Published var currentSessionId: String? = nil
    @Published var screenshotImage: UIImage? = nil
    @Published var isConnected: Bool = false
    @Published var chatMessages: [Message] = []
    @Published var isWaitingForResponse: Bool = false
    @Published var currentInputText: String = ""
    let macServerIP: String = "192.168.178.50"
}

### Services/WebSocketManager.swift
import Foundation
struct LogPayload: Decodable { let type: String; let content: String?; let tool: String? }
class WebSocketManager {
    private var webSocketTask: URLSessionWebSocketTask?
    private let appState: AppState
    init(appState: AppState) { self.appState = appState }
    func connect(sessionId: String) {
        guard let url = URL(string: "ws://\(appState.macServerIP):8000/v1/stream/\(sessionId)") else { return }
        webSocketTask = URLSession.shared.webSocketTask(with: url)
        webSocketTask?.resume()
        DispatchQueue.main.async { self.appState.isConnected = true }
        listen()
    }
    private func listen() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure: DispatchQueue.main.async { self.appState.isConnected = false }
            case .success(let msg):
                if case .string(let text) = msg { self.parse(text: text) }
                self.listen()
            }
        }
    }
    private func parse(text: String) {
        guard let data = text.data(using: .utf8) else { return }
        if let p = try? JSONDecoder().decode(LogPayload.self, from: data) {
            DispatchQueue.main.async {
                let sender = MessageSender(rawValue: p.type) ?? .systemError
                if sender == .assistant, let last = self.appState.chatMessages.indices.last, self.appState.chatMessages[last].sender == .assistant {
                    let old = self.appState.chatMessages[last]
                    self.appState.chatMessages[last] = Message(sender: .assistant, content: old.content + (p.content ?? ""), toolName: nil, timestamp: Date())
                } else {
                    self.appState.chatMessages.append(Message(sender: sender, content: p.content ?? "", toolName: p.tool, timestamp: Date()))
                }
            }
        }
    }
}

### Views/MainOverlayView.swift
import SwiftUI
struct MainOverlayView: View {
    @EnvironmentObject var appState: AppState
    @State private var wsManager: WebSocketManager?
    var body: some View {
        ZStack {
            if let img = appState.screenshotImage { Image(uiImage: img).resizable().aspectRatio(contentMode: .fill).ignoresSafeArea() }
            Rectangle().fill(.ultraThinMaterial).ignoresSafeArea()
            VStack {
                TranscriptStreamView()
                FloatingTextBox()
            }
        }
        .onAppear { self.wsManager = WebSocketManager(appState: appState) }
        .onOpenURL { url in
            guard url.scheme == "myassistant" else { return }
            let id = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "id" })?.value ?? ""
            appState.currentSessionId = id
            wsManager?.connect(sessionId: id)
            // Async Image Download von http://[MAC_IP]:8000/storage/screenshots/\(id).png hier einfügen
        }
    }
}
