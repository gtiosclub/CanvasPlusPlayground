//
//  HTMLTextNormalizerTests.swift
//  CanvasPlusPlaygroundTests
//
//  Created by Kareem Alaiwat on 10/18/26.
//

import Testing
@testable import CanvasPlusPlayground

struct HTMLTextNormalizerTests {
    typealias Block = HTMLTextNormalizer.Block

    let normalizer = HTMLTextNormalizer()

    private func texts(_ html: String) -> [String] {
        normalizer.blocks(fromHTML: html).map(\.text)
    }

    @Test(arguments: [
        ("AT&amp;T", "AT&T"),
        ("a&nbsp;b", "a b"),
        ("&lt;b&gt;", "<b>"),
        ("Oct 3 &ndash; Oct 5", "Oct 3 – Oct 5"),
        ("&#8211;", "–"),
        ("&#x2013;", "–"),
        ("&#X2013;", "–"),
        ("caf&#233;", "café"),
        ("&unknown;", "&unknown;"),
        ("AT&T", "AT&T"),
        ("&", "&"),
        ("&#xZZ;", "&#xZZ;"),
        ("&#1114112;", "&#1114112;"),
    ])
    func decodesEntities(input: String, expected: String) {
        #expect(HTMLTextNormalizer.decodeEntities(in: input) == expected)
    }

    @Test func keepsBlockBoundariesThatStripHTMLLoses() {
        #expect(texts("<p>Exam 1</p><p>Worth 20%</p>") == ["Exam 1", "Worth 20%"])
    }

    @Test func inlineElementsFlowIntoTheirBlock() {
        #expect(texts("<p>Due <strong>Friday</strong> at <a href='x'>noon</a>.</p>") == ["Due Friday at noon."])
    }

    @Test func collapsesWhitespace() {
        #expect(texts("<p>  Late\n\n   work\tloses  10%  </p>") == ["Late work loses 10%"])
    }

    @Test func tracksHeadingPathAndPopsOnSameOrHigherLevel() {
        let blocks = normalizer.blocks(fromHTML: """
            <h2>Grading</h2><p>Intro</p>
            <h3>Exams</h3><ul><li>Exam 1</li></ul>
            <h2>Policies</h2><p>One drop</p>
            """)

        #expect(blocks == [
            Block(kind: .heading(level: 2), text: "Grading", headingPath: []),
            Block(kind: .paragraph, text: "Intro", headingPath: ["Grading"]),
            Block(kind: .heading(level: 3), text: "Exams", headingPath: ["Grading"]),
            Block(kind: .listItem, text: "Exam 1", headingPath: ["Grading", "Exams"]),
            Block(kind: .heading(level: 2), text: "Policies", headingPath: ["Grading", "Exams"]),
            Block(kind: .paragraph, text: "One drop", headingPath: ["Policies"]),
        ])
    }

    @Test func tableRowsBecomeOneBlockWithSeparatedCells() {
        let blocks = normalizer.blocks(fromHTML: """
            <table><tr><th>Category</th><th>Weight</th></tr><tr><td>Homework</td><td>40%</td></tr></table>
            """)

        #expect(blocks.map(\.kind) == [.tableRow, .tableRow])
        #expect(blocks.map(\.text) == ["Category | Weight", "Homework | 40%"])
    }

    @Test func breakSplitsBlocksExceptInsidePre() {
        #expect(texts("<p>Exam 1: Oct 3<br>Exam 2: Nov 7</p>") == ["Exam 1: Oct 3", "Exam 2: Nov 7"])

        let pre = normalizer.blocks(fromHTML: "<pre>let x = 1<br>  let y = 2</pre>")
        #expect(pre == [Block(kind: .preformatted, text: "let x = 1\n  let y = 2", headingPath: [])])
    }

    @Test(arguments: [
        "<p>Keep</p><script>alert('<p>drop</p>')</script>",
        "<p>Keep</p><STYLE>p { color: red; }</STYLE>",
        "<p>Keep</p><!-- <p>drop</p> -->",
        "<head><title>drop</title></head><p>Keep</p>",
    ])
    func dropsNonContent(html: String) {
        #expect(texts(html) == ["Keep"])
    }

    @Test(arguments: [
        ("<p>if a < b then</p>", ["if a < b then"]),
        ("<p>score <3</p>", ["score <3"]),
        ("<p>trailing <b", ["trailing <b"]),
        ("<p>unclosed paragraph", ["unclosed paragraph"]),
        ("<script>never closed", []),
        ("<!-- never closed", []),
        ("", []),
    ])
    func toleratesMalformedHTML(html: String, expected: [String]) {
        #expect(texts(html) == expected)
    }

    @Test func plainTextSplitsOnBlankLines() {
        let blocks = normalizer.blocks(fromPlainText: "Line one\nstill one\n\n  \nPara two\n\n")
        #expect(blocks.map(\.text) == ["Line one still one", "Para two"])
        #expect(blocks.allSatisfy { $0.kind == .paragraph && $0.headingPath.isEmpty })
    }
}
