import Foundation
import Combine
import Economics

public class IncomeAllocatorViewModel: ObservableObject {
    public var allocatorVm: IncomeAllocatorAccountsViewModel?
    public var compounderVm: CompounderViewModel

    private var cancellables = Set<AnyCancellable>()

    @Published public var errorMessage: String = ""

    public init() {
        self.compounderVm = CompounderViewModel()
        do {
            self.allocatorVm = try IncomeAllocatorAccountsViewModel()
            bind()
        } catch {
            self.errorMessage = error.localizedDescription
        }

    }

    public func bind() {
        if let alloc = allocatorVm {
            alloc.$selectedAccountAmount
                .map { newValue in
                    return String(format: "%.2f", newValue)
                }
            .assign(to: \.monthlyInvestmentText, on: compounderVm)
                .store(in: &cancellables)

                alloc.$incomeText
                .sink { [weak self] _ in
                    self?.compounderVm.calculate()
                }
            .store(in: &cancellables)
        }
    }
}
