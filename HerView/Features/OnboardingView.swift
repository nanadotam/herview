import SwiftUI

struct OnboardingView: View {
    @Binding var hasSeenOnboarding: Bool

    var body: some View {
        ZStack {
            // Hero gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 1.0, green: 0.52, blue: 0.62),
                    Color(red: 0.97, green: 0.31, blue: 0.62),
                    Color(red: 0.75, green: 0.2, blue: 0.42)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: 20) {
                    // Face circle
                    Circle()
                        .fill(Color.white.opacity(0.25))
                        .frame(width: 72, height: 72)
                        .overlay(
                            Text("🤍")
                                .font(.system(size: 36))
                        )
                        .padding(.bottom, 8)

                    // Divider line
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.35))
                        .frame(width: 80, height: 4)
                        .padding(.bottom, 20)

                    // Headline
                    VStack(spacing: 12) {
                        Text("She's always\nwith you.")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)

                        Text("Put her on your home screen.\nNo apps. No scrolling. Just her.")
                            .font(.callout)
                            .foregroundColor(.white.opacity(0.75))
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                    }
                }
                .frame(maxHeight: .infinity, alignment: .center)
                .padding(.horizontal, 32)

                // Bottom sheet
                VStack(spacing: 12) {
                    Button(action: { hasSeenOnboarding = true }) {
                        Text("Get Started")
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.pink)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                            .font(.system(size: 16, weight: .semibold))
                    }

                    Text("Private · Offline · No account needed")
                        .font(.caption)
                        .foregroundColor(Color(UIColor.systemGray3))
                        .multilineTextAlignment(.center)
                }
                .padding(24)
                .padding(.bottom, 40)
                .background(Color.white)
            }
        }
    }
}

#Preview {
    OnboardingView(hasSeenOnboarding: .constant(false))
}
