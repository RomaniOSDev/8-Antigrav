import SwiftUI
import StoreKit
import UniformTypeIdentifiers
import UserNotifications

struct NyrelProfileNook: View {
    @EnvironmentObject private var vault: QelvOrbitVault
    var body: some View {
        let level = QelvAltitude.level(for: vault.blob.xp)
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(vault.blob.profile.nickname.isEmpty ? "Profile" : vault.blob.profile.nickname)
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .foregroundStyle(Color.qelvPaper)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Level \(level) · \(QelvAltitude.zone(for: level))")
                    .foregroundStyle(Color.qelvMint)
                Text(vault.blob.profile.goal)
                    .foregroundStyle(Color.qelvMist)
                Text("Sessions \(vault.blob.sessions.count) · XP \(vault.blob.xp)")
                    .foregroundStyle(Color.qelvPaper)
                    .monospacedDigit()
                if !vault.blob.programId.isEmpty {
                    Text(vault.blob.programPaused ? "Program paused" : "Program active")
                        .foregroundStyle(Color.qelvPaper)
                }
                NavigationLink(value: QelvPath.badges) { Text("Achievements").foregroundStyle(Color.qelvPaper).qelvCard() }.buttonStyle(.plain)
                NavigationLink(value: QelvPath.recap) { Text("Monthly recap").foregroundStyle(Color.qelvPaper).qelvCard() }.buttonStyle(.plain)
                NavigationLink(value: QelvPath.settings) { Text("Settings").foregroundStyle(Color.qelvPaper).qelvCard() }.buttonStyle(.plain)
                gearEditor
            }
            .padding(16)
            .padding(.bottom, 90)
        }
        .qelvScreen(image: "home_hero_banner", opacity: 0.18)
    }

    private var gearEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Equipment and goal").font(.headline).foregroundStyle(Color.qelvPaper)
            ForEach(["Build strength", "Lose fat", "Learn skills", "Stay active"], id: \.self) { goal in
                Button(goal) {
                    vault.blob.profile.goal = goal
                    vault.qelvWake()
                }
                .foregroundStyle(vault.blob.profile.goal == goal ? Color.qelvVoid : Color.qelvPaper)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background { Capsule().fill(vault.blob.profile.goal == goal ? Color.qelvMint : Color.qelvLift) }
            }
            ForEach(["none", "bar", "dip", "rings", "band"], id: \.self) { item in
                Button(item == "none" ? "No equipment" : item) {
                    if vault.blob.profile.equipment.contains(item) {
                        vault.blob.profile.equipment.removeAll { $0 == item }
                    } else {
                        vault.blob.profile.equipment.append(item)
                    }
                    if vault.blob.profile.equipment.isEmpty { vault.blob.profile.equipment = ["none"] }
                    vault.qelvWake()
                }
                .foregroundStyle(vault.blob.profile.equipment.contains(item) ? Color.qelvMint : Color.qelvPaper)
            }
        }
        .qelvCard()
    }
}

struct NyrelSettingsPane: View {
    @EnvironmentObject private var vault: QelvOrbitVault
    @State private var units = "kg"
    @State private var rest = 60
    @State private var remind = true
    @State private var risk = true
    @State private var haptics = true
    @State private var awake = true
    @State private var clock = Date()
    @State private var days: Set<Int> = [0, 2, 4]
    @State private var importing = false
    @State private var erase1 = false
    @State private var erase2 = false
    @State private var exportURL: URL?
    @State private var denied = false
    private let names = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Settings").font(.system(.largeTitle, design: .rounded).weight(.bold)).foregroundStyle(Color.qelvPaper)
                Picker("Units", selection: $units) {
                    Text("kg").tag("kg")
                    Text("lb").tag("lb")
                }
                .pickerStyle(.segmented)
                Stepper("Rest \(rest) seconds", value: $rest, in: 15...180, step: 15).foregroundStyle(Color.qelvPaper)
                Toggle("Reminder", isOn: $remind).tint(Color.qelvMint).foregroundStyle(Color.qelvPaper)
                DatePicker("Time", selection: $clock, displayedComponents: .hourAndMinute).foregroundStyle(Color.qelvPaper)
                Toggle("Charge at risk", isOn: $risk).tint(Color.qelvMint).foregroundStyle(Color.qelvPaper)
                Toggle("Haptics", isOn: $haptics).tint(Color.qelvMint).foregroundStyle(Color.qelvPaper)
                Toggle("Keep screen awake", isOn: $awake).tint(Color.qelvMint).foregroundStyle(Color.qelvPaper)
                Text("Training days").foregroundStyle(Color.qelvPaper)
                ForEach(0..<7, id: \.self) { index in
                    Button(names[index]) {
                        if days.contains(index) { days.remove(index) } else { days.insert(index) }
                    }
                    .foregroundStyle(days.contains(index) ? Color.qelvVoid : Color.qelvPaper)
                    .padding(8)
                    .background { Capsule().fill(days.contains(index) ? Color.qelvMint : Color.qelvLift) }
                }
                if denied {
                    Text("Reminders are off in system settings.").foregroundStyle(Color.qelvMist).fixedSize(horizontal: false, vertical: true)
                    Button("Open system settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                    }
                    .foregroundStyle(Color.qelvMint)
                }
                QelvGradientButton(title: "Save settings") { save() }
                Button("Rate us") { rateApp() }.foregroundStyle(Color.qelvPaper)
                Button("Privacy") { openLink(QelvLinkEnum.privacy) }.foregroundStyle(Color.qelvPaper)
                Button("Terms") { openLink(QelvLinkEnum.terms) }.foregroundStyle(Color.qelvPaper)
                if let exportURL {
                    ShareLink(item: exportURL) { Text("Export data").foregroundStyle(Color.qelvMint) }
                }
                Button("Reset all data") { erase1 = true }.foregroundStyle(Color.qelvAlarm)
                if !vault.importNote.isEmpty {
                    Text(vault.importNote).foregroundStyle(Color.qelvMist).fixedSize(horizontal: false, vertical: true)
                }
                Button("Import data") { importing = true }.foregroundStyle(Color.qelvPaper)
            }
            .padding(16)
        }
        .onAppear(perform: load)
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
            if case let .success(url) = result { vault.qelvImport(url) }
        }
        .alert("Erase everything?", isPresented: $erase1) {
            Button("Continue", role: .destructive) { erase2 = true }
            Button("Cancel", role: .cancel) {}
        }
        .alert("This cannot be undone. Erase all data?", isPresented: $erase2) {
            Button("Erase", role: .destructive) { vault.qelvErase() }
            Button("Cancel", role: .cancel) {}
        }
        .navigationBarTitleDisplayMode(.inline)
        .qelvScreen()
    }

    private func load() {
        units = vault.blob.profile.units
        rest = vault.blob.profile.restSeconds
        remind = vault.blob.profile.reminderOn
        risk = vault.blob.profile.riskOn
        haptics = vault.blob.profile.haptics
        awake = vault.blob.profile.keepAwake
        days = Set(vault.blob.profile.weekdays)
        var parts = DateComponents()
        parts.hour = vault.blob.profile.reminderHour
        parts.minute = vault.blob.profile.reminderMinute
        clock = Calendar.current.date(from: parts) ?? Date()
        exportURL = vault.qelvExportURL()
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async { denied = settings.authorizationStatus == .denied }
        }
    }

    private func save() {
        let parts = Calendar.current.dateComponents([.hour, .minute], from: clock)
        vault.blob.profile.units = units
        vault.blob.profile.restSeconds = rest
        vault.blob.profile.reminderOn = remind
        vault.blob.profile.riskOn = risk
        vault.blob.profile.haptics = haptics
        vault.blob.profile.keepAwake = awake
        vault.blob.profile.weekdays = days.sorted()
        vault.blob.profile.reminderHour = parts.hour ?? 18
        vault.blob.profile.reminderMinute = parts.minute ?? 0
        if remind { QelvNotify.qelvAsk { _ in QelvNotify.qelvRefresh(vault.blob) } }
        else { QelvNotify.qelvRefresh(vault.blob) }
        exportURL = vault.qelvExportURL()
        vault.qelvWake()
    }

    private func rateApp() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }

    private func openLink(_ raw: String) {
        if let url = URL(string: raw) {
            UIApplication.shared.open(url)
        }
    }
}
