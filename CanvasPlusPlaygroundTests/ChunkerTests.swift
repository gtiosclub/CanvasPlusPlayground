//
//  ChunkerTests.swift
//  CanvasPlusPlaygroundTests
//
//  Created by Kareem Alaiwat on 10/18/26.
//

import Testing
@testable import CanvasPlusPlayground

struct ChunkerPackTests {
    let chunker = Chunker()

    @Test(arguments: [
        ([], 10, []),
        ([5], 0, []),
        ([5], 10, [0..<1]),
        ([3, 3, 3], 100, [0..<3]),
        ([0, 0, 0], 5, [0..<3]),
        ([6, 6, 12, 4, 4, 4], 12, [0..<2, 2..<3, 3..<6]),
        ([12, 4], 12, [0..<1, 1..<2]),
        // Greedy-to-budget would give [0..<4, 4..<5]: a full chunk and a 1-token tail.
        ([5, 5, 5, 5, 1], 20, [0..<3, 3..<5]),
    ] as [([Int], Int, [Range<Int>])])
    func packsKnownCases(tokenCounts: [Int], budget: Int, expected: [Range<Int>]) {
        #expect(chunker.pack(tokenCounts, budget: budget) == expected)
    }

    @Test func satisfiesInvariantsOnRandomInputs() throws {
        var rng = SeededGenerator(seed: 579)

        for _ in 0..<5_000 {
            let budget = Int.random(in: 1...200, using: &rng)
            let counts = (0..<Int.random(in: 1...40, using: &rng)).map { _ in Int.random(in: 1...budget, using: &rng) }
            let ranges = chunker.pack(counts, budget: budget)
            let context: Comment = "counts: \(counts), budget: \(budget), ranges: \(ranges)"

            try #require(ranges.first?.lowerBound == 0, context)
            try #require(ranges.last?.upperBound == counts.count, context)
            for (index, range) in ranges.enumerated() {
                try #require(!range.isEmpty, context)
                try #require(counts[range].reduce(0, +) <= budget, context)
                if index > 0 {
                    try #require(range.lowerBound == ranges[index - 1].upperBound, context)
                }
            }
        }
    }

    @Test func staysCloseToTheMinimumChunkCount() {
        var rng = SeededGenerator(seed: 2026)
        var packed = 0
        var minimum = 0

        for _ in 0..<5_000 {
            let budget = Int.random(in: 20...200, using: &rng)
            let counts = (0..<Int.random(in: 1...40, using: &rng)).map { _ in Int.random(in: 1...(budget / 3), using: &rng) }
            packed += chunker.pack(counts, budget: budget).count
            minimum += greedyChunkCount(counts, budget: budget)
        }

        // Greedy-to-budget is the fewest contiguous chunks possible; balancing may cost a little more.
        #expect(Double(packed) <= Double(minimum) * 1.02, "packed \(packed) vs minimum \(minimum)")
    }

    private func greedyChunkCount(_ counts: [Int], budget: Int) -> Int {
        var chunks = 1
        var running = 0
        for count in counts {
            if running + count > budget, running > 0 {
                chunks += 1
                running = 0
            }
            running += count
        }
        return chunks
    }
}

struct ChunkerTests {
    static let syllabus = """
        <h2>Grading</h2><p>Your grade is computed as follows.&nbsp;Late work loses 10%/day.</p>
        <h3>Exams</h3><ul><li>Exam 1 &ndash; Oct 3</li><li>Exam 2 &#8211; Nov 7</li></ul>
        <table><tr><th>Category</th><th>Weight</th></tr><tr><td>Homework</td><td>40%</td></tr></table>
        <script>alert("x")</script><p>Office hours: Mon<br>Wed &amp; Fri. Note: a < b.</p>
        <h2>Policies</h2><p>Dr. Smith allows one drop. See e.g. the syllabus.</p>
        """

    @Test func chunksASyllabusOnePerSection() {
        let chunks = Chunker().chunks(fromHTML: Self.syllabus, sourceID: "page:1", title: "Syllabus")

        #expect(chunks.map(\.headingPath) == [
            ["Syllabus", "Grading"],
            ["Syllabus", "Grading", "Exams"],
            ["Syllabus", "Policies"],
        ])
        #expect(chunks.map(\.text) == [
            "Your grade is computed as follows. Late work loses 10%/day.",
            "Exam 1 – Oct 3\nExam 2 – Nov 7\nCategory | Weight\nHomework | 40%\nOffice hours: Mon\nWed & Fri. Note: a < b.",
            "Dr. Smith allows one drop. See e.g. the syllabus.",
        ])
        #expect(chunks.map(\.ordinal) == [0, 1, 2])
        #expect(chunks.allSatisfy { $0.sourceID == "page:1" })
    }

    @Test(arguments: ["", "<h1>Only a heading</h1>", "<script>x</script>", "   "])
    func producesNoChunksWithoutBodyText(html: String) {
        #expect(Chunker().chunks(fromHTML: html, sourceID: "page:1").isEmpty)
    }

    @Test(arguments: [nil, "CS Syllabus", "CS 2340 Syllabus"] as [String?])
    func neverExceedsMaxTokensIncludingHeadingPrefix(title: String?) throws {
        // Exactly 10 words = 13 estimated tokens, so per-unit rounding can't absorb an under-counted prefix.
        let sentence = "Students submit the lab report through Canvas before the deadline."
        let paragraph = Array(repeating: sentence, count: 12).joined(separator: " ")
        let html = "<h2>Lab Reports</h2><h3>Submission Rules</h3><p>\(paragraph)</p><p>\(paragraph)</p>"

        // A single maxTokens can miss an overrun that only shows when a chunk fills its budget exactly.
        for maxTokens in 30...120 {
            for chunk in Chunker(maxTokens: maxTokens).chunks(fromHTML: html, sourceID: "page:1", title: title) {
                let tokens = Chunker.estimatedTokens(chunk.embeddingText)
                try #require(tokens <= maxTokens, "maxTokens \(maxTokens): \(tokens) in \(chunk.embeddingText)")
            }
        }
    }

    @Test func splitsASentenceLongerThanTheBudget() {
        let runOn = Array(repeating: "word", count: 200).joined(separator: " ")
        let chunks = Chunker(maxTokens: 50).chunks(fromPlainText: runOn, sourceID: "file:1")

        #expect(chunks.count > 1)
        #expect(chunks.map(\.text).joined(separator: " ") == runOn)
    }

    /// Real `sequenceLength` from `NLContextualEmbedding` (English, revision 1) for Canvas-style text.
    static let measuredTokenCounts: [(text: String, tokens: Int)] = [
        ("Your grade is computed as follows.", 11),
        ("Late work loses 10% per day, up to a maximum of three days.", 21),
        ("Exam 1 will be held on Thursday, October 3rd, in Klaus 1443 from 9:30am to 10:45am.", 44),
        ("Submit HW3.pdf to Gradescope by 11:59pm EST.", 27),
        ("Office hours: Mon/Wed 2–4pm, CCB 345, or by appointment.", 29),
        ("The lowest quiz score will be dropped.", 12),
        ("Participation | 10%", 8),
        ("Homework | 40%", 9),
        ("Final Exam | 25%", 11),
        ("Please read Chapters 4.1–4.3 of Sipser before Tuesday's lecture.", 29),
        ("Academic integrity violations will be reported to the Office of Student Integrity (OSI).", 26),
        ("Regrade requests must be submitted within one week of grades being released via Gradescope.", 27),
        ("Project 2 (Pac-Man search agents) is due Friday, Nov 7 at 11:59 PM; partners are allowed.", 40),
        ("Lecture recordings are available on Canvas under Media Gallery → CS 3600.", 27),
        ("Accommodations: contact the Office of Disability Services at https://disabilityservices.gatech.edu.", 36),
        ("There will be no class on Monday, September 1st, due to Labor Day.", 24),
        ("Attendance is mandatory for recitations; more than three unexcused absences results in a 5% deduction.", 30),
        ("Use the #hw3-questions channel on Ed Discussion for clarifications.", 22),
        ("The midterm covers modules 1–6, including dynamic programming and greedy algorithms.", 28),
        ("Late submissions after 72 hours will receive a zero.", 15),
        ("TA: Jane Doe (jdoe3@gatech.edu), Section A04.", 31),
        ("CS 2340 Syllabus › Grading › Exams", 23),
        ("Lab 5: Implement a thread-safe LRU cache in Java using ReentrantLock.", 30),
    ]

    // Per-sentence misses are expected for dense text; ChunkEmbedder re-splits anything truncated.
    @Test func estimateCoversRealTokenCountsInAggregate() {
        let estimated = Self.measuredTokenCounts.map { Chunker.estimatedTokens($0.text) }.reduce(0, +)
        let real = Self.measuredTokenCounts.map(\.tokens).reduce(0, +)

        #expect(estimated >= real, "estimated \(estimated) vs real \(real)")
    }

    @Test func contentHashIsStableAndTracksHeadingChanges() {
        let chunk = TextChunk(sourceID: "page:1", ordinal: 0, headingPath: ["Grading"], text: "Exams are 40%.")
        let same = TextChunk(sourceID: "page:2", ordinal: 5, headingPath: ["Grading"], text: "Exams are 40%.")
        let renamed = TextChunk(sourceID: "page:1", ordinal: 0, headingPath: ["Assessment"], text: "Exams are 40%.")

        #expect(chunk.contentHash == same.contentHash)
        #expect(chunk.contentHash != renamed.contentHash)
        #expect(chunk.contentHash.count == 64)
    }
}

/// SplitMix64. Deterministic so a failing random case reproduces on every machine.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
