import SwiftUI

struct OnboardingView: View {
    @Environment(AppStateMachine.self) private var stateMachine
    @Environment(\.dismiss) private var dismiss  // T110: explicit dismiss handle (was missing — CTA had no effect)
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false  // T110: persist onboarding completion
    @State private var currentPage = 0

    let pages: [(title: String, description: String, icon: String, state: AppState)] = [
        ("One Interconnected Journey", "Life isn't silos. Every action ripples across Self, Stewardship, Care & Kin, and Meaning. OneWeave models this as a living state machine.", "arrow.triangle.2.circlepath", .weaving),
        ("Event-Driven Ripples", "Capture anything. It weaves into your Compass, updates energy, links threads, and shifts state (idle → weaving → reflecting). See the impact instantly.", "arrow.2.circlepath", .weaving),
        ("Calm, Sophisticated UI", "Peripheral awareness, not alerts. Color psychology for energy, subtle haptics, animations, glass effects. State machine visible but non-intrusive.", "brain.head.profile", .reflecting),
        ("Privacy by Design", "All local SwiftData. Export or clear anytime. No cloud, no training on your data. Follows white paper principles for well-being apps.", "lock.shield", .idle),
        // T125: explicit "what we will NEVER do" — privacy trust statement (Constitution §2)
        ("What OneWeave Will NEVER Do", "No accounts. No cloud sync. No ads. No analytics. No 'engagement' optimization. No streak-shaming. No notification spam. Your reflection is yours — and only yours.", "hand.raised.slash", .idle),
        ("Your State Machine", "Watch transitions: lowEnergy after stress, highFlow after wins. Use it to understand and steer your weave.", "flame", .highFlow)
    ]

    var body: some View {
        VStack {
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    VStack(spacing: 24) {
                        Image(systemName: pages[index].icon)
                            .font(.system(size: 80))
                            .foregroundStyle(pages[index].state.color)
                            // T108: gate pulse on Reduce Motion accessibility setting
                            .symbolEffect(.pulse, isActive: !accessibilityReduceMotion)

                        Text(pages[index].title)
                            .font(.title.bold())

                        Text(pages[index].description)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)

                        // Live state preview
                        HStack {
                            Image(systemName: pages[index].state.systemImage)
                            Text(pages[index].state.displayName)
                                .foregroundStyle(pages[index].state.color)
                        }
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                    }
                    .tag(index)
                    .padding()
                }
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            Button(currentPage == pages.count - 1 ? "Start Weaving" : "Next") {
                if currentPage < pages.count - 1 {
                    withAnimation { currentPage += 1 }
                } else {
                    // T110: actually mark onboarding complete + dismiss the sheet
                    hasCompletedOnboarding = true
                    stateMachine.currentState = .idle
                    dismiss()
                }
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
        .padding()
        .onAppear {
            stateMachine.currentState = pages[currentPage].state
        }
        .onChange(of: currentPage) { _, new in
            stateMachine.currentState = pages[new].state
        }
    }

    // T108: read Reduce Motion preference from environment
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
}

#Preview {
    OnboardingView()
        .environment(AppStateMachine())
}