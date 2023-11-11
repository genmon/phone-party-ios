import Foundation
import SwiftUI

struct ReceivedCircleData: Equatable {
    var x: CGFloat
    var y: CGFloat
    var color: Color
}

class WebSocketManager: NSObject, ObservableObject {
    private var webSocketTask: URLSessionWebSocketTask?
    @Published var lastReceivedMessage: String = ""
    @Published var lastReceivedTime: String = ""
    @Published var receivedCircleData: ReceivedCircleData?

    func connect() {
        let url = URL(string: "wss://phone-party.genmon.partykit.dev/party/default")!
        let urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
        webSocketTask = urlSession.webSocketTask(with: url)
        webSocketTask?.resume()
        listen()
    }

    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
    }

    func send(message: String) {
        webSocketTask?.send(URLSessionWebSocketTask.Message.string(message)) { error in
            if let error = error {
                print("WebSocket couldn’t send message because: \(error)")
            }
        }
    }

    private func listen() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .failure(let error):
                print("Error in receiving message: \(error)")
            case .success(let message):
                switch message {
                case .string(let text):
                    DispatchQueue.main.async {
                        self?.lastReceivedMessage = text
                        self?.lastReceivedTime = self?.getCurrentTimeString() ?? ""
                        self?.parseReceivedMessage(text)
                    }
                default:
                    break
                }

                self?.listen() // Listen for the next message
            }
        }
    }
    
    private func getCurrentTimeString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: Date())
    }
    
    private func parseReceivedMessage(_ message: String) {
        print("Received message: \(message)")

        guard let data = message.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            print("Failed to convert message to JSON")
            return
        }

        print("Converted JSON: \(json)")

        guard let type = json["type"] as? String,
              type == "circle",
              let px = json["px"] as? CGFloat,
              let py = json["py"] as? CGFloat,
              let colorString = json["color"] as? String,
              let color = ColorUtils.stringToColor(colorString) else {
            print("JSON does not contain valid 'circle' data")
            return
        }

        print("Parsed circle data: (px: \(px), py: \(py), color: \(colorString))")

        self.receivedCircleData = ReceivedCircleData(x: px, y: py, color: color)
    }
}

extension WebSocketManager: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("WebSocket connected")
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("WebSocket disconnected")
        // Handle reconnection logic here
    }
}
