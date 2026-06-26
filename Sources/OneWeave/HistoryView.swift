import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \TimelineEvent.timestamp, order: .reverse) private var allEvents: [TimelineEvent]
    @State private var searchText = ""
    @State private var filterThread: String?
    @State private var showOnlyRipples = false
    
    private var filteredEvents: [TimelineEvent] {
        var events = allEvents
        if let thread = filterThread {
            events = events.filter { $0.thread == thread || $0.linkedThreads.contains(thread) }
        }
        if showOnlyRipples {
            events = events.filter { !$0.linkedThreads.isEmpty }
        }
        if !searchText.isEmpty {
            let q = searchText.lowercased()
            events = events.filter { ev in
                ev.thread.lowercased().contains(q) ||
                ev.type.lowercased().contains(q) ||
                ev.payload.values.joined().lowercased().contains(q) ||
                ev.linkedThreads.joined().lowercased().contains(q)
            }
        }
        return events
    }
    
    var body: some View {
        List(filteredEvents) { event in
            NavigationLink(value: event.thread) {
                ModernHistoryRow(event: event)
            }
            .swipeActions(edge: .trailing) {
                Button {
                    // Could add quick action like "Weave again"
                } label: {
                    Label("Weave", systemImage: "arrow.triangle.2.circlepath")
                }
                .tint(.blue)
            }
        }
        .navigationTitle("Weave History")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search events, ripples, threads...")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("All Events") { filterThread = nil; showOnlyRipples = false }
                    Button("Only Ripples") { showOnlyRipples = true; filterThread = nil }
                    Divider()
                    ForEach(["Self", "Stewardship", "CareKin", "Meaning"], id: \.self) { t in
                        Button(t) { filterThread = t }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
        }
        .overlay {
            if filteredEvents.isEmpty {
                ContentUnavailableView(
                    "No Weaves Match",
                    systemImage: "clock",
                    description: Text("Use Quick Capture in Compass or add rich actions in Threads to create events.")
                )
            }
        }
        .navigationDestination(for: String.self) { threadName in
            ThreadDetailView(threadName: threadName)
        }
    }
}

struct ModernHistoryRow: View {
    let event: TimelineEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Circle()
                    .fill(threadColor(event.thread))
                    .frame(width: 10, height: 10)
                Text(event.thread)
                    .font(.headline)
                    .foregroundStyle(threadColor(event.thread))
                Text("• \(event.type)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(event.timestamp, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            
            Text(event.payload.map { "\($0.key): \($0.value)" }.joined(separator: " • "))
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            
            if !event.linkedThreads.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.triangle.branch")
                        .font(.caption)
                    Text("Ripples: \(event.linkedThreads.joined(separator: ", "))")
                        .font(.caption2.bold())
                        .foregroundStyle(.blue)
                }
            }
            
            if event.affectsEnergy {
                Label("Impacts Energy", systemImage: "bolt.fill")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func threadColor(_ thread: String) -> Color {
        switch thread {
        case "Self": return .blue
        case "Stewardship": return .green
        case "CareKin": return .orange
        case "Meaning": return .purple
        default: return .gray
        }
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: [TimelineEvent.self])
}
