import Foundation
import Domain

public final class BundleCardPackRepository: CardPackRepository, @unchecked Sendable {
    private let bundle: Bundle
    private let resourceName: String
    private let cache = NSCache<NSString, NSArray>()

    public init(bundle: Bundle? = nil, resourceName: String = "card_packs") {
        // Default to Tuist's auto-generated Bundle.module (internal), reachable
        // from inside the Data target.
        self.bundle = bundle ?? .module
        self.resourceName = resourceName
    }

    public func loadAllPacks() async throws -> [CardPack] {
        if let cached = cache.object(forKey: "all") as? [CardPack] {
            return cached
        }
        // Try the configured bundle, then fall back to the host app bundle
        // (Tuist may copy static-framework resources directly into the app bundle).
        let url = bundle.url(forResource: resourceName, withExtension: "json")
            ?? Bundle.main.url(forResource: resourceName, withExtension: "json")
        guard let url else {
            throw DomainError.bundleResourceMissing(name: "\(resourceName).json")
        }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        do {
            let bundleContent = try decoder.decode(CardPackBundle.self, from: data)
            cache.setObject(bundleContent.packs as NSArray, forKey: "all")
            return bundleContent.packs
        } catch {
            throw DomainError.decodingFailed(reason: String(describing: error))
        }
    }

    public func packs(for domain: LearningDomain?) async throws -> [CardPack] {
        let all = try await loadAllPacks()
        guard let domain else { return all }
        return all.filter { $0.domain == domain }
    }

    public func pack(byId id: String) async throws -> CardPack? {
        let all = try await loadAllPacks()
        return all.first { $0.packId == id }
    }
}
