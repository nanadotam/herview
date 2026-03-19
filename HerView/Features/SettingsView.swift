import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    let viewModel: SlideshowViewModel
    @State private var interval: Double
    @State private var shuffleEnabled: Bool
    @State private var cropMode: CropMode
    @State private var filter: PhotoFilter

    init(viewModel: SlideshowViewModel) {
        self.viewModel = viewModel
        _interval = State(initialValue: viewModel.settings.intervalSeconds)
        _shuffleEnabled = State(initialValue: viewModel.settings.shuffleEnabled)
        _cropMode = State(initialValue: viewModel.settings.cropMode)
        _filter = State(initialValue: viewModel.settings.filter)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Slideshow Interval") {
                    VStack(spacing: 12) {
                        HStack(spacing: 8) {
                            ForEach([10.0, 30.0, 60.0, 300.0], id: \.self) { intervalValue in
                                Button(action: {
                                    interval = intervalValue
                                    updateSettings()
                                }) {
                                    Text(formatInterval(intervalValue))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(interval == intervalValue ? Color.pink : Color(UIColor.systemGray5))
                                        .foregroundColor(interval == intervalValue ? .white : .gray)
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
                    Toggle(isOn: $shuffleEnabled.onChange(updateSettings)) {
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
                    Picker("Crop Mode", selection: $cropMode.onChange(updateSettings)) {
                        ForEach(CropMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }

                    Picker("Filter", selection: $filter.onChange(updateSettings)) {
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
                                    filter = filterOption
                                    updateSettings()
                                }) {
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(filterColor(filterOption))
                                            .frame(width: 12, height: 12)
                                        Text(filterOption.rawValue)
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 14)
                                    .background(filter == filterOption ? Color(red: 1, green: 0.9, blue: 0.95) : Color(UIColor.systemGray5))
                                    .foregroundColor(filter == filterOption ? .pink : .gray)
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
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("‹ Back") { dismiss() }
                        .foregroundColor(.pink)
                }
            }
        }
    }

    private func updateSettings() {
        let newSettings = SlideshowSettings(
            intervalSeconds: interval,
            shuffleEnabled: shuffleEnabled,
            cropMode: cropMode,
            filter: filter
        )
        viewModel.updateSettings(newSettings)
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

// Helper extension for binding onChange
extension Binding {
    func onChange(_ handler: @escaping () -> Void) -> Binding<Value> {
        Binding(
            get: { self.wrappedValue },
            set: { newValue in
                self.wrappedValue = newValue
                handler()
            }
        )
    }
}

#Preview {
    SettingsView(viewModel: SlideshowViewModel())
}
