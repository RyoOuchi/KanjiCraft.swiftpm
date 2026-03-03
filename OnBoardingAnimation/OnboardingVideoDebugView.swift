import AVFoundation
import AVKit
import Foundation
import SwiftUI

struct OnboardingVideoDebugView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var player = AVPlayer()
    @State private var resolvedURL: URL?
    @State private var debugLines: [String] = []
    @State private var playerStatusText = "Not started"
    @State private var isPlayableText = "Unknown"
    @State private var durationText = "Unknown"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                videoSurface

                VStack(alignment: .leading, spacing: 8) {
                    Text("Video Diagnostics")
                        .font(.title2.weight(.semibold))

                    debugValueRow(title: "Resolved URL", value: resolvedURL?.path ?? "None")
                    debugValueRow(title: "Playable", value: isPlayableText)
                    debugValueRow(title: "Duration", value: durationText)
                    debugValueRow(title: "Player Status", value: playerStatusText)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Resource Search")
                        .font(.headline)

                    ForEach(debugLines, id: \.self) { line in
                        Text(line)
                            .font(.system(.footnote, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                }

                HStack(spacing: 12) {
                    Button("Retry") {
                        SoundEffectService.shared.play(.clickLow)
                        Task {
                            await loadDebugState()
                        }
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Close") {
                        SoundEffectService.shared.play(.clickLow)
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(24)
        }
        .navigationTitle("Video Debug")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadDebugState()
        }
    }

    private var videoSurface: some View {
        VideoPlayer(player: player)
            .frame(maxWidth: .infinity)
            .aspectRatio(16 / 9, contentMode: .fit)
            .background(Color.black, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(alignment: .bottomLeading) {
                Text(playerStatusText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.6), in: Capsule())
                    .padding(16)
            }
    }

    @MainActor
    private func loadDebugState() async {
        player.pause()
        player.replaceCurrentItem(with: nil)

        debugLines = OnboardingVideoResolver.debugLines()
        resolvedURL = OnboardingVideoResolver.resolvedOnboardingExitVideoURL()
        playerStatusText = "Preparing..."
        isPlayableText = "Unknown"
        durationText = "Unknown"

        guard let resolvedURL else {
            playerStatusText = "No video URL resolved"
            return
        }

        let asset = AVURLAsset(url: resolvedURL)

        do {
            let isPlayable = try await asset.load(.isPlayable)
            isPlayableText = isPlayable ? "Yes" : "No"

            let duration = try await asset.load(.duration)
            if duration.isNumeric && duration.seconds.isFinite {
                durationText = String(format: "%.2f seconds", duration.seconds)
            } else {
                durationText = "Unavailable"
            }

            guard isPlayable else {
                playerStatusText = "Asset is not playable"
                return
            }

            let item = AVPlayerItem(asset: asset)
            player.replaceCurrentItem(with: item)
            _ = await player.seek(to: .zero)
            player.play()

            try? await Task.sleep(for: .milliseconds(700))

            if let error = item.error {
                playerStatusText = "Player item error: \(error.localizedDescription)"
            } else {
                switch item.status {
                case .unknown:
                    playerStatusText = "Player item status: unknown"
                case .readyToPlay:
                    playerStatusText = "Player item ready to play"
                case .failed:
                    playerStatusText = "Player item failed"
                @unknown default:
                    playerStatusText = "Player item status: unknown future case"
                }
            }
        } catch {
            playerStatusText = "Load failed: \(error.localizedDescription)"
        }
    }

    private func debugValueRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            Text(value)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        }
    }
}
