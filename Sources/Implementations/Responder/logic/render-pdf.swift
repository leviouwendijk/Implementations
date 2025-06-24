import Foundation
import plate
import Economics
import Interfaces

public func pdf(
    template: String,
    destination: String,
    replacements: [StringTemplateReplacement]
) throws {
    // let htmlRaw = try LoadableResource(name: template, fileExtension: "html").content()
    let htmlRaw = try ResourceLoader.contents(at: template)
    let converter = StringTemplateConverter(text: htmlRaw, replacements: replacements)
    let html = converter.replace()
    try html.weasyPDF(destination: destination)
    try copyFileObjectToClipboard(path: destination)
}
