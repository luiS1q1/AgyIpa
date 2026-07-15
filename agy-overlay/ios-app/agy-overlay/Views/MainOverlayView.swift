import SwiftUI

struct MainOverlayView: View {
    @EnvironmentObject var appState: AppState
    @State private var wsManager: WebSocketManager?
    
    var body: some View {
        ZStack {
            // Hintergrundbild: Zeige den Screenshot an
            if let img = appState.screenshotImage {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
                VStack(spacing: 20) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    Text("Lade Screenshot...")
                        .foregroundColor(.white)
                        .font(.headline)
                }
            }
            
            // Blur-Overlay (ultra-thin material)
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            
            VStack {
                // Verbindungsstatus-Indikator
                HStack {
                    Circle()
                        .fill(appState.isConnected ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
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
                .padding(.top, 10)
                
                // Stream der Log-Nachrichten
                TranscriptStreamView()
                
                // Text-Eingabefeld am unteren Rand
                FloatingTextBox()
            }
        }
        .onAppear {
            self.wsManager = WebSocketManager(appState: appState)
        }
        .onOpenURL { url in
            guard url.scheme == "myassistant" else { return }
            
            let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
            let id = queryItems?.first(where: { $0.name == "id" })?.value ?? ""
            
            guard !id.isEmpty else { return }
            
            appState.currentSessionId = id
            
            // Verbindung trennen falls bereits eine läuft
            wsManager?.disconnect()
            
            // WebSocket-Verbindung aufbauen
            wsManager?.connect(sessionId: id)
            
            // Async Image Download von http://[MAC_IP]:8000/storage/screenshots/\(id).png
            downloadScreenshot(id: id)
        }
    }
    
    private func downloadScreenshot(id: String) {
        guard let url = URL(string: "http://\(appState.macServerIP):8080/storage/screenshots/\(id).png") else { 
            print("Ungültige Screenshot-URL")
            return 
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Fehler beim Herunterladen des Screenshots: \(error.localizedDescription)")
                return
            }
            
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.appState.screenshotImage = image
                }
            }
        }.resume()
    }
}

struct MainOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        MainOverlayView()
            .environmentObject(AppState())
    }
}
