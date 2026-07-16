import SwiftUI

enum ChatItem: Identifiable, Equatable {
    case user(Message)
    case assistant(Message, thinking: [Message])
    case systemError(Message)
    
    var id: UUID {
        switch self {
        case .user(let m): return m.id
        case .assistant(let m, _): return m.id
        case .systemError(let m): return m.id
        }
    }
}

struct TranscriptStreamView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    
    // Track expanded thinking traces by session/message ID
    @State private var expandedThinking: Set<UUID> = []
    
    var body: some View {
        let chatItems = getChatItems(from: appState.chatMessages)
        
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if chatItems.isEmpty {
                        VStack(spacing: 12) {
                            Spacer()
                            Image(systemName: "cpu")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            Text("Warte auf Log-Stream...")
                                .font(.system(.subheadline, design: .monospaced))
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, minHeight: 300)
                    } else {
                        ForEach(chatItems) { item in
                            chatRow(for: item)
                                .id(item.id)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .onChange(of: appState.chatMessages) { _ in
                if let lastItem = chatItems.last {
                    withAnimation {
                        proxy.scrollTo(lastItem.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func chatRow(for item: ChatItem) -> some View {
        // Design Token Colors
        let textColor = colorScheme == .dark ? Color(red: 229/255, green: 226/255, blue: 225/255) : Color(red: 26/255, green: 26/255, blue: 26/255)
        let borderColor = colorScheme == .dark ? Color(red: 34/255, green: 34/255, blue: 34/255) : Color(red: 229/255, green: 229/255, blue: 229/255)
        let containerBg = colorScheme == .dark ? Color(red: 27/255, green: 28/255, blue: 28/255) : Color(red: 240/255, green: 240/255, blue: 242/255)
        let userCardBg = colorScheme == .dark ? Color.white : Color.black
        let userCardText = colorScheme == .dark ? Color.black : Color.white
        
        switch item {
        case .user(let message):
            // User Prompt Block: Full-width, high contrast, 0px rounded corners
            VStack(alignment: .leading, spacing: 0) {
                Text(message.content)
                    .font(.custom("Georgia", size: 16))
                    .foregroundColor(userCardText)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(userCardBg)
            }
            .cornerRadius(0)
            
        case .assistant(let message, let thinking):
            VStack(alignment: .leading, spacing: 16) {
                // Collapsible Thinking Section (if thinking is not empty)
                if !thinking.isEmpty {
                    let isExpanded = expandedThinking.contains(message.id)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Button(action: {
                            if isExpanded {
                                expandedThinking.remove(message.id)
                            } else {
                                expandedThinking.insert(message.id)
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "psychology")
                                    .font(.system(size: 14))
                                Text(isExpanded ? "Gedankengang ausblenden_" : "Gedankengang anzeigen_")
                                    .font(.system(.caption, design: .monospaced))
                                    .fontWeight(.bold)
                                Spacer()
                                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 10))
                            }
                            .foregroundColor(textColor)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(containerBg)
                            .overlay(
                                Rectangle()
                                    .stroke(borderColor, lineWidth: 1)
                            )
                        }
                        
                        if isExpanded {
                            // Timeline layout with left border line
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(thinking) { logMsg in
                                    HStack(alignment: .top, spacing: 8) {
                                        let isCall = logMsg.sender == .tool
                                        let isErr = logMsg.sender == .systemError
                                        
                                        Image(systemName: isErr ? "exclamationmark.triangle" : (isCall ? "magnifyingglass" : "chevron.right.square"))
                                            .font(.system(size: 11))
                                            .foregroundColor(isErr ? .red : (isCall ? .blue : .green))
                                            .padding(.top, 2)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(isErr ? "> Error:" : (isCall ? "> Tool Call:" : "> Tool Response:"))
                                                .font(.system(.caption2, design: .monospaced))
                                                .fontWeight(.bold)
                                                .foregroundColor(isErr ? .red : (isCall ? .blue : .green))
                                            
                                            Text(logMsg.content)
                                                .font(.system(.caption, design: .monospaced))
                                                .foregroundColor(textColor.opacity(0.75))
                                        }
                                    }
                                }
                            }
                            .padding(.leading, 12)
                            .border(width: 1, edges: [.leading], color: borderColor)
                            .padding(.leading, 6)
                        }
                    }
                }
                
                // Actual AI Response
                if !message.content.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        // AI Badge (1:1 Square block)
                        HStack(spacing: 8) {
                            Text("AI")
                                .font(.system(.caption2, design: .monospaced))
                                .fontWeight(.bold)
                                .foregroundColor(textColor)
                                .frame(width: 24, height: 24)
                                .background(containerBg)
                                .overlay(
                                    Rectangle()
                                        .stroke(borderColor, lineWidth: 1)
                                )
                            
                            // Model Metadata Tag
                            Text("MODEL: AG-1_")
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(containerBg)
                                .overlay(
                                    Rectangle()
                                        .stroke(borderColor, lineWidth: 1)
                                )
                        }
                        
                        Text(message.content)
                            .font(.custom("Georgia", size: 16))
                            .lineSpacing(6)
                            .foregroundColor(textColor)
                            .padding(.vertical, 8)
                    }
                    .padding(.vertical, 16)
                    .border(width: 1, edges: [.top, .bottom], color: borderColor)
                }
            }
            
        case .systemError(let message):
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundColor(.red)
                    .padding(8)
                    .background(Color.red.opacity(0.15))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("FEHLER_")
                        .font(.system(.caption2, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    
                    Text(message.content)
                        .font(.custom("Georgia", size: 15))
                        .foregroundColor(.red)
                }
            }
            .padding(12)
            .border(Color.red.opacity(0.3), width: 1)
        }
    }
    
    // Group consecutive tool calls into thinking traces
    private func getChatItems(from messages: [Message]) -> [ChatItem] {
        var items: [ChatItem] = []
        var currentThinking: [Message] = []
        
        for message in messages {
            switch message.sender {
            case .user:
                items.append(.user(message))
                currentThinking.removeAll()
            case .tool, .toolResponse:
                currentThinking.append(message)
            case .assistant:
                items.append(.assistant(message, thinking: currentThinking))
                currentThinking.removeAll()
            case .systemError:
                if !currentThinking.isEmpty {
                    currentThinking.append(message)
                } else {
                    items.append(.systemError(message))
                }
            }
        }
        
        // Handle active thinking if uvicorn is still streaming
        if !currentThinking.isEmpty {
            let dummyMsg = Message(sender: .assistant, content: "", toolName: nil, timestamp: Date())
            items.append(.assistant(dummyMsg, thinking: currentThinking))
        }
        
        return items
    }
}

// Border Helper Extension for 1px sharp borders
extension View {
    func border(width: CGFloat, edges: [Edge], color: Color) -> some View {
        overlay(EdgeBorder(width: width, edges: edges).foregroundColor(color))
    }
}

struct EdgeBorder: Shape {
    var width: CGFloat
    var edges: [Edge]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        for edge in edges {
            var x: CGFloat {
                switch edge {
                case .top, .bottom, .leading: return rect.minX
                case .trailing: return rect.maxX - width
                }
            }

            var y: CGFloat {
                switch edge {
                case .top, .leading, .trailing: return rect.minY
                case .bottom: return rect.maxY - width
                }
            }

            var w: CGFloat {
                switch edge {
                case .top, .bottom: return rect.width
                case .leading, .trailing: return width
                }
            }

            var h: CGFloat {
                switch edge {
                case .top, .bottom: return width
                case .leading, .trailing: return rect.height
                }
            }

            path.addRect(CGRect(x: x, y: y, width: w, height: h))
        }
        return path
    }
}

struct TranscriptStreamView_Previews: PreviewProvider {
    static var previews: some View {
        let appState = AppState()
        appState.chatMessages = [
            Message(sender: .user, content: "Kannst du die Performance analysieren?", toolName: nil, timestamp: Date()),
            Message(sender: .tool, content: "Search('latency logs')", toolName: "search", timestamp: Date()),
            Message(sender: .toolResponse, content: "Logs found: 5 spike reports.", toolName: nil, timestamp: Date()),
            Message(sender: .assistant, content: "Hier ist meine Analyse der Logs...", toolName: nil, timestamp: Date())
        ]
        return TranscriptStreamView()
            .environmentObject(appState)
            .background(Color(red: 15/255, green: 15/255, blue: 15/255))
    }
}
