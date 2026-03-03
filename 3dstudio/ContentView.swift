import SwiftUI

struct ContentView: View {
    @State private var showingScanner = false
    @State private var showingARStudio = false
    @State private var showingSettings = false
    @State private var selectedRoomID: Int? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                // Background Gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "001A33"), // Darker Deep Blue
                        Color(hex: "003366")  // Deep Blue
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // Decorative elements
                Circle()
                    .fill(Color(hex: "FF6F00").opacity(0.15)) // Safety Orange Glow
                    .frame(width: 300, height: 300)
                    .blur(radius: 50)
                    .offset(x: -100, y: -200)

                Circle()
                    .fill(Color(hex: "0055A4").opacity(0.2)) // Lighter blue glow
                    .frame(width: 250, height: 250)
                    .blur(radius: 40)
                    .offset(x: 150, y: 250)

                VStack(spacing: 40) {
                    Spacer()

                    // Title Section
                    VStack(spacing: 8) {
                        Image(systemName: "cube.transparent.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.white, Color(hex: "FF6F00")],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: Color(hex: "FF6F00").opacity(0.5), radius: 10, x: 0, y: 5)

                        Text("3D Studio")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(radius: 5)

                        Text("Scan QR to enter a studio room")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.8))
                    }

                    Spacer()

                    // Action Button
                    Button {
                        showingScanner = true
                    } label: {
                        HStack {
                            Image(systemName: "qrcode.viewfinder")
                                .font(.title)
                            Text("Scan Studio QR")
                                .font(.title2.bold())
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color(hex: "FF6F00")) // Safety Orange
                                .shadow(color: Color(hex: "FF6F00").opacity(0.5), radius: 15, x: 0, y: 8)
                        )
                        .foregroundColor(.white)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 10)

                    Spacer()
                        .frame(height: 40)
                }
            }
            .navigationDestination(isPresented: $showingARStudio) {
                if let roomID = selectedRoomID {
                    ARStudioView(roomID: roomID)
                }
            }
            .sheet(isPresented: $showingScanner) {
                QRScannerView(scannedRoomID: $selectedRoomID, showingARStudio: $showingARStudio)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.title3)
                            .foregroundColor(Color(hex: "FF6F00"))
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
        .preferredColorScheme(.dark)
    }
}

// Extension for Hex Colors to support the theme
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    ContentView()
}
