import SwiftUI
import SwiftData

/// LifeMomentReflectionSheet - follow-up sheet after capture.
/// Lets user add reflection, choose thread, optionally seal.
/// Persists only through LifeMomentService.attachToThread and LifeMomentService.seal.
/// Per Invariant 11: OCR text is NEVER shown to user here; user adds their own reflection only.
struct LifeMomentReflectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let moment: LifeMoment

    @State private var reflection = ""
    @State private var selectedThread: MomentThreadAssignment = .basicSelf
    @State private var sealRequested = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Reflection") {
                    TextField("What does this moment mean to you?", text: $reflection, axis: .vertical)
                        .lineLimit(3...8)
                }
                Section("Thread") {
                    Picker("Assign to thread", selection: $selectedThread) {
                        ForEach(MomentThreadAssignment.allCases, id: \.self) { thread in
                            Text(displayName(for: thread)).tag(thread)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Section("Privacy") {
                    Toggle("Seal moment (encrypt OCR + embeddings)", isOn: $sealRequested)
                    Text("Once sealed, OCR text and image embeddings are encrypted. Only your reflection stays searchable.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Reflect")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(trimmedReflection.isEmpty)
                }
            }
            .onAppear {
                if reflection.isEmpty {
                    reflection = moment.userReflection ?? ""
                }
                if let raw = moment.userAssignedThreadRaw,
                   let parsed = MomentThreadAssignment(rawValue: raw) {
                    selectedThread = parsed
                }
            }
        }
    }

    private var trimmedReflection: String {
        reflection.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    @MainActor
    private func save() {
        guard !trimmedReflection.isEmpty else { errorMessage = "Reflection cannot be empty."; return }

        moment.setUserReflection(trimmedReflection)
        LifeMomentService.attachToThread(moment, thread: selectedThread, modelContext: modelContext)
        if sealRequested && !moment.isSealed {
            do {
                _ = try LifeMomentService.seal(moment)
            } catch {
                errorMessage = "Seal failed: \(error.localizedDescription)"
                return
            }
        }

        do { try modelContext.save(); dismiss() } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func displayName(for thread: MomentThreadAssignment) -> String {
        switch thread {
        case .basicSelf: return "Self"
        case .stewardship: return "Stew."
        case .careKin: return "Care"
        case .meaning: return "Meaning"
        }
    }
}

#Preview {
    LifeMomentReflectionSheet(moment: LifeMoment(userReflection: "test"))
        .modelContainer(for: LifeMoment.self, inMemory: true)
}
