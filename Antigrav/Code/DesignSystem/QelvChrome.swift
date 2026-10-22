import SwiftUI
import UIKit

extension Color {
    static let qelvVoid = Color(red: 14 / 255, green: 13 / 255, blue: 18 / 255)
    static let qelvBloom = Color(red: 139 / 255, green: 48 / 255, blue: 156 / 255)
    static let qelvMint = Color(red: 36 / 255, green: 207 / 255, blue: 164 / 255)
    static let qelvSlab = Color(red: 23 / 255, green: 21 / 255, blue: 30 / 255)
    static let qelvLift = Color(red: 33 / 255, green: 30 / 255, blue: 43 / 255)
    static let qelvLine = Color(red: 46 / 255, green: 42 / 255, blue: 59 / 255)
    static let qelvPaper = Color.white
    static let qelvMist = Color(red: 162 / 255, green: 157 / 255, blue: 176 / 255)
    static let qelvAlarm = Color(red: 240 / 255, green: 85 / 255, blue: 106 / 255)
}

enum QelvPulse {
    static func tap(_ on: Bool) {
        guard on else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    static func pick(_ on: Bool) {
        guard on else { return }
        UISelectionFeedbackGenerator().selectionChanged()
    }
    static func win(_ on: Bool) {
        guard on else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    static func warn(_ on: Bool) {
        guard on else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}

struct QelvPress: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                Capsule()
                    .fill(LinearGradient(colors: [Color.qelvBloom, Color.qelvMint], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .shadow(color: Color.qelvBloom.opacity(configuration.isPressed ? 0.2 : 0.45), radius: configuration.isPressed ? 4 : 12, y: 4)
            }
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct QelvQuietPress: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                Capsule()
                    .fill(Color.qelvLift)
                    .overlay(Capsule().stroke(Color.qelvLine, lineWidth: 1))
            }
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct QelvCardMod: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(colors: [Color.qelvLift, Color.qelvSlab], startPoint: .top, endPoint: .bottom)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.qelvLine, lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.28), radius: 8, y: 5)
            }
    }
}

struct QelvBackdrop: ViewModifier {
    var imageName: String?
    var imageOpacity: Double = 0.4

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                Color.qelvVoid
                    .overlay {
                        if let imageName {
                            Image(imageName)
                                .resizable()
                                .scaledToFill()
                                .opacity(imageOpacity)
                        }
                    }
                    .overlay(alignment: .top) {
                        LinearGradient(colors: [Color.qelvBloom.opacity(0.28), .clear], startPoint: .top, endPoint: .bottom)
                            .frame(height: 180)
                            .frame(maxWidth: .infinity)
                            .allowsHitTesting(false)
                    }
                    .clipped()
                    .ignoresSafeArea()
            }
    }
}

extension View {
    func qelvScreen(image: String? = nil, opacity: Double = 0.38) -> some View {
        modifier(QelvBackdrop(imageName: image, imageOpacity: opacity))
    }
    func qelvCard() -> some View { modifier(QelvCardMod()) }
    func qelvKeysAway() -> some View {
        simultaneousGesture(TapGesture().onEnded {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        })
    }
}

struct QelvGradientButton: View {
    var title: String
    var action: () -> Void
    @EnvironmentObject private var vault: QelvOrbitVault
    var body: some View {
        Button {
            QelvPulse.tap(vault.blob.profile.haptics)
            action()
        } label: {
            Text(title)
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.qelvPaper)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
        }
        .buttonStyle(QelvPress())
        .accessibilityLabel(title)
    }
}

struct QelvMintButton: View {
    var title: String
    var action: () -> Void
    @EnvironmentObject private var vault: QelvOrbitVault
    var body: some View {
        Button {
            QelvPulse.tap(vault.blob.profile.haptics)
            action()
        } label: {
            Text(title)
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.qelvMint)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
        }
        .buttonStyle(QelvQuietPress())
        .accessibilityLabel(title)
    }
}

struct QelvCountUp: View, Animatable {
    var value: Double
    var animatableData: Double {
        get { value }
        set { value = newValue }
    }
    var body: some View {
        Text("\(Int(value.rounded()))").monospacedDigit()
    }
}

struct QelvRolling: View {
    var value: Int
    var font: Font = .system(.title, design: .rounded).weight(.bold)
    @EnvironmentObject private var vault: QelvOrbitVault
    @State private var shown = 0.0
    var body: some View {
        QelvCountUp(value: shown)
            .font(font)
            .foregroundStyle(Color.qelvPaper)
            .onAppear { roll() }
            .onChange(of: value) { _ in roll() }
    }
    private func roll() {
        if vault.motionQuiet { shown = Double(value) }
        else {
            shown = 0
            withAnimation(.easeOut(duration: 0.6)) { shown = Double(value) }
        }
    }
}

struct QelvRing: View {
    var progress: Double
    var tint: Color = .qelvMint
    var body: some View {
        ZStack {
            Circle().stroke(Color.qelvLine, lineWidth: 8)
            Circle()
                .trim(from: 0, to: min(1, max(0, progress)))
                .stroke(tint, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: tint.opacity(0.45), radius: 6)
        }
    }
}

struct QelvBodyMap: View {
    var primary: [String]
    var secondary: [String]
    var front: Bool

    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            func blob(_ rect: CGRect, _ name: String) {
                let hot = primary.contains(name)
                let warm = secondary.contains(name)
                let color: Color = hot ? .qelvMint : (warm ? .qelvBloom : .qelvLine)
                context.fill(Path(roundedRect: rect, cornerRadius: min(rect.width, rect.height) * 0.4), with: .color(color))
            }
            blob(CGRect(x: w * 0.38, y: h * 0.04, width: w * 0.24, height: h * 0.12), "head")
            if front {
                blob(CGRect(x: w * 0.32, y: h * 0.18, width: w * 0.36, height: h * 0.22), "chest")
                blob(CGRect(x: w * 0.34, y: h * 0.4, width: w * 0.32, height: h * 0.16), "abs")
                blob(CGRect(x: w * 0.18, y: h * 0.2, width: w * 0.12, height: h * 0.12), "shoulders")
                blob(CGRect(x: w * 0.7, y: h * 0.2, width: w * 0.12, height: h * 0.12), "shoulders")
                blob(CGRect(x: w * 0.14, y: h * 0.32, width: w * 0.1, height: h * 0.16), "biceps")
                blob(CGRect(x: w * 0.76, y: h * 0.32, width: w * 0.1, height: h * 0.16), "biceps")
                blob(CGRect(x: w * 0.3, y: h * 0.58, width: w * 0.16, height: h * 0.22), "quads")
                blob(CGRect(x: w * 0.54, y: h * 0.58, width: w * 0.16, height: h * 0.22), "quads")
            } else {
                blob(CGRect(x: w * 0.3, y: h * 0.18, width: w * 0.4, height: h * 0.22), "back")
                blob(CGRect(x: w * 0.34, y: h * 0.42, width: w * 0.32, height: h * 0.12), "glutes")
                blob(CGRect(x: w * 0.16, y: h * 0.22, width: w * 0.12, height: h * 0.1), "shoulders")
                blob(CGRect(x: w * 0.72, y: h * 0.22, width: w * 0.12, height: h * 0.1), "shoulders")
                blob(CGRect(x: w * 0.12, y: h * 0.34, width: w * 0.1, height: h * 0.14), "triceps")
                blob(CGRect(x: w * 0.78, y: h * 0.34, width: w * 0.1, height: h * 0.14), "triceps")
                blob(CGRect(x: w * 0.32, y: h * 0.56, width: w * 0.14, height: h * 0.2), "hamstrings")
                blob(CGRect(x: w * 0.54, y: h * 0.56, width: w * 0.14, height: h * 0.2), "hamstrings")
            }
            blob(CGRect(x: w * 0.34, y: h * 0.8, width: w * 0.1, height: h * 0.14), "calves")
            blob(CGRect(x: w * 0.56, y: h * 0.8, width: w * 0.1, height: h * 0.14), "calves")
        }
        .frame(height: 220)
        .accessibilityLabel(front ? "Front body map" : "Back body map")
    }
}
