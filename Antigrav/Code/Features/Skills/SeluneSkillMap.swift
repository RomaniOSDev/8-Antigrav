import SwiftUI
import Combine

struct SeluneSkillMap: View {
    @EnvironmentObject private var vault: QelvOrbitVault
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Skills")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .foregroundStyle(Color.qelvPaper)
                HStack {
                    ForEach(QelvCatalog.book.paths) { path in
                        let done = path.nodes.filter { vault.blob.skills[$0.id] != nil }.count
                        VStack {
                            QelvRing(progress: Double(done) / Double(path.nodes.count))
                                .frame(width: 36, height: 36)
                            Text(path.name).font(.caption2).foregroundStyle(Color.qelvMist).fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                ForEach(QelvCatalog.book.paths) { path in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(path.name).font(.headline).foregroundStyle(Color.qelvPaper)
                        Text(path.summary).font(.footnote).foregroundStyle(Color.qelvMist).fixedSize(horizontal: false, vertical: true)
                        ForEach(Array(path.nodes.enumerated()), id: \.element.id) { index, node in
                            let open = vault.qelvNodeOpen(node, path: path)
                            let unlocked = vault.blob.skills[node.id] != nil
                            NavigationLink(value: QelvPath.test(node.id)) {
                                HStack(alignment: .top) {
                                    Circle().fill(unlocked ? Color.qelvMint : (open ? Color.qelvBloom : Color.qelvLine)).frame(width: 14, height: 14).padding(.top, 4)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(node.title).foregroundStyle(Color.qelvPaper).fixedSize(horizontal: false, vertical: true)
                                        Text(node.how).font(.footnote).foregroundStyle(Color.qelvMist).fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                            .disabled(!open && !unlocked)
                            .opacity(open || unlocked ? 1 : 0.45)
                            if index < path.nodes.count - 1 {
                                Rectangle().fill(Color.qelvMint.opacity(unlocked ? 0.8 : 0.2)).frame(width: 2, height: 16).padding(.leading, 6)
                            }
                        }
                    }
                    .qelvCard()
                }
            }
            .padding(16)
            .padding(.bottom, 90)
        }
        .qelvScreen(image: "onboarding_art", opacity: 0.12)
    }
}

struct SeluneTestLab: View {
    let movementId: String
    @EnvironmentObject private var vault: QelvOrbitVault
    @State private var value = 0
    @State private var running = false
    @State private var elapsed = 0
    private var node: QelvNodeLine? {
        QelvCatalog.book.paths.flatMap(\.nodes).first { $0.id == movementId }
    }
    var body: some View {
        let timed = node?.timed ?? (QelvCatalog.book.qelvMove(movementId)?.timed ?? false)
        let previous = vault.blob.tests.filter { $0.movementId == movementId }.map(\.value).max() ?? 0
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(node?.title ?? QelvCatalog.book.qelvMove(movementId)?.name ?? "Test")
                    .font(.system(.title, design: .rounded).weight(.bold))
                    .foregroundStyle(Color.qelvPaper)
                    .fixedSize(horizontal: false, vertical: true)
                Text(node?.how ?? "Log a max set or a hold.")
                    .foregroundStyle(Color.qelvMist)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Previous best \(previous)")
                    .foregroundStyle(Color.qelvMint)
                    .monospacedDigit()
                if timed {
                    Text("\(elapsed)")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Color.qelvPaper)
                    QelvGradientButton(title: running ? "Stop and save" : "Start hold") {
                        if running {
                            running = false
                            vault.qelvSaveTest(movementId: movementId, value: elapsed, timed: true)
                        } else {
                            elapsed = 0
                            running = true
                        }
                    }
                } else {
                    Text("\(value)")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Color.qelvPaper)
                    Button("Tap to add one") {
                        value += 1
                        QelvPulse.tap(vault.blob.profile.haptics)
                    }
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.qelvVoid)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 28)
                    .background { RoundedRectangle(cornerRadius: 20).fill(Color.qelvMint) }
                    QelvGradientButton(title: "Save result") {
                        vault.qelvSaveTest(movementId: movementId, value: value, timed: false)
                    }
                }
            }
            .padding(16)
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            if running { elapsed += 1 }
        }
        .navigationBarTitleDisplayMode(.inline)
        .qelvScreen()
    }
}

struct VaskProgressAtlas: View {
    @EnvironmentObject private var vault: QelvOrbitVault
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Progress")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .foregroundStyle(Color.qelvPaper)
                if vault.blob.sessions.isEmpty && vault.blob.quick.isEmpty {
                    Text("Start today's session and this page fills with your own numbers.")
                        .foregroundStyle(Color.qelvMist)
                        .fixedSize(horizontal: false, vertical: true)
                    NavigationLink("Open today", value: QelvPath.altitude).foregroundStyle(Color.qelvMint)
                }
                lazyTiles
                Text("Sessions")
                    .font(.headline)
                    .foregroundStyle(Color.qelvPaper)
                let weeks = sessionWeeks()
                ChartBars(values: weeks)
                NavigationLink(value: QelvPath.altitude) { Text("Altitude map").foregroundStyle(Color.qelvPaper).qelvCard() }.buttonStyle(.plain)
                NavigationLink(value: QelvPath.badges) { Text("Achievements").foregroundStyle(Color.qelvPaper).qelvCard() }.buttonStyle(.plain)
                NavigationLink(value: QelvPath.recap) { Text("Monthly recap").foregroundStyle(Color.qelvPaper).qelvCard() }.buttonStyle(.plain)
                Text("Records")
                    .font(.headline)
                    .foregroundStyle(Color.qelvPaper)
                ForEach(recordRows(), id: \.0) { row in
                    NavigationLink(value: QelvPath.move(row.0)) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(row.1): \(row.2)")
                                .foregroundStyle(Color.qelvPaper)
                                .fixedSize(horizontal: false, vertical: true)
                            Text("Recent sets and tests")
                                .font(.caption)
                                .foregroundStyle(Color.qelvMist)
                        }
                    }
                }
                weightBlock
            }
            .padding(16)
            .padding(.bottom, 90)
        }
        .qelvScreen(image: "onboarding_art", opacity: 0.15)
    }

    private var lazyTiles: some View {
        let minutes = vault.blob.sessions.reduce(0) { $0 + $1.duration } / 60
        let reps = vault.blob.sets.reduce(0) { $0 + $1.reps }
        return VStack(alignment: .leading, spacing: 6) {
            Text("Sessions \(vault.blob.sessions.count)").foregroundStyle(Color.qelvPaper)
            Text("Reps \(reps)").foregroundStyle(Color.qelvPaper).monospacedDigit()
            Text("Minutes \(minutes)").foregroundStyle(Color.qelvPaper).monospacedDigit()
            Text("Best charge \(vault.blob.bestStreak)").foregroundStyle(Color.qelvMint)
        }
        .qelvCard()
    }

    private func sessionWeeks() -> [Int] {
        (0..<8).reversed().map { ago in
            let end = QelvClock.cal.date(byAdding: .day, value: -7 * ago, to: Date()) ?? Date()
            let start = QelvClock.mondayKey(end)
            let stop = QelvClock.addDays(start, 6)
            return vault.blob.sessions.filter { $0.date >= start && $0.date <= stop }.count
        }
    }

    private func recordRows() -> [(String, String, Int)] {
        var best: [String: Int] = [:]
        for set in vault.blob.sets {
            best[set.moveId] = max(best[set.moveId] ?? 0, max(set.reps, set.seconds))
        }
        return best.keys.sorted().prefix(12).map { id in
            (id, QelvCatalog.book.qelvMove(id)?.name ?? id, best[id] ?? 0)
        }
    }

    private var weightBlock: some View {
        WeightEditor()
    }
}

struct ChartBars: View {
    var values: [Int]
    var body: some View {
        let maxValue = max(values.max() ?? 1, 1)
        HStack(alignment: .bottom, spacing: 6) {
            ForEach(values.indices, id: \.self) { index in
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.qelvBloom)
                    .frame(height: 8 + CGFloat(values[index]) / CGFloat(maxValue) * 70)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 90)
    }
}

struct WeightEditor: View {
    @EnvironmentObject private var vault: QelvOrbitVault
    @State private var text = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Body weight (\(vault.blob.profile.units))")
                .font(.headline)
                .foregroundStyle(Color.qelvPaper)
            TextField("Add an entry", text: $text)
                .keyboardType(.decimalPad)
                .foregroundStyle(Color.qelvPaper)
                .padding(10)
                .background { RoundedRectangle(cornerRadius: 12).fill(Color.qelvLift) }
            Button("Save entry") {
                let cleaned = text.replacingOccurrences(of: ",", with: ".")
                if let value = Double(cleaned), value > 0 {
                    vault.qelvAddWeight(value)
                    text = ""
                }
            }
            .foregroundStyle(Color.qelvMint)
            ForEach(vault.blob.weights) { row in
                HStack {
                    Text("\(row.date) · \(String(format: "%.1f", row.value))")
                        .foregroundStyle(Color.qelvPaper)
                    Spacer()
                    Button("Delete") { vault.qelvDeleteWeight(row.id) }.foregroundStyle(Color.qelvAlarm)
                }
            }
        }
        .qelvCard()
        .qelvKeysAway()
    }
}

struct VaskAltitudeMap: View {
    @EnvironmentObject private var vault: QelvOrbitVault
    @State private var scroll = 0.0
    var body: some View {
        let level = QelvAltitude.level(for: vault.blob.xp)
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    ForEach((1...30).reversed(), id: \.self) { marker in
                        HStack {
                            Circle()
                                .fill(marker < level ? Color.qelvMint : (marker == level ? Color.qelvBloom : Color.qelvLine))
                                .frame(width: marker == level ? 22 : 14, height: marker == level ? 22 : 14)
                                .shadow(color: marker == level ? Color.qelvMint.opacity(0.7) : .clear, radius: 8)
                            VStack(alignment: .leading) {
                                Text("Level \(marker)")
                                    .foregroundStyle(Color.qelvPaper)
                                if marker % 5 == 1 || marker == 1 {
                                    Text(QelvAltitude.zone(for: marker))
                                        .font(.caption)
                                        .foregroundStyle(Color.qelvMint)
                                }
                            }
                            Spacer()
                        }
                        .padding(.vertical, 10)
                        .id(marker)
                    }
                }
                .padding(20)
                .background(GeometryReader { geo in
                    Color.clear.preference(key: QelvOffsetKey.self, value: geo.frame(in: .named("alt")).minY)
                })
            }
            .coordinateSpace(name: "alt")
            .onPreferenceChange(QelvOffsetKey.self) { scroll = $0 }
            .onAppear { proxy.scrollTo(level, anchor: .center) }
        }
        .background {
            Color.qelvVoid
                .overlay {
                    Image("altitude_backdrop")
                        .resizable()
                        .scaledToFill()
                        .offset(y: scroll * 0.25)
                }
                .clipped()
                .ignoresSafeArea()
        }
        .navigationTitle("Altitude")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct VaskBadgeGrid: View {
    @EnvironmentObject private var vault: QelvOrbitVault
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Achievements").font(.system(.title, design: .rounded).weight(.bold)).foregroundStyle(Color.qelvPaper)
                let recent = vault.blob.badges.sorted { $0.value > $1.value }.prefix(4)
                if !recent.isEmpty {
                    Text("Recently unlocked").foregroundStyle(Color.qelvMint)
                    ForEach(Array(recent), id: \.key) { item in
                        Text("\(title(item.key)) · \(item.value)").foregroundStyle(Color.qelvPaper).fixedSize(horizontal: false, vertical: true)
                    }
                }
                ForEach(QelvCatalog.book.badges) { badge in
                    let progress = vault.qelvBadgeProgress(badge.id)
                    let open = vault.blob.badges[badge.id] != nil
                    VStack(alignment: .leading, spacing: 4) {
                        Text(badge.title).foregroundStyle(open ? Color.qelvPaper : Color.qelvMist).fixedSize(horizontal: false, vertical: true)
                        Text(badge.detail).font(.footnote).foregroundStyle(Color.qelvMist).fixedSize(horizontal: false, vertical: true)
                        Text("\(min(progress.0, progress.1)) / \(progress.1)").font(.caption.monospacedDigit()).foregroundStyle(Color.qelvMint)
                    }
                    .qelvCard()
                }
            }
            .padding(16)
        }
        .navigationBarTitleDisplayMode(.inline)
        .qelvScreen(image: "level_up_banner", opacity: 0.2)
    }
    private func title(_ id: String) -> String { QelvCatalog.book.badges.first { $0.id == id }?.title ?? id }
}

struct VaskMonthRecap: View {
    @EnvironmentObject private var vault: QelvOrbitVault
    var body: some View {
        let month = String(QelvClock.key().prefix(7))
        let sessions = vault.blob.sessions.filter { $0.date.hasPrefix(month) }
        let reps = vault.blob.sets.filter { set in sessions.contains { $0.id == set.sessionId } }.reduce(0) { $0 + $1.reps }
        let minutes = sessions.reduce(0) { $0 + $1.duration } / 60
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("This month").font(.system(.title, design: .rounded).weight(.bold)).foregroundStyle(Color.qelvPaper)
                Text("Sessions \(sessions.count)").foregroundStyle(Color.qelvPaper)
                Text("Reps \(reps)").foregroundStyle(Color.qelvPaper).monospacedDigit()
                Text("Minutes \(minutes)").foregroundStyle(Color.qelvPaper).monospacedDigit()
                Text("Best charge \(vault.blob.bestStreak)").foregroundStyle(Color.qelvMint)
                Text("Zone \(QelvAltitude.zone(for: QelvAltitude.level(for: vault.blob.xp)))").foregroundStyle(Color.qelvPaper)
                ShareLink(item: "Month recap: \(sessions.count) sessions, \(reps) reps, \(minutes) minutes.") {
                    Text("Share recap").foregroundStyle(Color.qelvPaper)
                }
            }
            .padding(16)
        }
        .onAppear { vault.qelvMarkRecap() }
        .navigationBarTitleDisplayMode(.inline)
        .qelvScreen(image: "level_up_banner", opacity: 0.28)
    }
}
