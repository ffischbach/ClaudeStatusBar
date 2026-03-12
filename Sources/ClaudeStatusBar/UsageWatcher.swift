import Foundation
import Security

@MainActor
final class UsageWatcher: ObservableObject {
    @Published var usage: TokenUsage?
    @Published var planUsage: PlanUsage?
    @Published var lastUpdated: Date?
    @Published var isStale: Bool = false

    private let usageFileURL: URL
    private var source: DispatchSourceFileSystemObject?
    private var staleTimer: Timer?
    private var quotaTimer: Timer?
    private let decoder: JSONDecoder

    init() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        usageFileURL = home.appendingPathComponent(".claude/session_usage.json")
        decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        loadFromDisk()
        startWatching()
        Task { await fetchPlanUsage() }
        quotaTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { await self?.fetchPlanUsage() }
        }
    }

    private func loadFromDisk() {
        guard FileManager.default.fileExists(atPath: usageFileURL.path) else { return }
        guard let data = try? Data(contentsOf: usageFileURL),
              let decoded = try? decoder.decode(TokenUsage.self, from: data) else { return }
        usage = decoded
        lastUpdated = Date()
        resetStaleTimer()
    }

    private func startWatching() {
        let dirURL = usageFileURL.deletingLastPathComponent()
        let fd = open(dirURL.path, O_EVTONLY)
        guard fd >= 0 else { return }
        source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd, eventMask: [.write, .rename], queue: .main
        )
        source?.setEventHandler { [weak self] in self?.loadFromDisk() }
        source?.setCancelHandler { close(fd) }
        source?.resume()
    }

    private func resetStaleTimer() {
        staleTimer?.invalidate()
        isStale = false
        staleTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: false) { [weak self] _ in
            Task { @MainActor in self?.isStale = true }
        }
    }

    private func readOAuthToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "Claude Code-credentials",
            kSecReturnData as String: true
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }

        struct OAuthData: Decodable { let accessToken: String }
        struct Credentials: Decodable { let claudeAiOauth: OAuthData }
        return (try? JSONDecoder().decode(Credentials.self, from: data))?.claudeAiOauth.accessToken
    }

    func fetchPlanUsage() async {
        guard let token = readOAuthToken(),
              let url = URL(string: "https://api.anthropic.com/api/oauth/usage") else { return }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let decoded = try? decoder.decode(PlanUsage.self, from: data) else { return }
        planUsage = decoded
    }
}
