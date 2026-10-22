import SwiftUI
import Combine

struct OrryxOnboard: View {
    @EnvironmentObject private var vault: QelvOrbitVault
    @State private var page = 0
    @State private var goal = "Stay active"
    @State private var experience = "Beginner"
    @State private var gear: Set<String> = ["none"]
    @State private var days = 3
    @State private var clock = Calendar.current.date(from: DateComponents(hour: 18, minute: 0)) ?? Date()
    @State private var remind = true
    @State private var nickname = ""
    @State private var agreed = false
    @State private var spin = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if page == 0 {
                    Color.clear.frame(height: 180).frame(maxWidth: .infinity).background {
                        Image("onboarding_art").resizable().scaledToFill().rotationEffect(.degrees(spin ? 8 : -8))
                    }.clipped().clipShape(RoundedRectangle(cornerRadius: 24)).accessibilityHidden(true)
                    Text("Train against gravity")
                        .font(.system(.largeTitle, design: .rounded).weight(.bold))
                        .foregroundStyle(Color.qelvPaper)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Climb from the floor toward a higher zone by finishing real sessions.")
                        .foregroundStyle(Color.qelvMist)
                        .fixedSize(horizontal: false, vertical: true)
                    QelvGradientButton(title: "Start") { page = 1 }
                } else if page == 1 {
                    Text("Goal and level")
                        .font(.system(.title, design: .rounded).weight(.bold))
                        .foregroundStyle(Color.qelvPaper)
                    pick("Goal", ["Build strength", "Lose fat", "Learn skills", "Stay active"], $goal)
                    pick("Experience", ["Beginner", "Intermediate", "Advanced"], $experience)
                    QelvGradientButton(title: "Continue") { page = 2 }
                } else if page == 2 {
                    Text("Equipment")
                        .font(.system(.title, design: .rounded).weight(.bold))
                        .foregroundStyle(Color.qelvPaper)
                    ForEach(["none", "bar", "dip", "rings", "band"], id: \.self) { item in
                        Button(label(item)) {
                            if gear.contains(item) { gear.remove(item) } else { gear.insert(item) }
                            QelvPulse.pick(vault.blob.profile.haptics)
                        }
                        .foregroundStyle(gear.contains(item) ? Color.qelvVoid : Color.qelvPaper)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background { Capsule().fill(gear.contains(item) ? Color.qelvMint : Color.qelvLift) }
                    }
                    QelvGradientButton(title: "Continue") { page = 3 }
                } else if page == 3 {
                    Text("Schedule")
                        .font(.system(.title, design: .rounded).weight(.bold))
                        .foregroundStyle(Color.qelvPaper)
                    Stepper(value: $days, in: 2...7) {
                        Text("\(days) training days each week")
                            .foregroundStyle(Color.qelvPaper)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Toggle("Reminder", isOn: $remind).tint(Color.qelvMint).foregroundStyle(Color.qelvPaper)
                    DatePicker("Time", selection: $clock, displayedComponents: .hourAndMinute).foregroundStyle(Color.qelvPaper)
                    QelvGradientButton(title: "Continue") { page = 4 }
                    QelvMintButton(title: "Skip reminder") {
                        remind = false
                        page = 4
                    }
                } else {
                    Text("Before you train")
                        .font(.system(.title, design: .rounded).weight(.bold))
                        .foregroundStyle(Color.qelvPaper)
                    Text("Train within your limits. Consult a doctor if you have health concerns.")
                        .foregroundStyle(Color.qelvMist)
                        .fixedSize(horizontal: false, vertical: true)
                    Button(agreed ? "Acknowledged" : "I understand") { agreed = true }
                        .foregroundStyle(agreed ? Color.qelvVoid : Color.qelvPaper)
                        .padding(12)
                        .frame(maxWidth: .infinity)
                        .background { Capsule().fill(agreed ? Color.qelvMint : Color.qelvLift) }
                    TextField("Nickname, optional", text: $nickname)
                        .foregroundStyle(Color.qelvPaper)
                        .padding(12)
                        .background { RoundedRectangle(cornerRadius: 14).fill(Color.qelvLift) }
                    QelvGradientButton(title: "Enter today") {
                        guard agreed else { return }
                        let parts = Calendar.current.dateComponents([.hour, .minute], from: clock)
                        vault.qelvFinishOnboard(name: nickname, goal: goal, experience: experience, equipment: Array(gear), days: days, hour: parts.hour ?? 18, minute: parts.minute ?? 0, remind: remind)
                    }
                }
            }
            .padding(20)
        }
        .scrollDismissesKeyboard(.interactively)
        .qelvKeysAway()
        .qelvScreen(image: page == 0 ? nil : "onboarding_art", opacity: 0.2)
        .onAppear {
            withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) { spin = true }
        }
    }

    private func label(_ item: String) -> String {
        switch item {
        case "bar": return "Pull-up bar"
        case "dip": return "Parallel bars or dip station"
        case "rings": return "Gymnastic rings"
        case "band": return "Resistance band"
        default: return "No equipment"
        }
    }

    private func pick(_ title: String, _ options: [String], _ selection: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).foregroundStyle(Color.qelvMist)
            ForEach(options, id: \.self) { option in
                Button(option) { selection.wrappedValue = option }
                    .foregroundStyle(selection.wrappedValue == option ? Color.qelvVoid : Color.qelvPaper)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background { Capsule().fill(selection.wrappedValue == option ? Color.qelvMint : Color.qelvLift) }
            }
        }
    }
}

struct OrryxTodayDeck: View {
    @EnvironmentObject private var vault: QelvOrbitVault
    @State private var planBox: QelvPlanBox?
    @State private var showQuick = false
    @State private var showStreak = false
    @State private var offset: CGFloat = 0
    @State private var feelOpen = false
    @State private var sleep = 2
    @State private var muscles = 2
    @State private var energy = 2

    var body: some View {
        let card = vault.qelvTodayCard()
        let level = QelvAltitude.intoLevel(vault.blob.xp)
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(greeting)
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .foregroundStyle(Color.qelvPaper)
                    .fixedSize(horizontal: false, vertical: true)
                Text(dateLine)
                    .foregroundStyle(Color.qelvMist)
                readinessCard
                hero(card)
                charge
                quests
                weekStrip
                NavigationLink(value: QelvPath.altitude) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Level \(level.level) · \(QelvAltitude.zone(for: level.level))")
                            .foregroundStyle(Color.qelvPaper)
                        if level.need > 0 {
                            Text("\(level.current) / \(level.need) XP")
                                .foregroundStyle(Color.qelvMint)
                                .monospacedDigit()
                        } else {
                            Text("Max altitude reached")
                                .foregroundStyle(Color.qelvMint)
                        }
                    }
                    .qelvCard()
                }
                .buttonStyle(.plain)
                NavigationLink(value: QelvPath.challenge) {
                    Text("Weekly challenge")
                        .foregroundStyle(Color.qelvPaper)
                        .qelvCard()
                }
                .buttonStyle(.plain)
                if vault.blob.sessions.isEmpty {
                    Button {
                        planBox = QelvPlanBox(plan: vault.qelvQuickStart(), source: "quickstart")
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Quick start")
                                .font(.headline)
                                .foregroundStyle(Color.qelvPaper)
                            Text("A five minute first session is ready.")
                                .foregroundStyle(Color.qelvMist)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .qelvCard()
                    }
                    .buttonStyle(.plain)
                }
                HStack {
                    Button("Quick log") { showQuick = true }.foregroundStyle(Color.qelvMint)
                    Spacer()
                    NavigationLink("Interval timer", value: QelvPath.timer).foregroundStyle(Color.qelvPaper)
                    Spacer()
                    NavigationLink("Test lab", value: QelvPath.test("squat")).foregroundStyle(Color.qelvPaper)
                }
                if Calendar.current.component(.day, from: Date()) <= 3 {
                    NavigationLink(value: QelvPath.recap) {
                        Text("Monthly recap is ready")
                            .foregroundStyle(Color.qelvPaper)
                            .qelvCard()
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
            .padding(.bottom, 88)
            .background(GeometryReader { geo in
                Color.clear.preference(key: QelvOffsetKey.self, value: geo.frame(in: .named("today")).minY)
            })
        }
        .coordinateSpace(name: "today")
        .onPreferenceChange(QelvOffsetKey.self) { offset = $0 }
        .qelvScreen()
        .fullScreenCover(item: $planBox) { box in
            BrantixSessionRunner(plan: box.plan, source: box.source)
                .environmentObject(vault)
        }
        .sheet(isPresented: $showQuick) { OrryxQuickLog().environmentObject(vault) }
        .sheet(isPresented: $showStreak) { OrryxStreakSheet().environmentObject(vault) }
    }

    private var readinessCard: some View {
        let saved = vault.qelvReadiness()
        return VStack(alignment: .leading, spacing: 8) {
            Text("How you feel")
                .font(.headline)
                .foregroundStyle(Color.qelvPaper)
            if let saved, !feelOpen {
                Text(vault.qelvReadyLine(saved))
                    .foregroundStyle(Color.qelvMist)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Update") {
                    sleep = saved.sleep
                    muscles = saved.muscles
                    energy = saved.energy
                    feelOpen = true
                }
                .foregroundStyle(Color.qelvMint)
            } else {
                Text("A low score eases today's volume.")
                    .font(.footnote)
                    .foregroundStyle(Color.qelvMist)
                    .fixedSize(horizontal: false, vertical: true)
                feelRow("Sleep", ["Short", "Fair", "Solid"], $sleep)
                feelRow("Muscles", ["Sore", "Ok", "Fresh"], $muscles)
                feelRow("Energy", ["Low", "Steady", "High"], $energy)
                QelvGradientButton(title: "Use this today") {
                    vault.qelvSaveReadiness(sleep: sleep, muscles: muscles, energy: energy)
                    feelOpen = false
                }
            }
        }
        .qelvCard()
    }

    private func feelRow(_ title: String, _ options: [String], _ selection: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.footnote).foregroundStyle(Color.qelvMist)
            HStack(spacing: 6) {
                ForEach(options.indices, id: \.self) { index in
                    Button(options[index]) {
                        selection.wrappedValue = index + 1
                        QelvPulse.pick(vault.blob.profile.haptics)
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(selection.wrappedValue == index + 1 ? Color.qelvVoid : Color.qelvPaper)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background { Capsule().fill(selection.wrappedValue == index + 1 ? Color.qelvMint : Color.qelvLift) }
                }
            }
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let hello = hour < 12 ? "Good morning" : (hour < 17 ? "Good afternoon" : "Good evening")
        let name = vault.blob.profile.nickname
        return name.isEmpty ? hello : "\(hello), \(name)"
    }

    private var dateLine: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE d MMMM"
        return formatter.string(from: Date())
    }

    private func hero(_ card: QelvCardPlan) -> some View {
        let warmed = vault.qelvWithWarmup(card)
        let warmNames = warmed.items.filter { $0.id.hasPrefix("warm-") }.compactMap { QelvCatalog.book.qelvMove($0.moveId)?.name }
        let zone = vault.qelvActiveZone()
        let eased = card.focus != "Flow" && (vault.qelvReadyScore() ?? 9) <= 5
        return VStack(alignment: .leading, spacing: 8) {
            Text(card.title)
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(Color.qelvPaper)
                .fixedSize(horizontal: false, vertical: true)
            Text("\(warmed.minutes) min · \(card.focus)")
                .foregroundStyle(Color.qelvMint)
            HStack {
                ForEach(0..<3, id: \.self) { index in
                    Circle().fill(index < card.difficulty ? Color.qelvMint : Color.qelvLine).frame(width: 8, height: 8)
                }
            }
            if eased {
                Text("Eased for how you feel today")
                    .font(.footnote)
                    .foregroundStyle(Color.qelvMint)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if !zone.isEmpty {
                Text("Avoiding \(zone.lowercased()) today")
                    .font(.footnote)
                    .foregroundStyle(Color.qelvMint)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if !warmNames.isEmpty {
                Text("Warm-up: \(warmNames.joined(separator: ", "))")
                    .font(.footnote)
                    .foregroundStyle(Color.qelvMist)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text(card.tomorrow)
                .font(.footnote)
                .foregroundStyle(Color.qelvMist)
                .fixedSize(horizontal: false, vertical: true)
            QelvGradientButton(title: "Start") {
                planBox = QelvPlanBox(plan: warmed, source: card.programDayId.isEmpty ? (card.focus == "Flow" ? "flow" : "daily") : "program")
            }
        }
        .padding(16)
        .background {
            Color.qelvSlab
                .overlay {
                    Image("home_hero_banner")
                        .resizable()
                        .scaledToFill()
                        .opacity(0.45)
                        .offset(y: offset * 0.08)
                }
                .clipped()
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Color.qelvBloom.opacity(0.35), radius: 12, y: 6)
    }

    private var charge: some View {
        Button { showStreak = true } label: {
            HStack(spacing: 14) {
                QelvRing(progress: min(1, Double(vault.blob.streak) / 30))
                    .frame(width: 64, height: 64)
                    .overlay(Text("\(vault.blob.streak)").font(.headline.monospacedDigit()).foregroundStyle(Color.qelvPaper))
                VStack(alignment: .leading, spacing: 4) {
                    Text(vault.qelvChargeLabel())
                        .font(.headline)
                        .foregroundStyle(Color.qelvPaper)
                    Text("Best \(vault.blob.bestStreak) · passes \(vault.blob.passes)")
                        .foregroundStyle(Color.qelvMist)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .qelvCard()
        }
        .buttonStyle(.plain)
    }

    private var quests: some View {
        let today = QelvClock.key()
        let rows = vault.blob.quests.filter { $0.date == today }
        return VStack(alignment: .leading, spacing: 8) {
            Text("Daily quests").font(.headline).foregroundStyle(Color.qelvPaper)
            ForEach(rows) { quest in
                VStack(alignment: .leading, spacing: 4) {
                    Text(quest.title).foregroundStyle(Color.qelvPaper).fixedSize(horizontal: false, vertical: true)
                    Text("\(min(quest.progress, quest.target)) / \(quest.target)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(Color.qelvMint)
                }
            }
        }
        .qelvCard()
    }

    private var weekStrip: some View {
        let monday = QelvClock.mondayKey()
        return HStack {
            ForEach(0..<7, id: \.self) { offset in
                let key = QelvClock.addDays(monday, offset)
                let counted = vault.blob.days.first { $0.date == key }?.counted == true
                let rest = !vault.blob.profile.weekdays.contains(offset)
                VStack {
                    Circle()
                        .fill(counted ? Color.qelvMint : (rest ? Color.qelvBloom.opacity(0.5) : Color.qelvLine))
                        .frame(width: 16, height: 16)
                    Text(["M", "T", "W", "T", "F", "S", "S"][offset])
                        .font(.caption2)
                        .foregroundStyle(Color.qelvMist)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

struct QelvOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

struct OrryxQuickLog: View {
    @EnvironmentObject private var vault: QelvOrbitVault
    @Environment(\.dismiss) private var dismiss
    @State private var activity = "Calisthenics"
    @State private var minutes = 20
    @State private var effort = "Medium"
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Quick log").font(.system(.title, design: .rounded).weight(.bold)).foregroundStyle(Color.qelvPaper)
                Picker("Activity", selection: $activity) {
                    ForEach(["Calisthenics", "Running", "Cycling", "Swimming", "Yoga", "Walk", "Sports game", "Other"], id: \.self) { Text($0).tag($0) }
                }
                Stepper(value: $minutes, in: 5...180, step: 5) {
                    Text("\(minutes) minutes").foregroundStyle(Color.qelvPaper).monospacedDigit()
                }
                Picker("Effort", selection: $effort) {
                    ForEach(["Easy", "Medium", "Hard"], id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.segmented)
                Text(minutes >= 10 ? "This log counts for the charge." : "Logs under 10 minutes save XP but do not count the day.")
                    .foregroundStyle(Color.qelvMist)
                    .fixedSize(horizontal: false, vertical: true)
                QelvGradientButton(title: "Save log") {
                    vault.qelvQuickLog(activity: activity, minutes: minutes, effort: effort)
                    dismiss()
                }
                QelvMintButton(title: "Close") { dismiss() }
            }
            .padding(16)
        }
        .qelvScreen()
    }
}

struct OrryxStreakSheet: View {
    @EnvironmentObject private var vault: QelvOrbitVault
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Charge").font(.system(.title, design: .rounded).weight(.bold)).foregroundStyle(Color.qelvPaper)
                Text("A day counts after a session, a finished timer, or a quick log of at least 10 minutes. Planned rest days do not break the charge. A missed training day uses a rest pass if you have one, otherwise the charge drops by half.")
                    .foregroundStyle(Color.qelvMist)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Passes held: \(vault.blob.passes)")
                    .foregroundStyle(Color.qelvMint)
                ForEach(vault.blob.events.suffix(12).reversed()) { event in
                    Text("\(event.date) · \(event.kind)")
                        .foregroundStyle(Color.qelvPaper)
                }
                QelvMintButton(title: "Close") { dismiss() }
            }
            .padding(16)
        }
        .qelvScreen()
    }
}

struct OrryxChallengeSheet: View {
    @EnvironmentObject private var vault: QelvOrbitVault
    var body: some View {
        let week = vault.blob.weeks.first { $0.weekStart == QelvClock.mondayKey() }
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Weekly challenge")
                    .font(.system(.title, design: .rounded).weight(.bold))
                    .foregroundStyle(Color.qelvPaper)
                if let week, let move = QelvCatalog.book.qelvMove(week.moveId) {
                    Text(move.name).foregroundStyle(Color.qelvMint)
                    Text("Your total \(week.total) · ghost \(week.ghost)")
                        .foregroundStyle(Color.qelvPaper)
                        .monospacedDigit()
                        .fixedSize(horizontal: false, vertical: true)
                    ChartlessBars(values: week.daily, ghost: week.ghost)
                }
                Text("The ghost is your own best week for this movement. Beating it at week's end adds XP.")
                    .foregroundStyle(Color.qelvMist)
                    .fixedSize(horizontal: false, vertical: true)
                ForEach(vault.blob.weeks.filter { $0.closed }) { past in
                    Text("\(past.weekStart): \(past.total) / \(past.ghost) \(past.beaten ? "beaten" : "short")")
                        .foregroundStyle(Color.qelvPaper)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(16)
        }
        .navigationTitle("Challenge")
        .navigationBarTitleDisplayMode(.inline)
        .qelvScreen()
    }
}

struct ChartlessBars: View {
    var values: [Int]
    var ghost: Int
    var body: some View {
        let maxValue = max(ghost, values.max() ?? 1, 1)
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(values.indices, id: \.self) { index in
                VStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.qelvMint)
                        .frame(height: CGFloat(values[index]) / CGFloat(maxValue) * 80 + 4)
                    Text("\(index + 1)").font(.caption2).foregroundStyle(Color.qelvMist)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(minHeight: 110)
    }
}
