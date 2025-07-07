import Foundation
import plate
import Interfaces
import Structures

public enum ResponderViewModelError: LocalizedError {
    case missingRouteOrEndpoint
    case missingEndpointDataVariable
    
    public var errorDescription: String? {
        switch self {
        case .missingRouteOrEndpoint:
            return "No route or endpoint selected."
        case .missingEndpointDataVariable:
            return "A data variable required for this endpoint is missing"
        }
    }
}

extension ResponderViewModel {
    public func makePayload() throws -> any MailerAPIPayload {
        let toList     = finalEmail.split(separator: ",").map(String.init)
        let ccList:    [String]        = []
        let bccList:   [String]?       = nil
        let replyList: [String]?       = nil
        let headers:   [String: String] = [:]

        guard let endpoint = apiPathVm.selectedEndpoint, let route = apiPathVm.selectedRoute else {
            throw ResponderViewModelError.missingRouteOrEndpoint
        }

        switch route {
        case .appointment:
            let vars = MailerAPIAppointmentVariables(
                name:         client,
                dog:          dog,
                appointments: appointmentsQueue
            )
            return try AppointmentPayload(
                endpoint:      endpoint,
                variables:     vars,
                emailsTo:      toList,
                emailsCC:      ccList,
                emailsBCC:     bccList,
                emailsReplyTo: replyList,
                attachments:   nil,
                addHeaders:    headers
            )

        case .invoice:
            let iv = invoiceVm.invoiceVariables
            let vars = MailerAPIInvoiceVariables(
                clientName:    iv.client_name,
                email:         iv.email,
                invoiceId:     iv.invoice_id,
                dueDate:       iv.due_date,
                productLine:   iv.product_line,
                amount:        iv.amount,
                vatPercentage: iv.vat_percentage,
                vatAmount:     iv.vat_amount,
                total:         iv.total,
                termsTotal:    iv.terms_total,
                termsCurrent:  iv.terms_current
            )
            return try InvoicePayload(
                endpoint:      endpoint,
                variables:     vars,
                emailsTo:      toList,
                emailsCC:      ccList,
                emailsBCC:     bccList,
                emailsReplyTo: replyList,
                attachments:   nil,
                addHeaders:    headers
            )

        case .quote:
            let vars = MailerAPIQuoteVariables(
                name: client,
                dog:  dog
            )
            return try QuotePayload(
                endpoint:      endpoint,
                variables:     vars,
                emailsTo:      toList,
                emailsCC:      ccList,
                emailsBCC:     bccList,
                emailsReplyTo: replyList,
                attachments:   nil,
                addHeaders:    headers
            )

        case .lead:
            let activeSchedules = weeklyScheduleVm.schedules.filter { $0.value.enabled }
            guard !activeSchedules.isEmpty else {
                throw ResponderViewModelError.missingEndpointDataVariable
            }
            let vars = MailerAPILeadVariables(
                name:        client,
                dog:         dog,
                availability: activeSchedules
            )
            return try LeadPayload(
                endpoint:      endpoint,
                variables:     vars,
                emailsTo:      toList,
                emailsCC:      ccList,
                emailsBCC:     bccList,
                emailsReplyTo: replyList,
                attachments:   nil,
                addHeaders:    headers
            )

        case .service:
            let vars = MailerAPIServiceVariables(
                name: client,
                dog:  dog
            )
            return try ServicePayload(
                endpoint:      endpoint,
                variables:     vars,
                emailsTo:      toList,
                emailsCC:      ccList,
                emailsBCC:     bccList,
                emailsReplyTo: replyList,
                attachments:   nil,
                addHeaders:    headers
            )

        case .resolution:
            let vars = MailerAPIResolutionVariables(
                name: client,
                dog:  dog
            )
            return try ResolutionPayload(
                endpoint:      endpoint,
                variables:     vars,
                emailsTo:      toList,
                emailsCC:      ccList,
                emailsBCC:     bccList,
                emailsReplyTo: replyList,
                attachments:   nil,
                addHeaders:    headers
            )

        case .affiliate:
            let vars = MailerAPIAffiliateVariables(
                name: client,
                dog:  dog
            )
            return try AffiliatePayload(
                endpoint:      endpoint,
                variables:     vars,
                emailsTo:      toList,
                emailsCC:      ccList,
                emailsBCC:     bccList,
                emailsReplyTo: replyList,
                attachments:   nil,
                addHeaders:    headers
            )

        case .custom:
            let vars = MailerAPICustomVariables(
                body:         finalHtml,
                availability: weeklyScheduleVm.schedules
            )
            return try CustomPayload(
                endpoint:      endpoint,
                variables:     vars,
                emailsTo:      toList,
                emailsCC:      ccList,
                emailsBCC:     bccList,
                emailsReplyTo: replyList,
                attachments:   nil,
                addHeaders:    headers
            )

        case .template:
            let vars = MailerAPITemplateVariables(
                category: fetchableCategory,
                file:     fetchableFile
            )
            return try TemplatePayload(
                endpoint:      endpoint,
                variables:     vars
            )
        }
    }
}
