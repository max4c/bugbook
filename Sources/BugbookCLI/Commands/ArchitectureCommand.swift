import ArgumentParser
import Foundation
import Yams

struct Architecture: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "architecture",
        abstract: "Operate on a Daso Architecture repo",
        subcommands: [Open.self, ListADR.self, CreateADR.self, Validate.self, Pack.self]
    )

    struct Open: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "open",
            abstract: "Detect and summarize an Architecture repo workspace"
        )

        @Argument(help: "Local Architecture repo path")
        var path: String

        func run() throws {
            let repo = try ArchitectureRepo(path: path)
            try outputJSON(repo.summaryJSON())
        }
    }

    struct ListADR: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "list-adr",
            abstract: "List Architecture ADRs"
        )

        @OptionGroup var options: Bugbook.Options

        @Option(name: .long, help: "Filter by ADR status")
        var status: ArchitectureRecordStatus?

        func run() throws {
            let repo = try ArchitectureRepo(path: options.resolvedWorkspace)
            let adrs = try repo.adrs().filter { adr in
                guard let status else { return true }
                return adr.status == status.rawValue
            }
            try outputJSON([
                "repo_path": repo.path,
                "count": adrs.count,
                "adrs": adrs.map { $0.toJSON() },
            ])
        }
    }

    struct CreateADR: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "create-adr",
            abstract: "Create a draft Architecture ADR"
        )

        @OptionGroup var options: Bugbook.Options

        @Option(name: .long, help: "ADR status")
        var status: ArchitectureRecordStatus = .draft

        @Option(name: .long, help: "ADR title")
        var title: String

        @Option(name: .long, help: "ADR owner")
        var owner: String = "max"

        @Option(name: .long, parsing: .upToNextOption, help: "Tags")
        var tags: [String] = []

        @Option(name: .long, help: "Decision summary")
        var summary: String?

        @Option(name: .long, help: "Rationale or notes")
        var body: String?

        @Option(name: .long, help: "Body file path, or - for stdin")
        var bodyFile: String?

        @Option(name: .long, help: "Explicit relative path for the new ADR")
        var path: String?

        func run() throws {
            guard body == nil || bodyFile == nil else {
                throw CLIError.invalidInput("--body and --body-file are mutually exclusive")
            }

            let repo = try ArchitectureRepo(path: options.resolvedWorkspace)
            let request = ArchitectureADRCreateRequest(
                status: status,
                title: title,
                owner: owner,
                tags: tags,
                summary: summary,
                body: try bodyFile.map(readTextInput) ?? body,
                path: path
            )
            let adr = try repo.createADR(request)
            try outputJSON(adr.toJSON())
        }
    }

    struct Validate: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "validate",
            abstract: "Run scripts/validate_architecture.py"
        )

        @OptionGroup var options: Bugbook.Options

        func run() throws {
            let repo = try ArchitectureRepo(path: options.resolvedWorkspace)
            let result = try repo.runScript(ArchitectureRepo.validateScript)
            try outputJSON(result.toJSON())
        }
    }

    struct Pack: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "pack",
            abstract: "Print generated/architecture-context-pack.md"
        )

        @OptionGroup var options: Bugbook.Options

        func run() throws {
            let repo = try ArchitectureRepo(path: options.resolvedWorkspace)
            let content = try repo.architecturePack()
            FileHandle.standardOutput.write(Data(content.utf8))
        }
    }
}

enum ArchitectureRecordStatus: String, ExpressibleByArgument {
    case accepted
    case draft
    case seed
    case superseded
}

private struct ArchitectureRepo {
    let path: String

    static let validateScript = "scripts/validate_architecture.py"

    private var adrPath: String {
        (path as NSString).appendingPathComponent("adr")
    }

    init(path rawPath: String) throws {
        path = normalizePath((rawPath as NSString).expandingTildeInPath)
        try Self.validateArchitectureRepo(at: path)
    }

    func summaryJSON() throws -> [String: Any] {
        [
            "path": path,
            "adr_count": try adrs().count,
            "detected": true,
            "required_files": Self.requiredMarkers,
        ]
    }

    func adrs() throws -> [ArchitectureADR] {
        guard let enumerator = FileManager.default.enumerator(atPath: adrPath) else {
            return []
        }

        var adrs: [ArchitectureADR] = []
        while let relative = enumerator.nextObject() as? String {
            guard relative.hasSuffix(".md") else { continue }
            let fullPath = (adrPath as NSString).appendingPathComponent(relative)
            guard let adr = try ArchitectureADR(path: fullPath, repoPath: path) else { continue }
            adrs.append(adr)
        }
        return adrs.sorted {
            $0.relativePath.localizedCaseInsensitiveCompare($1.relativePath) == .orderedAscending
        }
    }

    func createADR(_ request: ArchitectureADRCreateRequest) throws -> ArchitectureADR {
        let relativePath = request.path ?? "adr/\(request.defaultFilename)"
        let fullPath = normalizePath((path as NSString).appendingPathComponent(relativePath))
        guard isPathInsideWorkspace(fullPath, workspace: path) else {
            throw CLIError.invalidInput("ADR path must stay inside Architecture repo: \(relativePath)")
        }
        guard !FileManager.default.fileExists(atPath: fullPath) else {
            throw CLIError.invalidInput("ADR already exists: \(relativePath)")
        }

        try FileManager.default.createDirectory(
            atPath: (fullPath as NSString).deletingLastPathComponent,
            withIntermediateDirectories: true
        )
        try request.renderMarkdown().write(toFile: fullPath, atomically: true, encoding: .utf8)

        guard let adr = try ArchitectureADR(path: fullPath, repoPath: path) else {
            throw CLIError.operationFailed("Created ADR could not be parsed: \(relativePath)")
        }
        return adr
    }

    func runScript(_ relativeScriptPath: String) throws -> ArchitectureScriptResult {
        let scriptPath = (path as NSString).appendingPathComponent(relativeScriptPath)
        guard FileManager.default.fileExists(atPath: scriptPath) else {
            throw CLIError.fileNotFound(relativeScriptPath)
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["python3", relativeScriptPath]
        process.currentDirectoryURL = URL(fileURLWithPath: path, isDirectory: true)

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        try process.run()
        process.waitUntilExit()

        return ArchitectureScriptResult(
            command: "python3 \(relativeScriptPath)",
            exitCode: Int(process.terminationStatus),
            stdout: String(decoding: stdout.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self),
            stderr: String(decoding: stderr.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        )
    }

    func architecturePack() throws -> String {
        let packPath = (path as NSString).appendingPathComponent("generated/architecture-context-pack.md")
        guard FileManager.default.fileExists(atPath: packPath) else {
            throw CLIError.fileNotFound("generated/architecture-context-pack.md")
        }
        return try String(contentsOfFile: packPath, encoding: .utf8)
    }

    private static let requiredMarkers = [
        "TECHNICAL_MANIFEST.md",
        "AGENTS.md",
        "adr",
        "system/repo-map.md",
        "system/system-map.md",
        "scripts/validate_architecture.py",
        "generated/architecture-context-pack.md",
    ]

    private static func validateArchitectureRepo(at path: String) throws {
        for marker in requiredMarkers {
            let markerPath = (path as NSString).appendingPathComponent(marker)
            guard FileManager.default.fileExists(atPath: markerPath) else {
                throw CLIError.invalidInput("Not an Architecture repo; missing \(marker)")
            }
        }
    }
}

private struct ArchitectureADRCreateRequest {
    let status: ArchitectureRecordStatus
    let title: String
    let owner: String
    let tags: [String]
    let summary: String?
    let body: String?
    let path: String?

    var defaultFilename: String {
        "\(dateValue)-\(slug).md"
    }

    func renderMarkdown() -> String {
        let currentDate = dateValue
        var lines = [
            "---",
            "id: adr_\(dateKey(for: currentDate))_\(slug.replacingOccurrences(of: "-", with: "_"))",
            "type: adr",
            "status: \(status.rawValue)",
            "title: \(architectureYAMLQuoted(title))",
            "owner: \(architectureYAMLQuoted(owner))",
            "created_at: \(currentDate)",
            "updated_at: \(currentDate)",
        ]
        lines.append(contentsOf: architectureYAMLList(key: "tags", values: tags))
        lines.append("supersedes: []")
        lines.append("superseded_by: []")
        lines.append("---")
        lines.append("")
        lines.append("# ADR: \(title)")
        lines.append("")
        lines.append("## Decision")
        lines.append("")
        lines.append(summaryText)
        lines.append("")
        lines.append("## Rationale")
        lines.append("")
        lines.append(bodyText)
        lines.append("")
        return lines.joined(separator: "\n")
    }

    private var summaryText: String {
        summary?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            ?? "Draft ADR created from Bugbook Architecture Mode."
    }

    private var bodyText: String {
        body?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            ?? "Rationale to be completed before this ADR is accepted."
    }

    private var dateValue: String {
        Self.dateFormatter.string(from: Date())
    }

    private var slug: String {
        architectureSlugify(title)
    }

    private func dateKey(for date: String) -> String {
        date.replacingOccurrences(of: "-", with: "_")
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

private struct ArchitectureADR {
    let relativePath: String
    let frontmatter: [String: Any]

    init?(path: String, repoPath: String) throws {
        let content = try String(contentsOfFile: path, encoding: .utf8)
        guard let frontmatter = architectureParseFrontmatter(content) else { return nil }
        relativePath = BugbookCLI.relativePath(from: path, workspace: repoPath)
        self.frontmatter = frontmatter
    }

    var id: String { frontmatter["id"] as? String ?? "" }
    var status: String { frontmatter["status"] as? String ?? "" }
    var title: String { frontmatter["title"] as? String ?? pageDisplayName(fromPath: relativePath) }
    var owner: String { frontmatter["owner"] as? String ?? "" }
    var tags: [String] { architectureStringList(frontmatter["tags"]) }

    func toJSON() -> [String: Any] {
        [
            "id": id,
            "type": "adr",
            "status": status,
            "title": title,
            "owner": owner,
            "tags": tags,
            "relative_path": relativePath,
        ]
    }
}

private struct ArchitectureScriptResult {
    let command: String
    let exitCode: Int
    let stdout: String
    let stderr: String

    func toJSON() -> [String: Any] {
        [
            "command": command,
            "exit_code": exitCode,
            "ok": exitCode == 0,
            "stdout": stdout.trimmingCharacters(in: .newlines),
            "stderr": stderr.trimmingCharacters(in: .newlines),
        ]
    }
}

private func architectureParseFrontmatter(_ content: String) -> [String: Any]? {
    guard content.hasPrefix("---\n"),
          let endRange = content.range(
              of: "\n---\n",
              range: content.index(content.startIndex, offsetBy: 4)..<content.endIndex
          ) else {
        return nil
    }

    let yamlStart = content.index(content.startIndex, offsetBy: 4)
    let yaml = String(content[yamlStart..<endRange.lowerBound])
    guard let loaded = try? Yams.load(yaml: yaml),
          let frontmatter = architectureJSONCompatibleObject(loaded) as? [String: Any] else {
        return nil
    }
    return frontmatter
}

private func architectureStringList(_ value: Any?) -> [String] {
    if let strings = value as? [String] {
        return strings
    }
    if let items = value as? [Any] {
        return items.compactMap { $0 as? String }
    }
    if let string = value as? String, !string.isEmpty {
        return [string]
    }
    return []
}

private func architectureYAMLList(key: String, values: [String]) -> [String] {
    guard !values.isEmpty else {
        return ["\(key): []"]
    }
    return [ "\(key):" ] + values.map { "  - \(architectureYAMLQuoted($0))" }
}

private func architectureYAMLQuoted(_ value: String) -> String {
    let escaped = value
        .replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: "\"", with: "\\\"")
    return "\"\(escaped)\""
}

private func architectureSlugify(_ value: String) -> String {
    let lowered = value.lowercased()
    let allowed = lowered.map { character -> Character in
        character.isLetter || character.isNumber ? character : "-"
    }
    let slug = String(allowed)
        .split(separator: "-")
        .joined(separator: "-")
    return slug.isEmpty ? "untitled-adr" : slug
}

private func architectureJSONCompatibleObject(_ value: Any) -> Any {
    switch value {
    case let dict as [String: Any]:
        return dict.reduce(into: [String: Any]()) { result, entry in
            result[entry.key] = architectureJSONCompatibleObject(entry.value)
        }
    case let dict as [AnyHashable: Any]:
        return dict.reduce(into: [String: Any]()) { result, entry in
            result[String(describing: entry.key)] = architectureJSONCompatibleObject(entry.value)
        }
    case let array as [Any]:
        return array.map(architectureJSONCompatibleObject)
    case let string as String:
        return string
    case let bool as Bool:
        return bool
    case let number as NSNumber:
        return number
    case is NSNull:
        return NSNull()
    default:
        return String(describing: value)
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
