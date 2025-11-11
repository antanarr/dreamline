import XCTest
@testable import Dreamline

final class ResonanceServiceTests: XCTestCase {
    func testCosineBasics() {
        let a: [Float] = [1,0,0]
        let b: [Float] = [1,0,0]
        let c: [Float] = [0,1,0]
        XCTAssertEqual(ResonanceMath.cosine(a,b), 1, accuracy: 1e-6)
        XCTAssertEqual(ResonanceMath.cosine(a,c), 0, accuracy: 1e-6)
    }

    func testTimeDecayMonotonic() {
        let w0 = ResonanceMath.timeDecayWeight(deltaDays: 0)
        let w21 = ResonanceMath.timeDecayWeight(deltaDays: 21)
        XCTAssertGreaterThan(w0, w21)
        XCTAssertGreaterThan(w21, 0)
    }

    func testPercentile() {
        let v: [Float] = [0.1, 0.3, 0.2, 0.9, 0.7, 0.5]
        let p90 = ResonanceMath.percentile(v, p: 0.9)
        XCTAssertGreaterThanOrEqual(p90, 0.7)
    }
}

