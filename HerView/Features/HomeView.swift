import SwiftUI
import Photos

struct HomeView: View {
    @State private var viewModel = SlideshowViewModel()
    @State private var showingPhotoPicker = false
    @State private var showingSettings = false
    @Environment(\.modelContext) var modelContext

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading) {
                        Text("Good morning")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Text("HerView")
                            .font(.system(size: 28, weight: .bold))
                    }
                    Spacer()
                    NavigationLink(destination: SettingsView(viewModel: viewModel)) {
                        Image(systemName: "gear")
                            .font(.system(size: 18))
                            .frame(width: 36, height: 36)
                            .background(Color(red: 1, green: 0.9, blue: 0.95))
                            .cornerRadius(18)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                ScrollView {
                    VStack(spacing: 20) {
                        // Active widget preview
                        if !viewModel.photoIdentifiers.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("ACTIVE WIDGET")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .fontWeight(.semibold)

                                SlideshowPreviewCard(viewModel: viewModel)

                                Button(action: { showingPhotoPicker = true }) {
                                    Text("Edit Photos")
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 42)
                                        .background(Color(UIColor.systemGray5))
                                        .cornerRadius(14)
                                        .foregroundColor(.primary)
                                }
                            }
                            .padding(.horizontal, 16)
                        }

                        // Quick stats
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(viewModel.photoIdentifiers.count)")
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundColor(.pink)
                                Text("Photos")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                            .background(Color.white)
                            .cornerRadius(12)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(Int(viewModel.settings.intervalSeconds))s")
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundColor(.blue)
                                Text("Interval")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                            .background(Color.white)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 16)

                        // Add widget guide
                        VStack(spacing: 12) {
                            HStack(spacing: 10) {
                                Image(systemName: "iphone")
                                    .font(.system(size: 18))
                                    .frame(width: 34, height: 34)
                                    .background(Color(red: 1, green: 0.9, blue: 0.95))
                                    .cornerRadius(10)

                                VStack(alignment: .leading) {
                                    Text("Add Widget to Home")
                                        .font(.callout)
                                        .fontWeight(.semibold)
                                    Text("3 easy steps")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                            }

                            NavigationLink(destination: WidgetGuideView()) {
                                HStack {
                                    Text("Show me how")
                                    Image(systemName: "arrow.right")
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                                .background(Color(red: 1, green: 0.9, blue: 0.95))
                                .foregroundColor(.pink)
                                .cornerRadius(12)
                                .font(.callout)
                                .fontWeight(.semibold)
                            }
                        }
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(red: 1, green: 0.9, blue: 0.95), lineWidth: 1.5)
                        )
                        .padding(.horizontal, 16)
                    }
                    .padding(.vertical, 20)
                }
            }
            .background(Color(UIColor.systemGray6))
            .sheet(isPresented: $showingPhotoPicker) {
                PhotoPickerView(viewModel: viewModel, onPhotosPicked: {})
            }
            .onAppear {
                viewModel.startSlideshow()
            }
            .onDisappear {
                viewModel.stopSlideshow()
            }
        }
    }
}

struct SlideshowPreviewCard: View {
    let viewModel: SlideshowViewModel
    @State private var currentImage: UIImage?

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Widget preview
                if let identifier = viewModel.currentPhotoIdentifier {
                    ZStack(alignment: .bottomLeading) {
                        if let image = PhotoLibraryService.shared.loadImage(for: identifier, targetSize: CGSize(width: 128, height: 128)) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipped()
                                .cornerRadius(12)
                        } else {
                            Color.gray.opacity(0.3)
                                .frame(width: 100, height: 100)
                                .cornerRadius(12)
                        }

                        Text("Photo \(viewModel.photoIdentifiers.firstIndex(of: identifier) ?? 0 + 1) of \(viewModel.photoIdentifiers.count)")
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(6)
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(6)
                            .padding(8)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("\(viewModel.photoIdentifiers.count) photos selected")
                        .font(.callout)
                        .fontWeight(.semibold)

                    Text("Shuffling every \(Int(viewModel.settings.intervalSeconds))s")
                        .font(.caption)
                        .foregroundColor(.gray)

                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                        Text("Running")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 10)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                }
                Spacer()
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
    }
}

#Preview {
    HomeView()
}
