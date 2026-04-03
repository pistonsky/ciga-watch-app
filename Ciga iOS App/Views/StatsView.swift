import SwiftUI

struct iOSStatsView: View {
    var inhales: [Inhale]

    @State private var now = Date()
    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // MARK: - Streaks
                VStack(spacing: 12) {
                    sectionHeader("Streaks")

                    streakRow(
                        icon: "nosign",
                        label: "Ciga-free",
                        value: StatsEngine.formatStreak(StatsEngine.cigaFreeStreak(inhales: inhales)),
                        color: .orange
                    )
                    streakRow(
                        icon: "leaf.fill",
                        label: "Nicotine-free",
                        value: StatsEngine.formatStreak(StatsEngine.nicotineFreeStreak(inhales: inhales)),
                        color: .green
                    )
                    streakRow(
                        icon: "smoke",
                        label: "Hookah-free",
                        value: StatsEngine.formatStreak(StatsEngine.hookahFreeStreak(inhales: inhales)),
                        color: .purple
                    )
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(16)

                // MARK: - Hookah Monthly
                VStack(spacing: 12) {
                    sectionHeader("Hookah This Month")

                    let sessionsCount = StatsEngine.hookahSessionsThisMonth(inhales: inhales)
                    let exposureScore = StatsEngine.hookahExposureScore(inhales: inhales)
                    let equivCigs = StatsEngine.equivalentCigarettes(inhales: inhales)

                    HStack(spacing: 12) {
                        statCard(label: "Sessions", value: "\(sessionsCount)", color: .purple)
                        statCard(label: "Score", value: "\(exposureScore)", color: .red)
                        statCard(label: "≈ Cigs", value: "\(equivCigs)", color: .orange)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(16)
            }
            .padding()
        }
        .navigationTitle("Stats")
        .onReceive(timer) { _ in
            now = Date()
        }
    }

    // MARK: - Components

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func streakRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(color)
                .monospacedDigit()
        }
        .padding(.vertical, 4)
    }

    private func statCard(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.title, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}
