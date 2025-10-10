import FoundationModels
import SwiftUI

enum IntelligenceSupport {
    static let gradientColors: [Color] = [
        .c1, .c1, .c2,
        .c2, .c2, .c3,
        .c3, .c4, .c4
    ]

    @available(iOS 26.0, macOS 26.0, *)
    static var modelAvailability: SystemLanguageModel.Availability {
        SystemLanguageModel.default.availability
    }

    @available(iOS 26.0, macOS 26.0, *)
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
        case .unavailable(_):
            return "Unknown error."
        }
    }

    @available(iOS 26.0, macOS 26.0, *)
    static var isModelAvailable: Bool {
        modelAvailability == .available
    }
}
