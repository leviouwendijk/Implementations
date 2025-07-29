import Foundation
import plate
import Economics
import Commerce
import Structures
import Interfaces

public func renderInvoice(
    _ invoice: InvoiceData,
    replaceEmpties: Bool = false,
    logo: ResourcesEnvironmentKey = .h_logo,
    template: ResourcesEnvironmentKey = .invoice_template
) throws {
    try prepareEnvironment()

    // var repls: [StringTemplateReplacement] = invoice.replacements() // this is being worked on in lib: `Commerce`
    var repls: [StringTemplateReplacement] = []

    // let logoPath = try LoadableResource(name: "logo", fileExtension: "png").path()
    let logoPath = try ResourcesEnvironment.require(logo)
    let logoRepl = StringTemplateReplacement(placeholders: ["logo_path"], replacement: logoPath, initializer: .auto)
    repls.append(logoRepl)

    let templatePath = try ResourcesEnvironment.require(template)
    let outputPath = "\(Home.string())/myworkdir/pdf_output/factuur.pdf"
    print("out:", outputPath)

    try pdf(template: templatePath, destination: outputPath, replacements: repls, replaceEmpties: replaceEmpties)
}
