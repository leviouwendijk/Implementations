import Foundation
import SwiftUI
import plate
import Structures
import Interfaces
import Contacts
import Economics

// small helper
public struct TemplateFetchResponse: Decodable {
    public let success: Bool
    public let html: String
    
    public init(
        success: Bool,
        html: String
    ) {
        self.success = success
        self.html = html
    }
}

@MainActor
public class MailerViewModel: ObservableObject {
    public var invoiceVm = MailerAPIInvoiceVariablesViewModel()
    public var weeklyScheduleVm = WeeklyScheduleViewModel()
    public var contactsVm = ContactsListViewModel()
    public var apiPathVm = MailerAPISelectionViewModel()

    // Economics
    public var quotaVm = QuotaViewModel()

    @Published public var mailerOutput: String = ""
    @Published public var sharedMailerCommandCopy: String = ""

    @Published public var client = ""
    @Published public var email = ""

    @Published public var dog = ""
    @Published public var location = ""
    @Published public var areaCode: String?
    @Published public var street: String?
    @Published public var number: String?
    @Published public var localLocation = "Alkmaar"
    @Published public var local = false

    @Published public var searchQuery = ""
    @Published public var contacts: [CNContact] = []
    @Published public var selectedContact: CNContact?

    @Published public var showSuccessBanner = false
    @Published public var successBannerMessage = ""

    @Published public var isSendingEmail = false

    @Published public var bannerColor: Color = .gray
    @Published public var httpStatus: Int?

    @Published public var fetchableCategory = ""
    @Published public var fetchableFile = ""

    @Published public var fetchedHtml: String = ""
    @Published public var subject: String = ""

    @Published public var includeQuoteInCustomMessage = false

    @Published public var selectedWAMessage: WAMessageTemplate = .called

    // public var filteredContacts: [CNContact] {
    //     if searchQuery.isEmpty { return contacts }
    //     let normalizedQuery = searchQuery.normalizedForClientDogSearch
    //     return contacts.filter {
    //         $0.givenName.normalizedForClientDogSearch.contains(normalizedQuery) ||
    //         $0.familyName.normalizedForClientDogSearch.contains(normalizedQuery) ||
    //         (($0.emailAddresses.first?.value as String?)?.normalizedForClientDogSearch.contains(normalizedQuery) ?? false)
    //     }
    // }

    public var finalEmail: String {
        email
        .commaSeparatedValuesToParsableArgument
    }

    public var finalSubject: String {
        return subject
            .replaceClientDogTemplatePlaceholders(client: client, dog: dog)
    }

    public var finalHtml: String {
        return fetchedHtml.htmlClean()
            .replaceClientDogTemplatePlaceholders(client: client, dog: dog)
    }

    public var finalHtmlContainsRawVariables: Bool {
        let ignorances = ["IMAGE_WIDTH"]
        let syntax = PlaceholderSyntax(prepending: "{", appending: "}", repeating: 2)
        return finalHtml
        .containsRawTemplatePlaceholderSyntaxes(
            ignoring: ignorances,
            placeholderSyntaxes: [syntax]
        )
    }

    public var clientIdentifier: String {
        let c = client.isEmpty ? "{client}" : client
        let d = dog.isEmpty ? "{dog}": dog
        let e = email.isEmpty ? "{email}" : email

        let allEmpty = (client.isEmpty && dog.isEmpty && email.isEmpty)

        let sequence = "\(c) | \(d) (\(e))"
        let fallback = "no contact specified"

        return allEmpty ? fallback : sequence
    }

    public var selectedWAMessageReplaced: String {
        return selectedWAMessage.replaced(client: client, dog: dog)
    }

    public var waMessageContainsRawPlaceholders: Bool {
        return selectedWAMessageReplaced
            .containsRawTemplatePlaceholderSyntaxes()
    }

    public var emptySubjectWarning: Bool {
        return subject.isEmpty
    }

    public var emptyEmailWarning: Bool {
        return email.isEmpty
    }

    public var anyInvalidConditionsCheck: Bool {
        if (apiPathVm.selectedRoute == .template) {
            return false
        } else if (apiPathVm.selectedRoute == .custom) {
            return (finalHtmlContainsRawVariables || emptySubjectWarning || emptyEmailWarning)
        } else {
            return false
        }
    }

    public init() {}

    public func constructMailerCommand(_ includeBinaryName: Bool = false) throws -> String {
        let stateVars = MailerCLIStateVariables(
            invoiceId: invoiceVm.invoiceVariables.invoice_id,
            fetchableCategory: fetchableCategory,
            fetchableFile: fetchableFile,
            finalEmail: finalEmail,
            finalSubject: finalSubject,
            finalHtml: finalHtml,
            includeQuote: includeQuoteInCustomMessage
        )

        let args = MailerCLIArguments(
            client: client,
            email: finalEmail,
            dog: dog,
            route: apiPathVm.selectedRoute,
            endpoint: apiPathVm.selectedEndpoint,
            availabilityJSON: try? weeklyScheduleVm.availabilityJSON(),
            needsAvailability: apiPathVm.endpointNeedsAvailabilityVariable,
            stateVariables: stateVars
        )
        return try args.string(includeBinaryName)
    }

    public func updateCommandInViewModel(newValue: String) {
        sharedMailerCommandCopy = newValue
    }


    public func cleanThisView() {
        clearContact()
        if includeQuoteInCustomMessage {
            includeQuoteInCustomMessage = false
        }
    }
    
    public func sendMailerEmail() throws {
        mailerOutput = ""

        withAnimation { isSendingEmail = true }

        let arguments = try constructMailerCommand(false)

        let argsWithBinary = try constructMailerCommand(true)
        updateCommandInViewModel(newValue: argsWithBinary)

        DispatchQueue.global(qos: .userInitiated).async {
            let home = Home.string()
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/bin/zsh")
            proc.arguments = ["-c", "source ~/dotfiles/.vars.zsh && \(home)/sbm-bin/mailer \(arguments)"]

            let outPipe = Pipe(), errPipe = Pipe()
            proc.standardOutput = outPipe
            proc.standardError  = errPipe

            // whenever stdout or stderr arrives, append it to mailerOutput
            func install(_ handle: FileHandle) {
                handle.readabilityHandler = { h in
                    let data = h.availableData
                    guard !data.isEmpty, let str = String(data: data, encoding: .utf8) else { return }
                    DispatchQueue.main.async {
                        self.mailerOutput += str
                    }
                }
            }
            install(outPipe.fileHandleForReading)
            install(errPipe.fileHandleForReading)

            do {
                try proc.run()
            } catch {
                DispatchQueue.main.async {
                    self.mailerOutput += "launch failed: \(error.localizedDescription)\n"
                }
            }

            proc.waitUntilExit()

            DispatchQueue.main.async {
                // stop spinner
                withAnimation { self.isSendingEmail = false }

                // banner
                self.successBannerMessage = proc.terminationStatus == 0 ? "mailer completed successfully." : "mailer exited with code \(proc.terminationStatus)."
                self.showSuccessBanner = true

                // color mechanism:
                // 1) try grab the HTTP status line
                if let codeStr = self.mailerOutput.firstCapturedGroup(
                        pattern: #"HTTP Status Code:\s*(\d{3})"#,
                        options: .caseInsensitive
                     ),
                    let code = Int(codeStr)
                {
                    self.httpStatus  = code
                    self.bannerColor = (200..<300).contains(code) ? .green : .red
                }
                // 2) grab the *last* {...} JSON
                if let jsonRange = self.mailerOutput.range(
                     of: #"\{[\s\S]*\}"#,
                     options: [.regularExpression, .backwards]
                   )
                {
                  let blob = String(self.mailerOutput[jsonRange])
                  if let d    = blob.data(using: .utf8),
                     let resp = try? JSONDecoder().decode(APIError.self, from: d)
                  {
                    // override color/message based on server response
                    self.bannerColor        = resp.success ? .green : .red
                    self.successBannerMessage = resp.message

                    if resp.success {
                        self.cleanThisView()
                    }
                  }
                }
                // end of color mechanism

                // also parse / extract html body if it was a template call:
                if (self.apiPathVm.isTemplateFetch) {
                    if let jsonRange = self.mailerOutput.range(
                        of: #"\{[\s\S]*\}"#, 
                        options: [.regularExpression, .backwards]
                        )
                    {
                    let blob = String(self.mailerOutput[jsonRange])
                    if let data = blob.data(using: .utf8),
                        let resp = try? JSONDecoder().decode(TemplateFetchResponse.self, from: data),
                        resp.success
                        {
                            self.fetchedHtml = resp.html
                        }
                    }
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation { self.showSuccessBanner = false }
                }
            }
        }
    }

    public func clearContact() {
        client = ""
        email = ""
        dog = ""
        location = ""
        areaCode = ""
        street = ""
        number = ""
        selectedContact = nil
    }
}
