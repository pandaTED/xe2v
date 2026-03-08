import XCTest
@testable import xe2v

final class FormParserTests: XCTestCase {
    func testParseOnceFromHiddenField() {
        let html = #"<input type=\"hidden\" name=\"once\" value=\"123456\">"#
        XCTAssertEqual(FormParser.parseOnce(from: html), "123456")
    }

    func testParseFailureReason() {
        let html = #"<div class=\"problem\"><ul><li>你已经发布过于频繁</li></ul></div>"#
        XCTAssertEqual(FormParser.parseFailureReason(html), "你已经发布过于频繁")
    }

    func testReplySuccessRecognition() {
        let html = "<div class=\"topic_buttons\">...</div>"
        XCTAssertTrue(FormParser.containsReplySuccess(html))
    }
}
