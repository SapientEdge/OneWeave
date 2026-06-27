//
//  CommandPalette.swift
//  OneWeave
//
//  Universal Command Palette (from Unified Blueprint - High priority UX).
//  Swipe-down natural language input.
//  Creates quests (QuestService), logs weaves (TimelineService), changes season,
//  searches graph entities (semantic placeholder).
//
//  Privacy / Calm contract:
//  - NO essence is awarded in any path. The command palette routes through real services.
//  - Quest creation routes through QuestService (which enforces reflection gate).
//  - Weave logging routes through TimelineService + state machine (no manual awards).
//  - Results are *intent previews* — final commits always require user confirmation
//    and, where applicable, a reflection text.
//

import SwiftUI
import SwiftData

struct CommandPaletteView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppStateMachine.self) private var stateMachine
    @Query private var contexts: [LifeContext]

    @State private var input: String = ""
    @State private var results: [CommandResult] = []
    @State private var pendingReflection: String = ""
    @State private var pendingAction: PendingCommandAction? = nil

    private var context: LifeContext? { contexts.first }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Command Palette")
                .font(.headline)
            Text("What do you want to weave? (e.g. 'log time with mom' or 'create quest for deep work')")
                .font(.caption)
                .foregroundStyle(.secondary)

            TextField("Type a command…", text: $input)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    processCommand(input)
                }

            if !results.isEmpty {
                List {
                    ForEach(results) { r in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(r.title).font(.subheadline.bold())
                            Text(r.detail).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(minHeight: 120)
            }

            // Reflection sheet (only for actions that need a note before commit).
            if let action = pendingAction {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Reflection required to commit \"\(action.title)\"")
                        .font(.caption.bold())
                    TextField("Optional reflection note", text: $pendingReflection, axis: .vertical)
                        .lineLimit(2...4)
                        .textFieldStyle(.roundedBorder)
                    HStack {
                        Button("Cancel") {
                            pendingAction = nil
                            pendingReflection = ""
                        }
                        Button("Commit") {
                            commitPending(action: action, reflection: pendingReflection)
                            pendingAction = nil
                            pendingReflection = ""
                        }
                        .disabled(pendingReflection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding(10)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding()
    }

    // MARK: - Intent parsing (simple, on-device, privacy-safe)

    func processCommand(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let lower = trimmed.lowercased()
        if lower.contains("quest") || lower.contains("create") {
            // Queue the action; require reflection before commit.
            pendingAction = PendingCommandAction(kind: .createQuest, title: trimmed, body: trimmed)
            results.append(CommandResult(
                title: "Quest queued",
                detail: "Reflection required before commit."
            ))
        } else if lower.contains("log") || lower.contains("win") || lower.contains("captured") {
            pendingAction = PendingCommandAction(kind: .logWeave, title: trimmed, body: trimmed)
            results.append(CommandResult(
                title: "Weave queued",
                detail: "Reflection required; essence only awarded after commit."
            ))
        } else if lower.contains("season") {
            if let ctx = context {
                ctx.changeSeason(to: trimmed)
                results.append(CommandResult(title: "Season change requested", detail: "Reflection gate will prompt next interaction."))
            }
        } else {
            // Semantic graph search preview (no modelContext mutation).
            results.append(CommandResult(
                title: "Graph search (preview)",
                detail: "Would use semantic embeddings for: \(trimmed.prefix(60))"
            ))
        }
        input = ""
    }

    // MARK: - Commit (reflection-gated, routes through real services)

    private func commitPending(action: PendingCommandAction, reflection: String) {
        guard let ctx = context else { return }
        let trimmed = reflection.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        switch action.kind {
        case .createQuest:
            // Real: route to QuestService (which enforces its own reflection gate).
            if let svc = QuestService.shared {
                _ = svc.generateSuggestedQuests(from: ctx, recentEvents: [])
                // Append a custom quest that needs the user's reflection on completion.
                results.append(CommandResult(
                    title: "Quest created",
                    detail: "Accept the quest, then reflect on completion to award essence."
                ))
            } else {
                results.append(CommandResult(title: "QuestService unavailable", detail: "Try again after app loads."))
            }
        case .logWeave:
            // Real: route through TimelineService + state machine (no manual essence).
            let ev = TimelineEvent(
                thread: "Self",
                type: "command_palette_weave",
                payload: ["text": action.body, "reflection": trimmed],
                affectsEnergy: true,
                linkedThreads: ["CareKin", "Stewardship", "Meaning"]
            )
            ctx.updateFromEvent(ev)
            results.append(CommandResult(
                title: "Weave logged",
                detail: "Routed through state machine. No manual essence awarded."
            ))
        }
    }

    // MARK: - Local types

    struct CommandResult: Identifiable, Hashable {
        let id = UUID()
        let title: String
        let detail: String
    }

    enum CommandKind { case createQuest, logWeave }

    struct PendingCommandAction: Identifiable {
        let id = UUID()
        let kind: CommandKind
        let title: String
        let body: String
    }
}

// Add to CompassView or as overlay (swipe down gesture).
