import Foundation
import plate
import Economics
import Interfaces

// good generic render implementation, but unused for particular tier selection export
// func render(quota: CustomQuota) throws {
//     try prepareEnvironment()

//     let tiers = quota.tiers()

//     var repls: [StringTemplateReplacement] = []

//     for t in tiers {
//         let r = t.replacements(roundTo: 10)
//         repls.append(contentsOf: r)
//     }
    
//     let estPlaceholders = quota.replacements()
//     repls.append(contentsOf: estPlaceholders)

//     // let logoPath = try LoadableResource(name: "logo", fileExtension: "png").path()
//     let logoPath = try ResourcesEnvironment.require(.h_logo)
//     let logoRepl = StringTemplateReplacement(placeholders: ["logo_path"], replacement: logoPath, initializer: .auto)
//     repls.append(logoRepl)

//     let templatePath = try ResourcesEnvironment.require(.quote_template)
//     let outputPath = "\(Home.string())/myworkdir/pdf_output/travel/offerte.pdf"
//     print("out:", outputPath)

//     try pdf(template: templatePath, destination: outputPath, replacements: repls)
// }

// adding for convenience openening
// public struct RenderedTierResult: Sendable {
//     // public let success: Bool
//     public let outputPath: String
// }

public func renderTier(quota: CustomQuota, for tier: QuotaTierType) throws {
// public func renderTier(quota: CustomQuota, for tier: QuotaTierType) throws -> RenderedTierResult {
    try prepareEnvironment()

    let t = try quota.tier(being: tier)

    var repls: [StringTemplateReplacement] = []

    let p = t.standardPriceStringReplacements(roundTo: 10)
    repls.append(contentsOf: p)

    let l = t.locationStringReplacements()
    repls.append(contentsOf: l)
    
    let kmCode = quota.kilometerCodeReplacement(for: tier)
    repls.append(contentsOf: kmCode)

    let expiration = quota.expirationReplacements()
    repls.append(contentsOf: expiration)

    // let logoPath = try LoadableResource(name: "logo", fileExtension: "png").path()
    let logoPath = try ResourcesEnvironment.require(.h_logo)
    let logoRepl_legacy = StringTemplateReplacement(placeholders: ["logo_path"], replacement: logoPath, initializer: .auto)
    let logoRepl_new = StringTemplateReplacement(placeholders: ["logomark_image"], replacement: logoPath, initializer: .auto)

    repls.append(logoRepl_legacy)
    repls.append(logoRepl_new)

    let templatePath = try ResourcesEnvironment.require(.quote_template)

    // let outputPath = "\(Home.string())/myworkdir/pdf_output/travel/offerte.pdf"
    // deprecated in favor of env:
    let outputPath = try ResourcesEnvironment.require(.quote_default_output)
    print("out:", outputPath)

    // try pdf(template: templatePath, destination: outputPath, replacements: repls)
    try pdf(template: templatePath, destination: outputPath, replacements: repls)
    // return RenderedTierResult(
    //     // success: true, // not relevant yet
    //     outputPath: outputPath
    // )
    // no longer needed with above env var for outputPath access
}

