import AVFoundation
import SwiftUI

struct OnboardingExitVideoView: View {
    private static let ctaMessages = [
        "Many people believe that Japanese characters, or kanji, are difficult to learn.",
        "But most kanji are built from radicals, and each radical carries meaning.",
        "Learn kanji intuitively.\nDiscover the art within every character."
    ]

    struct PreviewState {
        let isPreparingVideo: Bool
        let didFailToLoadVideo: Bool
        let whiteRevealOpacity: Double
    }

    let url: URL
    let onEnterApp: () -> Void
    private let previewState: PreviewState?

    @State private var player = AVPlayer()
    @State private var isPreparingVideo = true
    @State private var didFailToLoadVideo = false
    @State private var isTransitioningToApp = false
    @State private var ctaMessage = OnboardingExitVideoView.ctaMessages[0]
    @State private var ctaMessageOpacity = 1.0
    @State private var whiteRevealOpacity = 1.0

    init(
        url: URL,
        onEnterApp: @escaping () -> Void,
        previewState: PreviewState? = nil
    ) {
        self.url = url
        self.onEnterApp = onEnterApp
        self.previewState = previewState
        _isPreparingVideo = State(initialValue: previewState?.isPreparingVideo ?? true)
        _didFailToLoadVideo = State(initialValue: previewState?.didFailToLoadVideo ?? false)
        _ctaMessage = State(initialValue: OnboardingExitVideoView.ctaMessages[0])
        _whiteRevealOpacity = State(initialValue: previewState?.whiteRevealOpacity ?? 1.0)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            NonInteractiveVideoPlayerView(player: player)
                .ignoresSafeArea()
                .opacity(isPreparingVideo ? 0 : 1)

            if isPreparingVideo {
                ProgressView("Loading video...")
                    .tint(.mint)
                    .foregroundStyle(.primary)
            }

            if didFailToLoadVideo {
                VStack(spacing: 12) {
                    Text("The intro video could not be loaded.")
                        .font(.headline)
                    Button("Enter App") {
                        SoundEffectService.shared.play(.clickLow)
                        beginAppEntry()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(24)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            }

            if !didFailToLoadVideo {
                callToAction
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, 28)
                    .opacity(isPreparingVideo ? 0 : 1)
            }

            Color.white
                .ignoresSafeArea()
                .opacity(whiteRevealOpacity)
                .allowsHitTesting(false)
        }
        .task {
            guard previewState == nil else { return }
            await prepareAndPlayVideo()
        }
        .task(id: isPreparingVideo) {
            guard previewState == nil, !isPreparingVideo, !didFailToLoadVideo else { return }
            await runCallToActionMessageSequence()
        }
        .onReceive(NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)) { notification in
            guard let item = notification.object as? AVPlayerItem,
                  item == player.currentItem else { return }
            freezeOnLastFrame()
        }
    }

    @MainActor
    private func prepareAndPlayVideo() async {
        isPreparingVideo = true
        didFailToLoadVideo = false
        isTransitioningToApp = false
        ctaMessage = Self.ctaMessages[0]
        ctaMessageOpacity = 1
        whiteRevealOpacity = 1

        let asset = AVURLAsset(url: url)

        do {
            let isPlayable = try await asset.load(.isPlayable)
            guard isPlayable else {
                didFailToLoadVideo = true
                isPreparingVideo = false
                whiteRevealOpacity = 0
                return
            }

            let item = try await makePlaybackItem(from: asset)
            player.actionAtItemEnd = .pause
#if targetEnvironment(simulator)
            player.isMuted = true
#else
            player.isMuted = false
#endif
            player.replaceCurrentItem(with: item)
            _ = await player.seek(to: .zero)
            player.play()
            isPreparingVideo = false
            withAnimation(.easeOut(duration: 2.6)) {
                whiteRevealOpacity = 0
            }
        } catch {
            didFailToLoadVideo = true
            isPreparingVideo = false
            whiteRevealOpacity = 0
        }
    }

    private func makePlaybackItem(from asset: AVURLAsset) async throws -> AVPlayerItem {
#if targetEnvironment(simulator)
        let duration = try await asset.load(.duration)
        let videoTracks = try await asset.loadTracks(withMediaType: .video)

        guard let sourceVideoTrack = videoTracks.first else {
            return AVPlayerItem(asset: asset)
        }

        let composition = AVMutableComposition()
        guard let compositionTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else {
            return AVPlayerItem(asset: asset)
        }

        try compositionTrack.insertTimeRange(
            CMTimeRange(start: .zero, duration: duration),
            of: sourceVideoTrack,
            at: .zero
        )
        compositionTrack.preferredTransform = try await sourceVideoTrack.load(.preferredTransform)
        return AVPlayerItem(asset: composition)
#else
        return AVPlayerItem(asset: asset)
#endif
    }

    private func beginAppEntry() {
        guard !isTransitioningToApp else { return }

        player.pause()
        isTransitioningToApp = true

        withAnimation(.easeInOut(duration: 0.9)) {
            whiteRevealOpacity = 1
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(920))
            onEnterApp()
        }
    }

    private func freezeOnLastFrame() {
        player.pause()

        guard let duration = player.currentItem?.duration,
              duration.isNumeric else { return }

        let lastFrameTime = CMTimeSubtract(duration, CMTime(seconds: 0.03, preferredTimescale: 600))
        guard lastFrameTime.isValid && lastFrameTime.isNumeric else { return }

        Task {
            _ = await player.seek(to: lastFrameTime)
        }
    }

    @MainActor
    private func runCallToActionMessageSequence() async {
        ctaMessage = Self.ctaMessages[0]
        ctaMessageOpacity = 1

        try? await Task.sleep(for: .seconds(7.5))
        guard !isPreparingVideo, !didFailToLoadVideo else { return }
        await transitionCallToActionMessage(to: Self.ctaMessages[1])

        try? await Task.sleep(for: .seconds(5))
        guard !isPreparingVideo, !didFailToLoadVideo else { return }
        await transitionCallToActionMessage(to: Self.ctaMessages[2])
    }

    @MainActor
    private func transitionCallToActionMessage(to message: String) async {
        withAnimation(.easeInOut(duration: 0.35)) {
            ctaMessageOpacity = 0
        }

        try? await Task.sleep(for: .milliseconds(360))

        ctaMessage = message

        withAnimation(.easeInOut(duration: 0.45)) {
            ctaMessageOpacity = 1
        }
    }

    private var callToAction: some View {
        ZStack {
            VStack(spacing: 14) {
                Text("Discover Kanji")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                Text(ctaMessage)
                    .font(Font.body.monospacedDigit())
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                    .opacity(ctaMessageOpacity)

                Button {
                    SoundEffectService.shared.play(.clickLow)
                    beginAppEntry()
                } label: {
                    Text("Start Learning")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(red: 0.54, green: 0.36, blue: 0.22))
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 18)
        }
        .frame(width: 320)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.black.opacity(0.74))
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.16), lineWidth: 1)
        )
    }
}

private struct NonInteractiveVideoPlayerView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerContainerView {
        let view = PlayerContainerView()
        view.playerLayer.videoGravity = .resizeAspect
        view.playerLayer.player = player
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ uiView: PlayerContainerView, context: Context) {
        uiView.playerLayer.player = player
    }
}

private final class PlayerContainerView: UIView {
    override static var layerClass: AnyClass {
        AVPlayerLayer.self
    }

    var playerLayer: AVPlayerLayer {
        layer as! AVPlayerLayer
    }
}

#Preview("CTA Loaded") {
    ZStack {
        VStack(spacing: 14) {
            Text("Discover Kanji")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
            Text("Learn Kanji intuitively.\nUnderstand the art behind Kanji.")
                .font(Font.body.monospacedDigit())
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)

            Button {
//                SoundEffectService.shared.play(.clickLow)
//                beginAppEntry()
            } label: {
                Text("Start Learning")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(red: 0.54, green: 0.36, blue: 0.22))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
    }
    .frame(width: 320)
    .background(
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(Color.black.opacity(0.74))
    )
    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    .overlay(
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .stroke(Color.white.opacity(0.16), lineWidth: 1)
    )
}
