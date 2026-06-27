//
//  LivingGraphLoom.swift
//  OneWeave
//
//  Living Graph Loom — creative feature #6. SwiftUI renderer for the Loom.
//
//  The geometry + state derivation live in LoomGeometry.swift (pure Swift,
//  testable on Linux). This file is the iOS-only SwiftUI rendering layer:
//  it consumes LoomState and produces the visual breathing circular graph.
//
//  Renderer guarantees:
//    - No data leaves the device. All state is local.
//    - All animations are derived from a TimelineView at a low frame rate
//      (≤30 fps) to be calm + battery-friendly.
//    - No haptic, sound, or attention-grabbing motion.
//    - Tapping a thread surfaces its detail, but never auto-navigates.
//    - Drag-to-feel-relationship gestures do not mutate state.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

// MARK: - Loom renderer

/// SwiftUI view that renders a LoomState. Re-renders cheaply because the
/// only animated inputs are `breathPhase` (driven by TimelineView).
public struct LivingGraphLoom: View {
    public let input: LoomInput
    public let onThreadTap: ((LoomThread) -> Void)?

    @State private var selectedThreadID: UUID?
    @State private var dragOffsetLU: LoomPoint = .zero
    @State private var dragThreadID: UUID?
    @State private var breathStart: Date = Date()

    public init(input: LoomInput, onThreadTap: ((LoomThread) -> Void)? = nil) {
        self.input = input
        self.onThreadTap = onThreadTap
    }

    public var body: some View {
        TimelineView(.periodic(from: breathStart, by: 1.0 / 15.0)) { context in
            let elapsed = context.date.timeIntervalSince(breathStart)
            let bpm = LoomGeometry.breathingRate(season: input.season, timeOfDay: input.timeOfDay)
            let breathPhase = sin(elapsed * bpm / 60.0 * 2 * .pi) * 0.5 + 0.5  // 0..1
            let state = LoomGeometry.makeState(for: input, breathPhase: breathPhase)
            let scatter = LoomGeometry.scatterScale(coherence: state.coherenceScore)
            Canvas { ctx, size in
                drawLoom(state: state, in: ctx, size: size, scatter: scatter)
            }
            .gesture(loomGesture(threads: state.threads, size: nil))
            .overlay(threadOverlay(state: state, scatter: scatter))
        }
        .accessibilityLabel("Living Graph Loom")
        .accessibilityHint("A circular visualization of your life graph. Tap a thread to see its detail.")
    }

    // MARK: - Drawing

    /// Core draw pass. Renders background → strands → threads in that order.
    private func drawLoom(state: LoomState, in ctx: GraphicsContext, size: CGSize, scatter: Double) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let scaleLU = min(size.width, size.height) / 24.0  // 24 LU fits a square canvas

        // 1. Background — soft radial gradient (coherence-tinted).
        let bgGradient = Gradient(colors: [
            Color(hue: state.palette.coolHue, saturation: 0.3, brightness: state.palette.backgroundLU + 0.04),
            Color(hue: state.palette.coolHue, saturation: 0.4, brightness: state.palette.backgroundLU)
        ])
        ctx.fill(
            Path(ellipseIn: CGRect(origin: .zero, size: size)),
            with: .radialGradient(
                bgGradient,
                center: center,
                startRadius: 0,
                endRadius: min(size.width, size.height) / 2
            )
        )

        // 2. Strands (relationships) — soft curves between threads.
        let threadByID = Dictionary(uniqueKeysWithValues: state.threads.map { ($0.id, $0) })
        for strand in state.strands {
            guard let from = threadByID[strand.fromThreadID],
                  let to = threadByID[strand.toThreadID] else { continue }
            let breath = 1.0 + state.palette.breathAmplitude * sin(state.breathPhase * 2 * .pi)
            let fromPt = scaledPoint(from.position, center: center, scale: scaleLU * scatter * breath)
            let toPt = scaledPoint(to.position, center: center, scale: scaleLU * scatter * breath)
            var path = Path()
            path.move(to: fromPt)
            // Quadratic curve through the Loom's center for an organic feel.
            let mid = CGPoint(
                x: (fromPt.x + toPt.x) / 2 + (center.x - (fromPt.x + toPt.x) / 2) * 0.15,
                y: (fromPt.y + toPt.y) / 2 + (center.y - (fromPt.y + toPt.y) / 2) * 0.15
            )
            path.addQuadCurve(to: toPt, control: mid)
            let warmth = (from.warmth + to.warmth) / 2
            let strandColor = Color(
                hue: lerp(state.palette.coolHue, state.palette.warmHue, t: warmth),
                saturation: 0.4,
                brightness: 0.5 + warmth * 0.3
            )
            ctx.stroke(
                path,
                with: .color(strandColor.opacity(strand.opacity * 0.6)),
                lineWidth: strand.thicknessLU * scaleLU * 0.3
            )
        }

        // 3. Threads (entities) — soft circles.
        for thread in state.threads {
            let breath = 1.0 + state.palette.breathAmplitude * sin(state.breathPhase * 2 * .pi + thread.alignmentContribution)
            let pt = scaledPoint(thread.position, center: center, scale: scaleLU * scatter * breath)
            let radiusPt = thread.radiusLU * scaleLU * 0.4
            let rect = CGRect(
                x: pt.x - radiusPt, y: pt.y - radiusPt,
                width: radiusPt * 2, height: radiusPt * 2
            )
            // Outer glow (warmth)
            let glowColor = Color(
                hue: lerp(state.palette.coolHue, state.palette.warmHue, t: thread.warmth),
                saturation: 0.5,
                brightness: 0.7 + thread.warmth * 0.3
            )
            ctx.fill(
                Path(ellipseIn: rect),
                with: .color(glowColor.opacity(0.15 + thread.warmth * 0.2))
            )
            // Inner core
            let coreColor = Color(
                hue: lerp(state.palette.coolHue, state.palette.warmHue, t: thread.warmth),
                saturation: 0.6,
                brightness: 0.6 + thread.warmth * 0.3
            )
            ctx.fill(
                Path(ellipseIn: rect.insetBy(dx: radiusPt * 0.4, dy: radiusPt * 0.4)),
                with: .color(coreColor.opacity(0.9))
            )
        }

        // 4. Weave point — central calm dot.
        let weaveRect = CGRect(
            x: center.x - 4, y: center.y - 4, width: 8, height: 8
        )
        ctx.fill(
            Path(ellipseIn: weaveRect),
            with: .color(Color(hue: state.palette.warmHue, saturation: 0.2, brightness: 0.9).opacity(0.5))
        )
    }

    // MARK: - Overlay (tap targets)

    /// SwiftUI overlay that places invisible tap targets over each thread
    /// position so the user can tap them. The Canvas is rendered, but tap
    /// targets need to be real SwiftUI views for accessibility + gestures.
    @ViewBuilder
    private func threadOverlay(state: LoomState, scatter: Double) -> some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let scaleLU = min(geo.size.width, geo.size.height) / 24.0
            ZStack {
                ForEach(state.threads) { thread in
                    let pt = scaledPoint(thread.position, center: center, scale: scaleLU * scatter)
                    let radiusPx = max(18, thread.radiusLU * scaleLU * 1.5)
                    Circle()
                        .fill(Color.clear)
                        .frame(width: radiusPx * 2, height: radiusPx * 2)
                        .position(x: pt.x, y: pt.y)
                        .contentShape(Circle())
                        .onTapGesture {
                            selectedThreadID = thread.id
                            onThreadTap?(thread)
                        }
                        .accessibilityLabel(Text(thread.title))
                        .accessibilityHint(Text("Domain: \(thread.domain). Warmth: \(Int(thread.warmth * 100))%."))
                }
            }
            if let id = selectedThreadID,
               let thread = state.threads.first(where: { $0.id == id }) {
                LoomThreadDetail(thread: thread)
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    .padding()
                    .transition(.opacity)
            }
        }
    }

    // MARK: - Gestures

    private func loomGesture(threads: [LoomThread], size: CGSize?) -> some Gesture {
        // Drag-to-feel-relationship: when the user drags a thread toward
        // another, surface the relationship if it exists. Currently a no-op
        // for the geometry layer; future enhancement.
        DragGesture(minimumDistance: 5)
            .onChanged { _ in
                // Reserved for future drag-to-feel behavior.
            }
    }

    // MARK: - Helpers

    private func scaledPoint(_ p: LoomPoint, center: CGPoint, scale: Double) -> CGPoint {
        CGPoint(x: center.x + CGFloat(p.x) * CGFloat(scale), y: center.y + CGFloat(p.y) * CGFloat(scale))
    }

    private func lerp(_ a: Double, _ b: Double, t: Double) -> Double {
        return a + (b - a) * t.clamped(to: 0...1)
    }
}

// MARK: - Thread detail popover

private struct LoomThreadDetail: View {
    let thread: LoomThread
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(thread.title)
                .font(.headline)
            HStack(spacing: 12) {
                Label(thread.domain, systemImage: domainIcon(thread.domain))
                    .font(.caption)
                Label("\(Int(thread.warmth * 100))% warm",
                      systemImage: "flame.fill")
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
        }
    }

    private func domainIcon(_ domain: String) -> String {
        switch domain.lowercased() {
        case "self": return "person.crop.circle"
        case "carekin": return "heart"
        case "meaning": return "book"
        case "stewardship": return "leaf"
        default: return "circle"
        }
    }
}

// MARK: - Private clamping extension

private extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}