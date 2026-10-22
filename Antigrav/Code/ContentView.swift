import SwiftUI

enum QelvPath: Hashable {
    case move(String)
    case program(String)
    case skills
    case test(String)
    case altitude
    case badges
    case challenge
    case recap
    case settings
    case builder
    case timer
}

struct ContentView: View {
    @StateObject private var vault = QelvOrbitVault()
    var body: some View {
        Group {
            if vault.blob.profile.onboarded {
                QelvTabShell()
            } else {
                OrryxOnboard()
            }
        }
        .environmentObject(vault)
        .preferredColorScheme(.dark)
        .onAppear { vault.qelvWake() }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            vault.qelvWake()
        }
    }
}

struct QelvTabShell: View {
    @EnvironmentObject private var vault: QelvOrbitVault
    @State private var tab = 0
    @Namespace private var pill
    private let titles = ["Today", "Train", "Skills", "Progress", "Profile"]

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                if tab == 0 { NavigationStack { OrryxTodayDeck() }.qelvRoutes() }
                else if tab == 1 { NavigationStack { BrantixTrainBay() }.qelvRoutes() }
                else if tab == 2 { NavigationStack { SeluneSkillMap() }.qelvRoutes() }
                else if tab == 3 { NavigationStack { VaskProgressAtlas() }.qelvRoutes() }
                else { NavigationStack { NyrelProfileNook() }.qelvRoutes() }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            HStack(spacing: 0) {
                ForEach(titles.indices, id: \.self) { index in
                    Button {
                        QelvPulse.tap(vault.blob.profile.haptics)
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) { tab = index }
                    } label: {
                        Text(titles[index])
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(tab == index ? Color.qelvVoid : Color.qelvMist)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background {
                                if tab == index {
                                    Capsule()
                                        .fill(LinearGradient(colors: [Color.qelvMint, Color.qelvBloom], startPoint: .leading, endPoint: .trailing))
                                        .matchedGeometryEffect(id: "qelvPill", in: pill)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(titles[index])
                }
            }
            .padding(6)
            .background {
                Capsule().fill(Color.qelvSlab).shadow(color: Color.qelvBloom.opacity(0.35), radius: 12, y: 4)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .sheet(item: $vault.toast) { note in
            QelvToastSheet(note: note)
        }
        .fullScreenCover(isPresented: Binding(get: { vault.levelUp != nil }, set: { if !$0 { vault.levelUp = nil } })) {
            QelvLevelCover()
                .environmentObject(vault)
        }
    }
}

extension View {
    func qelvRoutes() -> some View {
        navigationDestination(for: QelvPath.self) { path in
            switch path {
            case .move(let id): BrantixMoveDetail(moveId: id)
            case .program(let id): BrantixProgramDetail(programId: id)
            case .skills: SeluneSkillMap()
            case .test(let id): SeluneTestLab(movementId: id)
            case .altitude: VaskAltitudeMap()
            case .badges: VaskBadgeGrid()
            case .challenge: OrryxChallengeSheet()
            case .recap: VaskMonthRecap()
            case .settings: NyrelSettingsPane()
            case .builder: BrantixBuilder()
            case .timer: BrantixIntervalTimer()
            }
        }
    }
}

private struct QelvToastHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

struct QelvToastSheet: View {
    @EnvironmentObject private var vault: QelvOrbitVault
    var note: QelvToast
    @State private var height: CGFloat = 210

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(note.title)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(Color.qelvPaper)
                .fixedSize(horizontal: false, vertical: true)
            Text(note.detail)
                .foregroundStyle(Color.qelvMist)
                .fixedSize(horizontal: false, vertical: true)
            if note.canUndo {
                TimelineView(.periodic(from: Date(), by: 1)) { timeline in
                    if let deadline = vault.qelvUndoDeadline(), timeline.date < deadline {
                        QelvMintButton(title: "Undo save") { vault.qelvUndoLast() }
                    }
                }
            }
            QelvGradientButton(title: "Close") { vault.toast = nil }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .background {
            GeometryReader { proxy in
                Color.qelvVoid.preference(key: QelvToastHeightKey.self, value: proxy.size.height)
            }
        }
        .onPreferenceChange(QelvToastHeightKey.self) { value in
            guard value > 80, value < 460, abs(value - height) > 1 else { return }
            height = value
        }
        .qelvToastDetent(height)
    }
}

private extension View {
    @ViewBuilder
    func qelvToastDetent(_ height: CGFloat) -> some View {
        if #available(iOS 16.4, *) {
            self.presentationDetents([.height(height)])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color.qelvVoid)
        } else {
            self.presentationDetents([.height(height)])
                .presentationDragIndicator(.visible)
        }
    }
}

struct QelvLevelCover: View {
    @EnvironmentObject private var vault: QelvOrbitVault
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("New level")
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .foregroundStyle(Color.qelvPaper)
            if let level = vault.levelUp {
                QelvRolling(value: level, font: .system(size: 64, weight: .bold, design: .rounded))
                Text(QelvAltitude.zone(for: level))
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.qelvMint)
                Text(QelvAltitude.zoneLine(QelvAltitude.zone(for: level)))
                    .foregroundStyle(Color.qelvMist)
                    .fixedSize(horizontal: false, vertical: true)
            }
            QelvGradientButton(title: "Continue") {
                vault.levelUp = nil
                dismiss()
            }
        }
        .padding(24)
        .qelvScreen(image: "level_up_banner", opacity: 0.55)
    }
}

struct QelvPlanBox: Identifiable {
    var id = UUID().uuidString
    var plan: QelvCardPlan
    var source: String
}
