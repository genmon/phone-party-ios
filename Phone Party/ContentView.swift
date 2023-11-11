import SwiftUI

struct CircleData {
    var id = UUID()
    var color: Color
    var position: CGPoint
}

struct ContentView: View {
    var body: some View {
        TabView {
            CirclesView()
                .tabItem {
                    Label("Circles", systemImage: "circle")
                }
            
            DebugView()
                .tabItem {
                    Label("Debug", systemImage: "ant")
                }
        }
    }
}

struct CirclesView: View {
    @State private var circles: [CircleData] = []

    var body: some View {
        ZStack {
            // Gesture recognizer covers the entire screen
            Color.clear
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onEnded { value in
                            let newCircle = CircleData(color: Color.randomPastel(), position: value.location)
                            circles.append(newCircle)
                            removeCircleDelayed(circleID: newCircle.id)
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
    @ObservedObject var webSocketManager = WebSocketManager()

    var body: some View {
        VStack {
            Button("Send Ping") {
                webSocketManager.send(message: "ping")
            }

            Text("Last received message: \(webSocketManager.lastReceivedMessage)")
            Text("Received at: \(webSocketManager.lastReceivedTime)")
        }
        .onAppear {
            webSocketManager.connect()
        }
        .onDisappear {
            webSocketManager.disconnect()
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
