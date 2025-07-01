import Foundation
import plate
import Economics
import Commerce
import Structures
import Interfaces

public func renderCertification(
    _ certification: CertificationData,
    replaceEmpties: Bool = false,
    logo: ResourcesEnvironmentKey = .h_logo,
    template: ResourcesEnvironmentKey = .certification_template
) throws {
    try prepareEnvironment()

    var repls: [StringTemplateReplacement] = certification.replacements()

    // let logoPath = try LoadableResource(name: "logo", fileExtension: "png").path()
    let logoPath = try ResourcesEnvironment.require(logo)
    let logoRepl = StringTemplateReplacement(placeholders: ["logo_path"], replacement: logoPath, initializer: .auto)
    repls.append(logoRepl)

    let signaturePath = try ResourcesEnvironment.require(.levi_signature)
    let signatureRepl = StringTemplateReplacement(placeholders: ["signature_path"], replacement: signaturePath, initializer: .auto)
    repls.append(signatureRepl)

    let templatePath = try ResourcesEnvironment.require(template)
    let outputPath = "\(Home.string())/myworkdir/pdf_output/certification.pdf"
    print("out:", outputPath)

    try pdf(template: templatePath, destination: outputPath, replacements: repls, replaceEmpties: replaceEmpties)
}
