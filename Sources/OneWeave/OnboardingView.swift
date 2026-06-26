import SwiftUI

struct OnboardingView: View {
    @Environment(AppStateMachine.self) private var stateMachine
    @State private var currentPage = 0
    
    let pages: [(title: String, description: String, icon: String, state: AppState)] = [
        ("One Interconnected Journey", "Life isn't silos. Every action ripples across Self, Stewardship, Care & Kin, and Meaning. OneWeave models this as a living state machine.", "arrow.triangle.2.circlepath", .weaving),
        ("Event-Driven Ripples", "Capture anything. It weaves into your Compass, updates energy, links threads, and shifts state (idle → weaving → reflecting). See the impact instantly.", "arrow.2.circlepath", .weaving),
        ("Calm, Sophisticated UI", "Peripheral awareness, not alerts. Color psychology for energy, subtle haptics, animations, glass effects. State machine visible but non-intrusive.", "brain.head.profile", .reflecting),
        ("Privacy by Design", "All local SwiftData. Export or clear anytime. No cloud, no training on your data. Follows white paper principles for well-being apps.", "lock.shield", .idle),
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
                            .symbolEffect(.pulse, isActive: true)
                        
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
                    // Dismiss and set state
                    stateMachine.currentState = .idle
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
}

#Preview {
    OnboardingView()
        .environment(AppStateMachine())
}