import Foundation

@MainActor
struct DreamInterpretationResult {
    let extraction: OracleExtraction
    let interpretation: DreamInterpretation
}

struct InterpretCoordinator {
    let oracle: OracleClient
    
    func runInterpret(dreamText: String) async -> DreamInterpretationResult? {
        do {
            let extraction = try await oracle.extract(from: dreamText)
            let transit = await AstroService.shared.transits(for: Date())
            let hist = await HistoryService.shared.summarize(days: 30)
            let interpretation = try await oracle.interpret(dreamText: dreamText, extraction: extraction, transit: transit, history: hist)
            return DreamInterpretationResult(extraction: extraction, interpretation: interpretation)
        } catch {
            return nil
        }
    }
}

