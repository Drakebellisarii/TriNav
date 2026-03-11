import SwiftUI
import CoreLocation

struct WelcomeView: View {
    let onChoice: (Bool) -> Void

    private let trinityNavy = Color(red: 0.0, green: 0.255, blue: 0.474)
    private let trinityGold = Color(red: 0.953, green: 0.769, blue: 0.016)

    @State private var locationManager = CLLocationManager()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [trinityNavy, trinityNavy.opacity(0.82)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Branding
                VStack(spacing: 14) {
                    Circle()
                        .fill(trinityGold)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Text("T")
                                .font(.system(size: 44, weight: .black, design: .serif))
                                .foregroundColor(.white)
                        )
                        .shadow(color: .black.opacity(0.25), radius: 12, y: 6)

                    Text("TriNav")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }

                // Permission description
                VStack(spacing: 12) {
                    Text("Location Services")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Allow TriNav to use your location so it can automatically set your starting point and guide you from where you are on campus.")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
                .padding(.horizontal, 24)

                // Buttons
                VStack(spacing: 14) {
                    Button {
                        locationManager.requestWhenInUseAuthorization()
                        onChoice(true)
                    } label: {
                        Text("Yes")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(trinityNavy)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(trinityGold)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    Button {
                        onChoice(false)
                    } label: {
                        Text("No")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 32)

                Spacer()
            }
        }
    }
}
