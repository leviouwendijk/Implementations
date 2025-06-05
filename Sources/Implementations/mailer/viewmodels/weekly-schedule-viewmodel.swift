import SwiftUI
import Combine
import Interfaces

public class WeeklyScheduleViewModel: ObservableObject {
    @Published public var schedules: [MailerAPIWeekday: MailerAPIDaySchedule]

    public init(
        schedules: [MailerAPIWeekday: MailerAPIDaySchedule]? = nil
    ) {
        let base = Dictionary(
            uniqueKeysWithValues: MailerAPIWeekday.allCases.map {
                ($0, MailerAPIDaySchedule(defaultsFor: $0))
            }
        )
        self.schedules = schedules ?? base
    }

    /// Convenience to get Encodable availability content
    public var availabilityContent: MailerAPIAvailabilityContent {
        MailerAPIAvailabilityContent(from: schedules)
    }

    // backwards compatibility for running through the mailer binary (until phased out)
    public func availabilityJSON() throws -> String {
        let dict = availabilityContent.time_range()
        let data = try JSONSerialization.data(withJSONObject: dict)
        let jsonAsString = String(data: data, encoding: .utf8) ?? ""
        return jsonAsString
        // return json.isEmpty ? nil : json
    }
}
