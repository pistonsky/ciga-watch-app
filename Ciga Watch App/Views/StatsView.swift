//
//  StatsView.swift
//  Ciga Watch App
//
//  Displays all streaks, hookah exposure score, and equivalent cigarettes.
//

import SwiftUI

struct StatsView: View {
    var inhales: [Inhale]

    @State private var now = Date()

    // Auto-refresh every 30 seconds to keep streak timers fresh
    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {

                // MARK: - Streaks Section
                Text("Streaks")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .frame(maxWidth: .infinity, alignment: .leading)

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

                Divider()

                // MARK: - Hookah Monthly Section
                Text("Hookah (This Month)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .frame(maxWidth: .infinity, alignment: .leading)

                let sessionsCount = StatsEngine.hookahSessionsThisMonth(inhales: inhales)
                let exposureScore = StatsEngine.hookahExposureScore(inhales: inhales)
                let equivCigs = StatsEngine.equivalentCigarettes(inhales: inhales)

                HStack {
                    statCard(label: "Sessions", value: "\(sessionsCount)", color: .purple)
                    statCard(label: "Score", value: "\(exposureScore)", color: .red)
                }

                statCard(label: "≈ Cigarettes", value: "\(equivCigs)", color: .orange)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 8)
        }
        .navigationTitle("Stats")
        .onReceive(timer) { _ in
            now = Date() // trigger refresh
        }
    }

    // MARK: - Components

    private func streakRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(color)
                .frame(width: 16)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
                .monospacedDigit()
        }
        .padding(.vertical, 2)
    }

    private func statCard(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.title3, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}
