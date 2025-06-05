import Foundation
import Combine
import Interfaces

@MainActor
public class MailerAPIInvoiceVariablesViewModel: ObservableObject {
    @Published public var invoiceVariables: MailerAPIInvoiceVariables

    public init(invoiceVariables: MailerAPIInvoiceVariables? = nil) {
        self.invoiceVariables = invoiceVariables ?? MailerAPIInvoiceVariables()
    }

    public func getCurrentInvoiceRender() throws {
        let extractor = try NumbersParserExtractor()
        let renderData = try extractor.getCurrentRender()

        guard let invoices = renderData["Invoices"] else {
            print("No Invoices block found")
            return
        }

        invoiceVariables = MailerAPIInvoiceVariables(
            clientName    : invoices["client_name"]     ?? "",
            email          : invoices["email"]           ?? "",
            invoiceId     : invoices["invoice_id"]      ?? "",
            dueDate       : invoices["due_date"]        ?? "",
            productLine   : invoices["product_line"]    ?? "",
            amount         : invoices["revenue_amount"]          ?? "", // note: amount = ["revenue_amount"]
            vatPercentage : invoices["vat_percentage"]  ?? "",
            vatAmount     : invoices["vat_amount"]      ?? "",
            total          : invoices["amount"]           ?? "", // note: total = ["amount"]
            termsTotal    : invoices["terms_total"]     ?? "",
            termsCurrent  : invoices["terms_current"]   ?? ""
        )
    }

    public func renderDataFromInvoiceId() throws {
        let parser = try NumbersParser(
            value: invoiceVariables.invoice_id,
            close: false,
            openAfterwards: false,
            openingMethod: .direct
        )

        try parser.renderInvoice()
    }
}
