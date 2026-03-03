import Foundation

enum SoundLibraryError: LocalizedError {
    case missingBundledAudio, emptyFolder(String)
    
    var errorDescription: String? {
        switch self {
        case .missingBundledAudio: "No bundled audio files were found"
        case let .emptyFolder(path): "No audio files found in \(path)"
        }
    }
}

struct SoundLibrary {
    private let supportedExtensions = Set(["mp3", "m4a", "aac", "wav"])
    
    func loadPack(for mode: SoundMode) throws -> SoundPack {
        let files = try loadBundledFiles(for: mode)
        return SoundPack(mode: mode, files: files)
    }
    
    private func loadBundledFiles(for mode: SoundMode) throws -> [URL] {
        // Primary path when Xcode preserves directory structure in the app bundle
        let folderFiles = bundledAudioFiles(subdirectory: "audio/\(mode.folderName)")
        if !folderFiles.isEmpty {
            return folderFiles.sorted { $0.lastPathComponent < $1.lastPathComponent }
        }
        
        // Fallback when Xcode flattens copied files directly into Contents/Resources
        let flatFiles = bundledAudioFiles(subdirectory: nil)
        guard !flatFiles.isEmpty else {
            throw SoundLibraryError.missingBundledAudio
        }
        
        let modeFiles = flatFiles
            .filter { matchesMode($0, mode: mode) }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
        
        if modeFiles.isEmpty {
            throw SoundLibraryError.emptyFolder("bundled resources for mode \(mode.rawValue)")
        }
        
        return modeFiles
    }
    
    private func loadFiles(from folderURL: URL) throws -> [URL] {
        let allFiles = try FileManager.default.contentsOfDirectory(
            at: folderURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )
        
        let audioFiles = allFiles
            .filter { supportedExtensions.contains($0.pathExtension.lowercased()) }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
        
        if audioFiles.isEmpty {
            throw SoundLibraryError.emptyFolder(folderURL.path())
        }
        
        return audioFiles
    }
    
    private func matchesMode(_ fileURL: URL, mode: SoundMode) -> Bool {
        let baseName = fileURL.deletingPathExtension().lastPathComponent
        let isPain = isTwoDigitsThenUnderscore(baseName)
        let isSexy = isExactlyTwoDigits(baseName)
        let isHalo = baseName.hasPrefix("halo_")
        
        switch mode {
        case .pain: return isPain
        case .sexy: return isSexy
        case .halo: return isHalo
        case .volchara: return !isPain && !isSexy && !isHalo
        }
    }
    
    private func bundledAudioFiles(subdirectory: String?) -> [URL] {
        let all = supportedExtensions.flatMap {
            Bundle.main.urls(forResourcesWithExtension: $0, subdirectory: subdirectory) ?? []
        }
        
        return Array(Set(all))
    }
    
    private func isExactlyTwoDigits(_ value: String) -> Bool {
        guard value.count == 2 else { return false }
        return value.allSatisfy(\.isNumber)
    }
    
    private func isTwoDigitsThenUnderscore(_ value: String) -> Bool {
        guard value.count >= 3 else { return false }
        
        let characters = Array(value)
        return characters[0].isNumber && characters[1].isNumber && characters[2] == "_"
    }
}
