import XCTest
@testable import Dreamline

final class EmbeddingServiceTests: XCTestCase {
    func testChunkingShortText() {
        let s = "short"
        let parts = EmbeddingService.chunk(text: s, threshold: 50)
        XCTAssertEqual(parts.count, 1)
        XCTAssertEqual(parts.first, "short")
    }

    func testNormalizeZeroGuard() {
        let v: [Float] = Array(repeating: 0, count: 4)
        let n = EmbeddingService.normalize(v)
        XCTAssertEqual(n.reduce(0,+), 0)
    }
}

