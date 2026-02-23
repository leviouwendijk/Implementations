import Path

public enum ResponderPath: StandardEnvironmentPath {
    case program_default
    case quote_default

    case quote_default_new

    public var standard_path: StandardPath {
        switch self {
        case .program_default:
            // ~/myworkdir/pdf_output/responder  (directory)
            return .init(.home, "myworkdir", "pdf_output", "responder")

        case .quote_default:
            // previous hardcoded default was:
            // "\(Home.string())/myworkdir/pdf_output/travel/offerte.pdf"
            // model as: .../offerte + .pdf
            return .init(
                basepath: .home,
                "myworkdir",
                "pdf_output",
                "travel",
                "offerte",
                filetype: AnyFileType(FileTypes.document.pdf)
            )

        case .quote_default_new:
            return .init(
                basepath: .home,
                "myworkdir",
                "pdf_output",
                "responder",
                "offerte",
                filetype: AnyFileType(FileTypes.document.pdf)
            )
        }
    }
}
