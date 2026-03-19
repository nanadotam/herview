import SwiftUI

struct WidgetGuideView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    // Step 1
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color.pink)
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Text("1")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.white)
                                )

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Long press your home screen")
                                    .font(.callout)
                                    .fontWeight(.semibold)
                                Text("Hold any empty space until icons start wiggling and a + button appears top left.")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .lineLimit(3)
                            }
                            Spacer()
                        }
                        .padding(16)
                    }
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.pink, lineWidth: 3)
                    )

                    // Step 2
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color(UIColor.systemGray4))
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Text("2")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.primary)
                                )

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Tap + and find HerView")
                                    .font(.callout)
                                    .fontWeight(.semibold)
                                Text("Search \"HerView\" in the widget gallery, then choose your size.")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .lineLimit(3)
                            }
                            Spacer()
                        }
                        .padding(16)
                    }
                    .background(Color.white)
                    .cornerRadius(12)

                    // Step 3
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color(UIColor.systemGray4))
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Text("3")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.primary)
                                )

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Tap \"Add Widget\" and place it")
                                    .font(.callout)
                                    .fontWeight(.semibold)
                                Text("Drag to your preferred spot and tap Done. She'll appear within seconds.")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .lineLimit(3)
                            }
                            Spacer()
                        }
                        .padding(16)
                    }
                    .background(Color.white)
                    .cornerRadius(12)

                    // Widget sizes
                    VStack(alignment: .leading, spacing: 10) {
                        Text("WIDGET SIZES")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.gray)
                            .padding(.leading, 4)

                        HStack(spacing: 12) {
                            VStack(spacing: 8) {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.pink.opacity(0.8), .pink]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 100, height: 100)
                                    .overlay(
                                        Text("Small\n(1×1)")
                                            .font(.caption2)
                                            .foregroundColor(.white)
                                            .fontWeight(.semibold)
                                            .multilineTextAlignment(.center)
                                    )

                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.red.opacity(0.7), .pink]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 100, height: 100)
                                    .overlay(
                                        Text("Medium\n(2×1)"
                                            )
                                            .font(.caption2)
                                            .foregroundColor(.white)
                                            .fontWeight(.semibold)
                                            .multilineTextAlignment(.center)
                                    )
                            }
                            Spacer()
                        }
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(12)
                }
                .padding(16)
            }
            .background(Color(UIColor.systemGray6))
            .navigationTitle("Add Widget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("‹ Back") { dismiss() }
                        .foregroundColor(.pink)
                }
            }
        }
    }
}

#Preview {
    WidgetGuideView()
}
