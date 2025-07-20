import Foundation

public class CodeAndPreviewViewModel: ObservableObject {
    @Published public var html: String = """
    <h1>Hello</h1><p>Edit me → see preview live</p>
    """

    public init(html: String = "") {
        if !html.isEmpty { self.html = html }
    }
}
