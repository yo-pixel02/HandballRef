import SwiftUI
import WatchKit

struct ContentView: View {
    @StateObject private var manager = WorkoutManager()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 10) {
                Text(manager.timeString)
                    .font(.system(size: 44, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.6)

                HStack(spacing: 10) {
                    Button {
                        WKInterfaceDevice.current().play(.click)
                        manager.toggleStartPause()
                    } label: {
                        Text(manager.primaryButtonTitle)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.white)

                    Button {
                        WKInterfaceDevice.current().play(.directionDown)
                        manager.reset()
                    } label: {
                        Text("Reset")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.6), lineWidth: 2)
                            )
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.white.opacity(0.9))
                }

                VStack(spacing: 4) {
                    Text("Schritte: \(Int(manager.steps))")
                    Text("kcal aktiv: \(Int(manager.activeEnergyKcal))")
                }
                .font(.footnote)
                .foregroundColor(.white.opacity(0.85))
                .padding(.top, 4)
            }
            .padding()
        }
        .task {
            await manager.requestAuthorizationIfNeeded()
        }
    }
}
