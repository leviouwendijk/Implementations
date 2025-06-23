import Foundation
import Combine
import Economics

public class IncomeAllocatorAccountsViewModel: ObservableObject {
    @Published public var incomeText: String = "2_500"
    @Published public var grossTargetText: String = "1_000_000"
    @Published public var accountTargetText: String = "500_000"
    @Published public var selectedAccount: IncomeAllocationAccount = .savings
    @Published public var periodsText: String = "12"

    @Published public private(set) var allocationResults: [String] = []
    @Published public private(set) var periodsToGrossText: String = ""
    @Published public private(set) var periodsToAccountText: String = ""
    @Published public private(set) var projectedBalanceText: String = ""

    @Published private(set) var selectedAccountAmount: Double = 0

    private let allocations: [IncomeAllocation]
    private var cancellables = Set<AnyCancellable>()

    public var incomeTextCleaned: String { incomeText.cleanedNumberInput() }
    public var grossTargetTextCleaned: String { grossTargetText.cleanedNumberInput() }
    public var accountTargetTextCleaned: String { accountTargetText.cleanedNumberInput() }

    @Published public var textReport: String = ""

    public var errorMessage = ""

    public init(
        allocations: [IncomeAllocation]? = nil
    ) throws {
        let defaults = try IncomeAllocationProvider.defaults()
        self.allocations = allocations?.sorted(by: { $0.order < $1.order }) ?? defaults.sorted(by: { $0.order < $1.order })
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

        $selectedAccount
        .sink { [weak self] _ in self?.recalculateAllocations() }
        .store(in: &cancellables)
    }

    private func recalculateAllocations() {
        guard let income = Double(incomeTextCleaned), income > 0 else {
            allocationResults = []
            return
        }
        let allocator = IncomeAllocator(income: income, allocations: allocations)
        let summary = allocator.divide()

        self.textReport = summary.textReport()

        if let entry = summary.entries.first(where: { $0.allocation.account == selectedAccount }) {
            selectedAccountAmount = entry.result
        } else {
            selectedAccountAmount = 0
        }

        allocationResults = summary.entries.map { entry in
            return "\(entry.allocation.account.rawValue) (\(entry.allocation.percentage?.display() ?? "") %): \(entry.result.display())"
        }
    }

    private func recalculateTargets() {
        guard let income = Double(incomeTextCleaned), income > 0 else {
            periodsToGrossText = ""
            periodsToAccountText = ""
            projectedBalanceText = ""
            return
        }
        let allocator = IncomeAllocator(income: income, allocations: allocations)

        if let grossTarget = Double(grossTargetTextCleaned), grossTarget > 0 {
            let periods = allocator.periodsToReachGross(target: grossTarget)
            periodsToGrossText = "Gross target in ~\(periods) periods"
        } else {
            periodsToGrossText = ""
        }

        if let accountTarget = Double(accountTargetTextCleaned), accountTarget > 0 {
            if let periods = allocator.periodsToReach(target: accountTarget, in: selectedAccount) {
                periodsToAccountText = "\(selectedAccount.rawValue) target in ~\(periods) periods (\(periods / 12) yrs)"
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
