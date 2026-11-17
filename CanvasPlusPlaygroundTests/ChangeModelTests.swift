import Foundation
import Testing
@testable import CanvasPlusPlayground

struct ChangeModelTests {
    @Test(arguments: [
        "canvas.example.edu", "https://Canvas.Example.edu/", " https://canvas.example.edu:443/ ",
        "http://canvas.example.edu:443/", "canvas.example.edu."
    ])
    func normalizesAccount(host: String) throws {
        let account = try AccountKey(rawHost: host, rawUserID: " 134\n")
        #expect(account.host == "canvas.example.edu")
        #expect(account.userID == "134")
    }

    @Test(arguments: [
        "", " \n", "ftp://canvas.example.edu", "https://name:password@canvas.example.edu",
        "https://canvas.example.edu:0", "canvas.example.edu..", ".canvas.example.edu"
    ])
    func rejectsInvalidHost(host: String) {
        #expect(throws: AccountKey.ValidationError.self) {
            try AccountKey(rawHost: host, rawUserID: "134")
        }
    }

    @Test(arguments: [
        ("canvas.example.edu", "canvas.example.edu"),
        ("CANVAS.Example.EDU", "canvas.example.edu"),
        ("https://Canvas.Example.edu/courses/1?x=1", "canvas.example.edu"),
        ("canvas.example.edu.", "canvas.example.edu"),
        ("https://bücher.example", "xn--bcher-kva.example"),
        ("xn--bcher-kva.example", "xn--bcher-kva.example"),
        ("localhost", "localhost"),
        ("localhost:3000", "localhost:3000"),
        ("http://localhost:3000/", "localhost:3000"),
        ("https://canvas.example.edu:8443", "canvas.example.edu:8443"),
        ("http://canvas.example.edu", "canvas.example.edu:80"),
        ("127.0.0.1", nil),
        ("http://10.0.0.1:8080", nil),
        ("https://[::1]", nil),
        ("[2001:db8::1]:443", nil),
        ("https://[::ffff:127.0.0.1]", nil)
    ] as [(String, String?)])
    func acceptedHostsRoundTripExactly(raw: String, expected: String?) throws {
        guard let expected else {
            #expect(throws: AccountKey.ValidationError.invalidHost) {
                try AccountKey(rawHost: raw, rawUserID: "134")
            }
            return
        }
        let account = try AccountKey(rawHost: raw, rawUserID: "134")
        #expect(account.host == expected)
        #expect(try JSONDecoder().decode(AccountKey.self, from: JSONEncoder().encode(account)) == account)
        #expect(try AccountKey(rawHost: account.host, rawUserID: account.userID) == account)
    }

    @Test func rejectsEmptyUser() {
        #expect(throws: AccountKey.ValidationError.self) {
            try AccountKey(rawHost: "canvas.example.edu", rawUserID: " \n")
        }
    }

    @Test func decodingUsesAccountValidation() throws {
        let valid = Data(#"{"host":"https://Canvas.Example.edu/","userID":" 134 "}"#.utf8)
        let account = try JSONDecoder().decode(AccountKey.self, from: valid)
        let expected = try ChangeTestSupport.item().account
        #expect(account == expected)

        let invalid = Data(#"{"host":"https://[::1]","userID":"134"}"#.utf8)
        #expect(throws: AccountKey.ValidationError.self) {
            try JSONDecoder().decode(AccountKey.self, from: invalid)
        }
    }

    @Test func scopesItemIdentity() throws {
        let item = try ChangeTestSupport.item()
        let keys = try [
            item, item,
            ChangeTestSupport.item(userID: "999"),
            ChangeTestSupport.item(courseID: "456"),
            ChangeTestSupport.item(itemID: "24"),
            ChangeTestSupport.item(itemType: .announcement)
        ]
        #expect(Set(keys).count == 5)
    }

    @Test(arguments: ChangeField.allCases)
    func roundTripsEveryField(field: ChangeField) throws {
        let item = try ChangeTestSupport.item()
        let values = ChangeTestSupport.values(for: field)
        let observation = ChangeTestSupport.observation(item, field: field, oldValue: values.old, newValue: values.new)
        let record = ChangeRecord(
            itemKey: item,
            field: field,
            oldValue: values.old,
            newValue: values.new,
            firstDetectedAt: ChangeTestSupport.time,
            lastDetectedAt: ChangeTestSupport.time,
            revision: 7
        )
        let envelope = ChangeStoreEnvelope(
            commitRevision: 7,
            accounts: [.init(account: item.account, snapshots: observation.snapshots, records: [record])]
        )
        let data = try JSONEncoder().encode(envelope)
        #expect(try JSONDecoder().decode(ChangeStoreEnvelope.self, from: data) == envelope)
    }

    @Test(arguments: [
        ChangeValue.GradeStatus.ungraded, .unposted, .graded, .excused, .unavailable
    ])
    func roundTripsNullableGrades(status: ChangeValue.GradeStatus) throws {
        let value = ChangeValue.grade(.init(status: status, score: nil, grade: nil, gradedAt: nil))
        let data = try JSONEncoder().encode(value)
        #expect(try JSONDecoder().decode(ChangeValue.self, from: data) == value)
    }

    @Test func preservesUnknownNullAndZero() throws {
        let item = try ChangeTestSupport.item()
        let snapshot = ChangeSnapshot(
            itemKey: item, displayTitle: "Essay", values: [.dueAt: .null, .pointsPossible: .number(0)]
        )
        let data = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(ChangeSnapshot.self, from: data)
        #expect(decoded.values[.lockAt] == nil)
        #expect(decoded.values[.dueAt] == .null)
        #expect(decoded.values[.pointsPossible] == .number(0))
        #expect(ChangeValue.null != .number(0))
    }

    @Test(arguments: [
        ChangeValue.null, .boolean(true), .text("Essay"), .number(0.1 + 0.2), .number(-0.0),
        .date(.distantPast), .date(.distantFuture), .date(ChangeTestSupport.time.addingTimeInterval(0.123_456)),
        .descriptionHash("digest"),
        .grade(.init(status: .graded, score: 92.5, grade: "A-", gradedAt: ChangeTestSupport.time))
    ])
    func roundTripsEveryValueKindInReadableShape(value: ChangeValue) throws {
        let data = try JSONEncoder().encode(value)
        #expect(try JSONDecoder().decode(ChangeValue.self, from: data) == value)
        let object = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(object["type"] is String)
        #expect(try #require(String(bytes: data, encoding: .utf8)).contains("_0") == false)
    }

    @Test func encodesSnapshotValuesAsFieldEntries() throws {
        let item = try ChangeTestSupport.item()
        let snapshot = ChangeSnapshot(itemKey: item, displayTitle: "Essay", values: [.name: .text("Essay"), .dueAt: .null])
        let object = try JSONSerialization.jsonObject(with: JSONEncoder().encode(snapshot)) as? [String: Any]
        let entries = try #require(object?["values"] as? [[String: Any]])
        #expect(entries.compactMap { $0["field"] as? String } == ["dueAt", "name"])

        let duplicate = Data(#"""
        {"itemKey":{"account":{"host":"canvas.example.edu","userID":"134"},"courseID":"123","itemID":"23","itemType":"assignment"},
         "displayTitle":"Essay","values":[{"field":"name","value":{"type":"null"}},{"field":"name","value":{"type":"null"}}]}
        """#.utf8)
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(ChangeSnapshot.self, from: duplicate)
        }
    }

    @Test func distinguishesZeroScoreFromNoScore() throws {
        let empty = ChangeValue.grade(.init(status: .graded, score: nil, grade: nil, gradedAt: ChangeTestSupport.time))
        let zero = ChangeValue.grade(.init(status: .graded, score: 0, grade: "0", gradedAt: ChangeTestSupport.time))
        #expect(empty != zero)
        let data = try JSONEncoder().encode(zero)
        #expect(try JSONDecoder().decode(ChangeValue.self, from: data) == zero)
    }
}
