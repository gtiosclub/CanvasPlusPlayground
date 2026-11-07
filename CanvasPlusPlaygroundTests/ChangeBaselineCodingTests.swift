@testable import CanvasPlusPlayground
import Foundation
import Testing

struct ChangeBaselineCodingTests {
    @Test(arguments: [false, true])
    func decodesBothPR1Fixtures(populated: Bool) throws {
        let data = populated ? Data(Self.populatedPR1JSON.utf8) : oldJSON()
        let envelope = try JSONDecoder().decode(ChangeStoreEnvelope.self, from: data)
        #expect(envelope.formatVersion == 1)
        #expect(envelope.accounts.count == 1)
        let account = try #require(envelope.accounts.first)
        #expect(account.baselines.isEmpty)
        if populated {
            let key = try ChangeTestSupport.item()
            let snapshot = ChangeSnapshot(
                itemKey: key, displayTitle: "Essay", values: [.name: .text("Essay"), .pointsPossible: .number(100)]
            )
            let record = ChangeRecord(
                itemKey: key,
                field: .name,
                oldValue: .text("Old title"),
                newValue: .text("Essay"),
                firstDetectedAt: ChangeTestSupport.time,
                lastDetectedAt: ChangeTestSupport.time,
                revision: 7
            )
            #expect(account.snapshots == [snapshot])
            #expect(account.records == [record])
            #expect(envelope.commitRevision == 7)
        } else {
            #expect(account.snapshots.isEmpty)
            #expect(account.records.isEmpty)
        }
    }

    @Test(arguments: [false, true])
    func encodesBaselineKey(populated: Bool) throws {
        let account = try ChangeTestSupport.item().account
        let baselines = populated ? ChangeResourceFamily.allCases.map {
            ChangeBaseline(courseID: "123", family: $0)
        } : []
        let envelope = ChangeStoreEnvelope(accounts: [.init(account: account, baselines: baselines)])
        let data = try JSONEncoder().encode(envelope)
        #expect(try JSONDecoder().decode(ChangeStoreEnvelope.self, from: data) == envelope)
        let object = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let accounts = try #require(object["accounts"] as? [[String: Any]])
        let encoded = try #require(accounts.first?["baselines"] as? [[String: Any]])
        #expect(encoded.count == baselines.count)
    }

    @Test(arguments: ["{}", "true", "42", "\"bad\"", "[{}]", #"[{"courseID":"123","family":"unknown"}]"#])
    func rejectsMalformedBaselines(value: String) {
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(ChangeStoreEnvelope.self, from: oldJSON(baselines: value))
        }
    }

    @Test func rejectsExplicitNull() {
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(ChangeStoreEnvelope.self, from: oldJSON(baselines: "null"))
        }
    }

    // Encoded by the unmodified JSONChangeEventStore at 24315ec.
    // swiftlint:disable:next line_length
    private static let populatedPR1JSON = #"{"accounts":[{"account":{"host":"canvas.example.edu","userID":"134"},"records":[{"field":"name","firstDetectedAt":821692800,"itemKey":{"account":{"host":"canvas.example.edu","userID":"134"},"courseID":"123","itemID":"23","itemType":"assignment"},"lastDetectedAt":821692800,"newValue":{"type":"text","value":"Essay"},"oldValue":{"type":"text","value":"Old title"},"revision":7}],"snapshots":[{"displayTitle":"Essay","itemKey":{"account":{"host":"canvas.example.edu","userID":"134"},"courseID":"123","itemID":"23","itemType":"assignment"},"values":[{"field":"name","value":{"type":"text","value":"Essay"}},{"field":"pointsPossible","value":{"type":"number","value":100}}]}]}],"commitRevision":7,"formatVersion":1,"resetGeneration":"00000000-0000-0000-0000-000000000001"}"#

    private func oldJSON(baselines: String? = nil) -> Data {
        let extra = baselines.map { ",\"baselines\":\($0)" } ?? ""
        return Data("""
        {"formatVersion":1,"resetGeneration":"00000000-0000-0000-0000-000000000001","commitRevision":0,
         "accounts":[{"account":{"host":"canvas.example.edu","userID":"134"},"snapshots":[],"records":[]\(extra)}]}
        """.utf8)
    }
}
