import SwiftUI
import SwiftData

/// LifeMomentTimelineEntry — single row in a list of LifeMoment records.
/// Shows thread indicator, date, reflection snippet, sealed status.
/// Per Invariant 11: NEVER shows OCR text or inferred content here.
struct LifeMomentTimelineEntry: View {
    let moment: LifeMoment

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(threadColor)
                .frame(width: 10, height: 10)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(moment.modifiedAt, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(moment.modifiedAt, style: .time)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if moment.isSealed {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("Sealed")
                    }

                    Spacer()

                    if moment.isAttachedToThread {
                        Text(threadName)
                            .font(.caption2)
                            .foregroundStyle(threadColor)
                    }
                }

                Text(reflectionText)
                    .font(.subheadline)
                    .lineLimit(2)
                    .foregroundStyle(moment.userReflection == nil ? .secondary : .primary)
            }
        }
        .padding(.vertical, 4)
    }

    private var reflectionText: String {
        guard let reflection = moment.userReflection,
              !reflection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return "(no reflection)"
        }
        return reflection
    }

    private var threadColor: Color {
        guard let raw = moment.userAssignedThreadRaw,
              let assignment = MomentThreadAssignment(rawValue: raw) else {
            return .gray
        }
        return threadColor(for: assignment)
    }

    private var threadName: String {
        guard let raw = moment.userAssignedThreadRaw,
              let assignment = MomentThreadAssignment(rawValue: raw) else {
            return ""
        }

        switch assignment {
        case .basicSelf:
            return "Self"
        case .stewardship:
            return "Stew."
        case .careKin:
            return "Care"
        case .meaning:
            return "Meaning"
        }
    }

    private func threadColor(for thread: MomentThreadAssignment) -> Color {
        switch thread {
        case .basicSelf:
            return .blue
        case .stewardship:
            return .green
        case .careKin:
            return .orange
        case .meaning:
            return .purple
        }
    }
}

#Preview {
    List {
        LifeMomentTimelineEntry(moment: LifeMoment(userReflection: "Walked in the park today."))
        LifeMomentTimelineEntry(moment: {
            let moment = LifeMoment(userReflection: "Coffee with Sarah felt really good.")
            moment.userAssignedThreadRaw = MomentThreadAssignment.careKin.rawValue
            moment.isSealed = true
            return moment
        }())
    }
}
