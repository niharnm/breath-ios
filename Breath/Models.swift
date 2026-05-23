import CoreGraphics
import Foundation

enum EmergencyMode: String, CaseIterable, Identifiable {
    case cpr
    case choking
    case bleeding
    case unknown

    var id: String { rawValue }
}

struct Step: Identifiable, Equatable {
    let id: String
    let title: String
    let instruction: String
    let helper: String?
    let urgent: Bool

    var speechText: String {
        [title, instruction, helper].compactMap { $0 }.joined(separator: ". ")
    }
}

struct OverlayMarker: Identifiable, Equatable {
    enum Tone: String {
        case cpr
        case choking
        case bleeding
    }

    let id: String
    let label: String
    let tone: Tone
    let defaultPosition: MarkerPosition
}

struct MarkerPosition: Equatable {
    var x: CGFloat
    var y: CGFloat
}

struct ProtocolGuide: Identifiable, Equatable {
    let mode: EmergencyMode
    let label: String
    let shortLabel: String
    let summary: String
    let overlayMarkers: [OverlayMarker]
    let steps: [Step]

    var id: EmergencyMode { mode }
}

struct Message: Identifiable, Equatable {
    enum Role {
        case assistant
        case user
    }

    let id = UUID()
    let role: Role
    let text: String
}
