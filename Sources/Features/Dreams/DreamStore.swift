import Foundation
import Observation

#if canImport(FirebaseFirestore)
import FirebaseFirestore
import FirebaseCore
#endif

@Observable final class DreamStore {
    var entries: [DreamEntry] = []
    
    private let defaults = UserDefaults.standard
    private let localCacheKey = "dreamline.dreams.cache.v1"
    
    #if canImport(FirebaseFirestore)
    private var db: Firestore? {
        guard FirebaseApp.app() != nil else {
            print("DreamStore: Firestore requested before FirebaseApp.configure()")
            return nil
        }
        return Firestore.firestore()
    }
    
    private var uid: String { "me" } // TODO: Replace with real auth UID
    #endif
    
    init() {
        loadFromCache()
        Task { await syncFromFirestore() }
    }

    func add(rawText: String, transcriptURL: URL? = nil) {
        let extracted = SymbolExtractor.shared.extract(from: rawText, max: 10)
        var entry = DreamEntry(rawText: rawText, transcriptURL: transcriptURL)
        entry.symbols = extracted

        entries.insert(entry, at: 0)
        saveToCache()
        Task { await persistToFirestore(entry) }

        let insertedEntry = entry

        Task.detached { [weak self] in
            guard let self else { return }
            do {
                let items = [EmbeddingItem(id: insertedEntry.id, text: rawText)]
                let resultMap = try await EmbeddingService.shared.embed(items: items)
                if let vec = resultMap[insertedEntry.id] {
                    await MainActor.run {
                        var updated = insertedEntry
                        updated.embedding = vec
                        self.update(updated)
                    }
                    let snapshot = await MainActor.run { self.entries }
                    await ConstellationStore.shared.rebuild(from: snapshot)
                    await MainActor.run {
                        NotificationCenter.default.post(name: .dreamsDidChange, object: self)
                    }
                }
            } catch {
                print("embedding-on-save error: \(error)")
            }
        }
    }
    
    func update(_ entry: DreamEntry) {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            var updated = entry
            updated.updatedAt = Date()
            entries[index] = updated
            saveToCache()
            Task { await persistToFirestore(updated) }
            NotificationCenter.default.post(name: .dreamsDidChange, object: self)
        }
    }
    
    func delete(_ entry: DreamEntry) {
        entries.removeAll { $0.id == entry.id }
        saveToCache()
        Task { await deleteFromFirestore(entry.id) }
    }
    
    // MARK: - Local Cache
    
    private func loadFromCache() {
        guard let data = defaults.data(forKey: localCacheKey) else { return }
        do {
            let decoded = try JSONDecoder().decode([DreamEntry].self, from: data)
            entries = decoded.sorted { $0.createdAt > $1.createdAt }
        } catch {
            print("DreamStore: Failed to load cache: \(error)")
        }
    }
    
    private func saveToCache() {
        do {
            let data = try JSONEncoder().encode(entries)
            defaults.set(data, forKey: localCacheKey)
        } catch {
            print("DreamStore: Failed to save cache: \(error)")
        }
    }
    
    // MARK: - Firestore Sync
    
    #if canImport(FirebaseFirestore)
    private func syncFromFirestore() async {
        guard let db = db else { return }
        do {
            let snapshot = try await db.collection("users").document(uid)
                .collection("dreams")
                .order(by: "createdAt", descending: true)
                .limit(to: 100)
                .getDocuments()
            
            let remoteEntries = snapshot.documents.compactMap { doc -> DreamEntry? in
                try? doc.data(as: DreamEntry.self)
            }
            
            // Merge with local entries (prefer remote if conflict)
            let localEntries = entries
            var merged = [String: DreamEntry]()
            for entry in localEntries {
                merged[entry.id] = entry
            }
            for entry in remoteEntries {
                merged[entry.id] = entry
            }
            
            let sortedEntries = merged.values.sorted { $0.createdAt > $1.createdAt }
            
            await MainActor.run {
                entries = sortedEntries
                saveToCache()
            }
        } catch {
            print("DreamStore: Failed to sync from Firestore: \(error)")
        }
    }
    
    private func persistToFirestore(_ entry: DreamEntry) async {
        guard let db = db else { return }
        do {
            try db.collection("users").document(uid)
                .collection("dreams")
                .document(entry.id)
                .setData(from: entry, merge: true)
        } catch {
            print("DreamStore: Failed to persist to Firestore: \(error)")
        }
    }
    
    private func deleteFromFirestore(_ id: String) async {
        guard let db = db else { return }
        do {
            try await db.collection("users").document(uid)
                .collection("dreams")
                .document(id)
                .delete()
        } catch {
            print("DreamStore: Failed to delete from Firestore: \(error)")
        }
    }
    #else
    private func syncFromFirestore() async {
        // No-op when Firebase is not available
    }
    
    private func persistToFirestore(_ entry: DreamEntry) async {
        // No-op when Firebase is not available
    }
    
    private func deleteFromFirestore(_ id: String) async {
        // No-op when Firebase is not available
    }
    #endif
}

extension Notification.Name {
    static let dreamsDidChange = Notification.Name("DreamsDidChange")
}
