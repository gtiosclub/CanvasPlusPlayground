/*
 Imported from fullmoon app: https://github.com/mainframecomputer/fullmoon-ios
 */

import MLXLLM
import Foundation

extension ModelConfiguration: @retroactive Equatable {
    public static func == (lhs: MLXLLM.ModelConfiguration, rhs: MLXLLM.ModelConfiguration) -> Bool {
        return lhs.name == rhs.name
    }

    public static let llama321B4bit = ModelConfiguration(
        id: "mlx-community/Llama-3.2-1B-Instruct-4bit"
    )

    public static let llama323b4bit = ModelConfiguration(
        id: "mlx-community/Llama-3.2-3B-Instruct-4bit"
    )

    public static var availableModels: [ModelConfiguration] = [
        llama321B4bit,
        llama323b4bit
    ]

    public static var defaultModel: ModelConfiguration {
        llama321B4bit
    }

    func getPromptHistory(thread: Thread, systemPrompt: String) -> String {
        var history = ""

        switch self {
        case .llama321B4bit, .llama323b4bit:
            history = "<|begin_of_text|>"
            history += "<|start_header_id|>system<|end_header_id|>\n\(systemPrompt)"

            for message in thread.sortedMessages {
                logger.debug("\(message.content)")
                if message.role == .user {
                    history += "<|eot_id|>\n<|start_header_id|>user<|end_header_id|>\n\(message.content)\n<|eot_id|>\n<|start_header_id|>assistant<|end_header_id|>"
                }

                if message.role == .assistant {
                    history += message.content + "\n"
                }
            }
        default:
            break
        }
        return history
    }
}
