import Foundation
import Structures
import Interfaces
import Readers
import Version
import plate

/// Version information for a running app built from its repository: the build record beside the
/// binary (`.build/<mode>/<product>.metadata`, written by every successful sbm build), the
/// newest release tag in the local checkout, and the newest release tag on the remote.
@MainActor
public class BuildInformationViewModel: ObservableObject {
    /// The running binary's product name, from its (symlink-resolved) executable path.
    public let product: String?
    /// The repository the binary was built in: the directory holding its `.build`.
    public let project: URL?

    /// What the running binary was built from; nil before the first recorded build.
    @Published public var built: ProductMetadata?
    /// The newest release tag reachable from HEAD in the local checkout.
    @Published public var release: ObjectVersion?
    @Published public var head: String?
    /// The newest release tag on the remote.
    @Published public var remoteRelease: ObjectVersion?
    @Published public var author: String = ""

    @Published public var alignment: AlignmentStyle
    @Published public var display: [[BuildInformationDisplayComponents]]
    @Published public var prefixStyle: VersionPrefixStyle

    @Published public var current: Int = 0

    @Published public var isUpdateAvailable: Bool = false
    @Published public var isBinaryOutdated: Bool = false
    @Published public var isBinaryAheadOfLocal: Bool = false
    @Published public var updateError: String = ""

    public var name: String { product ?? "" }

    public init(
        alignment: AlignmentStyle,
        display: [[BuildInformationDisplayComponents]],
        prefixStyle: VersionPrefixStyle,
        executable: URL? = Bundle.main.executableURL
    ) {
        let binary = executable?.resolvingSymlinksInPath()
        let buildDirectory = binary?.deletingLastPathComponent()
        let dotBuild = buildDirectory?.deletingLastPathComponent()

        self.product = binary?.lastPathComponent
        self.project = dotBuild?.lastPathComponent == ".build" ? dotBuild?.deletingLastPathComponent() : nil
        if let product, let buildDirectory {
            self.built = Self.readRecord(product: product, in: buildDirectory)
        }

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

        guard let project else {
            updateError = "Not running from a repository build; no version information."
            recomputeLocalBinaryState()
            return
        }

        do {
            release = try await GitRepo.latestRelease(at: project)
            head = try await GitRepo.head(project, .local)
            if let remote = try? await GitRepo.defaultRemoteAndBranch(project).remote,
               let url = try? await GitRepo.gitOut(project, ["remote", "get-url", remote]),
               let id = GitRepo.parseOwnerRepo(url.trimmingCharacters(in: .whitespacesAndNewlines)) {
                author = id.owner
            }

            remoteRelease = try await GitRepo.latestRemoteRelease(at: project)
            if let remoteRelease {
                isUpdateAvailable = release.map { remoteRelease > $0 } ?? true
            }

            recomputeLocalBinaryState()
        } catch {
            updateError = error.localizedDescription
        }
    }

    public func localVersionString() -> String {
        (built?.version ?? release ?? .zero()).string(prefixStyle: prefixStyle)
    }

    public func remoteVersionString() -> String {
        guard let remoteRelease else { return "—" }
        return remoteRelease.string(prefixStyle: prefixStyle, remote: true)
    }

    public func primaryBannerText() -> String? {
        if isUpdateAvailable, let remoteRelease {
            return "update available (\(remoteRelease.string(prefixStyle: prefixStyle)))"
        }
        if isBinaryOutdated {
            if let release, (built?.version).map({ $0 < release }) ?? true {
                return "binary outdated — update to \(release.string(prefixStyle: prefixStyle))"
            }
            return "binary outdated — rebuild\(head.map { " (\($0.prefix(7)))" } ?? "")"
        }
        return nil
    }

    public func secondaryHintText() -> String? {
        guard isBinaryAheadOfLocal, let version = built?.version else { return nil }
        return "running dev build (\(version.string(prefixStyle: prefixStyle)))"
    }

    /// Outdated: no build record, a record below the checkout's release, or (once HEAD is known)
    /// a record of another commit. Ahead: a record above the checkout's release.
    private func recomputeLocalBinaryState() {
        guard let built else {
            isBinaryOutdated = project != nil
            isBinaryAheadOfLocal = false
            return
        }

        let builtVersion = built.version
        if let release, let builtVersion, builtVersion > release {
            isBinaryOutdated = false
            isBinaryAheadOfLocal = true
            return
        }

        let belowRelease = release.map { release in builtVersion.map { $0 < release } ?? true } ?? false
        let otherCommit = head.map { $0 != built.commit } ?? false
        isBinaryOutdated = belowRelease || otherCommit
        isBinaryAheadOfLocal = false
    }

    private static func readRecord(product: String, in directory: URL) -> ProductMetadata? {
        let file = directory.appendingPathComponent("\(product).metadata")
        guard let result = try? TextFileReader(file).read(options: .init(missingFilePolicy: .returnEmpty)),
              result.existed
        else { return nil }
        return ProductMetadata(parsing: result.text)
    }
}
