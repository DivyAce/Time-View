import SwiftUI

struct PerspectivesView: View {
    @State private var selectedTab = "Milestones"
    let tabs = ["Milestones", "Insights"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Premium Segmented Picker
            HStack(spacing: 4) {
                ForEach(tabs, id: \.self) { tab in
                    Button(action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            selectedTab = tab
                        }
                    }) {
                        Text(tab)
                            .font(.system(size: 15, weight: selectedTab == tab ? .bold : .semibold, design: .rounded))
                            .foregroundStyle(selectedTab == tab ? Color.tvAccent : Color.tvSecondary.opacity(0.6))
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(
                                ZStack {
                                    if selectedTab == tab {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(.ultraThinMaterial)
                                            .shadow(color: Color.tvAccent.opacity(0.1), radius: 8, x: 0, y: 2)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .strokeBorder(Color.tvAccent.opacity(0.15), lineWidth: 1)
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .fill(Color.tvAccent.opacity(0.06))
                                            )
                                            .matchedGeometryEffect(id: "TabBackground", in: animationNamespace)
                                    }
                                }
                            )
                    }
                }
            }
            .padding(5)
            .glassCard(cornerRadius: 16)
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            // Tab Content View
            TabView(selection: $selectedTab) {
                MilestonesView()
                    .tag("Milestones")
                
                InsightPanelView(isPresented: .constant(true))
                    .tag("Insights")
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .background(Color.tvBackground.ignoresSafeArea())
    }
    
    @Namespace private var animationNamespace
}
