import Foundation
import Combine
import Economics

public class IncomeAllocatorViewModel: ObservableObject {
    public var allocatorVm: IncomeAllocatorAccountsViewModel = IncomeAllocatorAccountsViewModel()
    public var compounderVm: CompounderViewModel = CompounderViewModel()

    private var cancellables = Set<AnyCancellable>()

    public init() {
        allocatorVm.$selectedAccountAmount
            .map { newValue in
                return String(format: "%.2f", newValue)
            }
        .assign(to: \.monthlyInvestmentText, on: compounderVm)
            .store(in: &cancellables)

            allocatorVm.$incomeText
            .sink { [weak self] _ in
                self?.compounderVm.calculate()
            }
        .store(in: &cancellables)
    }
}
