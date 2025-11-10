import NIOFileSystem
import NIOCore
import Subprocess
import Foundation
import Logging

struct ArtifactDistributor {
    let configuration: DistributionConfig
    let fileSystem = FileSystem.shared
    let logger: Logger
    
    struct DistributionConfig {
        let firebaseAppId: String
        let ipaPath: String
        let dSymPath: String
        let artifactStoragePath: String
        let releaseNotes: String
        let groups: [String]
        let buildNumber: String
        let version: String
    }
    
    init(configuration: DistributionConfig, logger: Logger = Logger(label: "com.enterprise.distributor")) {
        self.configuration = configuration
        self.logger = logger
    }
    
    func distribute() async throws {
        logger.info("Starting distribution", metadata: [
            "version": "\(configuration.version)",
            "build": "\(configuration.buildNumber)"
        ])
        
        // 1. Validate files exist
        try await validateFiles()
        
        // 2. Store artifacts before distribution
        let artifactPaths = try await storeArtifacts()
        
        // 3. Upload to Firebase
        try await uploadToFirebase()
        
        // 4. Create manifest
        try await createManifest(artifactPaths: artifactPaths)
        
        logger.info("Distribution complete", metadata: [
            "artifacts": "\(artifactPaths.directory)"
        ])
    }
    
    private func validateFiles() async throws {
        let ipaExists = try await fileSystem.info(
            forFileAt: FilePath(configuration.ipaPath)
        ) != nil
        
        guard ipaExists else {
            logger.error("IPA not found", metadata: ["path": "\(configuration.ipaPath)"])
            throw DistributionError.ipaNotFound(configuration.ipaPath)
        }
        
        let dSymExists = try await fileSystem.info(
            forFileAt: FilePath(configuration.dSymPath)
        ) != nil
        
        guard dSymExists else {
            logger.error("dSYM not found", metadata: ["path": "\(configuration.dSymPath)"])
            throw DistributionError.dSymNotFound(configuration.dSymPath)
        }
        
        logger.info("Validated IPA and dSYM files")
    }
    
    private func storeArtifacts() async throws -> ArtifactPaths {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let buildIdentifier = "\(configuration.version)-\(configuration.buildNumber)-\(timestamp)"
        
        let artifactDir = FilePath(configuration.artifactStoragePath)
            .appending(buildIdentifier)
        
        logger.info("Creating artifact directory", metadata: ["path": "\(artifactDir)"])
        try await fileSystem.createDirectory(
            at: artifactDir,
            withIntermediateDirectories: true
        )
        
        // Copy IPA
        let ipaDestination = artifactDir.appending("\(configuration.version).ipa")
        logger.debug("Copying IPA", metadata: [
            "from": "\(configuration.ipaPath)",
            "to": "\(ipaDestination)"
        ])
        try await fileSystem.copyItem(
            at: FilePath(configuration.ipaPath),
            to: ipaDestination
        )
        
        // Copy dSYM
        let dSymDestination = artifactDir.appending("dSYMs.zip")
        logger.debug("Copying dSYMs", metadata: [
            "from": "\(configuration.dSymPath)",
            "to": "\(dSymDestination)"
        ])
        try await fileSystem.copyItem(
            at: FilePath(configuration.dSymPath),
            to: dSymDestination
        )
        
        logger.info("Artifacts stored successfully")
        
        return ArtifactPaths(
            ipa: ipaDestination.string,
            dSym: dSymDestination.string,
            directory: artifactDir.string
        )
    }
    
    private func uploadToFirebase() async throws {
        logger.info("Uploading to Firebase App Distribution")
        
        var arguments = [
            "appdistribution:distribute",
            configuration.ipaPath,
            "--app", configuration.firebaseAppId,
            "--release-notes", configuration.releaseNotes,
            "--debug-symbols", configuration.dSymPath
        ]
        
        if !configuration.groups.isEmpty {
            arguments += ["--groups", configuration.groups.joined(separator: ",")]
            logger.debug("Distribution groups", metadata: [
                "groups": "\(configuration.groups.joined(separator: ", "))"
            ])
        }
        
        let result = try await Subprocess.run(
            .named("firebase"),
            arguments: arguments,
            output: .stream { line in
                logger.trace("Firebase output", metadata: ["line": "\(line)"])
            }
        )
        
        guard result.terminationStatus.isSuccess else {
            let error = result.standardError
            logger.error("Firebase upload failed", metadata: ["error": "\(error)"])
            throw DistributionError.firebaseFailed(error)
        }
        
        logger.info("Firebase upload complete")
    }
    
    private func createManifest(artifactPaths: ArtifactPaths) async throws {
        let manifest = DistributionManifest(
            version: configuration.version,
            buildNumber: configuration.buildNumber,
            timestamp: Date(),
            firebaseAppId: configuration.firebaseAppId,
            ipaPath: artifactPaths.ipa,
            dSymPath: artifactPaths.dSym,
            releaseNotes: configuration.releaseNotes,
            groups: configuration.groups
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let manifestData = try encoder.encode(manifest)
        let manifestPath = FilePath(artifactPaths.directory).appending("manifest.json")
        
        let buffer = ByteBuffer(data: manifestData)
        
        try await fileSystem.withFileHandle(
            forWritingAt: manifestPath,
            options: .newFile(replaceExisting: true)
        ) { handle in
            try await handle.write(contentsOf: buffer, toAbsoluteOffset: 0)
        }
        
        logger.info("Manifest created", metadata: ["path": "\(manifestPath)"])
    }
}

struct ArtifactPaths {
    let ipa: String
    let dSym: String
    let directory: String
}

struct DistributionManifest: Codable {
    let version: String
    let buildNumber: String
    let timestamp: Date
    let firebaseAppId: String
    let ipaPath: String
    let dSymPath: String
    let releaseNotes: String
    let groups: [String]
}

enum DistributionError: Error {
    case ipaNotFound(String)
    case dSymNotFound(String)
    case firebaseFailed(String)
    case manifestCreationFailed(String)
}

// MARK: - Artifact Query

struct ArtifactQuery {
    let storagePath: String
    let fileSystem = FileSystem.shared
    let logger: Logger
    
    init(storagePath: String, logger: Logger = Logger(label: "com.enterprise.query")) {
        self.storagePath = storagePath
        self.logger = logger
    }
    
    func listBuilds() async throws -> [DistributionManifest] {
        logger.debug("Listing builds", metadata: ["path": "\(storagePath)"])
        var manifests: [DistributionManifest] = []
        
        for try await entry in fileSystem.listContents(of: FilePath(storagePath)) {
            guard entry.type == .directory else { continue }
            
            let manifestPath = entry.path.appending("manifest.json")
            
            guard try await fileSystem.info(forFileAt: manifestPath) != nil else {
                continue
            }
            
            let buffer = try await fileSystem.withFileHandle(
                forReadingAt: manifestPath
            ) { handle in
                let info = try await handle.info()
                return try await handle.readToEnd(
                    fromAbsoluteOffset: 0,
                    maximumSizeAllowed: .bytes(Int(info.size))
                )
            }
            
            let data = Data(buffer: buffer)
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let manifest = try decoder.decode(DistributionManifest.self, from: data)
            manifests.append(manifest)
        }
        
        logger.info("Found builds", metadata: ["count": "\(manifests.count)"])
        return manifests.sorted { $0.timestamp > $1.timestamp }
    }
    
    func findBuild(version: String, buildNumber: String) async throws -> DistributionManifest? {
        logger.debug("Finding build", metadata: [
            "version": "\(version)",
            "build": "\(buildNumber)"
        ])
        
        let build = try await listBuilds().first {
            $0.version == version && $0.buildNumber == buildNumber
        }
        
        if let build = build {
            logger.info("Build found", metadata: ["path": "\(build.ipaPath)"])
        } else {
            logger.warning("Build not found")
        }
        
        return build
    }
    
    func latestBuild() async throws -> DistributionManifest? {
        let latest = try await listBuilds().first
        
        if let latest = latest {
            logger.info("Latest build", metadata: [
                "version": "\(latest.version)",
                "build": "\(latest.buildNumber)"
            ])
        }
        
        return latest
    }
}

// MARK: - Main

@main
struct EnterpriseDistributor {
    static func main() async throws {
        // Setup logging
        LoggingSystem.bootstrap { label in
            var handler = StreamLogHandler.standardOutput(label: label)
            handler.logLevel = .info
            return handler
        }
        
        let logger = Logger(label: "com.enterprise.main")
        
        // Example configuration
        let distributor = ArtifactDistributor(
            configuration: .init(
                firebaseAppId: "1:123456789:ios:abcdef",
                ipaPath: "/build/output/App.ipa",
                dSymPath: "/build/output/dSYMs.zip",
                artifactStoragePath: "/artifacts/enterprise-builds",
                releaseNotes: "Enterprise build with crash reporting",
                groups: ["internal-testers", "qa-team"],
                buildNumber: "42",
                version: "1.2.3"
            )
        )
        
        do {
            try await distributor.distribute()
            
            // Query artifacts
            let query = ArtifactQuery(storagePath: "/artifacts/enterprise-builds")
            let builds = try await query.listBuilds()
            
            logger.info("Available builds", metadata: ["count": "\(builds.count)"])
            for build in builds.prefix(5) {
                logger.info("Build", metadata: [
                    "version": "\(build.version)",
                    "build": "\(build.buildNumber)",
                    "timestamp": "\(build.timestamp)"
                ])
            }
        } catch {
            logger.error("Distribution failed", metadata: ["error": "\(error)"])
            throw error
        }
    }
}
