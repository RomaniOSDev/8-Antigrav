import SwiftUI
import Combine

struct BrantixTrainBay: View {
    @EnvironmentObject private var vault: QelvOrbitVault
    @State private var segment = 0
    @State private var query = ""
    @State private var category = "All"
    @Namespace private var slide

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                ForEach(Array(["Library", "Programs", "Timers"].enumerated()), id: \.offset) { index, title in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { segment = index }
                    } label: {
                        Text(title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(segment == index ? Color.qelvVoid : Color.qelvMist)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background {
                                if segment == index {
                                    Capsule().fill(Color.qelvMint).matchedGeometryEffect(id: "seg", in: slide)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            Group {
                if segment == 0 { library }
                else if segment == 1 { programs }
                else { timerHome }
            }
        }
        .qelvScreen()
    }

    private var library: some View {
        let rows = vault.qelvLibrary().filter { move in
            (category == "All" || move.category == category) &&
            (query.isEmpty || move.name.localizedCaseInsensitiveContains(query))
        }
        return List {
            TextField("Search movements", text: $query).foregroundStyle(Color.qelvPaper).listRowBackground(Color.qelvLift)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(["All", "Push", "Pull", "Legs", "Core", "Balance", "Flow"], id: \.self) { item in
                        Button(item) { category = item }
                            .font(.footnote)
                            .foregroundStyle(category == item ? Color.qelvVoid : Color.qelvPaper)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background { Capsule().fill(category == item ? Color.qelvMint : Color.qelvSlab) }
                    }
                }
            }
            .listRowBackground(Color.clear)
            ForEach(rows) { move in
                NavigationLink(value: QelvPath.move(move.id)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(move.name).foregroundStyle(Color.qelvPaper).fixedSize(horizontal: false, vertical: true)
                        Text("\(move.category) · \(String(repeating: "●", count: move.difficulty))")
                            .font(.footnote)
                            .foregroundStyle(Color.qelvMist)
                        Text(move.primary.joined(separator: ", "))
                            .font(.caption)
                            .foregroundStyle(Color.qelvMint)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .listRowBackground(Color.qelvSlab)
            }
            NavigationLink(value: QelvPath.builder) {
                Text("Custom workout builder").foregroundStyle(Color.qelvMint)
            }
            .listRowBackground(Color.qelvSlab)
        }
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .qelvKeysAway()
    }

    private var programs: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(QelvCatalog.book.programs) { program in
                    NavigationLink(value: QelvPath.program(program.id)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(program.name).font(.headline).foregroundStyle(Color.qelvPaper).fixedSize(horizontal: false, vertical: true)
                            Text(program.summary).foregroundStyle(Color.qelvMist).fixedSize(horizontal: false, vertical: true)
                            Text("\(program.weeks) weeks · \(program.daysPerWeek) days · \(program.difficulty)")
                                .font(.footnote)
                                .foregroundStyle(Color.qelvMint)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .qelvCard()
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
            .padding(.bottom, 80)
        }
    }

    private var timerHome: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                NavigationLink(value: QelvPath.timer) {
                    Text("Open interval timer").foregroundStyle(Color.qelvPaper).qelvCard()
                }
                .buttonStyle(.plain)
                ForEach(vault.blob.presets) { preset in
                    Text("\(preset.name) · \(preset.mode) · \(preset.work)s / \(preset.rest)s · \(preset.rounds) rounds")
                        .foregroundStyle(Color.qelvPaper)
                        .fixedSize(horizontal: false, vertical: true)
                        .qelvCard()
                }
            }
            .padding(16)
        }
    }
}

struct BrantixMoveDetail: View {
    let moveId: String
    @EnvironmentObject private var vault: QelvOrbitVault
    @State private var front = true
    var body: some View {
        let move = QelvCatalog.book.qelvMove(moveId)
        ScrollView {
            if let move {
                VStack(alignment: .leading, spacing: 12) {
                    Text(move.name).font(.system(.title, design: .rounded).weight(.bold)).foregroundStyle(Color.qelvPaper).fixedSize(horizontal: false, vertical: true)
                    QelvBodyMap(primary: move.primary, secondary: move.secondary, front: front)
                    Button(front ? "Show back" : "Show front") { front.toggle() }.foregroundStyle(Color.qelvMint)
                    Text(move.summary).foregroundStyle(Color.qelvMist).fixedSize(horizontal: false, vertical: true)
                    Text("Cues").font(.headline).foregroundStyle(Color.qelvPaper)
                    ForEach(move.cues, id: \.self) { Text($0).foregroundStyle(Color.qelvPaper).fixedSize(horizontal: false, vertical: true) }
                    Text("Common mistakes").font(.headline).foregroundStyle(Color.qelvPaper)
                    ForEach(move.mistakes, id: \.self) { Text($0).foregroundStyle(Color.qelvMist).fixedSize(horizontal: false, vertical: true) }
                    Text(move.breathing).foregroundStyle(Color.qelvMint).fixedSize(horizontal: false, vertical: true)
                    Text("Targets \(move.beginTarget) / \(move.midTarget) / \(move.highTarget)\(move.timed ? " seconds" : " reps")")
                        .foregroundStyle(Color.qelvPaper)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Personal best \(vault.qelvPersonalBest(moveId: move.id))")
                        .foregroundStyle(Color.qelvMint)
                        .monospacedDigit()
                    moveTrail(move)
                    if let reg = move.regression, let easier = QelvCatalog.book.qelvMove(reg) {
                        NavigationLink("Easier: \(easier.name)", value: QelvPath.move(easier.id)).foregroundStyle(Color.qelvPaper)
                    }
                    if let prog = move.progression, let harder = QelvCatalog.book.qelvMove(prog) {
                        NavigationLink("Harder: \(harder.name)", value: QelvPath.move(harder.id)).foregroundStyle(Color.qelvPaper)
                    }
                    Button(vault.blob.favorites.contains(move.id) ? "Favorited" : "Favorite") {
                        vault.qelvToggleFavorite(move.id)
                    }
                    .foregroundStyle(Color.qelvMint)
                    NavigationLink("Add inside the builder", value: QelvPath.builder).foregroundStyle(Color.qelvPaper)
                }
                .padding(16)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .qelvScreen()
    }

    private func moveTrail(_ move: QelvMoveLine) -> some View {
        let trail = vault.qelvMoveTrail(move.id)
        let cap = max(move.highTarget, trail.map(\.value).max() ?? 1, 1)
        return VStack(alignment: .leading, spacing: 8) {
            Text("Recent").font(.headline).foregroundStyle(Color.qelvPaper)
            if trail.isEmpty {
                Text("No logged sets yet.")
                    .foregroundStyle(Color.qelvMist)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(Array(trail.reversed())) { row in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(row.kind == "Test" ? Color.qelvBloom : Color.qelvMint)
                            .frame(height: 8 + CGFloat(row.value) / CGFloat(cap) * 64)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 80)
                if let latest = trail.first {
                    let band = latest.value >= move.highTarget ? "high" : (latest.value >= move.midTarget ? "mid" : (latest.value >= move.beginTarget ? "begin" : "under begin"))
                    Text("Latest \(latest.value)\(latest.timed ? "s" : "") · \(band) target")
                        .foregroundStyle(Color.qelvMint)
                        .monospacedDigit()
                        .fixedSize(horizontal: false, vertical: true)
                }
                ForEach(trail) { row in
                    Text("\(row.date) · \(row.kind) · \(row.value)\(row.timed ? "s" : "")")
                        .font(.footnote)
                        .foregroundStyle(Color.qelvMist)
                        .monospacedDigit()
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

struct BrantixProgramDetail: View {
    let programId: String
    @EnvironmentObject private var vault: QelvOrbitVault
    @State private var planBox: QelvPlanBox?
    var body: some View {
        let program = QelvCatalog.book.qelvProgram(programId)
        let done = Set(vault.blob.programDone[programId] ?? [])
        ScrollView {
            if let program {
                VStack(alignment: .leading, spacing: 12) {
                    Text(program.name).font(.system(.title, design: .rounded).weight(.bold)).foregroundStyle(Color.qelvPaper).fixedSize(horizontal: false, vertical: true)
                    Text(program.summary).foregroundStyle(Color.qelvMist).fixedSize(horizontal: false, vertical: true)
                    if vault.blob.programId == program.id {
                        QelvMintButton(title: vault.blob.programPaused ? "Resume" : "Pause") { vault.qelvPauseProgram() }
                    } else {
                        QelvGradientButton(title: "Start program") { vault.qelvStartProgram(program.id) }
                    }
                    ForEach(program.days) { day in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(day.title).foregroundStyle(done.contains(day.id) ? Color.qelvMint : Color.qelvPaper).fixedSize(horizontal: false, vertical: true)
                            ForEach(day.items) { item in
                                Text("\(QelvCatalog.book.qelvMove(item.moveId)?.name ?? item.moveId) · \(item.sets) × \(item.amount)")
                                    .font(.footnote)
                                    .foregroundStyle(Color.qelvMist)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .qelvCard()
                    }
                    if vault.blob.programId == program.id, let next = program.days.first(where: { !done.contains($0.id) }) {
                        QelvGradientButton(title: "Continue \(next.title)") {
                            let items = next.items.map { item in
                                QelvPlanItem(id: item.id, moveId: item.moveId, sets: item.sets, amount: item.amount, timed: QelvCatalog.book.qelvMove(item.moveId)?.timed ?? false, rest: item.rest)
                            }
                            let raw = QelvCardPlan(title: next.title, minutes: program.minutes, focus: program.name, difficulty: 2, items: items, tomorrow: "", programDayId: next.id)
                            planBox = QelvPlanBox(plan: vault.qelvShape(raw), source: "program")
                        }
                    }
                }
                .padding(16)
            }
        }
        .fullScreenCover(item: $planBox) { box in
            BrantixSessionRunner(plan: box.plan, source: box.source).environmentObject(vault)
        }
        .navigationBarTitleDisplayMode(.inline)
        .qelvScreen()
    }
}

struct BrantixBuilder: View {
    @EnvironmentObject private var vault: QelvOrbitVault
    @State private var name = "My session"
    @State private var items: [QelvCustomItem] = []
    @State private var planBox: QelvPlanBox?
    var body: some View {
        List {
            TextField("Name", text: $name).foregroundStyle(Color.qelvPaper).listRowBackground(Color.qelvLift)
            ForEach(vault.qelvLibrary()) { move in
                Button("Add \(move.name)") {
                    items.append(QelvCustomItem(id: UUID().uuidString, moveId: move.id, sets: 3, amount: move.timed ? 20 : 8))
                }
                .foregroundStyle(Color.qelvPaper)
                .listRowBackground(Color.qelvSlab)
            }
            ForEach(items) { item in
                Text("\(QelvCatalog.book.qelvMove(item.moveId)?.name ?? "") · \(item.sets) × \(item.amount)")
                    .foregroundStyle(Color.qelvMint)
                    .listRowBackground(Color.qelvSlab)
            }
            .onMove { items.move(fromOffsets: $0, toOffset: $1) }
            Button("Save and run") { run(save: true) }.foregroundStyle(Color.qelvMint).listRowBackground(Color.qelvLift)
        }
        .scrollContentBackground(.hidden)
        .environment(\.editMode, .constant(.active))
        .qelvKeysAway()
        .fullScreenCover(item: $planBox) { box in
            BrantixSessionRunner(plan: box.plan, source: "custom").environmentObject(vault)
        }
        .navigationTitle("Builder")
        .navigationBarTitleDisplayMode(.inline)
        .qelvScreen()
    }

    private func run(save: Bool) {
        guard !items.isEmpty else { return }
        if save {
            vault.qelvSaveCustom(QelvCustomKnot(id: UUID().uuidString, name: name, items: items))
        }
        let planItems = items.map { item in
            QelvPlanItem(id: item.id, moveId: item.moveId, sets: item.sets, amount: item.amount, timed: QelvCatalog.book.qelvMove(item.moveId)?.timed ?? false, rest: vault.blob.profile.restSeconds)
        }
        planBox = QelvPlanBox(plan: QelvCardPlan(title: name, minutes: max(8, planItems.count * 3), focus: "Custom", difficulty: 2, items: planItems, tomorrow: "", programDayId: ""), source: "custom")
    }
}

struct BrantixIntervalTimer: View {
    @EnvironmentObject private var vault: QelvOrbitVault
    @State private var mode = "Tabata"
    @State private var work = 20
    @State private var rest = 10
    @State private var rounds = 8
    @State private var running = false
    @State private var remaining = 20
    @State private var round = 1
    @State private var working = true
    @State private var name = "Preset"
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Interval timer").font(.system(.title, design: .rounded).weight(.bold)).foregroundStyle(Color.qelvPaper)
                Picker("Mode", selection: $mode) {
                    ForEach(["AMRAP", "EMOM", "Tabata", "Custom"], id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.segmented)
                Stepper("Work \(work)s", value: $work, in: 5...300, step: 5).foregroundStyle(Color.qelvPaper)
                Stepper("Rest \(rest)s", value: $rest, in: 0...180, step: 5).foregroundStyle(Color.qelvPaper)
                Stepper("Rounds \(rounds)", value: $rounds, in: 1...40).foregroundStyle(Color.qelvPaper)
                Text(working ? "Work" : "Rest")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(working ? Color.qelvMint : Color.qelvBloom)
                Text("\(remaining)")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(remaining <= 3 ? Color.qelvAlarm : Color.qelvPaper)
                Text("Round \(round) of \(rounds)").foregroundStyle(Color.qelvMist)
                QelvGradientButton(title: running ? "Pause" : "Start") {
                    if !running { remaining = work; working = true; round = 1 }
                    running.toggle()
                    UIApplication.shared.isIdleTimerDisabled = running && vault.blob.profile.keepAwake
                }
                QelvMintButton(title: "Save preset") {
                    vault.qelvSavePreset(QelvPresetKnot(id: UUID().uuidString, name: name.isEmpty ? mode : name, mode: mode, work: work, rest: rest, rounds: rounds))
                }
                TextField("Preset name", text: $name).foregroundStyle(Color.qelvPaper).padding(10).background { RoundedRectangle(cornerRadius: 12).fill(Color.qelvLift) }
            }
            .padding(16)
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in tick() }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
        .scrollDismissesKeyboard(.interactively)
        .qelvKeysAway()
        .navigationBarTitleDisplayMode(.inline)
        .qelvScreen()
    }

    private func tick() {
        guard running else { return }
        if remaining <= 3 { QelvPulse.pick(vault.blob.profile.haptics) }
        if remaining > 1 {
            remaining -= 1
            return
        }
        QelvPulse.win(vault.blob.profile.haptics)
        if working {
            if rest == 0 || mode == "AMRAP" {
                advanceRound()
            } else {
                working = false
                remaining = rest
            }
        } else {
            advanceRound()
        }
    }

    private func advanceRound() {
        if round >= rounds {
            running = false
            UIApplication.shared.isIdleTimerDisabled = false
            let minutes = max(1, (work * rounds) / 60)
            vault.qelvQuickLog(activity: "Intervals", minutes: minutes, effort: "Hard")
        } else {
            round += 1
            working = true
            remaining = work
        }
    }
}

struct BrantixSessionRunner: View {
    let plan: QelvCardPlan
    let source: String
    @EnvironmentObject private var vault: QelvOrbitVault
    @Environment(\.dismiss) private var dismiss
    @State private var index = 0
    @State private var setIndex = 0
    @State private var actual = 0
    @State private var logged: [QelvSetKnot] = []
    @State private var resting = false
    @State private var restLeft = 0
    @State private var started = Date()
    @State private var paused = false
    @State private var summary = false
    @State private var confirmEnd = false
    @State private var items: [QelvPlanItem] = []
    @State private var heavyNote = ""
    @State private var savedId = ""

    private var liveItems: [QelvPlanItem] { items.isEmpty ? plan.items : items }

    var body: some View {
        let item = liveItems.indices.contains(index) ? liveItems[index] : nil
        VStack(alignment: .leading, spacing: 12) {
            if summary {
                BrantixSummary(plan: plan, logged: logged, seconds: Int(Date().timeIntervalSince(started)), sessionId: savedId) {
                    dismiss()
                }
            } else if let item, let move = QelvCatalog.book.qelvMove(item.moveId) {
                Text("\(index + 1) of \(liveItems.count)")
                    .foregroundStyle(Color.qelvMist)
                Text(move.name)
                    .font(.system(.title, design: .rounded).weight(.bold))
                    .foregroundStyle(Color.qelvPaper)
                    .fixedSize(horizontal: false, vertical: true)
                Text(item.timed ? "\(item.sets) × \(item.amount) s" : "\(item.sets) × \(item.amount)")
                    .foregroundStyle(Color.qelvMint)
                Text(move.cues.first ?? move.summary)
                    .foregroundStyle(Color.qelvMist)
                    .fixedSize(horizontal: false, vertical: true)
                QelvBodyMap(primary: move.primary, secondary: move.secondary, front: true)
                if resting {
                    Text("Rest \(restLeft)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Color.qelvBloom)
                    HStack {
                        Button("+15 s") { restLeft += 15 }.foregroundStyle(Color.qelvPaper)
                        Spacer()
                        Button("Skip") { resting = false }.foregroundStyle(Color.qelvMint)
                    }
                } else {
                    Stepper(value: $actual, in: 0...500) {
                        Text(item.timed ? "\(actual) seconds" : "\(actual) reps")
                            .foregroundStyle(Color.qelvPaper)
                            .monospacedDigit()
                    }
                    QelvGradientButton(title: "Complete set") { complete() }
                }
                Button("Too heavy") { soften() }
                    .foregroundStyle(Color.qelvMint)
                if !heavyNote.isEmpty {
                    Text(heavyNote)
                        .foregroundStyle(Color.qelvMist)
                        .fixedSize(horizontal: false, vertical: true)
                }
                HStack {
                    Button(paused ? "Resume" : "Pause") { paused.toggle() }.foregroundStyle(Color.qelvPaper)
                    Spacer()
                    Button("End early") { confirmEnd = true }.foregroundStyle(Color.qelvAlarm)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onAppear {
            if items.isEmpty { items = plan.items }
            if logged.isEmpty, let first = items.first { actual = first.amount }
            UIApplication.shared.isIdleTimerDisabled = vault.blob.profile.keepAwake
        }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            guard resting, !paused else { return }
            if restLeft > 0 { restLeft -= 1 } else { resting = false }
        }
        .confirmationDialog("End this session?", isPresented: $confirmEnd) {
            Button("Save what is done", role: .destructive) { finish() }
            Button("Keep going", role: .cancel) {}
        }
        .qelvScreen()
    }

    private func complete() {
        if items.isEmpty { items = plan.items }
        guard items.indices.contains(index) else { return }
        let item = items[index]
        logged.append(QelvSetKnot(id: UUID().uuidString, sessionId: "", moveId: item.moveId, setIndex: setIndex, reps: item.timed ? 0 : actual, seconds: item.timed ? actual : 0, best: false))
        QelvPulse.win(vault.blob.profile.haptics)
        heavyNote = ""
        if setIndex + 1 < item.sets {
            setIndex += 1
            restLeft = item.rest
            resting = true
        } else if index + 1 < items.count {
            index += 1
            setIndex = 0
            actual = items[index].amount
            restLeft = item.rest
            resting = true
        } else {
            finish()
        }
    }

    private func soften() {
        if items.isEmpty { items = plan.items }
        guard items.indices.contains(index) else { return }
        let item = items[index]
        guard let move = QelvCatalog.book.qelvMove(item.moveId) else { return }
        guard let reg = move.regression, let easier = QelvCatalog.book.qelvMove(reg) else {
            heavyNote = "This is the easiest step."
            return
        }
        guard vault.qelvAllowed(easier) else {
            heavyNote = "The easier step needs gear that is not in your profile."
            return
        }
        items[index].moveId = easier.id
        items[index].timed = easier.timed
        let amount = easier.timed ? min(20, max(10, easier.beginTarget / 2)) : max(4, easier.beginTarget / 2)
        items[index].amount = amount
        actual = amount
        heavyNote = "Switched to \(easier.name)."
        QelvPulse.pick(vault.blob.profile.haptics)
    }

    private func finish() {
        let seconds = max(1, Int(Date().timeIntervalSince(started)))
        if !logged.isEmpty {
            savedId = vault.qelvAddSession(title: plan.title, source: source, programDayId: plan.programDayId, duration: seconds, sets: logged)
        }
        summary = true
        UIApplication.shared.isIdleTimerDisabled = false
    }
}

struct BrantixSummary: View {
    let plan: QelvCardPlan
    let logged: [QelvSetKnot]
    let seconds: Int
    var sessionId: String
    var done: () -> Void
    @EnvironmentObject private var vault: QelvOrbitVault
    @State private var note = ""
    @State private var zone = ""
    private let zones = ["Shoulder", "Knee", "Lower back"]
    var body: some View {
        let reps = logged.reduce(0) { $0 + $1.reps }
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Session summary")
                    .font(.system(.title, design: .rounded).weight(.bold))
                    .foregroundStyle(Color.qelvPaper)
                QelvRolling(value: seconds / 60)
                Text("Minutes")
                    .foregroundStyle(Color.qelvMist)
                Text("\(logged.count) sets · \(reps) reps")
                    .foregroundStyle(Color.qelvPaper)
                    .monospacedDigit()
                Text("Charge: \(vault.qelvChargeLabel())")
                    .foregroundStyle(Color.qelvMint)
                if logged.contains(where: { $0.best }) {
                    Text("A personal best was highlighted in the log.")
                        .foregroundStyle(Color.qelvPaper)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if !sessionId.isEmpty {
                    Text("How it went")
                        .font(.headline)
                        .foregroundStyle(Color.qelvPaper)
                    TextField("A line for yourself", text: $note)
                        .foregroundStyle(Color.qelvPaper)
                        .padding(12)
                        .background { RoundedRectangle(cornerRadius: 14).fill(Color.qelvLift) }
                    Text("Sore spot for tomorrow")
                        .font(.headline)
                        .foregroundStyle(Color.qelvPaper)
                    ForEach(zones, id: \.self) { name in
                        Button(name) {
                            zone = zone == name ? "" : name
                            QelvPulse.pick(vault.blob.profile.haptics)
                        }
                        .foregroundStyle(zone == name ? Color.qelvVoid : Color.qelvPaper)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background { Capsule().fill(zone == name ? Color.qelvMint : Color.qelvLift) }
                    }
                }
                ShareLink(item: shareText) {
                    Text("Share")
                        .foregroundStyle(Color.qelvPaper)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(QelvQuietPress())
                QelvGradientButton(title: "Done") {
                    if !sessionId.isEmpty {
                        vault.qelvSaveSessionNote(sessionId, note: note.trimmingCharacters(in: .whitespacesAndNewlines), zone: zone)
                        vault.qelvHoldUndo()
                    }
                    done()
                }
            }
            .padding(.horizontal, 4)
        }
        .scrollDismissesKeyboard(.interactively)
        .qelvKeysAway()
        .padding(.top, 8)
        .qelvScreen(image: "level_up_banner", opacity: 0.35)
    }

    private var shareText: String {
        var line = "Session: \(plan.title). \(logged.count) sets in \(seconds / 60) minutes."
        if !zone.isEmpty { line += " Watched \(zone)." }
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { line += " \(trimmed)" }
        return line
    }
}
