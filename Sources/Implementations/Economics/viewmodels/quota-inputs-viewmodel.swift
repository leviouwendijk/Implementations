import Foundation
import Combine
import Economics
import Structures

@MainActor
public class QuotaInputsViewModel: ObservableObject {
    @Published public var customQuotaInputs: CustomQuotaInputs
    @Published public var inputsChanged: Bool = false
    @Published public var activateRender: Bool = false

    private var cancellables = Set<AnyCancellable>()

    public init() {
        self.customQuotaInputs = CustomQuotaInputs(
            base: "360",
            prognosis: SessionCountEstimationInputs(
                count: "5",
                local: "4"
            ),
            suggestion: SessionCountEstimationInputs(
                count: "3",
                local: "2"
            ),
            singular: SessionCountEstimationInputs(
                count: "1",
                local: "0"
            ),
            travelCost: TravelCostInputs(
                kilometers: "",
                speed: "80.0",
                rates: TravelCostRatesInputs(
                    travel: "0.25", 
                    time: "80"
                ),
                roundTrip: true
            ),
            expiration: ExpirationSettingInputs(
                start: Date(),
                unit: .weeks,
                interval: "4"
            )
        )

        $customQuotaInputs
            .sink { [weak self] _ in self?.inputsChanged = true }
            .store(in: &cancellables)
    
        $customQuotaInputs
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in self?.activateRender = true }
            .store(in: &cancellables)
    }

    public func makeCustomInputs() -> CustomQuotaInputs {
        return customQuotaInputs
    }
}
