import Foundation

#if canImport(HealthKit)
import HealthKit
#endif

// MARK: - Models

/// Health profile data used to estimate walking speed.
struct UserHealthProfile {
    var height: Double?         // meters
    var weight: Double?         // kilograms
    var biologicalSex: BiologicalSex?
    var age: Int?

    enum BiologicalSex { case female, male, other }
}

/// The result of a walking speed prediction, including its data source.
struct WalkingSpeedResult {
    let speedMetersPerSecond: Double
    let source: Source

    enum Source {
        /// Averaged from recent HealthKit walking speed samples.
        case healthKit
        /// Derived from health profile (height, weight, sex, age).
        case profileEstimate
        /// No usable data; safe adult-pace default applied.
        case `default`
    }
}

// MARK: - WalkingSpeedService

/// Predicts a user's walking speed using Apple Health data when available,
/// falling back to a profile-based estimate or a safe default.
final class WalkingSpeedService: ObservableObject {

#if canImport(HealthKit)

    private let store = HKHealthStore()

    private var readTypes: Set<HKObjectType> {
        var types = Set<HKObjectType>()
        for id: HKQuantityTypeIdentifier in [.height, .bodyMass, .walkingSpeed] {
            if let t = HKObjectType.quantityType(forIdentifier: id) { types.insert(t) }
        }
        if let t = HKObjectType.characteristicType(forIdentifier: .biologicalSex) { types.insert(t) }
        if let t = HKObjectType.characteristicType(forIdentifier: .dateOfBirth)   { types.insert(t) }
        return types
    }

    /// Requests read-only HealthKit authorization for the required data types.
    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        try? await store.requestAuthorization(toShare: [], read: readTypes)
    }

    /// Returns the best available walking speed: measured data first, then estimated.
    func fetchPredictedWalkingSpeed() async -> WalkingSpeedResult {
        if let measured = await fetchRecentWalkingSpeed() {
            return WalkingSpeedResult(speedMetersPerSecond: measured, source: .healthKit)
        }
        let profile = await fetchUserHealthProfile()
        return fallbackWalkingSpeed(from: profile)
    }

    /// Averages walking speed samples from the last 14 days.
    func fetchRecentWalkingSpeed() async -> Double? {
        guard let type = HKObjectType.quantityType(forIdentifier: .walkingSpeed) else { return nil }
        let end   = Date()
        let start = Calendar.current.date(byAdding: .day, value: -14, to: end) ?? end
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let samples = await fetchSamples(type: type, predicate: predicate, limit: 100)
        let unit  = HKUnit.meter().unitDivided(by: .second())
        let speeds = samples.compactMap { ($0 as? HKQuantitySample)?.quantity.doubleValue(for: unit) }
        guard !speeds.isEmpty else { return nil }
        return speeds.reduce(0, +) / Double(speeds.count)
    }

    /// Reads height, body mass, biological sex, and date of birth from HealthKit.
    func fetchUserHealthProfile() async -> UserHealthProfile {
        var profile = UserHealthProfile()

        if let type = HKQuantityType.quantityType(forIdentifier: .height),
           let sample = await fetchMostRecentSample(type: type) as? HKQuantitySample {
            profile.height = sample.quantity.doubleValue(for: .meter())
        }

        if let type = HKQuantityType.quantityType(forIdentifier: .bodyMass),
           let sample = await fetchMostRecentSample(type: type) as? HKQuantitySample {
            profile.weight = sample.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
        }

        if let sexObj = try? store.biologicalSex() {
            switch sexObj.biologicalSex {
            case .female: profile.biologicalSex = .female
            case .male:   profile.biologicalSex = .male
            default:      profile.biologicalSex = .other
            }
        }

        if let dob = try? store.dateOfBirthComponents().date {
            profile.age = Calendar.current.dateComponents([.year], from: dob, to: Date()).year
        }

        return profile
    }

    // MARK: Private helpers

    private func fetchSamples(
        type: HKSampleType,
        predicate: NSPredicate?,
        limit: Int
    ) async -> [HKSample] {
        await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: limit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, _ in
                continuation.resume(returning: samples ?? [])
            }
            store.execute(query)
        }
    }

    private func fetchMostRecentSample(type: HKSampleType) async -> HKSample? {
        await fetchSamples(type: type, predicate: nil, limit: 1).first
    }

#else   // Non-HealthKit platforms

    func requestAuthorization() async {}

    func fetchPredictedWalkingSpeed() async -> WalkingSpeedResult {
        fallbackWalkingSpeed(from: UserHealthProfile())
    }

    func fetchRecentWalkingSpeed() async -> Double? { nil }

    func fetchUserHealthProfile() async -> UserHealthProfile { UserHealthProfile() }

#endif

    // MARK: Fallback (all platforms)

    /// Estimates walking speed from health profile data, clamped to a sensible range.
    /// Falls back to a 1.4 m/s default if no useful profile data is available.
    func fallbackWalkingSpeed(from profile: UserHealthProfile) -> WalkingSpeedResult {
        // 1.4 m/s ≈ 5.0 km/h, the commonly cited average adult walking pace
        let defaultSpeed = 1.4
        let minSpeed     = 0.5   // slow shuffle / elderly
        let maxSpeed     = 2.2   // brisk walk

        guard profile.height != nil || profile.age != nil || profile.biologicalSex != nil else {
            return WalkingSpeedResult(speedMetersPerSecond: defaultSpeed, source: .default)
        }

        var speed = defaultSpeed

        // Age adjustment: research shows gait speed declines ~0.004 m/s per year after 30
        // (source: Bohannon 1997, normative gait speed studies)
        if let age = profile.age {
            if age > 30 {
                speed -= Double(age - 30) * 0.004
            } else if age < 20 {
                speed += 0.1   // younger adults tend to walk faster
            }
        }

        // Biological sex: population averages show ~0.05 m/s difference
        // (used only as a lightweight fallback; measured HealthKit data is always preferred)
        if profile.biologicalSex == .female { speed -= 0.05 }

        // Height adjustment: stride length scales with height (~0.1 m/s per 10 cm from 1.70 m mean)
        if let h = profile.height {
            speed += (h - 1.70) * 0.1
        }

        return WalkingSpeedResult(
            speedMetersPerSecond: min(max(speed, minSpeed), maxSpeed),
            source: .profileEstimate
        )
    }
}
