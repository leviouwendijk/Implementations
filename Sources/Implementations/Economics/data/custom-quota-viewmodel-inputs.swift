import Foundation
import Economics
import Structures
import plate

public enum InputConversionError: Error, Sendable {
    case invalidNumber(String)
}

public struct TravelCostRatesInputs: Sendable {
    public var travel: String
    public var time: String

    public init(
        travel: String,
        time: String
    ) {
        self.travel = travel
        self.time = time
    }

    public func travelCostRates() throws -> TravelCostRates {
        guard let tra = Double(travel) else {
            throw InputConversionError.invalidNumber("‘\(travel)’ is not a number")
        }
        guard let ti = Double(time) else {
            throw InputConversionError.invalidNumber("‘\(time)’ is not a number")
        }
        return TravelCostRates(
            travel: tra,
            time: ti
        )
    }
}

public struct TravelCostInputs: Sendable {
    public var kilometers: String
    public var speed: String
    public var rates: TravelCostRatesInputs
    public var roundTrip: Bool

    public init(
        kilometers: String,
        speed: String = "80.0",
        rates: TravelCostRatesInputs = TravelCostRatesInputs(travel: "0.25", time: "105"),
        roundTrip: Bool = true
    ) {
        self.kilometers = kilometers
        self.speed = speed
        self.rates = rates
        self.roundTrip = roundTrip
    }

    public func travelCost() throws -> TravelCost {
        guard let km = Double(kilometers) else {
            throw InputConversionError.invalidNumber("‘\(kilometers)’ is not a number")
        }
        guard let sp = Double(speed) else {
            throw InputConversionError.invalidNumber("‘\(speed)’ is not a number")
        }

        let ra = try rates.travelCostRates()

        return TravelCost(
            kilometers: km,
            speed: sp,
            rates: ra,
            roundTrip: roundTrip
        )
    }
}

public struct SessionCountEstimationInputs: Sendable {
    public var count: String {
        didSet {
            if let newCount = Int(count),
               let oldLocal  = Int(local),
               newCount < oldLocal
            {
                local = "\(newCount)"
            }
        }
    }
    public var local: String

    public init(
        count: String,
        local: String
    )
    {
        self.count = count
        self.local = local
    }

    public func sessionCountEstimation() throws -> SessionCountEstimationObject {
        guard let co = Int(count) else {
            throw InputConversionError.invalidNumber("‘\(count)’ is not a number")
        }

        guard let loc = Int(local) else {
            throw InputConversionError.invalidNumber("‘\(local)’ is not a number")
        }

        return try SessionCountEstimationObject(
            count: co,
            local: loc
        )
    }
}

public struct ExpirationSettingInputs: Sendable {
    public var start: Date
    public var unit: DateDistanceUnit
    public var interval: String
    
    public init(
        start: Date = Date(),
        unit: DateDistanceUnit = .weeks,
        interval: String = "4"
    ) {
        self.start = start
        self.unit = unit
        self.interval = interval
    }

    public func range() throws -> ExpirationDateRange {
        guard let count = Int(interval) else {
            throw InputConversionError.invalidNumber("‘\(interval)’ is not a number")
        }

        let comps = try unit.components(count: count)
        let end = start + comps
        return ExpirationDateRange(start: start, end: end)
    }

    public func expirationSetting() throws -> ExpirationSetting {
        let range = try range()
        return ExpirationSetting(using: range)
    }
}

public struct CustomQuotaInputs: Sendable {
    public var base: String
    public var prognosis: SessionCountEstimationInputs
    public var suggestion: SessionCountEstimationInputs
    public var singular: SessionCountEstimationInputs
    public var travelCost: TravelCostInputs
    public var expiration: ExpirationSettingInputs

    public init(
        base: String,
        prognosis: SessionCountEstimationInputs,
        suggestion: SessionCountEstimationInputs,
        singular: SessionCountEstimationInputs,
        travelCost: TravelCostInputs,
        expiration: ExpirationSettingInputs
    )
    {
        self.base = base
        self.prognosis = prognosis
        self.suggestion = suggestion
        self.singular = singular
        self.travelCost = travelCost
        self.expiration = expiration
    }

    public func customQuotaEstimation() throws -> CustomQuota {
        guard let ba = Double(base) else {
            throw InputConversionError.invalidNumber("‘\(base)’ is not a number")
        }

        let prog = try prognosis.sessionCountEstimation()
        let sugg = try suggestion.sessionCountEstimation()
        let sing = try singular.sessionCountEstimation()
        let trav = try travelCost.travelCost()
        let exp = try expiration.expirationSetting()

        return try CustomQuota(
            base: ba,
            travelCost: trav,
            prognosis: prog,
            suggestion: sugg,
            singular: sing,
            expiration: exp
        )
    }
}
