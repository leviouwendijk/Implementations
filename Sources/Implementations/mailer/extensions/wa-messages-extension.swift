import Foundation
import Structures
import plate

extension WAMessageTemplate {
    public func replaced(client: String, dog: String) -> String {
        let syntax = PlaceholderSyntax(prepending: "{", appending: "}", repeating: 1)
        return self.message
            .replaceClientDogTemplatePlaceholders(client: client, dog: dog, placeholderSyntax: syntax)
    }
}
