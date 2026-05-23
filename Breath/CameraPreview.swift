import AVFoundation
import SwiftUI

enum CameraStatus {
    case idle
    case requesting
    case live
    case failed

    var displayLabel: String {
        switch self {
        case .idle, .failed:
            return "Guided mode"
        case .requesting:
            return "Camera request"
        case .live:
            return "Camera live"
        }
    }
}

final class CameraSessionController: ObservableObject {
    @Published var status: CameraStatus = .idle

    let session = AVCaptureSession()
    private let queue = DispatchQueue(label: "breath.camera.session")
    private var configured = false

    func start() {
        guard status != .live else { return }
        status = .requesting

        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            guard let self else { return }

            if !granted {
                DispatchQueue.main.async {
                    self.status = .failed
                }
                return
            }

            queue.async {
                self.configureIfNeeded()
                self.session.startRunning()
                DispatchQueue.main.async {
                    self.status = self.session.isRunning ? .live : .failed
                }
            }
        }
    }

    func stop() {
        queue.async {
            if self.session.isRunning {
                self.session.stopRunning()
            }
            DispatchQueue.main.async {
                self.status = .idle
            }
        }
    }

    private func configureIfNeeded() {
        guard !configured else { return }

        session.beginConfiguration()
        session.sessionPreset = .high

        defer {
            session.commitConfiguration()
            configured = true
        }

        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else {
            return
        }

        session.addInput(input)
    }
}

struct CameraPreview: UIViewRepresentable {
    @ObservedObject var controller: CameraSessionController

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = controller.session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.previewLayer.session = controller.session
    }

    final class PreviewView: UIView {
        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }

        var previewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }
    }
}
