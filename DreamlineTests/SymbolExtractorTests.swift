import XCTest
@testable import Dreamline

final class SymbolExtractorTests: XCTestCase {
    func testExtractionStripsStopwordsAndNormalizes() {
        let text = "The moon over water and a rising bridge with you."
        let syms = SymbolExtractor.extract(from: text, max: 10)
        XCTAssertFalse(syms.contains("the"))
        XCTAssertTrue(syms.contains("moon"))
        XCTAssertTrue(syms.contains("water"))
        XCTAssertTrue(syms.contains("rising"))
        XCTAssertTrue(syms.contains("bridge"))
    }

    func testMaxCap() {
        let text = (0..<50).map { "token\($0)" }.joined(separator: " ")
        let syms = SymbolExtractor.extract(from: text, max: 5)
        XCTAssertEqual(syms.count, 5)
    }

    func testPercentileP90Basic() {
        let values: [Float] = [0.1, 0.2, 0.3, 0.4, 0.9, 0.8, 0.7]
        let p90 = ResonanceMath.percentile(values, p: 0.90)
        XCTAssertGreaterThanOrEqual(p90, 0.7)
    }

    func testAnchorDateParse() {
        let tz = TimeZone.current.identifier
        let formatter = DateFormatter()
        formatter.calendar = .init(identifier: .gregorian)
        formatter.timeZone = TimeZone(identifier: tz)
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        let key = "me|day|\(tz)|\(today)"
        let parsed = ResonanceService.anchorDateTestHook(anchorKey: key)
        XCTAssertNotNil(parsed)
    }
}

