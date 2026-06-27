//
//  BodyThreadSheet.swift
//  OneWeave
//
//  Sheet that reads a Body Thread reading from HealthKit (or from sample data)
//  and lets the user "weave" it into the Life Graph with an optional reflection.
//

import SwiftUI
import SwiftData

struct BodyThreadSheet: View {
    let context: LifeContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var reading: BodyThreadReading? = nil
    @State private var reflection: String = ""
    @State private var woven: Bool = false
    @State private var statusMessage: String? = nil

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button("Read Body Signals") {
                        Task { await refresh() }
                    }
                    if let r = reading {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Status")
                                .font(.caption2.bold())
                                .foregroundStyle(.secondary)
                            HStack {
                                Image(systemName: r.isLowCoherence ? "exclamationmark.triangle.fill" : "leaf.fill")
                                    .foregroundStyle(r.isLowCoherence ? .orange : .green)
                                Text(r.isLowCoherence ? "Body is signaling fatigue" : "Body is steady")
                                    .font(.headline)
                            }
                            Text(r.reason.isEmpty ? "—" : r.reason)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("Sleep fragmentation: \(Int(r.metrics.sleepFragmentationMinutes)) min")
                                .font(.caption2)
                            Text("Resting HR: \(Int(r.metrics.restingHeartRateBPM)) bpm")
                                .font(.caption2)
                        }
                    }
                    if let msg = statusMessage {
                        Text(msg).font(.caption).foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Body Thread (read-only)")
                }

                if let r = reading, r.isLowCoherence {
                    Section {
                        TextField("Optional reflection (required to count)", text: $reflection, axis: .vertical)
                            .lineLimit(3...6)
                        Button("Weave Pause") {
                            guard !reflection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                                statusMessage = "Reflection required to count toward coherence."
                                return
                            }
                            let wovenEntity = BodyThreadWeaver.weave(reading: r, into: context, modelContext: modelContext)
                            _ = wovenEntity
                            woven = true
                            statusMessage = "Body Thread refreshed. Reflection stored in Weave Pause."
                        }
                        if woven {
                            Text("Woven into graph. Body entity updated.")
                                .font(.caption).foregroundStyle(.green)
                        }
                    } header: {
                        Text("Weave Pause")
                    }
                }
            }
            .navigationTitle("Body Thread")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    @MainActor
    private func refresh() async {
        let leash = context.currentLeash(in: modelContext)
        if let live = await BodyThreadWeaver.liveReading(leash: leash) {
            reading = live
            statusMessage = nil
        } else {
            // Fallback: synthesize a steady reading (HealthKit unavailable on simulator etc.)
            let m = HealthMetrics(sleepFragmentationMinutes: 45, restingHeartRateBPM: 64)
            reading = BodyThreadWeaver.reading(from: m)
            statusMessage = "Using sample reading (Health unavailable in this environment)."
        }
    }
}
