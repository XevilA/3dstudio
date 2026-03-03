import SwiftUI
import AVFoundation

struct QRScannerView: UIViewControllerRepresentable {
    @Binding var scannedRoomID: Int?
    @Binding var showingARStudio: Bool
    
    @Environment(\.presentationMode) var presentationMode
    
    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var parent: QRScannerView
        
        init(parent: QRScannerView) {
            self.parent = parent
        }
        
        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            if let metadataObject = metadataObjects.first {
                guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
                guard let stringValue = readableObject.stringValue else { return }
                
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                
                // Parse the QR code, assuming format "room:X"
                let prefix = "room:"
                if stringValue.hasPrefix(prefix) {
                    let idString = stringValue.dropFirst(prefix.count)
                    if let roomId = Int(idString), roomId >= 1, roomId <= 8 {
                        // Found a valid room ID!
                        DispatchQueue.main.async {
                            self.parent.scannedRoomID = roomId
                            self.parent.presentationMode.wrappedValue.dismiss()
                            
                            // Delay the AR view transition slightly to allow dismissal animation
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                self.parent.showingARStudio = true
                            }
                        }
                    } else {
                        print("Invalid room ID in QR: \(stringValue)")
                    }
                } else {
                    print("Unrecognized QR format: \(stringValue)")
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    func makeUIViewController(context: Context) -> ScannerViewController {
        let viewController = ScannerViewController()
        viewController.delegate = context.coordinator
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}
}

class ScannerViewController: UIViewController {
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var delegate: AVCaptureMetadataOutputObjectsDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.black
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            // Simulator fallback or no camera
            print("No video device found. (Are you on the Simulator?)")
            return
        }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            print("Error parsing video input: \(error)")
            return
        }
        
        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            failed()
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(delegate, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            failed()
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        // Add a scan area overlay
        setupOverlay()
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }
    
    func setupOverlay() {
        let overlayPath = UIBezierPath(rect: view.bounds)
        
        // Calculate center square
        let squareSize: CGFloat = 250
        let xOffset = (view.bounds.width - squareSize) / 2
        let yOffset = (view.bounds.height - squareSize) / 2
        let squareRect = CGRect(x: xOffset, y: yOffset, width: squareSize, height: squareSize)
        
        let transparentPath = UIBezierPath(roundedRect: squareRect, cornerRadius: 10)
        overlayPath.append(transparentPath)
        overlayPath.usesEvenOddFillRule = true
        
        let fillLayer = CAShapeLayer()
        fillLayer.path = overlayPath.cgPath
        fillLayer.fillRule = .evenOdd
        fillLayer.fillColor = UIColor.black.withAlphaComponent(0.6).cgColor
        
        view.layer.addSublayer(fillLayer)
        
        // Add corner brackets
        let bracketSize: CGFloat = 40
        let bracketLayer = CAShapeLayer()
        let bracketPath = UIBezierPath()
        
        // Top Left
        bracketPath.move(to: CGPoint(x: xOffset, y: yOffset + bracketSize))
        bracketPath.addLine(to: CGPoint(x: xOffset, y: yOffset))
        bracketPath.addLine(to: CGPoint(x: xOffset + bracketSize, y: yOffset))
        
        // Top Right
        bracketPath.move(to: CGPoint(x: xOffset + squareSize - bracketSize, y: yOffset))
        bracketPath.addLine(to: CGPoint(x: xOffset + squareSize, y: yOffset))
        bracketPath.addLine(to: CGPoint(x: xOffset + squareSize, y: yOffset + bracketSize))
        
        // Bottom Right
        bracketPath.move(to: CGPoint(x: xOffset + squareSize, y: yOffset + squareSize - bracketSize))
        bracketPath.addLine(to: CGPoint(x: xOffset + squareSize, y: yOffset + squareSize))
        bracketPath.addLine(to: CGPoint(x: xOffset + squareSize - bracketSize, y: yOffset + squareSize))
        
        // Bottom Left
        bracketPath.move(to: CGPoint(x: xOffset + bracketSize, y: yOffset + squareSize))
        bracketPath.addLine(to: CGPoint(x: xOffset, y: yOffset + squareSize))
        bracketPath.addLine(to: CGPoint(x: xOffset, y: yOffset + squareSize - bracketSize))
        
        bracketLayer.path = bracketPath.cgPath
        bracketLayer.strokeColor = UIColor(Color(hex: "FF6F00")).cgColor
        bracketLayer.lineWidth = 4
        bracketLayer.fillColor = UIColor.clear.cgColor
        
        view.layer.addSublayer(bracketLayer)
        
        // Add instruction text
        let label = UILabel(frame: CGRect(x: 0, y: yOffset + squareSize + 30, width: view.bounds.width, height: 30))
        label.text = "Align Studio QR Code within the frame"
        label.textColor = .white
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        view.addSubview(label)
    }
    
    func failed() {
        let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if (captureSession?.isRunning == false) {
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession.startRunning()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if (captureSession?.isRunning == true) {
            captureSession.stopRunning()
        }
    }
    
    // Support rotation
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { _ in
            if let connection = self.previewLayer?.connection, connection.isVideoOrientationSupported {
                let orientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation ?? .portrait
                if let videoOrientation = AVCaptureVideoOrientation(rawValue: orientation.rawValue) {
                    connection.videoOrientation = videoOrientation
                }
            }
            self.previewLayer?.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            
            // Note: In a production app, we would recalculate and update the custom overlay bounding box here too upon rotation.
            // For prototyping simplicity, omitting overlay redraw.
        })
    }
}
