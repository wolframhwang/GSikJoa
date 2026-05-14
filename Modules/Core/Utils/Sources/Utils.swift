import Foundation

public enum DateFormatting {
    public static func relativeKorean(from date: Date, now: Date = Date()) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "오늘" }
        if calendar.isDateInYesterday(date) { return "어제" }
        let days = calendar.dateComponents([.day], from: date, to: now).day ?? 0
        if days < 7 { return "\(days)일 전" }
        if days < 30 { return "\(days / 7)주 전" }
        return "오래 전"
    }

    public static func koreanWeekdayShort(from date: Date) -> String {
        let weekdaySymbols = ["일", "월", "화", "수", "목", "금", "토"]
        let component = Calendar.current.component(.weekday, from: date)
        return weekdaySymbols[component - 1]
    }
}

public enum HapticFeedback {
    public enum Kind {
        case selection
        case success
        case warning
        case error
        case soft
    }
}
