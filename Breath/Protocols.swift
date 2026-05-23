import Foundation

enum BreathProtocols {
    static let all: [EmergencyMode: ProtocolGuide] = [
        .cpr: cpr,
        .choking: choking,
        .bleeding: bleeding,
        .unknown: unknown,
    ]

    static let cpr = ProtocolGuide(
        mode: .cpr,
        label: "Adult/teen CPR",
        shortLabel: "CPR",
        summary: "For an adult or teen who is unresponsive and not breathing normally.",
        overlayMarkers: [
            OverlayMarker(
                id: "cpr-chest",
                label: "Push here",
                tone: .cpr,
                defaultPosition: MarkerPosition(x: 50, y: 52)
            ),
        ],
        steps: [
            Step(
                id: "call",
                title: "Call 911",
                instruction: "Call 911 now and put the phone on speaker.",
                helper: "Follow dispatcher instructions over Breath.",
                urgent: true
            ),
            Step(
                id: "check",
                title: "Check response and breathing",
                instruction: "Check if the person is responsive and breathing normally.",
                helper: "Breath does not diagnose. Use what you see and what the dispatcher tells you.",
                urgent: false
            ),
            Step(
                id: "position",
                title: "Lay them flat",
                instruction: "If the person is unresponsive and not breathing normally, place them flat on a firm surface.",
                helper: nil,
                urgent: false
            ),
            Step(
                id: "hands",
                title: "Place your hands",
                instruction: "Place the heel of one hand in the center of the chest and put your other hand on top.",
                helper: nil,
                urgent: false
            ),
            Step(
                id: "compress",
                title: "Push hard and fast",
                instruction: "Push hard and fast in the center of the chest.",
                helper: "Use the 110 BPM rhythm timer if it helps you keep pace.",
                urgent: false
            ),
            Step(
                id: "continue",
                title: "Keep going",
                instruction: "Continue until responders take over, an AED is ready, the dispatcher says stop, or the person starts breathing normally.",
                helper: nil,
                urgent: false
            ),
        ]
    )

    static let choking = ProtocolGuide(
        mode: .choking,
        label: "Choking adult/child over 1",
        shortLabel: "Choking",
        summary: "For an adult or child over 1 who may be choking.",
        overlayMarkers: [
            OverlayMarker(
                id: "choking-back",
                label: "Back blows here",
                tone: .choking,
                defaultPosition: MarkerPosition(x: 48, y: 38)
            ),
            OverlayMarker(
                id: "choking-thrust",
                label: "Thrust here",
                tone: .choking,
                defaultPosition: MarkerPosition(x: 50, y: 58)
            ),
        ],
        steps: [
            Step(
                id: "cough",
                title: "Check if they can cough",
                instruction: "If they can cough, speak, or breathe, encourage coughing and monitor closely.",
                helper: "Do not start back blows or abdominal thrusts if they can cough, speak, or breathe.",
                urgent: false
            ),
            Step(
                id: "call",
                title: "Call 911 if airway is blocked",
                instruction: "If they cannot breathe, speak, or cough, call 911 now.",
                helper: "Put the phone on speaker and follow dispatcher instructions over Breath.",
                urgent: true
            ),
            Step(
                id: "back-blows",
                title: "Guide back blows",
                instruction: "For an adult or child over 1, guide back blows.",
                helper: "Infant choking is not covered in this MVP.",
                urgent: false
            ),
            Step(
                id: "thrusts",
                title: "Guide abdominal thrusts",
                instruction: "Then guide abdominal thrusts.",
                helper: "Use this only for an adult or child over 1 who cannot breathe, speak, or cough.",
                urgent: false
            ),
            Step(
                id: "unconscious",
                title: "If they become unconscious",
                instruction: "If they become unconscious, switch to CPR guidance.",
                helper: "Breath does not diagnose. Follow dispatcher instructions over Breath.",
                urgent: false
            ),
        ]
    )

    static let bleeding = ProtocolGuide(
        mode: .bleeding,
        label: "Severe bleeding",
        shortLabel: "Bleeding",
        summary: "For severe or uncontrolled bleeding.",
        overlayMarkers: [
            OverlayMarker(
                id: "bleeding-pressure",
                label: "Press here",
                tone: .bleeding,
                defaultPosition: MarkerPosition(x: 50, y: 52)
            ),
        ],
        steps: [
            Step(
                id: "call",
                title: "Call 911",
                instruction: "Call 911 for severe or uncontrolled bleeding.",
                helper: "Put the phone on speaker and follow dispatcher instructions over Breath.",
                urgent: true
            ),
            Step(
                id: "pressure",
                title: "Apply firm pressure",
                instruction: "Apply firm direct pressure to the wound with cloth, gauze, or clothing.",
                helper: nil,
                urgent: false
            ),
            Step(
                id: "layers",
                title: "Add layers if needed",
                instruction: "Do not remove soaked cloth; add more layers on top.",
                helper: nil,
                urgent: false
            ),
            Step(
                id: "hold",
                title: "Keep pressure",
                instruction: "Keep pressure until help arrives.",
                helper: nil,
                urgent: false
            ),
            Step(
                id: "tourniquet",
                title: "Tourniquet only with support",
                instruction: "For severe limb bleeding, use a tourniquet only if trained and available, or if directed by an emergency dispatcher.",
                helper: "Do not delay direct pressure while waiting for other supplies.",
                urgent: false
            ),
        ]
    )

    static let unknown = ProtocolGuide(
        mode: .unknown,
        label: "Not sure",
        shortLabel: "Not sure",
        summary: "Start with emergency help, then choose the closest situation.",
        overlayMarkers: [],
        steps: [
            Step(
                id: "call",
                title: "Call 911",
                instruction: "Call 911 now and put the phone on speaker.",
                helper: "Follow dispatcher instructions over Breath.",
                urgent: true
            ),
            Step(
                id: "describe",
                title: "Describe what you see",
                instruction: "Tell Breath what is happening in plain words, or choose collapsed, choking, or heavy bleeding.",
                helper: "Breath does not diagnose or replace professional medical help.",
                urgent: false
            ),
        ]
    )
}
