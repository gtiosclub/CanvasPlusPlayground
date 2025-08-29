import FoundationModels
import SwiftUI

@available(iOS 26.0, macOS 26.0, *)
enum IntelligenceSupport {
    static let gradientColors: [Color] = [
        .c1, .c2, .c3,
        .c4, .c2, .c4,
        .c3, .c2, .c3
    ]

    static var modelAvailability: SystemLanguageModel.Availability {
        SystemLanguageModel.default.availability
    }

    static var modelAvailabilityDescription: String {
        switch modelAvailability {
        case .available:
            return "Intelligence is ready."
        case .unavailable(.appleIntelligenceNotEnabled):
            return "Enable Apple Intelligence on your device to use this feature."
        case .unavailable(.modelNotReady):
            return "Model is not ready. Try again later."
        case .unavailable(.deviceNotEligible):
            return "Your device does not support this feature."
        case .unavailable:
            return "Unknown error."
        }
    }

    static var isModelAvailable: Bool {
        modelAvailability == .available
    }
}
