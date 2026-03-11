import Foundation
import Combine

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

    // HealthKit-free implementation

    /// No-op: HealthKit is not used in this build.
    func requestAuthorization() async {}

    /// Returns an estimated walking speed based on a (possibly empty) profile.
    /// This never attempts to read HealthKit and always falls back to local estimation.
    func fetchPredictedWalkingSpeed() async -> WalkingSpeedResult {
        let profile = await fetchUserHealthProfile()
        return fallbackWalkingSpeed(from: profile)
    }

    /// No HealthKit data available; return nil so callers rely on fallback.
    func fetchRecentWalkingSpeed() async -> Double? { nil }

    /// Provide an empty profile; callers can inject their own profile data if available.
    func fetchUserHealthProfile() async -> UserHealthProfile { UserHealthProfile() }

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

    // MARK: Formatting Helpers
    /// Converts a distance in meters to miles.
    /// - Parameter meters: The distance in meters.
    /// - Returns: The distance in miles.
    func miles(from meters: Double) -> Double {
        meters / 1609.344
    }

    /// Formats a duration in seconds as mm:ss.
    /// - Parameter seconds: The duration in seconds.
    /// - Returns: A string formatted as minutes:seconds (e.g., "07:35").
    func mmss(from seconds: TimeInterval) -> String {
        let totalSeconds = max(0, Int(seconds.rounded()))
        let minutes = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
}

