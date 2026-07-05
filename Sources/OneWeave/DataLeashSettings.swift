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

    // MARK: - Cycle 33 / GLM A7: Guest Mode (one-tap leash)
    //
    // A single toggle that flips all 9 categories to deny and treats every
    // category as private. The Mac side exposes a "Guest Mode" button in
    // Settings that triggers this. Restore requires a reflection-gated step.
    // Used when lending the device, entering a high-risk context, or
    // simply wanting to feel "the app forgets me for an hour."
    public mutating func enableGuestMode() {
        for cat in IntegrationCategory.allCases {
            allowedCategories[cat] = false
            privacyLevels[cat] = true
        }
    }

    /// Returns the categories whose allowed-state differs from `strictDefault`.
    /// Used by Settings to show "X categories are not in default state".
    public var deviatingCategories: [IntegrationCategory] {
        IntegrationCategory.allCases.filter { cat in
            allowedCategories[cat] != false || privacyLevels[cat] != true
        }
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
                        // B3: route through requestToggle which gates false→true
                        set: { requestToggle(cat, to: $0) }
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
        // B3: reflection prompt sheet for false→true toggles
        .sheet(item: $pendingToggleCategory) { cat in
            DataLeashReflectionSheet(
                category: cat,
                reflection: $pendingReflection,
                onConfirm: {
                    let trimmed = pendingReflection.trimmingCharacters(in: .whitespacesAndNewlines)
                    // Use the central gate: validate + entropy check (Constitution §6 anti-bypass)
                    if !trimmed.isEmpty && ReflectionGate.passesEntropyCheck(trimmed) {
                        state.setAllowed(cat, pendingToggleValue)
                        // Record the rationale in essenceLedger so the user can audit later
                        if let lc = (try? modelContext.fetch(FetchDescriptor<LifeContext>()))?.first {
                            lc.essenceLedger.append(
                                "data_leash:\(cat.rawValue):\(Date().ISO8601Format()) — \(trimmed.prefix(80))"
                            )
                            try? modelContext.save()
                        }
                    }
                    pendingToggleCategory = nil
                    pendingReflection = ""
                },
                onCancel: {
                    pendingToggleCategory = nil
                    pendingReflection = ""
                }
            )
        }
    }

    // B3: confirmation sheet that asks the user WHY before allowing egress. The
    // reflection is required (non-empty + passes entropy) and recorded in the
    // essence ledger so users can audit their own past decisions.

    private func icon(for cat: IntegrationCategory) -> String {
        switch cat {
        case .calendar:   return "calendar"
        case .reminders:  return "checklist"
        case .contacts:   return "person.2"
        case .health:     return "heart.fill"
        case .notes:      return "note.text"
        case .mail:       return "envelope"
        case .bodyThread: return "waveform.path.ecg"
        case .p2p:        return "person.crop.circle.dashed"
        case .insights:   return "sparkles"
        case .photos:     return "photo.on.rectangle.angled"
        }
    }

    // B3 (Claude round-5 audit): when the user turns a category ON (false→true),
    // require a one-line reflection via the central ReflectionGate. The reflection
    // is recorded as a ledger entry so the user can review what they enabled and why.
    // Constitution §4: "lasting consequence requires a non-empty reflection".
    // Enabling data egress is the most consequential setting in the app.
    @State private var pendingToggleCategory: IntegrationCategory? = nil
    @State private var pendingToggleValue: Bool = false
    @State private var pendingReflection: String = ""

    private func requestToggle(_ cat: IntegrationCategory, to value: Bool) {
        let current = state.isAllowed(cat)
        // Only gate false → true (enabling data egress). Disabling is always allowed.
        if !current && value {
            pendingToggleCategory = cat
            pendingToggleValue = value
            pendingReflection = ""
        } else {
            state.setAllowed(cat, value)
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

// `internal` not `public` — LifeContext is internal, so its extension must be too.
extension LifeContext {
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

// MARK: - B3 reflection sheet

/// Shown when the user toggles a data-leash category from OFF to ON.
/// Constitution §4: lasting consequence requires a non-empty reflection.
/// The reflection is validated through the central ReflectionGate
/// (non-empty + passes entropy check) and recorded in the essenceLedger
/// so the user can audit their own past decisions later.
struct DataLeashReflectionSheet: View {
    let category: IntegrationCategory
    @Binding var reflection: String
    let onConfirm: () -> Void
    let onCancel: () -> Void

    private var trimmed: String {
        reflection.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    private var passesGate: Bool {
        !trimmed.isEmpty && ReflectionGate.passesEntropyCheck(trimmed)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label(category.rawValue.capitalized, systemImage: icon(for: category))
                            .font(.headline)
                        Text("Allowing **\(category.rawValue)** data to leave your private space is a meaningful decision.")
                            .font(.body)
                        Text("Take a moment. Why now? What do you hope to gain?")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Section("Your reflection") {
                    TextEditor(text: $reflection)
                        .frame(minHeight: 100)
                    if !trimmed.isEmpty && !passesGate {
                        Label("Add a few more words, with real variety. One sentence is enough.")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }
                Section {
                    Button("Allow and Save") { onConfirm() }
                        .buttonStyle(.borderedProminent)
                        .disabled(!passesGate)
                    Button("Cancel", role: .cancel) { onCancel() }
                }
                Section {
                    Text("Your reason will be recorded privately in your essence ledger, so you can revisit and revoke at any time.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Reflection Gate")
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled(true)
        }
        .presentationDetents([.large])
    }

    private func icon(for cat: IntegrationCategory) -> String {
        switch cat {
        case .calendar:   return "calendar"
        case .reminders:  return "checklist"
        case .contacts:   return "person.2"
        case .health:     return "heart.fill"
        case .notes:      return "note.text"
        case .mail:       return "envelope"
        case .bodyThread: return "waveform.path.ecg"
        case .p2p:        return "person.crop.circle.dashed"
        case .insights:   return "sparkles"
        case .photos:     return "photo.on.rectangle.angled"
        }
    }
}
