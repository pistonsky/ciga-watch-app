import SwiftUI
import SwiftData

struct iOSTrackerView: View {
    var inhales: [Inhale]
    var showInhales: Bool

    @Environment(\.modelContext) private var modelContext

    private var cigaInhales: [Inhale] {
        inhales.filter { $0.isCigaEvent }
    }

    private var todayTotal: Int {
        cigaInhales.reduce(0) { result, inhale in
            result + (Calendar.current.isDateInToday(inhale.smokeDate) ? inhale.n : 0)
        }
    }

    private var lastCigaDate: Date? {
        cigaInhales.max(by: { $0.smokeDate < $1.smokeDate })?.smokeDate
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 8) {
                let displayCount = showInhales ? todayTotal : (todayTotal / 8)
                Text("\(displayCount)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundColor(.accentColor)

                Text(showInhales ? "inhales today" : "cigarettes today")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if let last = lastCigaDate {
                    Text(timerInterval: last...last.addingTimeInterval(86400),
                         countsDown: false, showsHours: true)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            VStack(spacing: 12) {
                Button {
                    logInhale(n: 8)
                } label: {
                    Label("1 Cigarette", systemImage: "flame.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .controlSize(.large)

                HStack(spacing: 12) {
                    ForEach([1, 2, 3], id: \.self) { n in
                        Button {
                            logInhale(n: n)
                        } label: {
                            Text("\(n)")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(n == 1 ? .green : n == 2 ? .blue : .cyan)
                        .controlSize(.large)
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .navigationTitle(showInhales ? "Inhales" : "Cigarettes")
    }

    private func logInhale(n: Int) {
        let newItem = Inhale(n: n)
        modelContext.insert(newItem)
        UIImpactFeedbackGenerator(style: n >= 8 ? .heavy : .light).impactOccurred()
        PhoneSessionManager.shared.sendLogInhale(date: newItem.smokeDate, n: n)
    }
}
