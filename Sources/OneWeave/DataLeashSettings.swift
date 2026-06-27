//
//  DataLeashSettings.swift
//  OneWeave
//
//  Privacy-First Data Leash (from Feature Matrix + Unified Blueprint - Critical Tier 1).
//  Granular per-category controls. Default: everything private.
//  Extends existing PrivacyAudit. Ties into LifeEntity.isPrivate + allowedCategories.
//  Honors reflection gates, no telemetry, no cloud by default.
//

import SwiftUI
import SwiftData

// MARK: - DataLeashState (shared, observable)

public struct DataLeashState: Codable, Equatable {
    /// Per-category "may this data leave the device / be processed?". Default: false (strict).
    public var allowedCategories: [IntegrationCategory: Bool]
    /// Per-category "is this data considered sensitive / private?". Default: true (conservative).
    public var privacyLevels: [IntegrationCategory: Bool]

    public static let strictDefault = DataLeashState(
        allowedCategories: Dictionary(uniqueKeysWithValues: IntegrationCategory.allCases.map { ($0, false) }),
        privacyLevels: Dictionary(uniqueKeysWithValues: IntegrationCategory.allCases.map { ($0, true) })
    )

    public func isAllowed(_ cat: IntegrationCategory) -> Bool {
        allowedCategories[cat] ?? false
    }
    public func isPrivate(_ cat: IntegrationCategory) -> Bool {
        privacyLevels[cat] ?? true
    }

    public mutating func setAllowed(_ cat: IntegrationCategory, _ allowed: Bool) {
        allowedCategories[cat] = allowed
    }
    public mutating func setPrivate(_ cat: IntegrationCategory, _ priv: Bool) {
        privacyLevels[cat] = priv
    }
}

// MARK: - Persisted in SwiftData (so settings survive app restarts)

@Model
public final class DataLeashSettingsRecord {
    @Attribute(.unique) public var id: String = "oneweave.data-leash"
    public var allowedJSON: Data
    public var privacyJSON: Data
    public var updatedAt: Date

    public init(state: DataLeashState = .strictDefault) {
        let enc = JSONEncoder()
        self.allowedJSON = (try? enc.encode(state.allowedCategories)) ?? Data()
        self.privacyJSON = (try? enc.encode(state.privacyLevels)) ?? Data()
        self.updatedAt = Date()
    }

    public func toState() -> DataLeashState {
        let dec = JSONDecoder()
        let allowed = (try? dec.decode([IntegrationCategory: Bool].self, from: allowedJSON)) ?? [:]
        let privacy = (try? dec.decode([IntegrationCategory: Bool].self, from: privacyJSON)) ?? [:]
        return DataLeashState(
            allowedCategories: allowed,
            privacyLevels: privacy
        )
    }

    public func apply(_ state: DataLeashState) {
        let enc = JSONEncoder()
        self.allowedJSON = (try? enc.encode(state.allowedCategories)) ?? Data()
        self.privacyJSON = (try? enc.encode(state.privacyLevels)) ?? Data()
        self.updatedAt = Date()
    }
}

// MARK: - Settings View (SwiftUI)

public struct DataLeashSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var state: DataLeashState = .strictDefault

    public init() {}

    public var body: some View {
        Form {
            Section {
                Text("Choose what leaves your device. Default: everything stays private and local.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Data Leash (Privacy Controls)")
            }

            ForEach(IntegrationCategory.allCases, id: \.self) { cat in
                Section {
                    Toggle(isOn: Binding(
                        get: { state.isAllowed(cat) },
                        set: { state.setAllowed(cat, $0) }
                    )) {
                        Label(cat.rawValue.capitalized, systemImage: icon(for: cat))
                    }
                    Toggle(isOn: Binding(
                        get: { state.isPrivate(cat) },
                        set: { state.setPrivate(cat, $0) }
                    )) {
                        Text("Mark as private (sensitive)")
                    }
                    .tint(.red)
                }
            }

            Section("Current Graph") {
                Text("All Life Graph entities respect these settings. Integrations block reads when not allowed.")
                    .font(.caption)
            }

            Section {
                Button("Save") { save() }
                    .buttonStyle(.borderedProminent)
                Button("Reset to Strict Default", role: .destructive) {
                    state = .strictDefault
                    save()
                }
            }
        }
        .navigationTitle("Data Leash")
        .onAppear(perform: load)
    }

    private func icon(for cat: IntegrationCategory) -> String {
        switch cat {
        case .calendar:   return "calendar"
        case .reminders:  return "checklist"
        case .contacts:   return "person.2"
        case .health:     return "heart.fill"
        case .notes:      return "note.text"
        case .mail:       return "envelope"
        }
    }

    private func load() {
        let descriptor = FetchDescriptor<DataLeashSettingsRecord>(
            predicate: #Predicate { $0.id == "oneweave.data-leash" }
        )
        if let existing = (try? modelContext.fetch(descriptor))?.first {
            state = existing.toState()
        } else {
            let record = DataLeashSettingsRecord()
            modelContext.insert(record)
            try? modelContext.save()
            state = .strictDefault
        }
    }

    private func save() {
        let descriptor = FetchDescriptor<DataLeashSettingsRecord>(
            predicate: #Predicate { $0.id == "oneweave.data-leash" }
        )
        if let existing = (try? modelContext.fetch(descriptor))?.first {
            existing.apply(state)
        } else {
            let record = DataLeashSettingsRecord(state: state)
            modelContext.insert(record)
        }
        try? modelContext.save()
    }
}

// MARK: - Convenience accessor for code that needs the leash state.

public extension LifeContext {
    /// Fetch the current DataLeashState. Caller is expected to refresh after settings changes.
    /// Nemotron finding #7: previously hardcoded to .strictDefault — now actually reads from
    /// the shared ModelContainer so user toggles are honoured by every integration call.
    @MainActor
    func currentLeash(in modelContext: ModelContext? = nil) -> DataLeashState {
        guard let mc = modelContext else {
            // No context available (e.g. pure compute path). Default strict so we err on privacy.
            return .strictDefault
        }
        let descriptor = FetchDescriptor<DataLeashSettingsRecord>(
            predicate: #Predicate { $0.id == "oneweave.data-leash" }
        )
        if let record = (try? mc.fetch(descriptor))?.first {
            return record.toState()
        }
        return .strictDefault
    }

    /// Backwards-compatible no-arg variant for code paths without a modelContext handy.
    /// Strict default — fail safe.
    func currentLeash() -> DataLeashState {
        .strictDefault
    }
}
