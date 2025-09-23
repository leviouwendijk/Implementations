import SwiftUI
import Combine
import Interfaces
import Structures

public enum StageTab: String, CaseIterable, Identifiable, Sendable {
    case all = "All"
    case sales = "Sales"
    case operations = "Operations"
    case billing = "Billing"
    case other = "Other"
    case testing = "Testing"

    public var id: Self { self }

    public var apiStage: MailerAPIEndpointStage? {
        switch self {
        case .all:        return nil
        case .sales:      return .sales
        case .operations: return .operations
        case .billing:    return .billing
        case .other:      return .other
        case .testing:    return .testing
        }
    }
}

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

    @Published public var selectedStage: StageTab = .all {
        didSet {
            // If current route falls outside filter, clear current selection
            if let r = selectedRoute, !filteredRoutes.contains(r) {
                selectedRoute = nil
                selectedEndpoint = nil
            }
        }
    }

    public var validEndpoints: [MailerAPIEndpoint] {
        guard let route = selectedRoute else { return [] }
        return MailerAPIPath.endpoints(for: route)
    }
    
    public var filteredRoutes: [MailerAPIRoute] {
        let routes = MailerAPIRoute.allCases
        guard let stage = selectedStage.apiStage else {
            return routes.sorted { $0.viewableString() < $1.viewableString() }
        }
        return routes
            .filter { MailerAPIPath.stage(for: $0) == stage }
            .sorted { $0.viewableString() < $1.viewableString() }
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

    public var requiresSelectedContact: Bool {
        guard !(selectedRoute == .template) else {
            return false
        }
        return true
    }
}
