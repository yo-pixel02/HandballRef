import Foundation
import HealthKit

@MainActor
final class WorkoutManager: NSObject, ObservableObject {
    // UI state
    @Published private(set) var isRunning = false
    @Published private(set) var hasStarted = false

    @Published private(set) var steps: Double = 0
    @Published private(set) var activeEnergyKcal: Double = 0
    @Published private(set) var elapsed: TimeInterval = 0

    private let healthStore = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?

    private var timer: Timer?
    private var startDate: Date?
    private var accumulated: TimeInterval = 0

    var primaryButtonTitle: String {
        if !hasStarted { return "Start" }
        return isRunning ? "Pause" : "Weiter"
    }

    var timeString: String {
        let total = Int(elapsed.rounded(.down))
        let s = total % 60
        let m = (total / 60) % 60
        let h = total / 3600
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        } else {
            return String(format: "%02d:%02d", m, s)
        }
    }

    func requestAuthorizationIfNeeded() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        let readTypes: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        ]
        let shareTypes: Set<HKSampleType> = [
            HKObjectType.workoutType()
        ]

        do {
            _ = try await withCheckedThrowingContinuation { cont in
                healthStore.requestAuthorization(toShare: shareTypes, read: readTypes) { success, error in
                    if let error { cont.resume(throwing: error); return }
                    cont.resume(returning: success)
                }
            }
        } catch {
            print("HealthKit auth error: \(error)")
        }
    }

    func toggleStartPause() {
        if !hasStarted {
            Task { await start() }
            return
        }
        isRunning ? pause() : resume()
    }

    func reset() {
        endWorkout()
        steps = 0
        activeEnergyKcal = 0
        elapsed = 0
        accumulated = 0
        startDate = nil
        hasStarted = false
        isRunning = false
    }

    private func start() async {
        hasStarted = true
        accumulated = 0
        elapsed = 0
        startDate = Date()

        do {
            let config = HKWorkoutConfiguration()
            config.activityType = .handball
            config.locationType = .indoor

            let s = try HKWorkoutSession(healthStore: healthStore, configuration: config)
            let b = s.associatedWorkoutBuilder()

            s.delegate = self
            b.delegate = self
            b.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: config)

            session = s
            builder = b

            let now = Date()
            s.startActivity(with: now)

            _ = try await withCheckedThrowingContinuation { cont in
                b.beginCollection(withStart: now) { success, error in
                    if let error { cont.resume(throwing: error); return }
                    cont.resume(returning: success)
                }
            }

            isRunning = true
            startUITimer()
        } catch {
            print("Workout start error: \(error)")
            hasStarted = false
            isRunning = false
        }
    }

    private func pause() {
        session?.pause()
        stopUITimer()
        if let startDate { accumulated += Date().timeIntervalSince(startDate) }
        startDate = nil
        isRunning = false
    }

    private func resume() {
        session?.resume()
        startDate = Date()
        isRunning = true
        startUITimer()
    }

    private func endWorkout() {
        stopUITimer()
        session?.end()

        if let startDate { accumulated += Date().timeIntervalSince(startDate) }
        startDate = nil
        isRunning = false

        guard let b = builder else { return }
        Task {
            do {
                _ = try await withCheckedThrowingContinuation { cont in
                    b.endCollection(withEnd: Date()) { success, error in
                        if let error { cont.resume(throwing: error); return }
                        cont.resume(returning: success)
                    }
                }
                _ = try await withCheckedThrowingContinuation { cont in
                    b.finishWorkout { workout, error in
                        if let error { cont.resume(throwing: error); return }
                        cont.resume(returning: workout as Any)
                    }
                }
            } catch {
                print("Workout finish error: \(error)")
            }
        }
    }

    private func startUITimer() {
        stopUITimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            guard let self else { return }
            let running = (self.startDate != nil) ? Date().timeIntervalSince(self.startDate!) : 0
            self.elapsed = self.accumulated + running
        }
    }

    private func stopUITimer() {
        timer?.invalidate()
        timer = nil
    }

    private func updateStats() {
        guard let b = builder else { return }

        if let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount),
           let stats = b.statistics(for: stepType),
           let sum = stats.sumQuantity() {
            steps = sum.doubleValue(for: .count())
        }

        if let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned),
           let stats = b.statistics(for: energyType),
           let sum = stats.sumQuantity() {
            activeEnergyKcal = sum.doubleValue(for: .kilocalorie())
        }
    }
}

extension WorkoutManager: HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession,
                                    didChangeTo toState: HKWorkoutSessionState,
                                    from fromState: HKWorkoutSessionState,
                                    date: Date) {
        // Optional: state handling if you want to mirror external pause/resume signals
    }

    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("Workout session error: \(error)")
    }

    nonisolated func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder,
                                    didCollectDataOf collectedTypes: Set<HKSampleType>) {
        Task { @MainActor in
            self.updateStats()
        }
    }

    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) { }
}
