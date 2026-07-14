import SwiftUI
import Combine

class AppState: ObservableObject {
    @Published var currentSessionId: String? = nil
    @Published var screenshotImage: UIImage? = nil
    @Published var isConnected: Bool = false
    @Published var chatMessages: [Message] = []
    @Published var isWaitingForResponse: Bool = false
    @Published var currentInputText: String = ""
    
    // IP-Adresse des macOS-Servers. Bitte bei Bedarf anpassen.
    let macServerIP: String = "192.168.178.50"
}
