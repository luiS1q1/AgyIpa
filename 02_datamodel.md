# 02. Datenmodell
Backend State:
ACTIVE_SESSIONS: dict[str, dict] = {}

Frontend State (Swift):
enum MessageSender: String, Codable {
    case user = "USER_INPUT"
    case assistant = "ASSISTANT_RESPONSE"
    case tool = "TOOL_CALL"
    case toolResponse = "TOOL_RESPONSE"
    case systemError = "ERROR"
}
struct Message: Identifiable, Equatable {
    let id = UUID()
    let sender: MessageSender
    let content: String
    let toolName: String?
    let timestamp: Date
}
