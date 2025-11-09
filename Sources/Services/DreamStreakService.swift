import Foundation

@MainActor
final class DreamStreakService {
    static let shared = DreamStreakService()
    
    private init() {}
    
    /// Calculate the current streak of consecutive days with dreams
    func calculateStreak(from entries: [DreamEntry]) -> Int {
        guard !entries.isEmpty else { return 0 }
        
        // Sort entries by date (most recent first)
        let sortedEntries = entries.sorted { $0.createdAt > $1.createdAt }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Check if there's a dream today or yesterday (to keep streak alive)
        let hasRecentDream = sortedEntries.contains { entry in
            let entryDay = calendar.startOfDay(for: entry.createdAt)
            let daysDiff = calendar.dateComponents([.day], from: entryDay, to: today).day ?? 999
            return daysDiff <= 1 // Today or yesterday
        }
        
        guard hasRecentDream else { return 0 }
        
        // Group entries by day
        let entriesByDay = Dictionary(grouping: sortedEntries) { entry in
            calendar.startOfDay(for: entry.createdAt)
        }
        
        // Count consecutive days from today backwards
        var streak = 0
        var currentDate = today
        
        while true {
            if entriesByDay[currentDate] != nil {
                streak += 1
                // Move to previous day
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                    break
                }
                currentDate = previousDay
            } else {
                // Streak broken
                break
            }
        }
        
        return streak
    }
    
    /// Get the total number of dreams logged
    func totalDreams(from entries: [DreamEntry]) -> Int {
        return entries.count
    }
    
    /// Calculate the longest streak ever
    func longestStreak(from entries: [DreamEntry]) -> Int {
        guard !entries.isEmpty else { return 0 }
        
        let sortedEntries = entries.sorted { $0.createdAt < $1.createdAt }
        let calendar = Calendar.current
        
        // Group entries by day
        let entriesByDay = Dictionary(grouping: sortedEntries) { entry in
            calendar.startOfDay(for: entry.createdAt)
        }
        
        // Get all unique days sorted
        let uniqueDays = entriesByDay.keys.sorted()
        
        var maxStreak = 0
        var currentStreak = 1
        
        for i in 1..<uniqueDays.count {
            let previousDay = uniqueDays[i - 1]
            let currentDay = uniqueDays[i]
            
            let daysDiff = calendar.dateComponents([.day], from: previousDay, to: currentDay).day ?? 999
            
            if daysDiff == 1 {
                // Consecutive day
                currentStreak += 1
            } else {
                // Streak broken, check if it's the longest
                maxStreak = max(maxStreak, currentStreak)
                currentStreak = 1
            }
        }
        
        // Don't forget to check the last streak
        maxStreak = max(maxStreak, currentStreak)
        
        return maxStreak
    }
    
    /// Get a motivational message based on current streak
    func motivationalMessage(for streak: Int) -> String {
        switch streak {
        case 0:
            return "Start your journey tonight 🌙"
        case 1:
            return "Great start! Keep going 🌟"
        case 2...6:
            return "Building momentum! 🔥"
        case 7...13:
            return "One week strong! 💪"
        case 14...29:
            return "Incredible dedication! ✨"
        case 30...99:
            return "Dream master! 🏆"
        default:
            return "Legendary streak! 👑"
        }
    }
    
    /// Get an emoji for the current streak
    func streakEmoji(for streak: Int) -> String {
        switch streak {
        case 0:
            return "🌙"
        case 1...2:
            return "⭐"
        case 3...6:
            return "🔥"
        case 7...13:
            return "💎"
        case 14...29:
            return "🏆"
        case 30...99:
            return "👑"
        default:
            return "🌟"
        }
    }
}

