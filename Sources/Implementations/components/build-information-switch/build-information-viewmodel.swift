import Foundation
import Structures
import Interfaces
import plate

public class BuildInformationViewModel: ObservableObject {
    // public let dirURL: URL

    public var build_object: BuildObjectConfiguration?
    public var compiled_object: CompiledLocalBuildObject?

    public var remote_build_object: BuildObjectConfiguration?

    @Published public var alignment: AlignmentStyle
    @Published public var display: [[BuildInformationDisplayComponents]]
    @Published public var prefixStyle: VersionPrefixStyle

    @Published public var current: Int = 0

    @Published public var isUpdateAvailable: Bool = false
    @Published public var isBinaryOutdated: Bool = false
    @Published public var isBinaryAheadOfLocal: Bool = false  
    @Published public var updateError: String = ""

    public init(
        alignment: AlignmentStyle = .center,
        display: [[BuildInformationDisplayComponents]] = [[.version], [.latestVersion], [.name], [.author]],
        prefixStyle: VersionPrefixStyle = .long
    ) {
        self.build_object = try? BuildObjectConfiguration(traversingFor: "build-object.pkl", maxDepth: 5)
        self.compiled_object = try? CompiledLocalBuildObject(traversingFor: "compiled.pkl", maxDepth: 5)

        self.remote_build_object = nil

        self.alignment = alignment
        self.display = display
        self.prefixStyle = prefixStyle

        recomputeLocalBinaryState()
    }

    public func rotate() {
        guard !display.isEmpty else { return }
        current = (current + 1) % display.count
    }

    public func refresh() async {
        updateError = ""
        isUpdateAvailable = false

        do {
            if build_object == nil {
                build_object = try? BuildObjectConfiguration(traversingFor: "build-object.pkl", maxDepth: 5)
            }
            if compiled_object == nil {
                compiled_object = try? CompiledLocalBuildObject(traversingFor: "compiled.pkl", maxDepth: 5)
            }

            guard let local = build_object else {
                updateError = "No local build-object found."
                recomputeLocalBinaryState()
                return
            }

            let remote = try await GitRepo.fetchBuildObject(fromUpdateURL: local.update)
            self.remote_build_object = remote

            isUpdateAvailable = remote.versions.release > local.versions.release

            recomputeLocalBinaryState()
        } catch let e as PklParserError {
            updateError = e.description
        } catch {
            updateError = error.localizedDescription
        }
    }

    public func localVersionString() -> String {
        if let co = compiled_object {
            return co.version.string(prefixStyle: prefixStyle)
        }
        if let bo = build_object {
            return bo.versions.release.string(prefixStyle: prefixStyle)
        }
        return ObjectVersion(major: 0, minor: 0, patch: 0).string(prefixStyle: prefixStyle)
    }

    public func remoteVersionString() -> String {
        guard let r = remote_build_object else { return "—" }
        return r.versions.release.string(prefixStyle: prefixStyle, remote: true)
    }

    public func primaryBannerText() -> String? {
        if isUpdateAvailable, let r = remote_build_object {
            return "update available (\(r.versions.release.string(prefixStyle: prefixStyle)))"
        }
        if isBinaryOutdated, let local = build_object {
            return "binary outdated — update to \(local.versions.release.string(prefixStyle: prefixStyle))"
        }
        return nil
    }

    public func secondaryHintText() -> String? {
        guard isBinaryAheadOfLocal, let co = compiled_object else { return nil }
        return "running dev build (\(co.version.string(prefixStyle: prefixStyle)))"
    }

    private func recomputeLocalBinaryState() {
        guard let local = build_object else {
            isBinaryOutdated = (compiled_object != nil) 
            isBinaryAheadOfLocal = false
            return
        }

        let localV = local.versions.release
        guard let compiled = compiled_object else {
            isBinaryOutdated = true
            isBinaryAheadOfLocal = false
            return
        }

        let binV = compiled.version
        if binV < localV {
            isBinaryOutdated = true
            isBinaryAheadOfLocal = false
        } else if binV > localV {
            isBinaryOutdated = false
            isBinaryAheadOfLocal = true
        } else {
            isBinaryOutdated = false
            isBinaryAheadOfLocal = false
        }
    }
}
