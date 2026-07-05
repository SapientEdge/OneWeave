import SwiftUI
import SwiftData

#if canImport(UIKit)
import UIKit
#endif

/// LifeMomentDetailView — full view for a single LifeMoment.
/// User can edit reflection, change thread, unseal OCR into memory,
/// seal inferred content, and promote the reflected moment to a quest.
struct LifeMomentDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var moment: LifeMoment

    @State private var editedReflection = ""
    @State private var selectedThread: MomentThreadAssignment = .basicSelf
    @State private var unsealedPayload: MomentPayload?
    @State private var showUnsealConfirm = false
    @State private var errorMessage: String?
    @State private var promotedQuest: WeaveQuest?
    @State private var hasPromoted = false

    private var trimmedReflection: String { editedReflection.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var hasReflection: Bool { !trimmedReflection.isEmpty }

    var body: some View {
        Form {
            Section("Image") { momentImage.frame(maxWidth: .infinity).padding(.vertical, 12) }

            Section("Reflection") {
                TextField("Reflection", text: $editedReflection, axis: .vertical)
                    .lineLimit(4...12)
            }

            Section("Thread") {
                Picker("Assign to", selection: $selectedThread) {
                    Text("Self").tag(MomentThreadAssignment.basicSelf)
                    Text("Stewardship").tag(MomentThreadAssignment.stewardship)
                    Text("Care & Kin").tag(MomentThreadAssignment.careKin)
                    Text("Meaning").tag(MomentThreadAssignment.meaning)
                }
            }

            Section("Status") {
                LabeledContent("Created", value: moment.createdAt.formatted(date: .abbreviated, time: .shortened))
                LabeledContent("Modified", value: moment.modifiedAt.formatted(date: .abbreviated, time: .shortened))
                LabeledContent("Sealed") {
                    if moment.isSealed { Label("Yes", systemImage: "lock.fill") } else { Text("No") }
                }
            }

            if let unsealedPayload {
                Section("Sealed content (visible after unseal)") {
                    payloadRow("OCR text", unsealedPayload.ocrText, emptyText: "(empty)", lineLimit: 4)
                    LabeledContent("Embedding length") { Text("\(unsealedPayload.imageEmbeddingText.count) chars").font(.caption) }
                    payloadRow("Detected entities", unsealedPayload.detectedEntitiesJSON, emptyText: "(none)", lineLimit: 3)
                }
            }

            Section("Actions") {
                if moment.isSealed {
                    Button { requestUnseal() } label: { Label("Unseal to view OCR", systemImage: "lock.open") }
                        .disabled(!hasReflection)
                } else {
                    Button { seal() } label: { Label("Re-seal", systemImage: "lock.fill") }
                }
                Button { promoteToQuest() } label: { Label("Promote to quest", systemImage: "arrow.up.forward.app") }
                    .disabled(!hasReflection || hasPromoted)
            }

            if let errorMessage {
                Section { Label(errorMessage, systemImage: "exclamationmark.triangle").foregroundStyle(.red) }
            }
        }
        .navigationTitle("Moment")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Save") { save() } } }
        .onAppear(perform: loadState)
        .confirmationDialog("Unseal this moment?", isPresented: $showUnsealConfirm) {
            Button("Unseal", role: .destructive) { unseal() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The OCR text and embeddings will be decrypted for viewing. They remain in memory until you leave this view.")
        }
        .sheet(item: $promotedQuest) { quest in
            NavigationStack {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.seal.fill").font(.system(size: 48)).foregroundStyle(.green)
                    Text("Promoted to quest").font(.title2.bold())
                    Text(quest.title).foregroundStyle(.secondary).multilineTextAlignment(.center)
                }
                .padding()
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            }
            .presentationDetents([.medium])
        }
    }

    @ViewBuilder
    private var momentImage: some View {
        #if canImport(UIKit)
        if let data = moment.imageEmbeddingText, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage).resizable().scaledToFit().clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            placeholderImage
        }
        #else
        placeholderImage
        #endif
    }

    private var placeholderImage: some View {
        Image(systemName: "photo")
            .font(.system(size: 44))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, minHeight: 120)
            .background(Color.secondary.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func payloadRow(_ title: String, _ value: String, emptyText: String, lineLimit: Int) -> some View {
        LabeledContent(title) { Text(value.isEmpty ? emptyText : value).font(.caption).lineLimit(lineLimit) }
    }

    private func loadState() {
        editedReflection = moment.userReflection ?? ""
        if let raw = moment.userAssignedThreadRaw, let parsed = MomentThreadAssignment(rawValue: raw) {
            selectedThread = parsed
        }
    }

    private func save() {
        moment.setUserReflection(trimmedReflection.isEmpty ? nil : trimmedReflection)
        LifeMomentService.attachToThread(moment, thread: selectedThread, modelContext: modelContext)
        try? modelContext.save()
        dismiss()
    }

    private func requestUnseal() {
        guard hasReflection else {
            errorMessage = "Add a non-empty reflection before unsealing."
            return
        }
        showUnsealConfirm = true
    }

    private func seal() {
        do {
            _ = try LifeMomentService.seal(moment)
            unsealedPayload = nil
            try? modelContext.save()
        } catch {
            errorMessage = "Seal failed: \(error.localizedDescription)"
        }
    }

    private func unseal() {
        moment.setUserReflection(trimmedReflection)
        do {
            unsealedPayload = try LifeMomentService.unseal(moment)
            errorMessage = nil
        } catch {
            errorMessage = "Unseal failed: \(error.localizedDescription)"
        }
    }

    private func promoteToQuest() {
        guard hasReflection else {
            errorMessage = "Add a non-empty reflection before promoting."
            return
        }
        moment.setUserReflection(trimmedReflection)
        do {
            promotedQuest = try LifeMomentService.promoteToQuest(moment, modelContext: modelContext)
            hasPromoted = true
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        LifeMomentDetailView(moment: LifeMoment(userReflection: "Beautiful sunset at the lake."))
    }
}
