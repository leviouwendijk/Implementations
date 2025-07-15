import Foundation
import Structures
import Combine

public struct BlockedWeekdayItem: Identifiable {
    public let id = UUID()
    public let weekday: MailerAPIWeekday
    public var isOn:     Bool
    public var limitText: String

    public var apiModel: MailerAPIBlockedWeekday? {
        guard isOn else { return nil }
        let limit = Int(limitText)
        return MailerAPIBlockedWeekday(weekday: weekday, limit: limit)
    }
}

public class BlockedWeekdaysViewModel: ObservableObject {
    @Published public var items: [BlockedWeekdayItem]

    public init(
        initial: [MailerAPIBlockedWeekday] = []
    ) {
        let onSet = Set(initial.map(\.weekday))
        let limitMap: [MailerAPIWeekday: Int] = Dictionary(
            uniqueKeysWithValues:
                initial.compactMap { rule in
                    guard let lim = rule.limit else { return nil }
                    return (rule.weekday, lim)
                }
        )

        self.items = MailerAPIWeekday.allCases.map { day in
            let isOn = onSet.contains(day)

            let limText: String
            if let lim = limitMap[day] {
                limText = String(lim)
            } else {
                limText = ""
            }

            return BlockedWeekdayItem(
                weekday: day,
                isOn: isOn,
                limitText: limText
            )
        }
    }

    public var apiModels: [MailerAPIBlockedWeekday] {
        items.compactMap { item in
            guard item.isOn else { return nil }
            let lim = Int(item.limitText)
            return MailerAPIBlockedWeekday(weekday: item.weekday, limit: lim)
        }
    }
}
