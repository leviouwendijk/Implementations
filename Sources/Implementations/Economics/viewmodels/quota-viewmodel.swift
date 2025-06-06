import Foundation
import Combine
import Economics

@MainActor
public class QuotaViewModel: ObservableObject {
    @Published public var customQuotaInputs: CustomQuotaInputs
 
    @Published public private(set) var loadedQuota: CustomQuota? = nil
    @Published public private(set) var isLoading: Bool = false

    @Published public var errorMessage = ""
    // @Published public var errorMessage: String? = nil

    @Published public var selectedTier: QuotaTierType = .combined

    private var cancellables = Set<AnyCancellable>()

    // private var debounceQuotaTask: Task<Void, Never>? = nil
    // private let debounceInterval: TimeInterval = 0.2
    
    public init() {
        self.customQuotaInputs = CustomQuotaInputs(
            base: "350",
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
                    time: "105"
                ),
                roundTrip: true
            )
        )
    
        $customQuotaInputs
            .debounce(for: .milliseconds(800), scheduler: DispatchQueue.global(qos: .userInteractive))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] inputs in
                guard let self = self else { return }

                self.isLoading = true
                self.loadedQuota = nil

                DispatchQueue.global(qos: .userInitiated).async {
                    do {
                        let q = try inputs.customQuotaEstimation()
                        DispatchQueue.main.async {
                            self.loadedQuota = q
                            self.isLoading = false
                            self.errorMessage = ""
                        }
                    } catch {
                        DispatchQueue.main.async {
                            self.loadedQuota = nil
                            self.isLoading = false
                            self.errorMessage = error.localizedDescription
                        }
                    }
                }
            }
            .store(in: &cancellables)
    }

    // public func compute() {
    //     isLoading = true
    //     loadedQuota = nil
        
    //     let inputs = self.customQuotaInputs
    //     DispatchQueue.global(qos: .userInitiated).async {
    //         do {
    //             let q = try inputs.customQuotaEstimation()
    //             DispatchQueue.main.async {
    //                 self.loadedQuota = q
    //                 self.isLoading = false
    //             }
    //         } catch {
    //             DispatchQueue.main.async {
    //                 self.loadedQuota = nil
    //                 self.isLoading = false
    //             }
    //         }
    //     }
    // }

    public var hasEmptyInputs: Bool {
        let inputs = customQuotaInputs

        if inputs.base.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return true
        }

        if inputs.prognosis.count.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
           inputs.prognosis.local.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        {
            return true
        }
        if inputs.suggestion.count.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
           inputs.suggestion.local.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        {
            return true
        }
        if inputs.singular.count.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
           inputs.singular.local.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        {
            return true
        }

        let travel = inputs.travelCost
        if travel.kilometers.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
           travel.speed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        {
            return true
        }
        if travel.rates.travel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
           travel.rates.time.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        {
            return true
        }

        return false
    }
}
