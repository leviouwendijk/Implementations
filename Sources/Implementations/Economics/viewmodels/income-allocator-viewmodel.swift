import Foundation
import Combine
import Economics

public class IncomeAllocatorViewModel: ObservableObject {
    public var allocatorVm: IncomeAllocatorAccountsViewModel
    public var compounderVm: CompounderViewModel

    private var cancellables = Set<AnyCancellable>()

    public init() throws {
        self.compounderVm = CompounderViewModel()
        self.allocatorVm = try IncomeAllocatorAccountsViewModel()

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
