import Foundation
import Interfaces

@MainActor
final class PostcodeLookupViewModel: ObservableObject {
    @Published var postcode: String = ""
    @Published var huisnummer: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String = ""

    // Non-editable outputs
    @Published var rawJSON: String = ""
    @Published var street: String = ""
    @Published var woonplaats: String = ""

    private let client: PostcodeClient

    init(client: PostcodeClient = .init()) {
        self.client = client
    }

    var canSearch: Bool {
        client.isValidInput(postcode: postcode, huisnummer: huisnummer) && !isLoading
    }

    func lookup() async {
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
