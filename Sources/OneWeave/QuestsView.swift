import SwiftUI
import SwiftData

// Phase 6: Lightweight QuestsView (or use as modal). Lists suggested/active + reflection flow.
// Reuses QuestService + LifeContext. Calm, IRL-first. Keep simple.
struct QuestsView: View {
    @Query private var contexts: [LifeContext]
    @Environment(\.modelContext) private var modelContext
    @State private var showReflectionFor: UUID?
    @State private var reflectionText: String = ""
    @State private var feedback: String = ""
    
    var body: some View {
        if let ctx = contexts.first {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("🎯 Quests")
                        .font(.title2.bold())
                    Text("Suggested by your threads & energy. Complete IRL, reflect for full reward.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    let suggested = QuestService.shared.generateSuggestedQuests(from: ctx, recentEvents: [])
                    let active = ctx.activeQuests
                    
                    if !suggested.isEmpty {
                        Text("Suggested").font(.headline)
                        ForEach(suggested.prefix(3), id: \.id) { q in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(q.title).font(.subheadline.bold())
                                Text(q.description).font(.caption)
                                HStack {
                                    Text("~\(q.estimatedIRLMinutes) min • +\(q.baseEssence) Essence")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Button("Accept") {
                                        QuestService.shared.acceptQuest(q, context: ctx, modelContext: modelContext)
                                        feedback = "Accepted: \(q.title). Do it IRL."
                                    }
                                    .buttonStyle(.bordered)
                                    .font(.caption)
                                }
                            }
                            .padding(8)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    
                    if !active.isEmpty {
                        Text("Active").font(.headline).padding(.top)
                        ForEach(active, id: \.self) { qid in
                            Text("Active quest ID: \(qid.uuidString.prefix(8))... (complete in flows)")
                                .font(.caption)
                        }
                    }
                    
                    if !feedback.isEmpty {
                        Text(feedback).font(.caption).foregroundStyle(.green)
                    }
                    
                    Button("Open Reflection for Last") {
                        if let last = active.last {
                            showReflectionFor = last
                        } else {
                            feedback = "Accept a quest first."
                        }
                    }
                    .buttonStyle(.bordered)
                    
                    if let qid = showReflectionFor {
                        VStack {
                            Text("Reflect (required for full reward)")
                            TextField("What happened IRL?", text: $reflectionText)
                                .textFieldStyle(.roundedBorder)
                            Button("Complete with Reflection") {
                                QuestService.shared.completeWithReflection(questId: qid, reflection: reflectionText, context: ctx, modelContext: modelContext)
                                feedback = "Reflected. +Essence awarded."
                                reflectionText = ""
                                showReflectionFor = nil
                            }
                            .disabled(reflectionText.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                        .padding()
                        .background(.thinMaterial)
                    }
                    
                    Text("All local. Reflection gate for anti-grind. See History for ripples.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding()
            }
        } else {
            Text("Seed in Prototype.")
                .padding()
        }
    }
}
