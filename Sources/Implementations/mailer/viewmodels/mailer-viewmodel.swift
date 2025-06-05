import Foundation

public class MailerViewModel: ObservableObject {
    @Published public var mailerOutput: String = ""
    @Published public var sharedMailerCommandCopy: String = ""
}

