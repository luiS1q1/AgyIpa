import SwiftUI

@main
struct agy_overlayApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            MainOverlayView()
                .environmentObject(appState)
        }
    }
}
