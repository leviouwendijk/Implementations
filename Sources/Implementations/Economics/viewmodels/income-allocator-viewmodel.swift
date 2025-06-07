import Foundation
import Combine
import Economics

public class IncomeAllocatorViewModel: ObservableObject {
    @Published public var incomeText: String = "2000"
    @Published public var grossTargetText: String = "1000000"
    @Published public var accountTargetText: String = "500000"
    @Published public var selectedAccount: IncomeAllocationAccount = .savings
    @Published public var periodsText: String = ""

    @Published public private(set) var allocationResults: [String] = []
    @Published public private(set) var periodsToGrossText: String = ""
    @Published public private(set) var periodsToAccountText: String = ""
    @Published public private(set) var projectedBalanceText: String = ""

    private let allocations: [IncomeAllocation]
    private var cancellables = Set<AnyCancellable>()

    public init(
        allocations: [IncomeAllocation]? = nil
    ) {
        self.allocations = allocations?.sorted(by: { $0.order < $1.order }) ?? IncomeAllocationProvider.defaults().sorted(by: { $0.order < $1.order })
        bindInputs()
        recalculateAllocations()
        recalculateTargets()
    }

    private func bindInputs() {
        $incomeText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in 
                self?.recalculateAllocations()
                self?.recalculateTargets()
            }
            .store(in: &cancellables)

        Publishers.CombineLatest4(
            $grossTargetText,
            $accountTargetText,
            $selectedAccount.map { $0 },
            $periodsText
        )
        .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
        .sink { [weak self] _, _, _, _ in self?.recalculateTargets() }
        .store(in: &cancellables)
    }

    private func recalculateAllocations() {
        guard let income = Double(incomeText), income > 0 else {
            allocationResults = []
            return
        }
        let allocator = IncomeAllocator(income: income, allocations: allocations)
        let summary = allocator.divide()
        allocationResults = summary.entries.map { entry in
            return "\(entry.allocation.account.rawValue): \(entry.result.display(decimals: 3))"
        }
    }

    private func recalculateTargets() {
        guard let income = Double(incomeText), income > 0 else {
            periodsToGrossText = ""
            periodsToAccountText = ""
            projectedBalanceText = ""
            return
        }
        let allocator = IncomeAllocator(income: income, allocations: allocations)

        if let grossTarget = Double(grossTargetText), grossTarget > 0 {
            let periods = allocator.periodsToReachGross(target: grossTarget)
            periodsToGrossText = "Gross target in ~\(periods) periods"
        } else {
            periodsToGrossText = ""
        }

        if let accountTarget = Double(accountTargetText), accountTarget > 0 {
            if let periods = allocator.periodsToReach(target: accountTarget, in: selectedAccount) {
                periodsToAccountText = "\(selectedAccount.rawValue) target in ~\(periods) periods"
            } else {
                periodsToAccountText = "No allocation for \(selectedAccount.rawValue)"
            }
        } else {
            periodsToAccountText = ""
        }

        if let periods = Int(periodsText), periods > 0 {
            let balance = allocator.projectedBalance(for: selectedAccount, periods: periods)
            projectedBalanceText = String(format: "%@ after %d periods: %.2f", selectedAccount.rawValue, periods, balance)
        } else {
            projectedBalanceText = ""
        }
    }
}
