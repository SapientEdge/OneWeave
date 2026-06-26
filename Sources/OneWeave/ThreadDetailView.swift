import SwiftUI
import SwiftData

struct ThreadDetailView: View {
    let threadName: String
    @Environment(\\.modelContext) private var modelContext
    @Query private var contexts: [LifeContext]
    @Query private var events: [TimelineEvent]
    
    @State private var inputText = ""
    @State private var service: TimelineService?
    @State private var showExport = false
    @State private var exportData = ""
    
    private var context: LifeContext? { contexts.first }
    private var threadEvents: [TimelineEvent] {
        events.filter { $0.thread == threadName || $0.linkedThreads.contains(threadName) }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(threadName)
                        .font(.largeTitle.bold())
                    
                    if let ctx = context {
                        Text("Energy Profile: \(ctx.energyProfile.rawValue)")
                            .font(.headline)
                    }
                    
                    // Integrated actions wired to state machine and ripples
                    VStack {
                        Text("Quick Action for \(threadName)")
                            .font(.headline)
                        
                        TextField("Describe action (e.g. add task, complete, log story, detect leak)", text: $inputText)
                            .textFieldStyle(.roundedBorder)
                        
                        Button("Process & Weave") {
                            processAction()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(inputText.isEmpty)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    Text("Recent Activity & Ripples")
                        .font(.headline)
                    
                    if threadEvents.isEmpty {
                        Text("No activity yet. Use actions above or Quick Capture in Compass.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(threadEvents.prefix(10)) { event in
                            VStack(alignment: .leading) {
                                Text("\(event.type) - \(event.timestamp, style: .time)")
                                    .font(.subheadline)
                                Text(event.payload.values.joined(separator: " • "))
                                    .font(.caption)
                                if !event.linkedThreads.isEmpty {
                                    Text("Rippled to: \(event.linkedThreads.joined(separator: ", "))")
                                        .font(.caption2)
                                        .foregroundStyle(.blue)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    // Cross-thread suggestions (integrated)
                    if let ctx = context {
                        VStack(alignment: .leading) {
                            Text("Integrated Suggestions")
                                .font(.headline)
                            let suggestions = generateCrossSuggestions(for: threadName, context: ctx)
                            ForEach(suggestions, id: \\.self) { sug in
                                Text("• \(sug)")
                                    .font(.caption)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(threadName)
            .toolbar {
                Button("Export Thread") {
                    exportThreadData()
                }
            }
            .sheet(isPresented: $showExport) {
                Text(exportData)
                    .padding()
                    .onTapGesture { showExport = false }
            }
        }
        .onAppear {
            service = TimelineService(modelContext: modelContext)
        }
    }
    
    private func processAction() {
        guard !inputText.isEmpty, let svc = service, let ctx = context else { return }
        
        let lower = inputText.lowercased()
        
        if threadName == "CareKin" {
            if lower.contains("add task") || lower.contains("add care") || lower.contains("family task") {
                let parts = inputText.components(separatedBy: .whitespaces)
                var taskName = "New care task"
                var prio = "normal"
                var due: Date? = nil
                if parts.count > 2 {
                    taskName = parts[2...].joined(separator: " ")
                    if let last = parts.last, ["high","normal","low"].contains(last.lowercased()) {
                        prio = last.lowercased()
                        taskName = parts[2..<parts.count-1].joined(separator: " ")
                    }
                    // Real date parsing with fallback
                    if let last = parts.last, last.contains("-") || last.contains("/") {
                        let formatter = ISO8601DateFormatter()
                        if let d = formatter.date(from: last) {
                            due = d
                            taskName = parts[2..<parts.count-1].joined(separator: " ")
                        } else {
                            taskName = parts[2..<parts.count].joined(separator: " ")
                        }
                    }
                }
                let care = CareKinThread()
                care.addTask(taskName, priority: prio, dueDate: due, service: svc, context: ctx)
                inputText = ""
                return
            } else if lower.contains("complete task") || lower.contains("done task") || lower.contains("finish") {
                // Wire completion
                let taskName = inputText.replacingOccurrences(of: "complete task ", with: "", options: .caseInsensitive)
                let care = CareKinThread()
                care.completeTask(named: taskName, service: svc, context: ctx)
                inputText = ""
                return
            }
        }
        
        // Generic weave for any thread
        svc.emitEvent(
            thread: threadName,
            type: "user_action",
            payload: ["action": inputText],
            affectsEnergy: threadName == "Self" || threadName == "CareKin",
            linkedThreads: threadName == "Self" ? ["CareKin", "Stewardship", "Meaning"] : []
        )
        inputText = ""
    }
    
    private func generateCrossSuggestions(for thread: String, context: LifeContext) -> [String] {
        var suggestions: [String] = []
        if thread == "Self" && context.energyProfile == .low {
            suggestions.append("Consider a quick CareKin task to build momentum.")
        }
        if thread == "Stewardship" && !context.recentEventSummaries.isEmpty {
            suggestions.append("Redirect savings to Meaning legacy or Self habit.")
        }
        suggestions.append("Check Compass for current ripples from this thread.")
        return suggestions
    }
    
    private func exportThreadData() {
        let data = threadEvents.map { event in
            "\(event.timestamp): \(event.type) - \(event.payload.values.joined()) Ripples: \(event.linkedThreads.joined())"
        }.joined(separator: "\n")
        exportData = "OneWeave Export for \(threadName)\n\n\(data)"
        showExport = true
    }
}