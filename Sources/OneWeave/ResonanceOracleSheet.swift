//
//  ResonanceOracleSheet.swift
//  OneWeave
//
//  SwiftUI sheet for the Resonance Oracle (local decision simulator).
//  Privacy: stays on-device; respects reflection gate before any weave commit.
//

import SwiftUI

struct ResonanceOracleSheet: View {
    let context: LifeContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var scenario: String = ""
    @State private var simulation: ResonanceSimulation? = nil
    @State private var reflection: String = ""
    @State private var committedMessage: String? = nil

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Describe a decision you're weighing. The Oracle will simulate impact on your Life Graph locally.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("e.g. Taking on a new project this month", text: $scenario, axis: .vertical)
                        .lineLimit(2...4)
                } header: {
                    Text("Scenario")
                }

                Section {
                    Button("Simulate Resonance") {
                        let trimmed = scenario.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        simulation = ResonanceOracle.simulate(scenario: trimmed, context: context)
                    }
                    .disabled(scenario.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                if let sim = simulation {
                    Section {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Predicted Coherence Delta")
                                .font(.caption2.bold())
                                .foregroundStyle(.secondary)
                            Text(String(format: "%+.2f", sim.coherenceDelta))
                                .font(.title2.bold())
                                .foregroundStyle(sim.coherenceDelta >= 0 ? .green : .orange)
                            Text("Essence cost: \(Int(sim.essenceCost)) • Harmony ripple: \(String(format: "%+.2f", sim.harmonyImpact))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if !sim.threadRipples.isEmpty {
                            ForEach(sim.threadRipples.sorted(by: { $0.value > $1.value }), id: \.key) { k, v in
                                HStack {
                                    Text(k).font(.caption)
                                    Spacer()
                                    Text(String(format: "%+.2f", v))
                                        .font(.caption.bold())
                                        .foregroundStyle(v >= 0 ? .green : .orange)
                                }
                            }
                        }
                        if !sim.suggestedMicroWeaves.isEmpty {
                            Text("Micro-weaves to try")
                                .font(.caption.bold())
                                .padding(.top, 4)
                            ForEach(sim.suggestedMicroWeaves, id: \.self) { s in
                                Text("• \(s)").font(.caption)
                            }
                        }
                        if !sim.riskNotes.isEmpty {
                            Text("Risks")
                                .font(.caption.bold())
                                .foregroundStyle(.red)
                                .padding(.top, 4)
                            ForEach(sim.riskNotes, id: \.self) { s in
                                Text("• \(s)").font(.caption)
                            }
                        }
                    } header: {
                        Text("Simulation")
                    }

                    Section {
                        Text("Reflection required to commit.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("What do you want to remember about this decision?", text: $reflection, axis: .vertical)
                            .lineLimit(3...8)
                        Button("Commit Weave (with reflection)") {
                            guard let s = simulation else { return }
                            ResonanceOracle.commitWeave(from: s, into: context, userReflection: reflection, modelContext: modelContext)
                            committedMessage = "Weave committed. Reflection stored with entity."
                            reflection = ""
                            simulation = nil
                        }
                        .disabled(reflection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        if let msg = committedMessage {
                            Text(msg).font(.caption).foregroundStyle(.green)
                        }
                    } header: {
                        Text("Commit")
                    }
                }
            }
            .navigationTitle("Resonance Oracle")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
