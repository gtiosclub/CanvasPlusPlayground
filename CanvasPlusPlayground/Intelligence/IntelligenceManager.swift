/*
 Imported from fullmoon app: https://github.com/mainframecomputer/fullmoon-ios
 */

import SwiftData
import SwiftUI

class IntelligenceManager: ObservableObject {
    static let gradientColors: [Color] = [
        .c1, .c2, .c3,
        .c4, .c2, .c4,
        .c3, .c2, .c3
    ]

    @AppStorage("systemPrompt") var systemPrompt = "you are a helpful assistant"
    @AppStorage("currentModelName") var currentModelName: String?

    private let installedModelsKey = StorageKeys.installedModelsKey

    @Published var installedModels: [String] = [] {
        didSet {
            saveInstalledModelsToUserDefaults()
        }
    }

    init() {
        loadInstalledModelsFromUserDefaults()
    }

    // Function to save the array to UserDefaults as JSON
    private func saveInstalledModelsToUserDefaults() {
        if let jsonData = try? JSONEncoder().encode(installedModels) {
            UserDefaults.standard.set(jsonData, forKey: installedModelsKey)
        }
    }

    // Function to load the array from UserDefaults
    private func loadInstalledModelsFromUserDefaults() {
        if let jsonData = UserDefaults.standard.data(forKey: installedModelsKey),
           let decodedArray = try? JSONDecoder().decode([String].self, from: jsonData) {
            self.installedModels = decodedArray
        } else {
            self.installedModels = [] // Default to an empty array if there's no data
        }
    }

    func addInstalledModel(_ model: String) {
        if !installedModels.contains(model) {
            installedModels.append(model)
        }
    }

    func modelDisplayName(_ modelName: String) -> String {
        modelName.replacingOccurrences(of: "mlx-community/", with: "").lowercased()
    }
}

enum Role: String, Codable {
    case assistant
    case user
    case system
}

class Message {
    var id: UUID
    var role: Role
    var content: String
    var timestamp: Date

    var thread: Thread?

    init(role: Role, content: String, thread: Thread? = nil) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.timestamp = Date()
        self.thread = thread
    }
}

class Thread {
    var id: UUID
    var title: String?
    var timestamp: Date

    var messages: [Message] = []

    var sortedMessages: [Message] {
        messages.sorted { $0.timestamp < $1.timestamp }
    }

    init() {
        self.id = UUID()
        self.timestamp = Date()
    }
}
