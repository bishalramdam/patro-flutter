// PatroWidget.swift
// Native iOS Home Screen and Lock Screen Widget for Patro in SwiftUI.

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> PatroEntry {
        PatroEntry(
            date: Date(),
            bsDay: "१७",
            bsMonth: "कात्तिक",
            bsYear: "२०८३",
            weekday: "मङ्गलबार",
            weekdayShort: "मङ्गल",
            gregDay: "3",
            gregMonth: "Nov",
            tithi: "शुक्ल नवमी",
            isHoliday: false
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (PatroEntry) -> ()) {
        completion(fetchCurrentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = fetchCurrentEntry()
        // Next refresh at midnight
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date())) ?? Date().addingTimeInterval(86400)
        let timeline = Timeline(entries: [entry], policy: .after(tomorrow))
        completion(timeline)
    }

    private func fetchCurrentEntry() -> PatroEntry {
        let userDefaults = UserDefaults(suiteName: "group.com.bishal.patro_flutter")
        let day = userDefaults?.string(forKey: "bs_day") ?? "१७"
        let month = userDefaults?.string(forKey: "bs_month") ?? "कात्तिक"
        let year = userDefaults?.string(forKey: "bs_year") ?? "२०८३"
        let weekday = userDefaults?.string(forKey: "weekday") ?? "मङ्गलबार"
        let weekdayShort = userDefaults?.string(forKey: "weekday_short") ?? "मङ्गल"
        let gregDay = userDefaults?.string(forKey: "gregorian_day") ?? "3"
        let gregMonth = userDefaults?.string(forKey: "gregorian_month") ?? "Nov"
        let tithi = userDefaults?.string(forKey: "tithi_label") ?? "शुक्ल नवमी"
        let isHoliday = userDefaults?.bool(forKey: "is_holiday") ?? false

        return PatroEntry(
            date: Date(),
            bsDay: day,
            bsMonth: month,
            bsYear: year,
            weekday: weekday,
            weekdayShort: weekdayShort,
            gregDay: gregDay,
            gregMonth: gregMonth,
            tithi: tithi,
            isHoliday: isHoliday
        )
    }
}

struct PatroEntry: TimelineEntry {
    let date: Date
    let bsDay: String
    let bsMonth: String
    let bsYear: String
    let weekday: String
    let weekdayShort: String
    let gregDay: String
    let gregMonth: String
    let tithi: String
    let isHoliday: Bool
}

struct PatroWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidgetView
        case .systemMedium:
            mediumWidgetView
        default:
            smallWidgetView
        }
    }

    // Small (2x2) Widget View
    var smallWidgetView: some View {
        VStack(spacing: 2) {
            Text(entry.weekday)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.blue)

            Text(entry.bsDay)
                .font(.system(size: 44, weight: .heavy, design: .rounded))
                .foregroundColor(.primary)
                .minimumScaleFactor(0.7)

            Text("\(entry.bsMonth) \(entry.bsYear)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.primary.opacity(0.85))

            Text("\(entry.gregDay) \(entry.gregMonth)")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
        }
        .containerBackground(for: .widget) {
            Color(UIColor.systemBackground)
        }
    }

    // Medium (4x2) Widget View
    var mediumWidgetView: some View {
        HStack(spacing: 20) {
            // Left: Big Nepali date
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.weekday)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.blue)

                Text(entry.bsDay)
                    .font(.system(size: 46, weight: .heavy, design: .rounded))
                    .foregroundColor(.primary)

                Text("\(entry.bsMonth) \(entry.bsYear)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.primary.opacity(0.85))
            }

            Divider()

            // Right: Gregorian & Holiday/Observance
            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("ईस्वी संवत् (AD)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                    Text("\(entry.gregDay) \(entry.gregMonth)")
                        .font(.system(size: 14, weight: .bold))
                }

                if entry.isHoliday {
                    Text("सार्वजनिक बिदा")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.red)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .containerBackground(for: .widget) {
            Color(UIColor.systemBackground)
        }
    }
}

@main
struct PatroWidget: Widget {
    let kind: String = "PatroWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            PatroWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("गते (Gate)")
        .description("आजको नेपाली मिति र बार देखाउँछ।")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
