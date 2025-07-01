import Foundation
import plate
import Economics
import Interfaces

public func pdfFromHtmlString(
    html: String,
    destination: String,
    replacements: [StringTemplateReplacement],
    replaceEmpties: Bool = false
) throws {
    let converter = StringTemplateConverter(text: html, replacements: replacements)
    let html = converter.replace(replaceEmpties: replaceEmpties)
    try html.weasyPDF(destination: destination)
    try copyFileObjectToClipboard(path: destination)
}

public enum LoadHTMLError: Error, LocalizedError, Sendable {
    case encodingFailure
}

public func loadHTML(at path: String) throws -> String {
    let url  = URL(fileURLWithPath: path)
    let data = try Data(contentsOf: url)

    if let utf8 = String(data: data, encoding: .utf8) {
        return utf8
    }

    let cfEncoding = CFStringEncodings.windowsHebrew
    let nsEncoding = CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(cfEncoding.rawValue))
    guard let win1255 = String(data: data, encoding: String.Encoding(rawValue: nsEncoding)) else {
        throw LoadHTMLError.encodingFailure
    }
    return win1255
}
