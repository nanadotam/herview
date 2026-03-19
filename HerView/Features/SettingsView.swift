import SwiftUI

struct SettingsView: View {
    let viewModel: SlideshowViewModel

    var body: some View {
            Form {
                Section("Slideshow Interval") {
                    VStack(spacing: 12) {
                        HStack(spacing: 8) {
                            ForEach([10.0, 30.0, 60.0, 300.0], id: \.self) { intervalValue in
                                Button(action: {
                                    var newSettings = viewModel.settings
                                    newSettings.intervalSeconds = intervalValue
                                    viewModel.updateSettings(newSettings)
                                }) {
                                    Text(formatInterval(intervalValue))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(viewModel.settings.intervalSeconds == intervalValue ? Color.pink : Color(UIColor.systemGray5))
                                        .foregroundColor(viewModel.settings.intervalSeconds == intervalValue ? .white : .gray)
                                        .cornerRadius(8)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("Playback") {
                    Toggle(isOn: Binding(
                        get: { viewModel.settings.shuffleEnabled },
                        set: { newValue in
                            var newSettings = viewModel.settings
                            newSettings.shuffleEnabled = newValue
                            viewModel.updateSettings(newSettings)
                        }
                    )) {
                        HStack(spacing: 12) {
                            Image(systemName: "shuffle")
                                .font(.callout)
                                .foregroundColor(.pink)
                                .frame(width: 30, height: 30)
                                .background(Color(red: 1, green: 0.9, blue: 0.95))
                                .cornerRadius(8)

                            VStack(alignment: .leading) {
                                Text("Shuffle")
                                    .font(.callout)
                                Text("Random order")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }

                    Toggle(isOn: .constant(true)) {
                        HStack(spacing: 12) {
                            Image(systemName: "repeat")
                                .font(.callout)
                                .foregroundColor(.blue)
                                .frame(width: 30, height: 30)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)

                            VStack(alignment: .leading) {
                                Text("Loop")
                                    .font(.callout)
                                Text("Repeat after last photo")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }

                Section("Display") {
                    Picker("Crop Mode", selection: Binding(
                        get: { viewModel.settings.cropMode },
                        set: { newValue in
                            var newSettings = viewModel.settings
                            newSettings.cropMode = newValue
                            viewModel.updateSettings(newSettings)
                        }
                    )) {
                        ForEach(CropMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }

                    Picker("Filter", selection: Binding(
                        get: { viewModel.settings.filter },
                        set: { newValue in
                            var newSettings = viewModel.settings
                            newSettings.filter = newValue
                            viewModel.updateSettings(newSettings)
                        }
                    )) {
                        ForEach(PhotoFilter.allCases, id: \.self) { filterOption in
                            Text(filterOption.rawValue).tag(filterOption)
                        }
                    }
                }

                Section("Filter Picker") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(PhotoFilter.allCases, id: \.self) { filterOption in
                                Button(action: {
                                    var newSettings = viewModel.settings
                                    newSettings.filter = filterOption
                                    viewModel.updateSettings(newSettings)
                                }) {
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(filterColor(filterOption))
                                            .frame(width: 12, height: 12)
                                        Text(filterOption.rawValue)
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 14)
                                    .background(viewModel.settings.filter == filterOption ? Color(red: 1, green: 0.9, blue: 0.95) : Color(UIColor.systemGray5))
                                    .foregroundColor(viewModel.settings.filter == filterOption ? .pink : .gray)
                                    .cornerRadius(12)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }

                Section("About") {
                    NavigationLink(destination: Text("Rate HerView")) {
                        HStack(spacing: 12) {
                            Image(systemName: "star.fill")
                                .font(.callout)
                                .foregroundColor(.orange)
                                .frame(width: 30, height: 30)
                                .background(Color.yellow.opacity(0.1))
                                .cornerRadius(8)
                            Text("Rate HerView")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                    }

                    NavigationLink(destination: Text("Send Feedback")) {
                        HStack(spacing: 12) {
                            Image(systemName: "envelope.fill")
                                .font(.callout)
                                .foregroundColor(.orange)
                                .frame(width: 30, height: 30)
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(8)
                            Text("Send Feedback")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                    }

                    NavigationLink(destination: Text("Privacy Policy")) {
                        HStack(spacing: 12) {
                            Image(systemName: "lock.fill")
                                .font(.callout)
                                .foregroundColor(.blue)
                                .frame(width: 30, height: 30)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                    }

                    VStack(spacing: 0) {
                        Divider()
                        Text("HerView v1.0.0 · All data stays on device")
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .padding(.vertical, 12)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
    }

    private func formatInterval(_ seconds: Double) -> String {
        if seconds < 60 { return "\(Int(seconds))s" }
        return "\(Int(seconds / 60)) min"
    }

    private func filterColor(_ filter: PhotoFilter) -> Color {
        switch filter {
        case .none: return .pink
        case .grayscale: return .gray
        case .warm: return .orange
        case .cool: return .blue
        }
    }
}

#Preview {
    SettingsView(viewModel: SlideshowViewModel())
}
