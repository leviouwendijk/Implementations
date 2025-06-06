import SwiftUI
import Combine
import Interfaces

public class MailerAPISelectionViewModel: ObservableObject {
    @Published public var selectedRoute: MailerAPIRoute? {
        didSet {
            if oldValue != selectedRoute {
                selectedEndpoint = nil
            }
        }
    }

    @Published public var selectedEndpoint: MailerAPIEndpoint?

    public init(
        initialRoute: MailerAPIRoute? = nil,
        initialEndpoint: MailerAPIEndpoint? = nil
    ) {
        self.selectedRoute = initialRoute
        if
            let route = initialRoute,
            let endpoint = initialEndpoint,
            MailerAPIPath.isValid(endpoint: endpoint, for: route)
        {
            self.selectedEndpoint = endpoint
        } else {
            self.selectedEndpoint = nil
        }
    }

    public var validEndpoints: [MailerAPIEndpoint] {
        guard let route = selectedRoute else { return [] }
        return MailerAPIPath.endpoints(for: route)
    }

    public var apiPath: MailerAPIPath? {
        guard
            let route = selectedRoute,
            let endpoint = selectedEndpoint,
            MailerAPIPath.isValid(endpoint: endpoint, for: route)
        else {
            return nil
        }

        return try? MailerAPIPath(route: route, endpoint: endpoint)
    }

    public func viewableURL() -> String {
        var out = ""
        do {
            if let string = try apiPath?.string() {
                out = string
            }
        } catch {
            print(error)
        }
        return out
    }

    public var isTemplateFetch: Bool {
        return (selectedRoute == .template && selectedEndpoint == .fetch) 
    }

    public var endpointNeedsAvailabilityVariable: Bool {
        if let api = apiPath {
            return api.requiresAvailability
        } else {
            return false
        }
    }

    public var routeOrEndpointIsNil: Bool {
        return (selectedRoute == nil || selectedEndpoint == nil)
    }
}
