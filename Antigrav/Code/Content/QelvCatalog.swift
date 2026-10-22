import Foundation

struct QelvMoveLine: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var category: String
    var equipment: String
    var difficulty: Int
    var summary: String
    var cues: [String]
    var mistakes: [String]
    var breathing: String
    var primary: [String]
    var secondary: [String]
    var regression: String?
    var progression: String?
    var beginTarget: Int
    var midTarget: Int
    var highTarget: Int
    var timed: Bool
}

struct QelvProgramItem: Codable, Identifiable, Equatable {
    var id: String
    var moveId: String
    var sets: Int
    var amount: Int
    var rest: Int
}

struct QelvProgramDay: Codable, Identifiable, Equatable {
    var id: String
    var title: String
    var items: [QelvProgramItem]
}

struct QelvProgramLine: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var summary: String
    var weeks: Int
    var daysPerWeek: Int
    var difficulty: String
    var needs: String
    var minutes: Int
    var days: [QelvProgramDay]
}

struct QelvNodeLine: Codable, Identifiable, Equatable {
    var id: String
    var title: String
    var moveId: String
    var target: Int
    var timed: Bool
    var perSide: Bool
    var how: String
    var flowCount: Int
}

struct QelvPathLine: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var summary: String
    var nodes: [QelvNodeLine]
}

struct QelvBadgeLine: Codable, Identifiable, Equatable {
    var id: String
    var title: String
    var detail: String
}

struct QelvBook: Codable, Equatable {
    var moves: [QelvMoveLine]
    var programs: [QelvProgramLine]
    var paths: [QelvPathLine]
    var badges: [QelvBadgeLine]
    var reminders: [String]

    func qelvMove(_ id: String) -> QelvMoveLine? { moves.first { $0.id == id } }
    func qelvProgram(_ id: String) -> QelvProgramLine? { programs.first { $0.id == id } }
}

enum QelvCatalog {
    static let book: QelvBook = {
        guard let url = Bundle.main.url(forResource: "qelv_book", withExtension: "json") else {
            fatalError("Missing bundled training book")
        }
        do {
            return try JSONDecoder().decode(QelvBook.self, from: Data(contentsOf: url))
        } catch {
            fatalError("Training book could not be read")
        }
    }()
}

enum QelvClock {
    static var cal: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar
    }
    static func key(_ date: Date = Date()) -> String {
        let parts = cal.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }
    static func date(_ key: String) -> Date {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return Date() }
        return cal.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2])) ?? Date()
    }
    static func addDays(_ key: String, _ days: Int) -> String {
        Self.key(cal.date(byAdding: .day, value: days, to: date(key)) ?? Date())
    }
    static func dayDelta(_ from: String, _ to: String) -> Int {
        cal.dateComponents([.day], from: cal.startOfDay(for: date(from)), to: cal.startOfDay(for: date(to))).day ?? 0
    }
    static func weekdayIndex(_ date: Date = Date()) -> Int {
        (cal.component(.weekday, from: date) + 5) % 7
    }
    static func mondayKey(_ date: Date = Date()) -> String {
        let start = cal.startOfDay(for: date)
        let delta = (cal.component(.weekday, from: start) + 5) % 7
        return key(cal.date(byAdding: .day, value: -delta, to: start) ?? start)
    }
    static func dayNumber(_ key: String) -> Int { max(0, dayDelta("2020-01-06", key)) }
}

struct QelvProfileKnot: Codable, Equatable {
    var nickname: String
    var goal: String
    var experience: String
    var equipment: [String]
    var weekdays: [Int]
    var reminderOn: Bool
    var reminderHour: Int
    var reminderMinute: Int
    var riskOn: Bool
    var haptics: Bool
    var keepAwake: Bool
    var units: String
    var restSeconds: Int
    var onboarded: Bool
    var installKey: String
}

struct QelvSessionKnot: Codable, Equatable, Identifiable {
    var id: String
    var date: String
    var duration: Int
    var source: String
    var programDayId: String
    var xp: Int
    var title: String
    var hour: Int
    var note: String? = nil
    var zone: String? = nil
}

struct QelvSetKnot: Codable, Equatable, Identifiable {
    var id: String
    var sessionId: String
    var moveId: String
    var setIndex: Int
    var reps: Int
    var seconds: Int
    var best: Bool
}

struct QelvQuickKnot: Codable, Equatable, Identifiable {
    var id: String
    var date: String
    var activity: String
    var minutes: Int
    var effort: String
    var xp: Int
}

struct QelvTestKnot: Codable, Equatable, Identifiable {
    var id: String
    var date: String
    var movementId: String
    var value: Int
    var timed: Bool
}

struct QelvDayKnot: Codable, Equatable, Identifiable {
    var date: String
    var counted: Bool
    var minutes: Int
    var xp: Int
    var id: String { date }
}

struct QelvEventKnot: Codable, Equatable, Identifiable {
    var id: String
    var date: String
    var kind: String
}

struct QelvQuestKnot: Codable, Equatable, Identifiable {
    var id: String
    var date: String
    var kind: String
    var moveId: String
    var target: Int
    var progress: Int
    var done: Bool
    var title: String
    var xpGiven: Bool
}

struct QelvWeekKnot: Codable, Equatable, Identifiable {
    var weekStart: String
    var moveId: String
    var total: Int
    var ghost: Int
    var beaten: Bool
    var closed: Bool
    var daily: [Int]
    var id: String { weekStart }
}

struct QelvReadinessKnot: Codable, Equatable, Identifiable {
    var date: String
    var sleep: Int
    var muscles: Int
    var energy: Int
    var id: String { date }
}

struct QelvTrailKnot: Identifiable, Equatable {
    var id: String
    var date: String
    var value: Int
    var timed: Bool
    var kind: String
}

struct QelvWeightKnot: Codable, Equatable, Identifiable {
    var id: String
    var date: String
    var value: Double
}

struct QelvPresetKnot: Codable, Equatable, Identifiable {
    var id: String
    var name: String
    var mode: String
    var work: Int
    var rest: Int
    var rounds: Int
}

struct QelvCustomItem: Codable, Equatable, Identifiable {
    var id: String
    var moveId: String
    var sets: Int
    var amount: Int
}

struct QelvCustomKnot: Codable, Equatable, Identifiable {
    var id: String
    var name: String
    var items: [QelvCustomItem]
}

struct QelvPlanItem: Identifiable, Equatable {
    var id: String
    var moveId: String
    var sets: Int
    var amount: Int
    var timed: Bool
    var rest: Int
}

struct QelvCardPlan: Equatable {
    var title: String
    var minutes: Int
    var focus: String
    var difficulty: Int
    var items: [QelvPlanItem]
    var tomorrow: String
    var programDayId: String
}

struct QelvLedgerBlob: Codable, Equatable {
    var profile: QelvProfileKnot
    var xp: Int
    var sessions: [QelvSessionKnot]
    var sets: [QelvSetKnot]
    var quick: [QelvQuickKnot]
    var tests: [QelvTestKnot]
    var skills: [String: String]
    var programId: String
    var programPaused: Bool
    var programDone: [String: [String]]
    var finishedPrograms: [String]
    var days: [QelvDayKnot]
    var streak: Int
    var bestStreak: Int
    var passes: Int
    var passesEarned: Int
    var lastCounted: String
    var sealedThrough: String
    var events: [QelvEventKnot]
    var quests: [QelvQuestKnot]
    var weeks: [QelvWeekKnot]
    var badges: [String: String]
    var weights: [QelvWeightKnot]
    var presets: [QelvPresetKnot]
    var customs: [QelvCustomKnot]
    var favorites: [String]
    var recapSeen: String
    var ghostBeats: Int
    var flowSessions: Int
    var readiness: [QelvReadinessKnot]? = nil

    static func fresh() -> QelvLedgerBlob {
        let today = QelvClock.key()
        return QelvLedgerBlob(
            profile: QelvProfileKnot(nickname: "", goal: "Stay active", experience: "Beginner", equipment: ["none"], weekdays: [0, 2, 4], reminderOn: true, reminderHour: 18, reminderMinute: 0, riskOn: true, haptics: true, keepAwake: true, units: "kg", restSeconds: 60, onboarded: false, installKey: today),
            xp: 0, sessions: [], sets: [], quick: [], tests: [], skills: [:],
            programId: "", programPaused: false, programDone: [:], finishedPrograms: [],
            days: [], streak: 0, bestStreak: 0, passes: 0, passesEarned: 0, lastCounted: "",
            sealedThrough: QelvClock.addDays(today, -1), events: [], quests: [], weeks: [],
            badges: [:], weights: [], presets: [], customs: [], favorites: [], recapSeen: "",
            ghostBeats: 0, flowSessions: 0, readiness: []
        )
    }
}

enum QelvAltitude {
    static let zones = ["Ground", "Rooftop", "Skyline", "Stratosphere", "Orbit", "Deep Space"]
    static func level(for xp: Int) -> Int {
        var remain = xp
        var level = 1
        while level < 30 {
            let step = 120 + 30 * (level - 1)
            if remain < step { break }
            remain -= step
            level += 1
        }
        return level
    }
    static func intoLevel(_ xp: Int) -> (current: Int, need: Int, level: Int) {
        var remain = xp
        var level = 1
        while level < 30 {
            let step = 120 + 30 * (level - 1)
            if remain < step { return (remain, step, level) }
            remain -= step
            level += 1
        }
        return (remain, 0, 30)
    }
    static func zone(for level: Int) -> String {
        let index = min(zones.count - 1, max(0, (level - 1) / 5))
        return zones[index]
    }
    static func zoneLine(_ name: String) -> String {
        switch name {
        case "Ground": return "Feet on the floor. The work starts here."
        case "Rooftop": return "The city is below and the habits are forming."
        case "Skyline": return "The days stack into a taller shape."
        case "Stratosphere": return "The air is thin and the sessions are yours."
        case "Orbit": return "You circle the work you used to chase."
        default: return "The map ends. The sessions do not."
        }
    }
}
