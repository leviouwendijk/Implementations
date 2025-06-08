import Foundation
import Combine
import Economics

public class CompounderViewModel: ObservableObject {
    @Published public var principalText: String = ""
    @Published public var annualRateText: String = ""
    @Published public var monthlyInvestmentText: String = ""
    @Published public var yearsText: String = ""
    @Published public var rounding: Bool = false
    @Published public var calculationTime: CompoundTime = .end

    @Published public private(set) var totalInvestedText: String = ""
    @Published public private(set) var finalValueText: String = ""
    @Published public private(set) var totalReturnText: String = ""

    private var cancellables = Set<AnyCancellable>()

    public init() {
        bindInputs()
    }

    public func bindInputs() {
        Publishers.CombineLatest4(
            $principalText,
            $annualRateText,
            $monthlyInvestmentText,
            $yearsText
        )
        .merge(with: $rounding.map { _ in ("", "", "", "") },
               $calculationTime.map { _ in ("", "", "", "") })
        .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
        .sink { [weak self] _ in
            self?.calculate()
        }
        .store(in: &cancellables)
    }

    public func calculate() {
        let principal = Double(principalText.filter { "0123456789.".contains($0) }) ?? 0
        let annualRate = Double(annualRateText.filter { "0123456789.".contains($0) }) ?? 0
        let monthlyInvestment = Double(monthlyInvestmentText.filter { "0123456789.".contains($0) }) ?? 0
        let years = Int(yearsText.filter { "0123456789".contains($0) }) ?? 0

        guard years > 0 else {
            clearOutputs()
            return
        }

        let config = CompoundValue.Configuration(
            principal: principal,
            annualRate: annualRate,
            monthlyInvestment: monthlyInvestment,
            rounding: rounding
        )

        let result = CompoundValue.value(
            config: config,
            years: years,
            calculationTime: calculationTime
        )

        totalInvestedText = "Total Invested: €\(result.invested.display())"
        finalValueText = "Final Amount after \(years) years: €\(result.value.display())"
        totalReturnText = "Total Return (Profit): €\(result.return.display())"
    }

    public func clearOutputs() {
        totalInvestedText = ""
        finalValueText = ""
        totalReturnText = ""
    }
}
