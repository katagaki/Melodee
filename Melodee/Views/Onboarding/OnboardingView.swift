import SwiftUI

struct OnboardingView: View {

    var onContinue: () -> Void

    private let appName = "Melodee"

    private var welcomeTitle: Text {
        let format = String(localized: "Onboarding.Title")
        let accent = Text(appName).foregroundStyle(.accent)
        guard let range = format.range(of: "%@") else {
            return Text(format).foregroundStyle(.primary)
        }
        let leading = Text(String(format[..<range.lowerBound])).foregroundStyle(.primary)
        let trailing = Text(String(format[range.upperBound...])).foregroundStyle(.primary)
        return leading + accent + trailing
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16.0) {
                welcomeTitle
                    .fontWeight(.black)
                    .font(.largeTitle)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 24.0)
                Spacer()
                VStack(alignment: .leading, spacing: 32.0) {
                    FeatureRow(
                        symbol: "waveform",
                        colors: [.accent, .primary],
                        title: "Onboarding.Feature.PlayAnything.Title",
                        blurb: "Onboarding.Feature.PlayAnything.Blurb"
                    )
                    FeatureRow(
                        symbol: "tag.fill",
                        colors: [.pink, .red],
                        title: "Onboarding.Feature.EditTags.Title",
                        blurb: "Onboarding.Feature.EditTags.Blurb"
                    )
                    FeatureRow(
                        symbol: "doc.richtext.fill",
                        colors: [.green, .yellow],
                        title: "Onboarding.Feature.BeyondAudio.Title",
                        blurb: "Onboarding.Feature.BeyondAudio.Blurb"
                    )
                    FeatureRow(
                        symbol: "folder.fill",
                        colors: [.cyan, .blue],
                        title: "Onboarding.Feature.OpenFolder.Title",
                        blurb: "Onboarding.Feature.OpenFolder.Blurb"
                    )
                }
                Spacer()
            }
            .padding(18.0)
        }
        .background {
            LinearGradient(
                colors: [.accent.opacity(0.12), .clear],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()
        }
        .safeAreaInset(edge: .bottom, spacing: 0.0) {
            VStack(spacing: 12.0) {
                continueButton
            }
            .padding()
        }
        .interactiveDismissDisabled()
        .presentationDragIndicator(.hidden)
    }

    @ViewBuilder
    private var continueButton: some View {
        Button(action: onContinue) {
            Text("Onboarding.Continue")
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6.0)
        }
        .clipShape(.capsule)
        .tint(.accent)
        .buttonStyle(.glassProminent)
    }
}

private struct FeatureRow: View {

    var symbol: String
    var colors: [Color]
    var title: LocalizedStringKey
    var blurb: LocalizedStringKey

    var body: some View {
        HStack(alignment: .center, spacing: 16.0) {
            Image(systemName: symbol)
                .font(.system(size: 40.0))
                .foregroundStyle(
                    LinearGradient(
                        colors: colors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 56.0, height: 56.0)
            VStack(alignment: .leading, spacing: 6.0) {
                Text(title)
                    .fontWeight(.bold)
                Text(blurb)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0.0)
        }
    }
}

extension OnboardingView {
    static var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    }

    static func shouldShow(currentVersion: String, lastSeenVersion: String) -> Bool {
        guard let current = majorMinor(currentVersion) else { return false }
        guard let last = majorMinor(lastSeenVersion) else { return true }
        if current.major != last.major { return current.major > last.major }
        return current.minor > last.minor
    }

    static func majorMinor(_ version: String) -> (major: Int, minor: Int)? {
        let components = version.split(separator: ".")
        guard let major = components.first.flatMap({ Int($0) }) else { return nil }
        let minor = components.count > 1 ? (Int(components[1]) ?? 0) : 0
        return (major, minor)
    }
}
