import Foundation

enum LibrarySource: Hashable {
    case local
    case cloud
    case external(UUID)
}

extension LibrarySource: RawRepresentable {
    init?(rawValue: String) {
        switch rawValue {
        case "local": self = .local
        case "cloud": self = .cloud
        default:
            let prefix = "external:"
            if rawValue.hasPrefix(prefix),
               let id = UUID(uuidString: String(rawValue.dropFirst(prefix.count))) {
                self = .external(id)
            } else {
                return nil
            }
        }
    }

    var rawValue: String {
        switch self {
        case .local: return "local"
        case .cloud: return "cloud"
        case .external(let id): return "external:\(id.uuidString)"
        }
    }
}
