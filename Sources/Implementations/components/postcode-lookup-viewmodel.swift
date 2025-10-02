import Foundation
import Interfaces

@MainActor
public final class PostcodeLookupViewModel: ObservableObject {
    @Published public var postcode: String = ""
    @Published public var huisnummer: String = ""
    @Published public var isLoading = false
    @Published public var errorMessage: String = ""

    // Non-editable outputs
    @Published public var rawJSON: String = ""
    @Published public var street: String = ""
    @Published public var woonplaats: String = ""

    public let client: PostcodeClient

    public init(client: PostcodeClient = .init()) {
        self.client = client
    }

    public var canSearch: Bool {
        client.isValidInput(postcode: postcode, huisnummer: huisnummer) && !isLoading
    }

    public func lookup() async {
        guard canSearch else {
            errorMessage = "Voer een geldige postcode (6 tekens) en huisnummer in."
            return
        }

        isLoading = true
        errorMessage = ""
        rawJSON = ""
        street = ""
        woonplaats = ""

        do {
            let data = try await client.fetchSuggest(postcode: postcode, huisnummer: huisnummer)
            rawJSON = JSONPretty.string(from: data) ?? "<geen geldige JSON>"

            let model = try client.decodePDOKModel(data: data)
            if let name = model.response.docs?.first?.weergavenaam {
                street = PostcodeClient.extractStreetName(from: name)
                woonplaats = PostcodeClient.extractWoonplaats(from: name)
            }
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

        isLoading = false
    }
}
