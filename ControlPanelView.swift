import SwiftUI

struct ControlPanelView: View {
    @EnvironmentObject var model: LifeModel
    @State private var panelOffset: CGFloat = 0
    @State private var isExpanded = false
    
    private let collapsedHeight: CGFloat = 44
    private let expandedHeight: CGFloat = 320
    
    var body: some View {
        VStack(spacing: 0) {
            // Drag handle
            VStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(.systemGray3))
                    .frame(width: 36, height: 4)
                
                Text("Adjust Habits")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.tvSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 10)
            .padding(.bottom, 8)
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let newOffset = value.translation.height
                        if isExpanded {
                            // When expanded, dragging down collapses
                            panelOffset = max(0, newOffset)
                        } else {
                            // When collapsed, dragging up expands
                            panelOffset = min(0, newOffset)
                        }
                    }
                    .onEnded { value in
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            if isExpanded {
                                // If dragged down > 50pt, collapse
                                isExpanded = value.translation.height < 50
                            } else {
                                // If dragged up > 50pt, expand
                                isExpanded = value.translation.height < -50
                            }
                            panelOffset = 0
                        }
                    }
            )
            
            if isExpanded {
                VStack(spacing: 16) {
                    sliderRow(
                        icon: "iphone",
                        title: "Screen Time",
                        unit: "hrs",
                        value: $model.dailyScreenTime,
                        range: 0...16,
                        color: Color.tvScreenTime
                    )
                    
                    sliderRow(
                        icon: "moon.fill",
                        title: "Sleep",
                        unit: "hrs",
                        value: $model.dailySleepHours,
                        range: 3...12,
                        color: Color.tvSleep
                    )
                    
                    sliderRow(
                        icon: "figure.run",
                        title: "Exercise",
                        unit: "min",
                        value: $model.dailyExerciseMinutes,
                        range: 0...120,
                        color: Color.tvHealth
                    )
                    
                    // Impact summary
                    HStack(spacing: 16) {
                        impactBadge(label: "Free/Day", value: "\(Int(model.freeHoursPerDay))h", color: Color.tvRemaining)
                        impactBadge(label: "Screen %", value: "\(Int(model.screenTimePercentage))%", color: Color.tvScreenTime)
                        impactBadge(label: "Free Yrs", value: "\(Int(model.freeYears))", color: Color.tvAccent)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .glassCard(cornerRadius: 20)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .offset(y: panelOffset)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isExpanded)
    }
    
    private func sliderRow(icon: String, title: String, unit: String, value: Binding<Double>, range: ClosedRange<Double>, color: Color) -> some View {
        VStack(spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(color)
                    .frame(width: 18)
                Text(title)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.tvSecondary.opacity(0.8))
                Spacer()
                Text("\(Int(value.wrappedValue)) \(unit)")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                    .contentTransition(.numericText())
            }
            
            Slider(value: value, in: range, step: 1)
                .tint(color)
                .onChange(of: value.wrappedValue) { _, _ in
                    HapticManager.shared.playSliderTick()
                }
        }
    }
    
    private func impactBadge(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .contentTransition(.numericText())
            Text(label)
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(Color.tvSecondary.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.08))
        )
    }
}
