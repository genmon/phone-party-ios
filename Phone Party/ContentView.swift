import SwiftUI

struct CircleData {
    var id = UUID()
    var color: Color
    var position: CGPoint
}

struct ContentView: View {
    @StateObject var webSocketManager = WebSocketManager()

    var body: some View {
        TabView {
            CirclesView(webSocketManager: webSocketManager)
                .tabItem {
                    Label("Circles", systemImage: "circle")
                }
            
            DebugView(webSocketManager: webSocketManager)
                .tabItem {
                    Label("Debug", systemImage: "ant")
                }
        }
        .onAppear {
            webSocketManager.connect()
        }
        .onDisappear {
            webSocketManager.disconnect()
        }
    }
}

struct CirclesView: View {
    @ObservedObject var webSocketManager: WebSocketManager
    @State private var circles: [CircleData] = []

    var body: some View {
        ZStack {
            // Gesture recognizer covers the entire screen
            Color.clear
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onEnded { value in
                            let xCoordinate = value.location.x / UIScreen.main.bounds.width
                            let yCoordinate = value.location.y / UIScreen.main.bounds.height
                            let color = Color.randomPastel()
                            
                            let message: [String: Any] = [
                                "type": "circle",
                                "px": xCoordinate,
                                "py": yCoordinate,
                                "color": ColorUtils.colorToString(color)
                            ]

                            if let jsonData = try? JSONSerialization.data(withJSONObject: message, options: .prettyPrinted),
                               let jsonString = String(data: jsonData, encoding: .utf8) {
                                webSocketManager.send(message: jsonString)
                            }

                            addCircle(at: value.location, color: color)
                        }
                )

            VStack {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("Hello, world!")
            }
            .padding()

            // Render circles
            ForEach(circles, id: \.id) { circle in
                CircleView(circle: circle)
                    .onDisappear {
                        circles.removeAll { $0.id == circle.id }
                    }
            }
        }
        // Observe changes in receivedCircleData
        .onChange(of: webSocketManager.receivedCircleData) { newData in
            if let data = newData {
                let screenWidth = UIScreen.main.bounds.width
                let screenHeight = UIScreen.main.bounds.height
                let xPosition = data.x * screenWidth
                let yPosition = data.y * screenHeight
                let color = data.color
                
                print("Adding circle at normalized coordinates (\(data.x), \(data.y)), which is (\(xPosition), \(yPosition)) on screen")

                addCircle(at: CGPoint(x: xPosition, y: yPosition), color: color)
            }
        }
    }

    private func addCircle(at position: CGPoint, color: Color) {
        let newCircle = CircleData(color: color, position: position)
        circles.append(newCircle)
        removeCircleDelayed(circleID: newCircle.id)
    }

    private func removeCircleDelayed(circleID: UUID) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                circles.removeAll { $0.id == circleID }
            }
        }
    }
}

struct CircleView: View {
    let circle: CircleData

    var body: some View {
        Circle()
            .fill(circle.color)
            .frame(width: UIScreen.main.bounds.width * 0.2, height: UIScreen.main.bounds.width * 0.2)
            .position(circle.position)
            .transition(.opacity)
            .allowsHitTesting(false) // Ignore touch events
    }
}

extension Color {
    static func randomPastel() -> Color {
        let hue = Double.random(in: 0...1)
        let saturation: Double = 0.6 // Pastel-like saturation
        let brightness: Double = 0.9 // Bright enough to appear pastel
        return Color(hue: hue, saturation: saturation, brightness: brightness)
    }
}

struct DebugView: View {
    @ObservedObject var webSocketManager: WebSocketManager

    var body: some View {
        VStack {
            Button("Send Ping") {
                webSocketManager.send(message: "ping")
            }

            Text("Last received message: \(webSocketManager.lastReceivedMessage)")
            Text("Received at: \(webSocketManager.lastReceivedTime)")
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
