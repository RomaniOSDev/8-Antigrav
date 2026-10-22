import Foundation
import SwiftUI
import UserNotifications

struct QelvToast: Identifiable, Equatable {
    var id = UUID().uuidString
    var title: String
    var detail: String
    var canUndo: Bool = false
}

@MainActor
final class QelvOrbitVault: ObservableObject {
    @Published var blob: QelvLedgerBlob
    @Published var toast: QelvToast?
    @Published var levelUp: Int?
    @Published var importNote = ""
    private let fileURL: URL
    private var levelBefore = 1
    private var undoHold: QelvUndoHold?

    init() {
        let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("QelvOrbitVault", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        fileURL = folder.appendingPathComponent("ledger.json")
        if let data = try? Data(contentsOf: fileURL), let saved = try? JSONDecoder().decode(QelvLedgerBlob.self, from: data) {
            blob = saved
        } else {
            blob = .fresh()
        }
        levelBefore = QelvAltitude.level(for: blob.xp)
    }

    var motionQuiet: Bool { UIAccessibility.isReduceMotionEnabled }

    func qelvWake() {
        if blob.readiness == nil { blob.readiness = [] }
        qelvCloseGaps()
        qelvEnsureQuests()
        qelvRollWeek()
        qelvSyncBadges()
        QelvNotify.qelvRefresh(blob)
        qelvSave()
    }

    func qelvFinishOnboard(name: String, goal: String, experience: String, equipment: [String], days: Int, hour: Int, minute: Int, remind: Bool) {
        blob.profile.nickname = name
        blob.profile.goal = goal
        blob.profile.experience = experience
        blob.profile.equipment = equipment.isEmpty ? ["none"] : equipment
        blob.profile.weekdays = qelvDefaultDays(days)
        blob.profile.reminderHour = hour
        blob.profile.reminderMinute = minute
        blob.profile.reminderOn = remind
        blob.profile.onboarded = true
        if experience == "Intermediate" {
            ["push-1", "legs-1", "core-1"].forEach { blob.skills[$0] = QelvClock.key() }
        } else if experience == "Advanced" {
            ["push-1", "push-2", "legs-1", "legs-2", "core-1", "core-2"].forEach { blob.skills[$0] = QelvClock.key() }
        }
        qelvSave()
        if remind {
            QelvNotify.qelvAsk { [weak self] _ in self?.qelvWake() }
        } else {
            qelvWake()
        }
    }

    func qelvDefaultDays(_ count: Int) -> [Int] {
        let patterns: [[Int]] = [[0, 3], [0, 2, 4], [0, 1, 3, 4], [0, 1, 2, 3, 4], [0, 1, 2, 3, 4, 5], [0, 1, 2, 3, 4, 5, 6]]
        let index = min(max(count, 2), 7) - 2
        return patterns[index]
    }

    func qelvAllowed(_ move: QelvMoveLine) -> Bool {
        let gear = Set(blob.profile.equipment)
        if move.equipment == "none" || gear.contains("none") && move.equipment == "none" { return move.equipment == "none" || gear.contains(move.equipment) }
        if move.equipment == "none" { return true }
        return gear.contains(move.equipment)
    }

    func qelvLibrary() -> [QelvMoveLine] {
        QelvCatalog.book.moves.filter { qelvAllowed($0) }
    }

    func qelvIsRest(_ date: Date = Date()) -> Bool {
        !blob.profile.weekdays.contains(QelvClock.weekdayIndex(date))
    }

    func qelvTodayCard() -> QelvCardPlan { qelvCard(for: Date()) }

    func qelvCard(for date: Date) -> QelvCardPlan {
        qelvShape(qelvPlainCard(for: date), on: date)
    }

    func qelvShape(_ plan: QelvCardPlan, on date: Date = Date()) -> QelvCardPlan {
        qelvApplyZone(qelvApplyReadiness(qelvApplyZone(plan, on: date), on: date), on: date)
    }

    func qelvReadiness(on date: Date = Date()) -> QelvReadinessKnot? {
        (blob.readiness ?? []).first { $0.date == QelvClock.key(date) }
    }

    func qelvReadyScore(on date: Date = Date()) -> Int? {
        guard let row = qelvReadiness(on: date) else { return nil }
        return row.sleep + row.muscles + row.energy
    }

    func qelvReadyLine(_ row: QelvReadinessKnot) -> String {
        let word: (Int, [String]) -> String = { value, names in
            names[min(names.count - 1, max(0, value - 1))]
        }
        return "Sleep \(word(row.sleep, ["Short", "Fair", "Solid"])) · Muscles \(word(row.muscles, ["Sore", "Ok", "Fresh"])) · Energy \(word(row.energy, ["Low", "Steady", "High"]))"
    }

    func qelvSaveReadiness(sleep: Int, muscles: Int, energy: Int) {
        let clamp: (Int) -> Int = { min(3, max(1, $0)) }
        let today = QelvClock.key()
        var rows = blob.readiness ?? []
        let row = QelvReadinessKnot(date: today, sleep: clamp(sleep), muscles: clamp(muscles), energy: clamp(energy))
        if let index = rows.firstIndex(where: { $0.date == today }) { rows[index] = row }
        else { rows.append(row) }
        blob.readiness = rows
        qelvSave()
    }

    func qelvActiveZone(on date: Date = Date()) -> String {
        let key = QelvClock.key(date)
        let prior = blob.sessions.filter { !($0.zone ?? "").isEmpty && $0.date < key }.max { $0.date < $1.date }
        guard let prior, let zone = prior.zone, !zone.isEmpty else { return "" }
        let gap = QelvClock.dayDelta(prior.date, key)
        guard gap >= 1, gap <= 2 else { return "" }
        return zone
    }

    func qelvWithWarmup(_ card: QelvCardPlan) -> QelvCardPlan {
        if card.focus == "Flow" || card.focus == "Start" || card.items.isEmpty { return card }
        if card.items.contains(where: { $0.id.hasPrefix("warm-") }) { return card }
        let zone = qelvActiveZone()
        let used = Set(card.items.map(\.moveId))
        let category = QelvCatalog.book.qelvMove(card.items[0].moveId)?.category ?? card.focus
        var pool = qelvLibrary().filter { $0.category == category && $0.difficulty <= 1 && !used.contains($0.id) && (zone.isEmpty || !qelvHitsZone($0, zone)) }
        if pool.count < 2 {
            pool = qelvLibrary().filter { $0.difficulty <= 1 && !used.contains($0.id) && (zone.isEmpty || !qelvHitsZone($0, zone)) }
        }
        let picks = Array(pool.sorted { $0.id < $1.id }.prefix(2))
        guard !picks.isEmpty else { return card }
        var warmed = card
        let warmItems = picks.enumerated().map { index, move in
            let amount = move.timed ? min(20, max(10, move.beginTarget / 2)) : max(4, move.beginTarget / 2)
            return QelvPlanItem(id: "warm-\(index)-\(move.id)", moveId: move.id, sets: 1, amount: amount, timed: move.timed, rest: 15)
        }
        warmed.items = warmItems + card.items
        warmed.minutes = min(40, card.minutes + 4)
        return warmed
    }

    func qelvMoveTrail(_ moveId: String) -> [QelvTrailKnot] {
        let nodeIds = Set(QelvCatalog.book.paths.flatMap(\.nodes).filter { $0.moveId == moveId }.map(\.id))
        var rows: [QelvTrailKnot] = []
        for set in blob.sets where set.moveId == moveId {
            let value = max(set.reps, set.seconds)
            guard value > 0 else { continue }
            let date = blob.sessions.first { $0.id == set.sessionId }?.date ?? ""
            rows.append(QelvTrailKnot(id: set.id, date: date, value: value, timed: set.seconds > 0, kind: "Set"))
        }
        for test in blob.tests where test.movementId == moveId || nodeIds.contains(test.movementId) {
            rows.append(QelvTrailKnot(id: test.id, date: test.date, value: test.value, timed: test.timed, kind: "Test"))
        }
        return Array(rows.sorted { lhs, rhs in
            if lhs.date == rhs.date { return lhs.kind > rhs.kind }
            return lhs.date > rhs.date
        }.prefix(8))
    }

    func qelvSaveSessionNote(_ id: String, note: String, zone: String) {
        guard let index = blob.sessions.firstIndex(where: { $0.id == id }) else { return }
        blob.sessions[index].note = note
        blob.sessions[index].zone = zone
        qelvSave()
    }

    func qelvUndoDeadline() -> Date? { undoHold?.until }

    func qelvHoldUndo() {
        guard let hold = undoHold else { return }
        undoHold?.until = Date().addingTimeInterval(20)
        if toast == nil {
            toast = QelvToast(title: "Session saved", detail: hold.detail, canUndo: true)
        }
    }

    func qelvUndoLast() {
        guard let hold = undoHold, Date() < hold.until else { return }
        blob = hold.prior
        levelUp = hold.levelUp
        undoHold = nil
        toast = QelvToast(title: "Session removed", detail: "XP and today's charge were put back.")
        qelvSave()
    }

    private func qelvPlainCard(for date: Date) -> QelvCardPlan {
        let key = QelvClock.key(date)
        if !blob.programId.isEmpty, !blob.programPaused, let program = QelvCatalog.book.qelvProgram(blob.programId) {
            if qelvIsRest(date) {
                return qelvFlowCard(prefix: "Optional flow", seed: QelvClock.dayNumber(key))
            }
            let done = Set(blob.programDone[program.id] ?? [])
            if let next = program.days.first(where: { !done.contains($0.id) }) {
                let items = next.items.map { item in
                    let timed = QelvCatalog.book.qelvMove(item.moveId)?.timed ?? false
                    return QelvPlanItem(id: item.id, moveId: item.moveId, sets: item.sets, amount: item.amount, timed: timed, rest: item.rest)
                }
                let tomorrow = qelvTomorrowLine(from: date)
                return QelvCardPlan(title: next.title, minutes: program.minutes, focus: program.name, difficulty: program.difficulty == "Beginner" ? 1 : 2, items: items, tomorrow: tomorrow, programDayId: next.id)
            }
        }
        if qelvIsRest(date) {
            return qelvFlowCard(prefix: "Rest-day flow", seed: QelvClock.dayNumber(key))
        }
        return qelvGenerated(date)
    }

    func qelvQuickStart() -> QelvCardPlan {
        let picks = ["squat", "incline-push", "plank"].compactMap { QelvCatalog.book.qelvMove($0) }
        let items = picks.enumerated().map { index, move in
            QelvPlanItem(id: "quick-\(index)", moveId: move.id, sets: 2, amount: move.timed ? 20 : 6, timed: move.timed, rest: 30)
        }
        return QelvCardPlan(title: "First five minutes", minutes: 5, focus: "Start", difficulty: 1, items: items, tomorrow: qelvTodayCard().tomorrow, programDayId: "")
    }

    func qelvPersonalBest(moveId: String) -> Int {
        let rows = blob.sets.filter { $0.moveId == moveId }
        let reps = rows.map(\.reps).max() ?? 0
        let seconds = rows.map(\.seconds).max() ?? 0
        return max(reps, seconds)
    }

    func qelvAddSession(title: String, source: String, programDayId: String, duration: Int, sets logged: [QelvSetKnot]) -> String {
        let prior = blob
        let priorLevel = levelUp
        let today = QelvClock.key()
        let hour = Calendar.current.component(.hour, from: Date())
        var earned = 50
        var stored: [QelvSetKnot] = []
        for row in logged {
            var copy = row
            let previous = qelvPersonalBest(moveId: row.moveId)
            let value = max(row.reps, row.seconds)
            copy.best = value > previous && value > 0
            if row.seconds > 0 {
                earned += 10 + min(30, row.seconds / 3)
            } else {
                earned += 10 + min(20, row.reps)
            }
            stored.append(copy)
        }
        let session = QelvSessionKnot(id: UUID().uuidString, date: today, duration: duration, source: source, programDayId: programDayId, xp: earned, title: title, hour: hour)
        var withSession = stored
        for index in withSession.indices { withSession[index].sessionId = session.id }
        blob.sessions.append(session)
        blob.sets.append(contentsOf: withSession)
        if source == "flow" || withSession.contains(where: { QelvCatalog.book.qelvMove($0.moveId)?.category == "Flow" }) {
            blob.flowSessions += 1
        }
        if !programDayId.isEmpty, !blob.programId.isEmpty {
            var done = blob.programDone[blob.programId] ?? []
            if !done.contains(programDayId) { done.append(programDayId) }
            blob.programDone[blob.programId] = done
            if let program = QelvCatalog.book.qelvProgram(blob.programId), done.count >= program.days.count, !blob.finishedPrograms.contains(program.id) {
                blob.finishedPrograms.append(program.id)
                blob.programPaused = true
            }
        }
        qelvGrant(earned)
        qelvAddMinutes(duration / 60, xp: earned)
        qelvCountToday()
        qelvAddWeekVolume(sets: withSession)
        qelvRefreshQuests()
        qelvUnlockFlow()
        qelvSyncBadges()
        undoHold = QelvUndoHold(prior: prior, levelUp: priorLevel, until: Date().addingTimeInterval(20), detail: "\(earned) XP from \(title).")
        toast = QelvToast(title: "Session saved", detail: "\(earned) XP from \(title).", canUndo: true)
        qelvSave()
        return session.id
    }

    func qelvQuickLog(activity: String, minutes: Int, effort: String) {
        let multiplier = effort == "Hard" ? 1.6 : (effort == "Medium" ? 1.3 : 1.0)
        let xp = min(60, Int((Double(minutes) * multiplier).rounded()))
        blob.quick.append(QelvQuickKnot(id: UUID().uuidString, date: QelvClock.key(), activity: activity, minutes: minutes, effort: effort, xp: xp))
        qelvGrant(xp)
        qelvAddMinutes(minutes, xp: xp)
        if minutes >= 10 { qelvCountToday() }
        qelvRefreshQuests()
        qelvSyncBadges()
        toast = QelvToast(title: "Log saved", detail: "\(xp) XP from \(minutes) minutes.")
        qelvSave()
    }

    func qelvSaveTest(movementId: String, value: Int, timed: Bool) {
        let previous = blob.tests.filter { $0.movementId == movementId }.map(\.value).max() ?? 0
        blob.tests.append(QelvTestKnot(id: UUID().uuidString, date: QelvClock.key(), movementId: movementId, value: value, timed: timed))
        qelvUnlockNodes()
        qelvGrant(previous == 0 ? 20 : 10)
        qelvSyncBadges()
        let delta = value - previous
        toast = QelvToast(title: "Test saved", detail: delta > 0 ? "Up \(delta) from your previous best." : "Saved next to your previous best.")
        qelvSave()
    }

    func qelvToggleFavorite(_ id: String) {
        if blob.favorites.contains(id) { blob.favorites.removeAll { $0 == id } }
        else { blob.favorites.append(id) }
        qelvSave()
    }

    func qelvStartProgram(_ id: String) {
        guard let program = QelvCatalog.book.qelvProgram(id) else { return }
        if program.needs == "bar" && !blob.profile.equipment.contains("bar") {
            toast = QelvToast(title: "Bar needed", detail: "This path uses a pull-up bar. Add one in profile or pick another program.")
            return
        }
        blob.programId = id
        blob.programPaused = false
        qelvSave()
    }

    func qelvPauseProgram() {
        blob.programPaused.toggle()
        qelvSave()
    }

    func qelvSaveCustom(_ workout: QelvCustomKnot) {
        if let index = blob.customs.firstIndex(where: { $0.id == workout.id }) { blob.customs[index] = workout }
        else { blob.customs.append(workout) }
        qelvSave()
    }

    func qelvDeleteCustom(_ id: String) {
        blob.customs.removeAll { $0.id == id }
        qelvSave()
    }

    func qelvSavePreset(_ preset: QelvPresetKnot) {
        if let index = blob.presets.firstIndex(where: { $0.id == preset.id }) { blob.presets[index] = preset }
        else { blob.presets.append(preset) }
        qelvSave()
    }

    func qelvAddWeight(_ value: Double) {
        blob.weights.append(QelvWeightKnot(id: UUID().uuidString, date: QelvClock.key(), value: value))
        qelvSave()
    }

    func qelvDeleteWeight(_ id: String) {
        blob.weights.removeAll { $0.id == id }
        qelvSave()
    }

    func qelvMarkRecap() {
        let month = String(QelvClock.key().prefix(7))
        if blob.recapSeen != month {
            blob.recapSeen = month
            qelvSyncBadges()
            qelvSave()
        }
    }

    func qelvNodeOpen(_ node: QelvNodeLine, path: QelvPathLine) -> Bool {
        guard let index = path.nodes.firstIndex(where: { $0.id == node.id }) else { return false }
        if index == 0 { return true }
        return blob.skills[path.nodes[index - 1].id] != nil
    }

    func qelvExportURL() -> URL? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(blob) else { return nil }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("training-ledger.json")
        try? data.write(to: url, options: .atomic)
        return url
    }

    func qelvImport(_ url: URL) {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        guard let data = try? Data(contentsOf: url), let incoming = try? JSONDecoder().decode(QelvLedgerBlob.self, from: data) else {
            importNote = "That file could not be read."
            return
        }
        blob = incoming
        qelvSave()
        importNote = "The ledger on this device was replaced."
        qelvWake()
    }

    func qelvErase() {
        blob = .fresh()
        levelUp = nil
        toast = nil
        try? FileManager.default.removeItem(at: fileURL)
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        qelvSave()
    }

    func qelvBadgeProgress(_ id: String) -> (Int, Int) {
        let reps = blob.sets.reduce(0) { $0 + $1.reps }
        let sessions = blob.sessions.count
        let level = QelvAltitude.level(for: blob.xp)
        let variety = Set(blob.sets.map(\.moveId)).count
        switch id {
        case "streak-3": return (blob.bestStreak, 3)
        case "streak-7": return (blob.bestStreak, 7)
        case "streak-14": return (blob.bestStreak, 14)
        case "streak-30": return (blob.bestStreak, 30)
        case "streak-60": return (blob.bestStreak, 60)
        case "streak-100": return (blob.bestStreak, 100)
        case "sessions-1": return (sessions, 1)
        case "sessions-10": return (sessions, 10)
        case "sessions-25": return (sessions, 25)
        case "sessions-50": return (sessions, 50)
        case "sessions-100": return (sessions, 100)
        case "sessions-250": return (sessions, 250)
        case "volume-100": return (reps, 100)
        case "volume-1000": return (reps, 1000)
        case "volume-5000": return (reps, 5000)
        case "skill-first": return (blob.skills.isEmpty ? 0 : 1, 1)
        case "skill-path": return (qelvFinishedPaths(), 1)
        case "skill-all": return (qelvFinishedPaths(), 6)
        case "level-5": return (level, 5)
        case "level-10": return (level, 10)
        case "level-20": return (level, 20)
        case "level-30": return (level, 30)
        case "variety-10": return (variety, 10)
        case "variety-25": return (variety, 25)
        case "early-bird": return (blob.sessions.contains { $0.hour < 8 } ? 1 : 0, 1)
        case "night-owl": return (blob.sessions.contains { $0.hour >= 21 } ? 1 : 0, 1)
        case "ghost-1": return (blob.ghostBeats, 1)
        case "ghost-5": return (blob.ghostBeats, 5)
        case "perfect-week": return (qelvPerfectWeeks(), 1)
        case "pass-saved": return (blob.passesEarned, 1)
        case "test-1": return (blob.tests.count, 1)
        case "test-10": return (blob.tests.count, 10)
        case "program-1": return (blob.finishedPrograms.count, 1)
        case "program-all": return (blob.finishedPrograms.count, 5)
        case "flow-5": return (blob.flowSessions, 5)
        case "recap-viewed": return (blob.recapSeen.isEmpty ? 0 : 1, 1)
        default: return (0, 1)
        }
    }

    func qelvChargeLabel() -> String {
        let today = QelvClock.key()
        if blob.days.first(where: { $0.date == today })?.counted == true { return "Charged" }
        if qelvIsRest() { return "Rest day" }
        if blob.events.contains(where: { $0.date == today && $0.kind == "decay" }) { return "Decayed" }
        if Calendar.current.component(.hour, from: Date()) >= 18 { return "At risk" }
        return "Open"
    }

    private func qelvGrant(_ amount: Int) {
        guard amount > 0 else { return }
        let before = QelvAltitude.level(for: blob.xp)
        blob.xp += amount
        let after = QelvAltitude.level(for: blob.xp)
        if after > before {
            levelUp = after
            QelvPulse.win(blob.profile.haptics)
        }
    }

    private func qelvAddMinutes(_ minutes: Int, xp: Int) {
        let today = QelvClock.key()
        if let index = blob.days.firstIndex(where: { $0.date == today }) {
            blob.days[index].minutes += minutes
            blob.days[index].xp += xp
        } else {
            blob.days.append(QelvDayKnot(date: today, counted: false, minutes: minutes, xp: xp))
        }
    }

    private func qelvCountToday() {
        let today = QelvClock.key()
        guard blob.days.first(where: { $0.date == today })?.counted != true else { return }
        if let index = blob.days.firstIndex(where: { $0.date == today }) {
            blob.days[index].counted = true
        } else {
            blob.days.append(QelvDayKnot(date: today, counted: true, minutes: 0, xp: 0))
        }
        blob.streak += 1
        blob.bestStreak = max(blob.bestStreak, blob.streak)
        blob.lastCounted = today
        if blob.streak.isMultiple(of: 7), blob.passes < 2 {
            blob.passes += 1
            blob.passesEarned += 1
        }
        blob.events.append(QelvEventKnot(id: UUID().uuidString, date: today, kind: "gain"))
        QelvNotify.qelvCancelRisk()
        QelvPulse.win(blob.profile.haptics)
    }

    private func qelvCloseGaps() {
        let today = QelvClock.key()
        if !blob.lastCounted.isEmpty, QelvClock.dayDelta(today, blob.lastCounted) > 0 { return }
        let through = QelvClock.addDays(today, -1)
        var cursor = blob.sealedThrough.isEmpty ? QelvClock.addDays(blob.profile.installKey, -1) : blob.sealedThrough
        var guardrail = 0
        while QelvClock.dayDelta(cursor, through) > 0 && guardrail < 400 {
            cursor = QelvClock.addDays(cursor, 1)
            qelvSeal(cursor)
            guardrail += 1
        }
        blob.sealedThrough = through
    }

    private func qelvSeal(_ day: String) {
        if blob.days.first(where: { $0.date == day })?.counted == true { return }
        let date = QelvClock.date(day)
        if qelvIsRest(date) { return }
        if blob.passes > 0 {
            blob.passes -= 1
            blob.events.append(QelvEventKnot(id: UUID().uuidString, date: day, kind: "pass"))
            if let index = blob.days.firstIndex(where: { $0.date == day }) {
                blob.days[index].counted = true
            } else {
                blob.days.append(QelvDayKnot(date: day, counted: true, minutes: 0, xp: 0))
            }
            return
        }
        if blob.streak > 0 {
            blob.streak = blob.streak / 2
            blob.events.append(QelvEventKnot(id: UUID().uuidString, date: day, kind: "decay"))
            QelvPulse.warn(blob.profile.haptics)
        }
    }

    private func qelvGenerated(_ date: Date) -> QelvCardPlan {
        let key = QelvClock.key(date)
        let number = QelvClock.dayNumber(key)
        let recentIds = Set(blob.sessions.filter { QelvClock.dayDelta($0.date, key) <= 3 && QelvClock.dayDelta($0.date, key) >= 0 }.flatMap { session in
            blob.sets.filter { $0.sessionId == session.id }.map(\.moveId)
        })
        let cap = blob.profile.experience == "Beginner" ? 1 : (blob.profile.experience == "Intermediate" ? 2 : 3)
        var pool = qelvLibrary().filter { $0.difficulty <= cap && $0.category != "Flow" && !recentIds.contains($0.id) }
        if pool.count < 4 { pool = qelvLibrary().filter { $0.difficulty <= cap && $0.category != "Flow" } }
        let zone = qelvActiveZone(on: date)
        if !zone.isEmpty {
            let safe = pool.filter { !qelvHitsZone($0, zone) }
            if !safe.isEmpty { pool = safe }
        }
        let categories = ["Push", "Pull", "Legs", "Core", "Balance"]
        let focus = categories[number % categories.count]
        var picked: [QelvMoveLine] = []
        let ordered = pool.sorted { lhs, rhs in
            let lb = lhs.category == focus ? 0 : 1
            let rb = rhs.category == focus ? 0 : 1
            if lb != rb { return lb < rb }
            return lhs.id < rhs.id
        }
        for move in ordered where picked.count < 5 {
            if !picked.contains(where: { $0.id == move.id }) { picked.append(move) }
        }
        if picked.isEmpty {
            let fallback = qelvLibrary().filter { zone.isEmpty || !qelvHitsZone($0, zone) }
            picked = Array((fallback.isEmpty ? qelvLibrary() : fallback).prefix(4))
        }
        let items = picked.enumerated().map { index, move in
            let amount = blob.profile.experience == "Advanced" ? move.highTarget / 2 : (blob.profile.experience == "Intermediate" ? max(4, move.midTarget / 2) : max(4, move.beginTarget / 2))
            return QelvPlanItem(id: "\(key)-\(index)", moveId: move.id, sets: 3, amount: max(4, amount), timed: move.timed, rest: blob.profile.restSeconds)
        }
        let minutes = min(25, max(12, items.count * 4))
        let actual = picked.first?.category ?? focus
        return QelvCardPlan(title: "\(actual) session", minutes: minutes, focus: actual, difficulty: cap, items: items, tomorrow: qelvTomorrowLine(from: date), programDayId: "")
    }

    private func qelvFlowCard(prefix: String, seed: Int) -> QelvCardPlan {
        let flow = QelvCatalog.book.moves.filter { $0.category == "Flow" }
        let items = (0..<4).map { index in
            let move = flow[(seed + index) % max(flow.count, 1)]
            return QelvPlanItem(id: "flow-\(seed)-\(index)", moveId: move.id, sets: 2, amount: move.timed ? 30 : 6, timed: move.timed, rest: 20)
        }
        return QelvCardPlan(title: prefix, minutes: 10, focus: "Flow", difficulty: 1, items: items, tomorrow: "A fresh session arrives tomorrow.", programDayId: "")
    }

    private func qelvTomorrowLine(from date: Date) -> String {
        let next = QelvClock.cal.date(byAdding: .day, value: 1, to: date) ?? date
        var line = "Tomorrow: \(qelvCardPreview(next))"
        let zone = qelvActiveZone(on: next)
        if !zone.isEmpty { line += " · avoiding \(zone.lowercased())" }
        return line
    }

    private func qelvHitsZone(_ move: QelvMoveLine, _ zone: String) -> Bool {
        let muscles = Set(move.primary)
        switch zone {
        case "Shoulder": return muscles.contains("shoulders")
        case "Knee": return muscles.contains("quads")
        case "Lower back": return muscles.contains("back")
        default: return false
        }
    }

    private func qelvDodge(_ item: QelvPlanItem, zone: String) -> QelvPlanItem {
        guard !zone.isEmpty else { return item }
        var copy = item
        var guardrail = 0
        while let move = QelvCatalog.book.qelvMove(copy.moveId), qelvHitsZone(move, zone), guardrail < 6 {
            guard let reg = move.regression, let easier = QelvCatalog.book.qelvMove(reg), qelvAllowed(easier) else { break }
            copy.moveId = easier.id
            copy.timed = easier.timed
            copy.amount = max(4, easier.timed ? min(copy.amount, max(10, easier.beginTarget)) : max(4, easier.beginTarget / 2))
            guardrail += 1
        }
        return copy
    }

    private func qelvApplyZone(_ plan: QelvCardPlan, on date: Date) -> QelvCardPlan {
        let zone = qelvActiveZone(on: date)
        guard !zone.isEmpty, plan.focus != "Flow" else { return plan }
        var plan = plan
        plan.items = plan.items.map { qelvDodge($0, zone: zone) }
        return plan
    }

    private func qelvApplyReadiness(_ plan: QelvCardPlan, on date: Date) -> QelvCardPlan {
        guard plan.focus != "Flow", let score = qelvReadyScore(on: date), score <= 5 else { return plan }
        var plan = plan
        plan.difficulty = 1
        plan.minutes = max(8, plan.minutes * 2 / 3)
        plan.items = plan.items.map { item in
            var copy = item
            copy.sets = max(1, copy.sets - 1)
            if score <= 4 {
                copy.amount = max(4, copy.amount * 2 / 3)
                if let move = QelvCatalog.book.qelvMove(copy.moveId), let reg = move.regression, let easier = QelvCatalog.book.qelvMove(reg), qelvAllowed(easier) {
                    copy.moveId = easier.id
                    copy.timed = easier.timed
                }
            }
            return copy
        }
        return plan
    }

    private func qelvCardPreview(_ date: Date) -> String {
        if qelvIsRest(date) { return "optional flow" }
        if !blob.programId.isEmpty, !blob.programPaused, let program = QelvCatalog.book.qelvProgram(blob.programId) {
            let done = Set(blob.programDone[program.id] ?? [])
            return program.days.first { !done.contains($0.id) }?.title ?? "program complete"
        }
        let categories = ["Push", "Pull", "Legs", "Core", "Balance"]
        return categories[QelvClock.dayNumber(QelvClock.key(date)) % categories.count] + " session"
    }

    private func qelvEnsureQuests() {
        let today = QelvClock.key()
        if blob.quests.contains(where: { $0.date == today }) { return }
        let level = QelvAltitude.level(for: blob.xp)
        let reps = 20 + level * 4
        let hold = 30 + level * 5
        let kinds = ["today", "reps", "hold", "mobility", "fresh", "best", "early", "mix"]
        let number = QelvClock.dayNumber(today)
        var chosen: [String] = []
        var cursor = 0
        while chosen.count < 3 && cursor < 20 {
            let kind = kinds[(number + cursor * 3) % kinds.count]
            if !chosen.contains(kind) { chosen.append(kind) }
            cursor += 1
        }
        let move = qelvLibrary().first?.id ?? "squat"
        for kind in chosen {
            let title: String
            let target: Int
            switch kind {
            case "reps": title = "Log \(reps) reps of one movement"; target = reps
            case "hold": title = "Hold for \(hold) seconds"; target = hold
            case "mobility": title = "Finish a mobility session"; target = 1
            case "fresh": title = "Try a movement unused in 7 days"; target = 1
            case "best": title = "Log a personal best"; target = 1
            case "early": title = "Finish a session before 9"; target = 1
            case "mix": title = "Use 3 categories today"; target = 3
            default: title = "Finish today's session"; target = 1
            }
            blob.quests.append(QelvQuestKnot(id: UUID().uuidString, date: today, kind: kind, moveId: move, target: target, progress: 0, done: false, title: title, xpGiven: false))
        }
    }

    private func qelvRefreshQuests() {
        qelvEnsureQuests()
        let today = QelvClock.key()
        let todaysSets = blob.sets.filter { set in
            blob.sessions.contains { $0.id == set.sessionId && $0.date == today }
        }
        for index in blob.quests.indices where blob.quests[index].date == today && !blob.quests[index].xpGiven {
            let quest = blob.quests[index]
            let progress: Int
            switch quest.kind {
            case "reps": progress = todaysSets.reduce(0) { $0 + $1.reps }
            case "hold": progress = todaysSets.reduce(0) { $0 + $1.seconds }
            case "mobility": progress = blob.sessions.contains { $0.date == today && ($0.source == "flow" || blob.sets.contains { $0.sessionId == $0.sessionId && QelvCatalog.book.qelvMove($0.moveId)?.category == "Flow" }) } ? 1 : (blob.flowSessions > 0 && blob.sessions.contains { $0.date == today } ? 1 : 0)
            case "fresh":
                let old = Set(blob.sets.filter { set in
                    guard let session = blob.sessions.first(where: { $0.id == set.sessionId }) else { return false }
                    return QelvClock.dayDelta(session.date, today) > 0 && QelvClock.dayDelta(session.date, today) <= 7
                }.map(\.moveId))
                progress = todaysSets.contains { !old.contains($0.moveId) } ? 1 : 0
            case "best": progress = todaysSets.contains { $0.best } ? 1 : 0
            case "early": progress = blob.sessions.contains { $0.date == today && $0.hour < 9 } ? 1 : 0
            case "mix":
                let cats = Set(todaysSets.compactMap { QelvCatalog.book.qelvMove($0.moveId)?.category })
                progress = cats.count
            default:
                progress = blob.sessions.contains { $0.date == today && $0.source != "timer" } ? 1 : 0
            }
            blob.quests[index].progress = progress
            if progress >= quest.target {
                blob.quests[index].done = true
                blob.quests[index].xpGiven = true
                qelvGrant(40)
                toast = QelvToast(title: "Quest complete", detail: "40 XP added.")
                QelvPulse.win(blob.profile.haptics)
            }
        }
    }

    private func qelvRollWeek() {
        let monday = QelvClock.mondayKey()
        if let index = blob.weeks.firstIndex(where: { $0.weekStart == monday }) {
            if !blob.weeks[index].closed { return }
        }
        for index in blob.weeks.indices where blob.weeks[index].weekStart < monday && !blob.weeks[index].closed {
            blob.weeks[index].closed = true
            if blob.weeks[index].total >= blob.weeks[index].ghost && blob.weeks[index].ghost > 0 {
                blob.weeks[index].beaten = true
                blob.ghostBeats += 1
                qelvGrant(200)
            }
        }
        if !blob.weeks.contains(where: { $0.weekStart == monday }) {
            let pool = qelvLibrary().filter { $0.category != "Flow" }
            let move = pool.isEmpty ? "squat" : pool[QelvClock.dayNumber(monday) % pool.count].id
            let ghost = blob.weeks.filter { $0.moveId == move }.map(\.total).max() ?? (20 + QelvAltitude.level(for: blob.xp) * 5)
            blob.weeks.append(QelvWeekKnot(weekStart: monday, moveId: move, total: 0, ghost: ghost, beaten: false, closed: false, daily: Array(repeating: 0, count: 7)))
        }
    }

    private func qelvAddWeekVolume(sets: [QelvSetKnot]) {
        qelvRollWeek()
        let monday = QelvClock.mondayKey()
        guard let index = blob.weeks.firstIndex(where: { $0.weekStart == monday }) else { return }
        let move = blob.weeks[index].moveId
        let timed = QelvCatalog.book.qelvMove(move)?.timed ?? false
        let add = sets.filter { $0.moveId == move }.reduce(0) { $0 + (timed ? $1.seconds : $1.reps) }
        blob.weeks[index].total += add
        let day = QelvClock.weekdayIndex()
        if blob.weeks[index].daily.count == 7 { blob.weeks[index].daily[day] += add }
    }

    private func qelvUnlockNodes() {
        for path in QelvCatalog.book.paths where path.id != "flow" {
            for node in path.nodes where blob.skills[node.id] == nil && qelvNodeOpen(node, path: path) {
                let best = blob.tests.filter { $0.movementId == node.id || $0.movementId == node.moveId }.map(\.value).max() ?? 0
                if best >= node.target {
                    blob.skills[node.id] = QelvClock.key()
                    qelvGrant(150)
                    QelvPulse.win(blob.profile.haptics)
                }
            }
        }
    }

    private func qelvUnlockFlow() {
        guard let path = QelvCatalog.book.paths.first(where: { $0.id == "flow" }) else { return }
        for node in path.nodes where blob.skills[node.id] == nil && blob.flowSessions >= node.flowCount && qelvNodeOpen(node, path: path) {
            blob.skills[node.id] = QelvClock.key()
            qelvGrant(150)
        }
    }

    private func qelvFinishedPaths() -> Int {
        QelvCatalog.book.paths.filter { path in path.nodes.allSatisfy { blob.skills[$0.id] != nil } }.count
    }

    private func qelvPerfectWeeks() -> Int {
        let monday = QelvClock.mondayKey()
        let needed = Set(blob.profile.weekdays)
        var hits = 0
        for offset in 0..<7 {
            let key = QelvClock.addDays(monday, offset)
            let index = QelvClock.weekdayIndex(QelvClock.date(key))
            if needed.contains(index), blob.days.first(where: { $0.date == key })?.counted == true { hits += 1 }
        }
        return hits >= needed.count && !needed.isEmpty ? 1 : 0
    }

    private func qelvSyncBadges() {
        for badge in QelvCatalog.book.badges {
            let progress = qelvBadgeProgress(badge.id)
            if progress.0 >= progress.1, blob.badges[badge.id] == nil {
                blob.badges[badge.id] = QelvClock.key()
                qelvGrant(25)
            }
        }
    }

    private func qelvSave() {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(blob) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}

private struct QelvUndoHold {
    var prior: QelvLedgerBlob
    var levelUp: Int?
    var until: Date
    var detail: String
}

enum QelvNotify {
    static func qelvAsk(_ done: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { ok, _ in
            DispatchQueue.main.async { done(ok) }
        }
    }
    static func qelvCancelRisk() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["qelv-risk"])
    }
    static func qelvRefresh(_ blob: QelvLedgerBlob) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else { return }
            center.removeAllPendingNotificationRequests()
            guard blob.profile.reminderOn else { return }
            let notes = QelvCatalog.book.reminders
            for offset in 0..<max(notes.count, 1) {
                guard let day = QelvClock.cal.date(byAdding: .day, value: offset, to: Date()) else { continue }
                var parts = QelvClock.cal.dateComponents([.year, .month, .day], from: day)
                parts.hour = blob.profile.reminderHour
                parts.minute = blob.profile.reminderMinute
                let content = UNMutableNotificationContent()
                content.title = "Session window"
                content.body = notes.isEmpty ? "A short session keeps the charge alive." : notes[offset % notes.count]
                content.sound = .default
                center.add(UNNotificationRequest(identifier: "qelv-day-\(offset)", content: content, trigger: UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)))
            }
            guard blob.profile.riskOn else { return }
            let today = QelvClock.key()
            if blob.days.first(where: { $0.date == today })?.counted == true { return }
            var risk = QelvClock.cal.dateComponents([.year, .month, .day], from: Date())
            risk.hour = 20
            risk.minute = 30
            let body = UNMutableNotificationContent()
            body.title = "Charge still open"
            body.body = "A session, a timer, or a 10 minute log keeps today counted."
            body.sound = .default
            center.add(UNNotificationRequest(identifier: "qelv-risk", content: body, trigger: UNCalendarNotificationTrigger(dateMatching: risk, repeats: false)))
        }
    }
}
