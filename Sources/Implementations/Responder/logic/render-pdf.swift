import Foundation
import plate
import Economics
import Interfaces

public func pdf(
    template: String,
    destination: String,
    replacements: [StringTemplateReplacement],
    replaceEmpties: Bool = false
) throws {
    // let htmlRaw = try LoadableResource(name: template, fileExtension: "html").content()
    let htmlRaw = try ResourceLoader.contents(at: template)
    let converter = StringTemplateConverter(text: htmlRaw, replacements: replacements)
    let html = converter.replace(replaceEmpties: replaceEmpties)
    try html.weasyPDF(destination: destination)
    try copyFileObjectToClipboard(path: destination)
}
