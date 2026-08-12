import Foundation
import TipKit

struct NPQueueTip: Tip {
    // Popover tips render at window level, so they would otherwise appear on top
    // of the onboarding sheet.
    @Parameter
    static var isOnboardingActive: Bool = false

    var rules: [Rule] {
        #Rule(Self.$isOnboardingActive) { $0 == false }
    }

    var title: Text {
        Text("NowPlaying.Tip.Queue.Title")
    }
    var message: Text? {
        Text("NowPlaying.Tip.Queue.Text")
    }
    var image: Image? {
        Image(systemName: "text.line.last.and.arrowtriangle.forward")
    }
}
