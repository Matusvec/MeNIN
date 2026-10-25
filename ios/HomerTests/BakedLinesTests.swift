import XCTest
@testable import Homer

final class BakedLinesTests: XCTestCase {
    /// Must match bake_lines.py's key(), or baked lines never play.
    @MainActor func testKeyMatchesTheBaker() {
        XCTAssertEqual(HomerVoice.bakedKey("  Again. "), "4976e23dbe3080d2")
        XCTAssertEqual(HomerVoice.bakedKey("AGAIN.\n"), "4976e23dbe3080d2")
    }
}
