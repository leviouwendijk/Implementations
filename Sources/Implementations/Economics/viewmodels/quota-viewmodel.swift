import Foundation
import Combine
import Economics
import Structures

@MainActor
public class QuotaViewModel: ObservableObject {
    // @Published public var customQuotaInputs: CustomQuotaInputs

    @Published public var inputsVm: QuotaInputsViewModel = QuotaInputsViewModel()
 
    @Published public private(set) var loadedQuota: CustomQuota? = nil
    @Published public private(set) var isLoading: Bool = false

    @Published public var errorMessage = ""

    @Published public var tiers: [QuotaTierContent]? = nil

    @Published public var selectedTier: QuotaTierType? = nil

    // @Published public var displayPolicy: QuotaDisplayPolicy = .raw
    @Published public var displayPolicy: QuotaPriceDisplayPolicy = .rounded(
        multiple: 10.0,
        direction: .down,
        offset: 1.0,
        // integer: true
    )

    public var selectedTierIsNil: Bool {
        return (self.selectedTier == nil)
    }

    private var cancellables = Set<AnyCancellable>()

    // private var debounceQuotaTask: Task<Void, Never>? = nil
    // private let debounceInterval: TimeInterval = 0.2
    
    public init() {
        // self.customQuotaInputs = CustomQuotaInputs(
        //     base: "360",
        //     prognosis: SessionCountEstimationInputs(
        //         count: "5",
        //         local: "4"
        //     ),
        //     suggestion: SessionCountEstimationInputs(
        //         count: "3",
        //         local: "2"
        //     ),
        //     singular: SessionCountEstimationInputs(
        //         count: "1",
        //         local: "0"
        //     ),
        //     travelCost: TravelCostInputs(
        //         kilometers: "",
        //         speed: "80.0",
        //         rates: TravelCostRatesInputs(
        //             travel: "0.25", 
        //             time: "80"
        //         ),
        //         roundTrip: true
        //     ),
        //     expiration: ExpirationSettingInputs(
        //         start: Date(),
        //         unit: .weeks,
        //         interval: "4"
        //     )
        // )
    
        // $customQuotaInputs
        //     .debounce(for: .milliseconds(200), scheduler: DispatchQueue.global(qos: .userInteractive))
        //     .receive(on: DispatchQueue.main)
        //     .sink { [weak self] inputs in
        //         guard let self = self else { return }

        //         // self.inputsChanged = true
        //         self.isLoading = true
        //         self.loadedQuota = nil

        //         DispatchQueue.global(qos: .userInitiated).async {
        //             do {
        //                 let q = try inputs.customQuotaEstimation()
        //                 DispatchQueue.main.async {
        //                     self.loadedQuota = q
        //                     self.isLoading = false
        //                     self.errorMessage = ""
        //                     self.inputsChanged  = false
        //                 }
        //             } catch {
        //                 DispatchQueue.main.async {
        //                     self.loadedQuota = nil
        //                     self.isLoading = false
        //                     self.errorMessage = error.localizedDescription
        //                 }
        //             }
        //         }
        //     }
        //     .store(in: &cancellables)

        inputsVm.$activateRender
            .filter { $0 }
            .debounce(for: .milliseconds(200), scheduler: DispatchQueue.global(qos: .userInteractive))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] inputs in
                guard let self = self else { return }

                self.isLoading = true
                // self.loadedQuota = nil
                self.inputsVm.activateRender = false

                let inputs = self.inputsVm.makeCustomInputs()

                DispatchQueue.global(qos: .userInitiated).async {
                    do {
                        let q = try inputs.customQuotaEstimation()
                        DispatchQueue.main.async {
                            self.loadedQuota = q
                            self.isLoading = false
                            self.errorMessage = ""
                            self.inputsVm.inputsChanged  = false
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

        $loadedQuota
        .sink { [weak self] quota in
            guard let self = self else { return }
            if let quota = quota {
                do {
                    self.tiers = try quota.tiers()
                } catch {
                    self.errorMessage = error.localizedDescription
                    self.tiers = nil
                }
            } else {
                self.tiers = nil
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
        let inputs = inputsVm.customQuotaInputs

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

    public func copyable(
        length: CopyableStringLengthType = .short,
        clientIdentifier: String? = nil)
    throws -> String {
        guard let quota = loadedQuota else { 
            throw QuotaStringError.quotaIsNil
        }

        var str = ""

        if let client = clientIdentifier {
            str.append(client)
            str.append("\n")
            let div = String(repeating: "-", count: 55)
            str.append(div)
            str.append("\n")
        }

        if let selectedTier = selectedTier {
            let inputs = (length == .short) ? try quota.shortInputs(for: selectedTier) : quota.inputs()
            str.append(inputs)
        }

        return str
    }
}
