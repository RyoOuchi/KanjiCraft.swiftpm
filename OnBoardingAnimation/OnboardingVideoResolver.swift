import Foundation
import UIKit

enum OnboardingVideoResolver {
    static func resolvedOnboardingExitVideoURL() -> URL? {
        if let introMP4URL = bundledVideoURL(assetName: "IntroVideo", fileExtension: "mp4") {
            return introMP4URL
        }

        if let introMOVURL = bundledVideoURL(assetName: "IntroVideo", fileExtension: "mov") {
            return introMOVURL
        }

        if let mainURL = Bundle.main.url(forResource: "OnboardingExitVideo", withExtension: "mp4") {
            return mainURL
        }

        if let moduleURL = Bundle.module.url(forResource: "OnboardingExitVideo", withExtension: "mp4") {
            return moduleURL
        }

        if let mainMOVURL = Bundle.main.url(forResource: "OnboardingExitVideo", withExtension: "mov") {
            return mainMOVURL
        }

        return Bundle.module.url(forResource: "OnboardingExitVideo", withExtension: "mov")
    }

    static func debugLines() -> [String] {
        var lines: [String] = []

        for candidate in candidateURLs() {
            if let url = candidate.url {
                lines.append("\(candidate.label): found")
                lines.append("  \(url.path)")
                if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
                   let fileSize = attributes[.size] as? NSNumber {
                    lines.append("  size: \(ByteCountFormatter.string(fromByteCount: fileSize.int64Value, countStyle: .file))")
                }
            } else {
                lines.append("\(candidate.label): missing")
            }
        }

        let hasDataAsset = NSDataAsset(name: "IntroVideo", bundle: .main) != nil
            || NSDataAsset(name: "IntroVideo", bundle: .module) != nil
        lines.append("IntroVideo data asset: \(hasDataAsset ? "found" : "missing")")

        if let resolvedURL = resolvedOnboardingExitVideoURL() {
            lines.append("Resolved URL:")
            lines.append(resolvedURL.path)
        } else {
            lines.append("Resolved URL: none")
        }

        return lines
    }

    private static func candidateURLs() -> [(label: String, url: URL?)] {
        [
            ("Bundle.main direct mp4", Bundle.main.url(forResource: "IntroVideo", withExtension: "mp4")),
            ("Bundle.module direct mp4", Bundle.module.url(forResource: "IntroVideo", withExtension: "mp4")),
            ("Bundle.main Resources mp4", Bundle.main.url(forResource: "IntroVideo", withExtension: "mp4", subdirectory: "Resources")),
            ("Bundle.module Resources mp4", Bundle.module.url(forResource: "IntroVideo", withExtension: "mp4", subdirectory: "Resources")),
            ("Bundle.main direct mov", Bundle.main.url(forResource: "IntroVideo", withExtension: "mov")),
            ("Bundle.module direct mov", Bundle.module.url(forResource: "IntroVideo", withExtension: "mov")),
            ("Bundle.main fallback mp4", bundleResourceURL(bundle: .main, fileName: "IntroVideo.mp4")),
            ("Bundle.module fallback mp4", bundleResourceURL(bundle: .module, fileName: "IntroVideo.mp4"))
        ]
    }

    private static func bundledVideoURL(assetName: String, fileExtension: String) -> URL? {
        if let directURL = Bundle.main.url(forResource: assetName, withExtension: fileExtension)
            ?? Bundle.module.url(forResource: assetName, withExtension: fileExtension)
            ?? Bundle.main.url(forResource: assetName, withExtension: fileExtension, subdirectory: "Resources")
            ?? Bundle.module.url(forResource: assetName, withExtension: fileExtension, subdirectory: "Resources") {
            return directURL
        }

        if let mainResourceURL = bundleResourceURL(bundle: .main, fileName: "\(assetName).\(fileExtension)") {
            return mainResourceURL
        }

        if let moduleResourceURL = bundleResourceURL(bundle: .module, fileName: "\(assetName).\(fileExtension)") {
            return moduleResourceURL
        }

        guard let dataAsset = NSDataAsset(name: assetName, bundle: .main)
            ?? NSDataAsset(name: assetName, bundle: .module) else {
            return nil
        }

        let temporaryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(assetName)
            .appendingPathExtension(fileExtension)

        if FileManager.default.fileExists(atPath: temporaryURL.path) {
            return temporaryURL
        }

        do {
            try dataAsset.data.write(to: temporaryURL, options: .atomic)
            return temporaryURL
        } catch {
            return nil
        }
    }

    private static func bundleResourceURL(bundle: Bundle, fileName: String) -> URL? {
        if let directURL = bundle.resourceURL?.appendingPathComponent(fileName),
           FileManager.default.fileExists(atPath: directURL.path) {
            return directURL
        }

        if let nestedURL = bundle.resourceURL?
            .appendingPathComponent("Resources")
            .appendingPathComponent(fileName),
           FileManager.default.fileExists(atPath: nestedURL.path) {
            return nestedURL
        }

        return nil
    }
}
