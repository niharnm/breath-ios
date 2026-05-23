import SwiftUI

struct ContentView: View {
    @StateObject private var cameraController = CameraSessionController()
    @StateObject private var speechReader = SpeechReader()
    @StateObject private var metronome = CompressionMetronome()

    @State private var activeMode: EmergencyMode?
    @State private var stepIndex = 0
    @State private var inputText = ""
    @State private var messages: [Message] = [
        Message(
            role: .assistant,
            text: "Breath uses predefined emergency protocols. Call 911 now and tell me what is happening."
        ),
    ]
    @State private var markerPositions = BreathProtocols.all.values
        .flatMap(\.overlayMarkers)
        .reduce(into: [String: MarkerPosition]()) { positions, marker in
            positions[marker.id] = marker.defaultPosition
        }

    private var protocolGuide: ProtocolGuide {
        BreathProtocols.all[activeMode ?? .unknown] ?? BreathProtocols.unknown
    }

    private var currentStep: Step {
        protocolGuide.steps[min(stepIndex, protocolGuide.steps.count - 1)]
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.03, green: 0.06, blue: 0.09), Color(red: 0.04, green: 0.10, blue: 0.15)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                SafetyBanner()

                if activeMode == nil {
                    HomeScreen(onSelect: selectMode)
                } else {
                    GuidanceScreen(
                        protocolGuide: protocolGuide,
                        currentStep: currentStep,
                        stepIndex: stepIndex,
                        inputText: $inputText,
                        messages: messages,
                        markerPositions: $markerPositions,
                        cameraController: cameraController,
                        metronome: metronome,
                        onBack: returnHome,
                        onStepChange: moveStep,
                        onStepSelect: { stepIndex = $0 },
                        onReadStep: { speechReader.speak(currentStep.speechText) },
                        onSubmitText: submitText,
                        onSwitchToCPR: { selectMode(.cpr) }
                    )
                }
            }
        }
        .onChange(of: activeMode) { _, newMode in
            if newMode == nil {
                cameraController.stop()
                metronome.stop()
            } else {
                cameraController.start()
            }
        }
    }

    private func selectMode(_ mode: EmergencyMode) {
        activeMode = mode
        stepIndex = 0
        metronome.stop()
        messages.append(Message(role: .assistant, text: EmergencyClassifier.startMessage(for: mode)))
    }

    private func returnHome() {
        activeMode = nil
        stepIndex = 0
        speechReader.stop()
        metronome.stop()
    }

    private func moveStep(_ direction: Int) {
        stepIndex = min(max(stepIndex + direction, 0), protocolGuide.steps.count - 1)
    }

    private func submitText() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let result = EmergencyClassifier.reply(to: trimmed, activeMode: activeMode ?? .unknown)
        messages.append(Message(role: .user, text: trimmed))
        messages.append(Message(role: .assistant, text: result.reply))
        inputText = ""

        if result.mode != activeMode {
            activeMode = result.mode
            metronome.stop()
        }

        if let nextStepIndex = result.stepIndex {
            stepIndex = nextStepIndex
        }
    }
}

private struct SafetyBanner: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Call 911 now.")
                .font(.system(size: 25, weight: .black))
                .textCase(.uppercase)
            Text("Put phone on speaker. Follow dispatcher instructions over Breath.")
                .font(.system(size: 14, weight: .semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .background(Color(red: 0.70, green: 0.11, blue: 0.11))
        .foregroundStyle(.white)
    }
}

private struct HomeScreen: View {
    let onSelect: (EmergencyMode) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack {
                    BreathMark()
                    Text("Breath")
                        .font(.system(size: 17, weight: .black))
                    Spacer()
                    Text("On-device MVP")
                        .font(.system(size: 11, weight: .black))
                        .textCase(.uppercase)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .overlay(
                            Capsule().stroke(Color.white.opacity(0.22), lineWidth: 1)
                        )
                }
                .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 14) {
                    Text("Breath turns panic into guided action.")
                        .font(.system(size: 52, weight: .black))
                        .lineSpacing(-4)
                        .minimumScaleFactor(0.74)
                    Text("Breath gives live first-aid guidance before help arrives, using predefined emergency protocols, visual overlays, voice instructions, and a CPR rhythm timer.")
                        .font(.system(size: 18, weight: .medium))
                        .lineSpacing(4)
                        .foregroundStyle(Color(red: 0.79, green: 0.85, blue: 0.92))
                }

                VStack(spacing: 12) {
                    EmergencyButton(
                        title: "Collapsed / not breathing",
                        detail: "Adult or teen is unresponsive or not breathing normally.",
                        color: Color(red: 0.75, green: 0.16, blue: 0.10),
                        action: { onSelect(.cpr) }
                    )
                    EmergencyButton(
                        title: "Choking",
                        detail: "Adult or child over 1 cannot breathe, speak, or cough.",
                        color: Color(red: 0.71, green: 0.25, blue: 0.07),
                        action: { onSelect(.choking) }
                    )
                    EmergencyButton(
                        title: "Heavy bleeding",
                        detail: "Severe or uncontrolled bleeding needs direct pressure.",
                        color: Color(red: 0.75, green: 0.16, blue: 0.10),
                        action: { onSelect(.bleeding) }
                    )
                    EmergencyButton(
                        title: "Not sure",
                        detail: "Start with calling 911 and describe what is happening.",
                        color: Color(red: 0.07, green: 0.30, blue: 0.45),
                        action: { onSelect(.unknown) }
                    )
                }

                Text("Breath does not diagnose or replace professional medical help.")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(red: 0.75, green: 0.86, blue: 1))
                    .padding(.leading, 12)
                    .overlay(alignment: .leading) {
                        Rectangle()
                            .fill(Color(red: 0.22, green: 0.74, blue: 0.97))
                            .frame(width: 4)
                    }
            }
            .padding(18)
        }
    }
}

private struct GuidanceScreen: View {
    let protocolGuide: ProtocolGuide
    let currentStep: Step
    let stepIndex: Int
    @Binding var inputText: String
    let messages: [Message]
    @Binding var markerPositions: [String: MarkerPosition]
    @ObservedObject var cameraController: CameraSessionController
    @ObservedObject var metronome: CompressionMetronome
    let onBack: () -> Void
    let onStepChange: (Int) -> Void
    let onStepSelect: (Int) -> Void
    let onReadStep: () -> Void
    let onSubmitText: () -> Void
    let onSwitchToCPR: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                HStack(spacing: 12) {
                    Button("Back", action: onBack)
                        .buttonStyle(SecondaryButtonStyle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(protocolGuide.shortLabel) guidance")
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(Color(red: 0.58, green: 0.77, blue: 1))
                            .textCase(.uppercase)
                        Text(protocolGuide.label)
                            .font(.system(size: 24, weight: .black))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                }

                CameraPanel(
                    protocolGuide: protocolGuide,
                    markerPositions: $markerPositions,
                    cameraController: cameraController
                )

                ProtocolCard(
                    protocolGuide: protocolGuide,
                    currentStep: currentStep,
                    stepIndex: stepIndex,
                    onStepChange: onStepChange,
                    onStepSelect: onStepSelect,
                    onReadStep: onReadStep
                )

                if protocolGuide.mode == .cpr {
                    MetronomeCard(metronome: metronome)
                }

                if protocolGuide.mode == .choking {
                    Button("Switch to CPR guidance", action: onSwitchToCPR)
                        .buttonStyle(DangerButtonStyle())
                }

                AssistantCard(
                    inputText: $inputText,
                    messages: messages,
                    onSubmitText: onSubmitText
                )
            }
            .padding(16)
        }
    }
}

private struct CameraPanel: View {
    let protocolGuide: ProtocolGuide
    @Binding var markerPositions: [String: MarkerPosition]
    @ObservedObject var cameraController: CameraSessionController

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                CameraPreview(controller: cameraController)
                    .opacity(cameraController.status == .live ? 1 : 0)

                if cameraController.status != .live {
                    GuidedModeBackground(status: cameraController.status)
                }

                LinearGradient(
                    colors: [.black.opacity(0.66), .clear, .black.opacity(0.80)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(protocolGuide.summary)
                                .font(.system(size: 14, weight: .black))
                            Text("Drag the marker to match what you see. No body detection is running.")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color(red: 0.75, green: 0.86, blue: 1))
                        }
                        .padding(12)
                        .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 12))

                        Spacer()

                        Text(cameraController.status.displayLabel)
                            .font(.system(size: 11, weight: .black))
                            .textCase(.uppercase)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(.black.opacity(0.55), in: Capsule())
                    }

                    Spacer()

                    Text("Manual overlay only. Move the marker yourself before following steps.")
                        .font(.system(size: 12, weight: .semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(.black.opacity(0.58), in: RoundedRectangle(cornerRadius: 12))
                }
                .padding(12)

                ForEach(protocolGuide.overlayMarkers) { marker in
                    OverlayMarkerView(
                        marker: marker,
                        position: binding(for: marker),
                        panelSize: geometry.size
                    )
                }
            }
        }
        .frame(height: 430)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.16), lineWidth: 1)
        )
    }

    private func binding(for marker: OverlayMarker) -> Binding<MarkerPosition> {
        Binding(
            get: { markerPositions[marker.id] ?? marker.defaultPosition },
            set: { markerPositions[marker.id] = $0 }
        )
    }
}

private struct GuidedModeBackground: View {
    let status: CameraStatus

    var body: some View {
        ZStack {
            Color(red: 0.03, green: 0.08, blue: 0.13)
            GridPattern()
                .stroke(Color.white.opacity(0.09), lineWidth: 1)
            VStack(spacing: 8) {
                Text(status == .requesting ? "Requesting camera" : "Guided mode")
                    .font(.system(size: 20, weight: .black))
                Text(status == .requesting ? "Allow camera access to use visual overlays." : "Camera is unavailable or blocked. Breath still works with guided steps.")
                    .font(.system(size: 14, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color(red: 0.58, green: 0.77, blue: 1))
            }
            .padding()
        }
    }
}

private struct OverlayMarkerView: View {
    let marker: OverlayMarker
    @Binding var position: MarkerPosition
    let panelSize: CGSize

    var body: some View {
        Text(marker.label)
            .font(.system(size: 14, weight: .black))
            .foregroundStyle(.white)
            .padding(.horizontal, 15)
            .padding(.vertical, 12)
            .background(markerColor, in: Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.82), lineWidth: 3))
            .shadow(color: markerColor.opacity(0.42), radius: 16)
            .position(x: panelSize.width * position.x / 100, y: panelSize.height * position.y / 100)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        position = MarkerPosition(
                            x: min(max(value.location.x / panelSize.width * 100, 8), 92),
                            y: min(max(value.location.y / panelSize.height * 100, 12), 88)
                        )
                    }
            )
            .accessibilityLabel("Move overlay marker: \(marker.label)")
    }

    private var markerColor: Color {
        switch marker.tone {
        case .cpr:
            return Color(red: 0.86, green: 0.15, blue: 0.15)
        case .choking:
            return Color(red: 0.88, green: 0.34, blue: 0.08)
        case .bleeding:
            return Color(red: 0.76, green: 0.07, blue: 0.24)
        }
    }
}

private struct ProtocolCard: View {
    let protocolGuide: ProtocolGuide
    let currentStep: Step
    let stepIndex: Int
    let onStepChange: (Int) -> Void
    let onStepSelect: (Int) -> Void
    let onReadStep: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Step \(stepIndex + 1) of \(protocolGuide.steps.count)")
                Spacer()
                if currentStep.urgent {
                    Text("Urgent")
                }
            }
            .font(.system(size: 12, weight: .black))
            .foregroundStyle(Color(red: 0.58, green: 0.77, blue: 1))
            .textCase(.uppercase)

            Text(currentStep.title)
                .font(.system(size: 30, weight: .black))
                .foregroundStyle(.white)

            Text(currentStep.instruction)
                .font(.system(size: 19, weight: .semibold))
                .lineSpacing(4)
                .foregroundStyle(Color(red: 0.89, green: 0.93, blue: 0.97))

            if let helper = currentStep.helper {
                Text(helper)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(red: 0.75, green: 0.86, blue: 1))
                    .padding(.leading, 12)
                    .overlay(alignment: .leading) {
                        Rectangle()
                            .fill(Color(red: 0.22, green: 0.74, blue: 0.97))
                            .frame(width: 4)
                    }
            }

            HStack(spacing: 6) {
                ForEach(protocolGuide.steps.indices, id: \.self) { index in
                    Button {
                        onStepSelect(index)
                    } label: {
                        Capsule()
                            .fill(index == stepIndex ? Color(red: 0.22, green: 0.74, blue: 0.97) : Color.white.opacity(0.24))
                            .frame(width: index == stepIndex ? 24 : 10, height: 10)
                    }
                    .accessibilityLabel("Go to \(protocolGuide.steps[index].title)")
                }
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                Button("Previous") { onStepChange(-1) }
                    .buttonStyle(SecondaryButtonStyle())
                    .disabled(stepIndex == 0)
                Button("Next step") { onStepChange(1) }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(stepIndex == protocolGuide.steps.count - 1)
                Button("Read aloud", action: onReadStep)
                    .buttonStyle(SecondaryButtonStyle())
                Link("Call 911", destination: URL(string: "tel:911")!)
                    .buttonStyle(DangerButtonStyle())
            }
        }
        .cardStyle()
    }
}

private struct MetronomeCard: View {
    @ObservedObject var metronome: CompressionMetronome

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Compression rhythm")
                        .font(.system(size: 17, weight: .black))
                    Text("110 BPM")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(Color(red: 0.58, green: 0.77, blue: 1))
                }
                Spacer()
                Text("Push")
                    .font(.system(size: 15, weight: .black))
                    .frame(width: 66, height: 66)
                    .background(Color(red: 0.86, green: 0.15, blue: 0.15), in: Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.85), lineWidth: 6))
                    .scaleEffect(metronome.isRunning && metronome.pulse ? 1.1 : 0.92)
                    .animation(.easeInOut(duration: 0.18), value: metronome.pulse)
            }
            if metronome.isRunning {
                Button("Pause rhythm") {
                    metronome.toggle()
                }
                .buttonStyle(DangerButtonStyle())
            } else {
                Button("Start 110 BPM rhythm") {
                    metronome.toggle()
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .foregroundStyle(.white)
        .cardStyle()
    }
}

private struct AssistantCard: View {
    @Binding var inputText: String
    let messages: [Message]
    let onSubmitText: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Tell Breath what is happening")
                    .font(.system(size: 18, weight: .black))
                Text("Replies are limited to predefined CPR, choking, and bleeding protocol steps.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color(red: 0.58, green: 0.77, blue: 1))
            }

            VStack(spacing: 8) {
                ForEach(messages.suffix(6)) { message in
                    Text(message.text)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(message.role == .assistant ? Color(red: 0.88, green: 0.96, blue: 1) : Color(red: 0.03, green: 0.18, blue: 0.29))
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: message.role == .assistant ? .leading : .trailing)
                        .background(message.role == .assistant ? Color(red: 0.06, green: 0.19, blue: 0.32) : Color(red: 0.88, green: 0.96, blue: 1), in: RoundedRectangle(cornerRadius: 12))
                }
            }

            HStack(spacing: 10) {
                TextField("Example: he collapsed and is not breathing", text: $inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15, weight: .medium))
                    .padding(12)
                    .background(Color.black.opacity(0.28), in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.white)
                    .submitLabel(.send)
                    .onSubmit(onSubmitText)

                Button("Send", action: onSubmitText)
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .foregroundStyle(.white)
        .cardStyle()
    }
}

private struct EmergencyButton: View {
    let title: String
    let detail: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.system(size: 18, weight: .black))
                    Text(detail)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.86))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(Color(red: 0.03, green: 0.18, blue: 0.29))
                    .frame(width: 36, height: 36)
                    .background(Color(red: 0.88, green: 0.96, blue: 1), in: Circle())
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(color, in: RoundedRectangle(cornerRadius: 15))
            .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.white.opacity(0.16), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
    }
}

private struct BreathMark: View {
    var body: some View {
        ZStack {
            Circle().fill(Color(red: 0.88, green: 0.96, blue: 1))
            Circle().stroke(Color(red: 0.22, green: 0.74, blue: 0.97), lineWidth: 6)
            Circle().fill(Color(red: 0.86, green: 0.15, blue: 0.15)).frame(width: 12, height: 12)
        }
        .frame(width: 36, height: 36)
    }
}

private struct GridPattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let spacing: CGFloat = 46

        stride(from: rect.minX, through: rect.maxX, by: spacing).forEach { x in
            path.move(to: CGPoint(x: x, y: rect.minY))
            path.addLine(to: CGPoint(x: x, y: rect.maxY))
        }

        stride(from: rect.minY, through: rect.maxY, by: spacing).forEach { y in
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: y))
        }

        return path
    }
}

private extension View {
    func cardStyle() -> some View {
        padding(16)
            .background(Color(red: 0.06, green: 0.09, blue: 0.16).opacity(0.94), in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.12), lineWidth: 1))
    }
}

private struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .black))
            .frame(maxWidth: .infinity, minHeight: 46)
            .padding(.horizontal, 12)
            .background(Color(red: 0.88, green: 0.96, blue: 1).opacity(configuration.isPressed ? 0.82 : 1), in: RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(Color(red: 0.03, green: 0.18, blue: 0.29))
    }
}

private struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .black))
            .frame(maxWidth: .infinity, minHeight: 46)
            .padding(.horizontal, 12)
            .background(Color.white.opacity(configuration.isPressed ? 0.10 : 0.06), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.18), lineWidth: 1))
            .foregroundStyle(Color(red: 0.84, green: 0.94, blue: 1))
    }
}

private struct DangerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .black))
            .frame(maxWidth: .infinity, minHeight: 46)
            .padding(.horizontal, 12)
            .background(Color(red: 0.86, green: 0.15, blue: 0.15).opacity(configuration.isPressed ? 0.82 : 1), in: RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(.white)
    }
}

#Preview {
    ContentView()
}
