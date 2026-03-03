import Foundation

enum SoundMode: String, CaseIterable, Identifiable {
    case pain, sexy, halo, volchara
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .pain: "Pain"
        case .sexy: "Sexy"
        case .halo: "Halo"
        case .volchara: "Volchara"
        }
    }
    
    var folderName: String {
        switch self {
        case .pain: "pain"
        case .sexy: "sexy"
        case .halo: "halo"
        case .volchara: "volchara"
        }
    }
    
    var usesEscalation: Bool {
        self == .sexy
    }
}
