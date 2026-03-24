import UIKit
import SwiftUI
import CryptoKit

@Observable final class ImageCache {
    private let cache: NSCache<NSURL, UIImage> = {
        let c = NSCache<NSURL, UIImage>()
        c.countLimit = 200
        c.totalCostLimit = 50 * 1024 * 1024
        return c
    }()

    private static let diskMaxBytes = 150 * 1024 * 1024
    private static let diskEvictTarget = 120 * 1024 * 1024

    func image(for url: URL) async -> UIImage? {
        let key = url as NSURL
        if let cached = cache.object(forKey: key) {
            return cached
        }

        if let diskImage = loadFromDisk(for: url) {
            cache.setObject(diskImage, forKey: key)
            return diskImage
        }

        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let image = UIImage(data: data) else {
            return nil
        }

        cache.setObject(image, forKey: key, cost: data.count)
        Task.detached { [self] in self.saveToDisk(data, for: url) }
        return image
    }

    // MARK: - Favourite Image Storage

    func storeFavouriteImages(urls: [URL]) async {
        let fm = FileManager.default
        try? fm.createDirectory(at: favouriteImageURL, withIntermediateDirectories: true)

        for url in urls {
            let dest = favouritePath(for: url)
            guard !fm.fileExists(atPath: dest.path(percentEncoded: false)) else { continue }

            // Try copying from cache dir first
            let cachePath = diskPath(for: url)
            if fm.fileExists(atPath: cachePath.path(percentEncoded: false)) {
                try? fm.copyItem(at: cachePath, to: dest)
                continue
            }

            // Not in cache — download and save to both locations
            guard let (data, _) = try? await URLSession.shared.data(from: url) else { continue }
            try? data.write(to: dest)
            Task.detached { [self] in self.saveToDisk(data, for: url) }
        }
    }

    func removeFavouriteImages(urls: [URL]) {
        let fm = FileManager.default
        for url in urls {
            try? fm.removeItem(at: favouritePath(for: url))
        }
    }

    // MARK: - Disk Cache

    private var diskCacheURL: URL {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return caches.appending(path: "ImageCache", directoryHint: .isDirectory)
    }

    private var favouriteImageURL: URL {
        let library = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
        return library.appending(path: "FavouriteImages", directoryHint: .isDirectory)
    }

    private func hashString(for url: URL) -> String {
        let hash = SHA256.hash(data: Data(url.absoluteString.utf8))
        return hash.map { String(format: "%02x", $0) }.joined()
    }

    private func diskPath(for url: URL) -> URL {
        diskCacheURL.appending(path: hashString(for: url))
    }

    private func favouritePath(for url: URL) -> URL {
        favouriteImageURL.appending(path: hashString(for: url))
    }

    private func loadFromDisk(for url: URL) -> UIImage? {
        // Check favourites directory first (permanent), then cache
        if let data = try? Data(contentsOf: favouritePath(for: url)) {
            return UIImage(data: data)
        }
        guard let data = try? Data(contentsOf: diskPath(for: url)) else { return nil }
        return UIImage(data: data)
    }

    private func saveToDisk(_ data: Data, for url: URL) {
        let fm = FileManager.default
        try? fm.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
        try? data.write(to: diskPath(for: url))
        evictIfNeeded()
    }

    private func evictIfNeeded() {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(
            at: diskCacheURL,
            includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey]
        ) else { return }

        var totalSize = 0
        var entries: [(url: URL, date: Date, size: Int)] = []
        for file in files {
            guard let values = try? file.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey]),
                  let date = values.contentModificationDate,
                  let size = values.fileSize else { continue }
            totalSize += size
            entries.append((file, date, size))
        }

        guard totalSize > Self.diskMaxBytes else { return }

        entries.sort { $0.date < $1.date }
        for entry in entries {
            try? fm.removeItem(at: entry.url)
            totalSize -= entry.size
            if totalSize <= Self.diskEvictTarget { break }
        }
    }
}

private struct ImageCacheKey: EnvironmentKey {
    static let defaultValue = ImageCache()
}

extension EnvironmentValues {
    var imageCache: ImageCache {
        get { self[ImageCacheKey.self] }
        set { self[ImageCacheKey.self] = newValue }
    }
}
