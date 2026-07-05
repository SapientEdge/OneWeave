import SwiftUI
import PhotosUI
import SwiftData

#if canImport(UIKit)
import UIKit
#endif

/// LifeMomentCaptureView - entry point for creating a new life moment.
/// Photos picker -> image preview -> optional reflection -> capture -> reflect sheet.
struct LifeMomentCaptureView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var leashRecords: [DataLeashSettingsRecord]

    @State private var photoItem: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var reflectionText = ""
    @State private var isCapturing = false
    @State private var errorMessage: String?
    @State private var capturedMoment: LifeMoment?

    private var dataLeash: DataLeashSettingsRecord? {
        leashRecords.first
    }

    private var photosEnabled: Bool {
        dataLeash?.toState().isAllowed(.photos) ?? false
    }

    private var canCapture: Bool {
        imageData != nil && photosEnabled && !isCapturing
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Photo") {
                    if let imageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)

                        PhotosPicker(selection: $photoItem, matching: .images) {
                            Label("Choose a different photo", systemImage: "photo.badge.plus")
                        }
                    } else {
                        PhotosPicker(selection: $photoItem, matching: .images) {
                            Label("Choose photo", systemImage: "photo.badge.plus")
                        }
                    }

                    if !photosEnabled {
                        Label("Photos are disabled in Data Leash.", systemImage: "lock")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Reflection (optional)") {
                    TextField("What's the story behind this moment?", text: $reflectionText, axis: .vertical)
                        .lineLimit(3...6)
                }

                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Capture Moment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isCapturing ? "Capturing..." : "Capture") {
                        Task { await capture() }
                    }
                    .disabled(!canCapture)
                }
            }
            .onChange(of: photoItem) { _, newItem in
                Task { await loadImage(from: newItem) }
            }
            .sheet(item: $capturedMoment) { moment in
                LifeMomentReflectionSheet(moment: moment)
            }
        }
    }

    private func loadImage(from item: PhotosPickerItem?) async {
        do {
            imageData = try await item?.loadTransferable(type: Data.self)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func capture() async {
        guard let imageData else { return }
        guard let leash = dataLeash else {
            errorMessage = "Data Leash not initialized."
            return
        }
        guard photosEnabled else {
            errorMessage = LifeMomentError.photosDisabled.localizedDescription
            return
        }

        isCapturing = true
        errorMessage = nil
        defer { isCapturing = false }

        do {
            let trimmedReflection = reflectionText.trimmingCharacters(in: .whitespacesAndNewlines)
            let moment = try await LifeMomentService.capture(
                imageData: imageData,
                userReflection: trimmedReflection.isEmpty ? nil : trimmedReflection,
                modelContext: modelContext,
                dataLeash: leash
            )
            capturedMoment = moment
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    LifeMomentCaptureView()
        .modelContainer(for: [LifeMoment.self, DataLeashSettingsRecord.self], inMemory: true)
}
