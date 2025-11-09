import XCTest

final class AstroAssetsExistTests: XCTestCase {
    struct AuditRow: Decodable { let name: String; let path: String; let exists: Bool }

    private func locateAudit() -> URL? {
        let fm = FileManager.default
        let cwd = URL(fileURLWithPath: fm.currentDirectoryPath).appendingPathComponent("asset_audit.json")
        if fm.fileExists(atPath: cwd.path) { return cwd }
        if let srcroot = ProcessInfo.processInfo.environment["SRCROOT"] {
            let root = URL(fileURLWithPath: srcroot).appendingPathComponent("asset_audit.json")
            if fm.fileExists(atPath: root.path) { return root }
        }
        let guesses = [
            "../asset_audit.json",
            "../../asset_audit.json"
        ].map { URL(fileURLWithPath: $0).standardizedFileURL }
        for g in guesses where fm.fileExists(atPath: g.path) { return g }
        return nil
    }

    func testBaselineAssetsPresent() throws {
        guard let url = locateAudit() else {
            throw XCTSkip("asset_audit.json not found in working directories.")
        }
        let data = try Data(contentsOf: url)
        let rows = try JSONDecoder().decode([AuditRow].self, from: data)
        let mustHavePrefixes = ["zodiac_", "planet_", "bg_horoscope_card"]
        let failing = rows.filter { row in
            (row.name == "bg_horoscope_card" || mustHavePrefixes.contains { p in row.name.hasPrefix(p) })
            && row.exists == false
        }
        XCTAssertTrue(failing.isEmpty, "Missing baseline assets: \(failing.map{$0.name})")
    }
}
