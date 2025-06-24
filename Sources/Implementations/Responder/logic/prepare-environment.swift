import Foundation
import plate
import Economics
import Interfaces

public func prepareEnvironment() throws {
    let env = DefaultEnvironmentVariables.string()
    let vars = try ApplicationEnvironmentLoader.load(from: env)
    ApplicationEnvironmentLoader.set(to: vars)
}
