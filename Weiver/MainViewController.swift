//
//  MainViewController.swift
//  Weiver
//
//  Created by Nikita Elizarov on 01.07.2019.
//  Copyright © 2019 Nikita Elizarov. All rights reserved.
//

import UIKit
import AVFoundation
import Speech
import SwiftyWave
import Sica
import Vision
import CoreGraphics


class MainViewController: UIViewController, SFSpeechRecognizerDelegate {

    // MARK: Outlets
    @IBOutlet weak var weiverMainImage: UIImageView!
    @IBOutlet weak var voiceToTextField: UITextView!
    @IBOutlet weak var swiftyWaves: SwiftyWaveView!
    @IBOutlet weak var previewView: UIView?

    // MARK: Properties
    private let speechSynthesizer = AVSpeechSynthesizer()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()


    //MARK: Resources
    private let networkManager = NetworkManager()
    private let beginRecordingSoundID: SystemSoundID = 1115
    private let endRecordingSoundID: SystemSoundID = 1116
    private var finalText: String?
    private var objPlayer: AVAudioPlayer?
    private var timer:Timer?
    private var recordInProcess = false
    private var playAudio = false
    private var speakForFirstTime = true
    private var introductionIsOn = true

    // AVCapture variables to hold sequence data
    var session: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?

    var videoDataOutput: AVCaptureVideoDataOutput?
    var videoDataOutputQueue: DispatchQueue?

    var captureDevice: AVCaptureDevice?
    var captureDeviceResolution: CGSize = CGSize()

    var currentFaceWidth: CGFloat?

    // Layer UI for drawing Vision results
    var rootLayer: CALayer?
    var detectionOverlayLayer: CALayer?
    var detectedFaceRectangleShapeLayer: CAShapeLayer?
    var detectedFaceLandmarksShapeLayer: CAShapeLayer?

    // Vision requests
    private var detectionRequests: [VNDetectFaceRectanglesRequest]?
    private var trackingRequests: [VNTrackObjectRequest]?

    lazy var sequenceRequestHandler = VNSequenceRequestHandler()

    //MARK: - View cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        speechSynthesizer.delegate = self
        
        self.session = self.setupAVCaptureSession()

        self.prepareVisionRequest()

        self.session?.startRunning()

        swiftyWaves.alpha = 0.0
        voiceToTextField.alpha = 0.0
    }

    //MARK: - Animations
    func animateIdleWeiverLeft(view:UIView, state: Bool) {
        let animator = Animator(view: view)
        if state {
            animator
                .addBasicAnimation(keyPath: .positionX, from: 500, to: 0, duration: 1)
                .run(type: .sequence)
        } else {
            animator.removeAll()
        }
    }
    func animateIdleWeiver(view: UIView, state: Bool) {
        let animator = Animator(view: view)
        if state {
        animator
            .addBasicAnimation(keyPath: .transformRotationZ, from: 0, to: -0.25, duration: 1, delay: 0)
            .addBasicAnimation(keyPath: .transformRotationZ, from: -0.25, to: 0, duration: 1, delay: 0)
            .addBasicAnimation(keyPath: .transformRotationZ, from: 0, to: 0.25, duration: 1, delay : 0)
            .addBasicAnimation(keyPath: .transformRotationZ, from: 0.25, to: 0, duration: 1, delay : 0)
            .addBasicAnimation(keyPath: .transformRotationZ, from: 0, to: -0.25, duration: 1, delay: 0)
            .addBasicAnimation(keyPath: .transformRotationZ, from: -0.25, to: 0, duration: 1, delay: 0)
            .addBasicAnimation(keyPath: .transformRotationZ, from: 0, to: 0.25, duration: 1, delay: 0)
            .addBasicAnimation(keyPath: .transformRotationZ, from: 0.25, to: 0, duration: 1, delay : 0)
            .forever(autoreverses: true)
            .run(type: .sequence)
        } else {
            animator.removeAll()
        }
    }

    func animateTalkingWeiver(view: UIView, state: Bool) {
        let animator = Animator(view: view)
        if state {
            animator
                .addBasicAnimation(keyPath: .positionY, from: 200, to: 250, duration: 0.5)
                .forever(autoreverses: true)
                .run(type: .parallel)
        } else {
            animator.removeAll()
        }
    }

    func animateKnockingWeiver(view: UIView, state: Bool) {
        let animator = Animator(view: view)
        if state {
            animator
            .addBasicAnimation(keyPath: .positionX, from: 0, to: 100, duration: 0.5)
            .addBasicAnimation(keyPath: .transformRotationZ, from: 0, to: 0.5, duration: 0.5)
            .forever(autoreverses: true)
            .run(type: .parallel)

        } else {
            animator.removeAll()
        }
    }

    func animateKnockicngWeiverReverse(view: UIView, state: Bool) {
        let animator = Animator(view: view)
        if state {
            animator
                .addBasicAnimation(keyPath: .positionX, from: 0, to: -1000, duration: 0.5)
                .addBasicAnimation(keyPath: .transformRotationZ, from: 0.5, to: 0, duration: 0.5)
                .run(type: .parallel)

        } else {
            animator.removeAll()
        }
    }

    func animateListeningWeiver(view: UIView, state: Bool) {
        let animator = Animator(view: view)
        if state {
            animator
                .addBasicAnimation(keyPath: .positionX, from: 400, to: 500, duration: 0.5)
                .addBasicAnimation(keyPath: .transformRotationZ, from: 0, to: 0.5, duration: 0.5)
                .run(type: .parallel)

        } else {
            animator.removeAll()
                animator
                    .addBasicAnimation(keyPath: .positionX, from: 500, to: -400, duration: 0.5)
                    .addBasicAnimation(keyPath: .transformRotationZ, from: 0, to: 0.5, duration: 0.5)
                    .run(type: .parallel)
        }
    }

    func temp(width: CGFloat) {
        if width > CGFloat(0.02) {
            timer?.invalidate()
            if introductionIsOn == true {
            if !playAudio {

                playAudio = true
                animateIdleWeiver(view: weiverMainImage, state: false)
                animateKnockingWeiver(view: weiverMainImage, state: true)

                playAudioFile(4.0)

            }
                timer = Timer.scheduledTimer(withTimeInterval: 6, repeats: false) { (_) in
                self.animateKnockingWeiver(view: self.weiverMainImage, state: false)

                self.animateIdleWeiver(view: self.weiverMainImage, state: true)
                }
            }
        }
        if width > CGFloat(0.4) {
            if !recordInProcess {
                introductionIsOn = false
                animateKnockingWeiver(view: weiverMainImage, state: false)
                animateIdleWeiver(view: weiverMainImage, state: true)

                if speakForFirstTime {
                    greetUser()
                } else {
                    if self.recordInProcess == false {
                        self.recordStart()
                        self.recordInProcess = true
                    }
                }
            }
        }
    }

    func greetUser() {
        timer?.invalidate()
        AudioServicesPlaySystemSound (self.beginRecordingSoundID)
        speakForFirstTime = false

        recordInProcess = true
        voiceToTextField.fadeOut()
        voiceToTextField.text = "Hello there, my name is Weiver, I help running this place, mind sharing a few thoughts about our place?"
        voiceToTextField.fadeIn()

        textToSpeech(text: "Hello there, my name is Weiver, I help running this place, mind sharing a few thoughts about our place?")

        timer = Timer.scheduledTimer(withTimeInterval: 7, repeats: false) { (_) in
            if self.recordInProcess == false {
                self.recordStart()
                self.recordInProcess = true
            }
        }
    }


    func playAudioFile(_ interval: Double) {

        timer?.invalidate()

        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { (_) in
            AudioServicesPlaySystemSound (self.beginRecordingSoundID)
        }

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { (_) in
            AudioServicesPlaySystemSound (self.beginRecordingSoundID)
        }

        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { (_) in
            self.playAudio = false
        }
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

//        animateIdleWeiver(view: weiverMainImage, state: true)
            animateIdleWeiverLeft(view: weiverMainImage, state: true)
//        animateKnockingWeiver(view: weiverMainImage, state: true)
//        animateTalkingWeiver(view: weiverMainImage, state: true)
//        animateListeningWeiver(view: weiverMainImage, state: true)

        // Configure the SFSpeechRecognizer object already
        // stored in a local member variable.

        audioEngine.stop()
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.playback)
            try audioSession.setMode(AVAudioSession.Mode.default)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }

        speechRecognizer.delegate = self

    }

    //MARK: - Voice Generation
    func generateVoiceFromText(text: String) {
        let speechUtterance: AVSpeechUtterance = AVSpeechUtterance(string: text)
        speechUtterance.rate = AVSpeechUtteranceMaximumSpeechRate / 2.2
        speechUtterance.voice = AVSpeechSynthesisVoice(language: "en-gb")
        speechSynthesizer.speak(speechUtterance)
    }

    //MARK: - Audio timer
    private func startRecordingAudio() { createTimer(12) }

    private func whileRecordingAudio() { createTimer(2) }

    private func setTimer(_ interval: Double, function: () ) {
        timer?.invalidate()

        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { (_) in
                function
        }
    }

    private func createTimer(_ interval:Double) {

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { (_) in
            if self.audioEngine.isRunning {
                self.audioRecordingIsRunning(status: false)
            }
        }
    }

    //MARK: - Audio recording
    private func startRecording() throws {

        // Cancel the previous task if it's running.
        recognitionTask?.cancel()
        self.recognitionTask = nil

        // Configure the audio session for the app.
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        let inputNode = audioEngine.inputNode

        // Create and configure the speech recognition request.
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { fatalError("Unable to create a SFSpeechAudioBufferRecognitionRequest object") }
        recognitionRequest.shouldReportPartialResults = true

        self.startRecordingAudio()

        // Create a recognition task for the speech recognition session.
        // Keep a reference to the task so that it can be canceled.
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false

            if let result = result {
                // Update the text view with the results.

                self.whileRecordingAudio()
                isFinal = result.isFinal

                self.finalText = result.bestTranscription.formattedString
            }

            if error != nil || isFinal {
                // Stop recognizing speech if there is a problem.
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)

                self.recognitionRequest = nil
                self.recognitionTask = nil

            }
        }

        // Configure the microphone input.
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        // Let the user know to start talking.

    }

    //MARK: - UI interactions

    func audioRecordingIsRunning(status : Bool) {
        if status {
            // Play recording sound
            let audioSession = AVAudioSession.sharedInstance()
            do {
                try audioSession.setCategory(AVAudioSession.Category.playback)
                try audioSession.setMode(AVAudioSession.Mode.default)
            } catch {
                print("audioSession properties weren't set because of an error.")
            }

            AudioServicesPlaySystemSound (beginRecordingSoundID)

            swiftyWaves.fadeIn()
            swiftyWaves.start()

            animateIdleWeiver(view: weiverMainImage, state: true)

        } else {
            // Play recording sound
            let audioSession = AVAudioSession.sharedInstance()
            do {
                try audioSession.setCategory(AVAudioSession.Category.playback)
                try audioSession.setMode(AVAudioSession.Mode.default)
            } catch {
                print("audioSession properties weren't set because of an error.")
            }
            audioEngine.stop()

            swiftyWaves.fadeOut()
            swiftyWaves.stop()

            audioEngine.stop()
            recognitionRequest?.endAudio()

            guard let text = finalText else {
                timer?.invalidate()
                timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { (_) in
                    self.recordInProcess = false
                }
                return
            }

            networkManager.postAnswer(text: text, placeId: "55.74833548.741747", completion: toText(text:), failure: errorToText)
        }
    }

    func errorToText() {
        animateTalkingWeiver(view: weiverMainImage, state: true)

        voiceToTextField.fadeOut()
        voiceToTextField.text = "Oops, sorry, didn't quite catch that, could you say it one more time?"
        voiceToTextField.fadeIn()

        audioEngine.stop()
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.playback)
            try audioSession.setMode(AVAudioSession.Mode.default)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }

        textToSpeech(text: voiceToTextField.text)
        let components = voiceToTextField.text.components(separatedBy: .whitespacesAndNewlines)
        let words = components.filter { !$0.isEmpty }

        print(words.count)

//        timer?.invalidate()
//        timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(words.count / 2), repeats: true) { (_) in
//            self.recordInProcess = false
//            self.animateTalkingWeiver(view: self.weiverMainImage, state: false)
//        }
    }

    func toText(text: String) {
        animateTalkingWeiver(view: weiverMainImage, state: true)
        voiceToTextField.fadeOut()
        voiceToTextField.text = text
        voiceToTextField.fadeIn()

        audioEngine.stop()
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.playback)
            try audioSession.setMode(AVAudioSession.Mode.default)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }

        textToSpeech(text: text)

//        let components = text.components(separatedBy: .whitespacesAndNewlines)
//        let words = components.filter { !$0.isEmpty }
//
//        print(words.count)

//        timer?.invalidate()
//        timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(words.count / 2), repeats: true) { (_) in
//                self.recordInProcess = false
//                self.animateTalkingWeiver(view: self.weiverMainImage, state: false)
//            }
    }

    // MARK: SFSpeechRecognizerDelegate
    public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
        } else {
        }
    }

    // MARK: Actions

    func recordStart() {
        if audioEngine.isRunning {
            audioRecordingIsRunning(status: false)
        } else {
            do {
                audioRecordingIsRunning(status: true)
                try startRecording()
            } catch {

            }
        }
    }

    func textToSpeech(text: String) {
        let speechUtterance: AVSpeechUtterance = AVSpeechUtterance(string: text)
        speechUtterance.rate = AVSpeechUtteranceMaximumSpeechRate / 1.9
        speechUtterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
        speechSynthesizer.speak(speechUtterance)
    }

}

extension MainViewController: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        print("FUCK")
        self.recordInProcess = false
        animateIdleWeiver(view: weiverMainImage, state: true)
        self.animateTalkingWeiver(view: self.weiverMainImage, state: false)
    }
}

extension MainViewController: AVCaptureVideoDataOutputSampleBufferDelegate{

    // Ensure that the interface stays locked in Portrait.
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    // Ensure that the interface stays locked in Portrait.
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }

    // MARK: AVCapture Setup

    /// - Tag: CreateCaptureSession
    fileprivate func setupAVCaptureSession() -> AVCaptureSession? {
        let captureSession = AVCaptureSession()
        do {
            let inputDevice = try self.configureFrontCamera(for: captureSession)
            self.configureVideoDataOutput(for: inputDevice.device, resolution: inputDevice.resolution, captureSession: captureSession)
            self.designatePreviewLayer(for: captureSession)
            return captureSession
        } catch let executionError as NSError {
            self.presentError(executionError)
        } catch {
            self.presentErrorAlert(message: "An unexpected failure has occured")
        }

        self.teardownAVCapture()

        return nil
    }

    /// - Tag: ConfigureDeviceResolution
    fileprivate func highestResolution420Format(for device: AVCaptureDevice) -> (format: AVCaptureDevice.Format, resolution: CGSize)? {
        var highestResolutionFormat: AVCaptureDevice.Format? = nil
        var highestResolutionDimensions = CMVideoDimensions(width: 0, height: 0)

        for format in device.formats {
            let deviceFormat = format as AVCaptureDevice.Format

            let deviceFormatDescription = deviceFormat.formatDescription
            if CMFormatDescriptionGetMediaSubType(deviceFormatDescription) == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange {
                let candidateDimensions = CMVideoFormatDescriptionGetDimensions(deviceFormatDescription)
                if (highestResolutionFormat == nil) || (candidateDimensions.width > highestResolutionDimensions.width) {
                    highestResolutionFormat = deviceFormat
                    highestResolutionDimensions = candidateDimensions
                }
            }
        }

        if highestResolutionFormat != nil {
            let resolution = CGSize(width: CGFloat(highestResolutionDimensions.width), height: CGFloat(highestResolutionDimensions.height))
            return (highestResolutionFormat!, resolution)
        }

        return nil
    }

    fileprivate func configureFrontCamera(for captureSession: AVCaptureSession) throws -> (device: AVCaptureDevice, resolution: CGSize) {
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .front)

        if let device = deviceDiscoverySession.devices.first {
            if let deviceInput = try? AVCaptureDeviceInput(device: device) {
                if captureSession.canAddInput(deviceInput) {
                    captureSession.addInput(deviceInput)
                }

                if let highestResolution = self.highestResolution420Format(for: device) {
                    try device.lockForConfiguration()
                    device.activeFormat = highestResolution.format
                    device.unlockForConfiguration()

                    return (device, highestResolution.resolution)
                }
            }
        }

        throw NSError(domain: "ViewController", code: 1, userInfo: nil)
    }

    /// - Tag: CreateSerialDispatchQueue
    fileprivate func configureVideoDataOutput(for inputDevice: AVCaptureDevice, resolution: CGSize, captureSession: AVCaptureSession) {

        let videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.alwaysDiscardsLateVideoFrames = true

        // Create a serial dispatch queue used for the sample buffer delegate as well as when a still image is captured.
        // A serial dispatch queue must be used to guarantee that video frames will be delivered in order.
        let videoDataOutputQueue = DispatchQueue(label: "com.example.apple-samplecode.VisionFaceTrack")
        videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)

        if captureSession.canAddOutput(videoDataOutput) {
            captureSession.addOutput(videoDataOutput)
        }

        videoDataOutput.connection(with: .video)?.isEnabled = true

        if let captureConnection = videoDataOutput.connection(with: AVMediaType.video) {
            if captureConnection.isCameraIntrinsicMatrixDeliverySupported {
                captureConnection.isCameraIntrinsicMatrixDeliveryEnabled = true
            }
        }

        self.videoDataOutput = videoDataOutput
        self.videoDataOutputQueue = videoDataOutputQueue

        self.captureDevice = inputDevice
        self.captureDeviceResolution = resolution
    }

    /// - Tag: DesignatePreviewLayer
    fileprivate func designatePreviewLayer(for captureSession: AVCaptureSession) {
        let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.previewLayer = videoPreviewLayer

        videoPreviewLayer.name = "CameraPreview"
        videoPreviewLayer.backgroundColor = UIColor.black.cgColor
        videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill

        if let previewRootLayer = self.previewView?.layer {
            self.rootLayer = previewRootLayer

            previewRootLayer.masksToBounds = true
            videoPreviewLayer.frame = previewRootLayer.bounds
        }
    }

    // Removes infrastructure for AVCapture as part of cleanup.
    fileprivate func teardownAVCapture() {
        self.videoDataOutput = nil
        self.videoDataOutputQueue = nil

        if let previewLayer = self.previewLayer {
            previewLayer.removeFromSuperlayer()
            self.previewLayer = nil
        }
    }

    // MARK: Helper Methods for Error Presentation

    fileprivate func presentErrorAlert(withTitle title: String = "Unexpected Failure", message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        self.present(alertController, animated: true)
    }

    fileprivate func presentError(_ error: NSError) {
        self.presentErrorAlert(withTitle: "Failed with error \(error.code)", message: error.localizedDescription)
    }

    // MARK: Helper Methods for Handling Device Orientation & EXIF

    fileprivate func radiansForDegrees(_ degrees: CGFloat) -> CGFloat {
        return CGFloat(Double(degrees) * Double.pi / 180.0)
    }

    func exifOrientationForDeviceOrientation(_ deviceOrientation: UIDeviceOrientation) -> CGImagePropertyOrientation {

        switch deviceOrientation {
        case .portraitUpsideDown:
            return .rightMirrored

        case .landscapeLeft:
            return .downMirrored

        case .landscapeRight:
            return .upMirrored

        default:
            return .leftMirrored
        }
    }

    func exifOrientationForCurrentDeviceOrientation() -> CGImagePropertyOrientation {
        return exifOrientationForDeviceOrientation(UIDevice.current.orientation)
    }

    // MARK: Performing Vision Requests

    /// - Tag: WriteCompletionHandler
    fileprivate func prepareVisionRequest() {

        //self.trackingRequests = []
        var requests = [VNTrackObjectRequest]()

        let faceDetectionRequest = VNDetectFaceRectanglesRequest(completionHandler: { (request, error) in

            if error != nil {
                print("FaceDetection error: \(String(describing: error)).")
            }

            guard let faceDetectionRequest = request as? VNDetectFaceRectanglesRequest,
                let results = faceDetectionRequest.results as? [VNFaceObservation] else {
                    return
            }
            DispatchQueue.main.async {
                // Add the observations to the tracking list
                for observation in results {
                    let faceTrackingRequest = VNTrackObjectRequest(detectedObjectObservation: observation)
                    requests.append(faceTrackingRequest)
                }
                self.trackingRequests = requests
            }
        })

        // Start with detection.  Find face, then track it.
        self.detectionRequests = [faceDetectionRequest]

        self.sequenceRequestHandler = VNSequenceRequestHandler()

        self.setupVisionDrawingLayers()
    }

    // MARK: Drawing Vision Observations

    fileprivate func setupVisionDrawingLayers() {
        let captureDeviceResolution = self.captureDeviceResolution

        let captureDeviceBounds = CGRect(x: 0,
                                         y: 0,
                                         width: captureDeviceResolution.width,
                                         height: captureDeviceResolution.height)

        let captureDeviceBoundsCenterPoint = CGPoint(x: captureDeviceBounds.midX,
                                                     y: captureDeviceBounds.midY)

        let normalizedCenterPoint = CGPoint(x: 0.5, y: 0.5)

        guard let rootLayer = self.rootLayer else {
            self.presentErrorAlert(message: "view was not property initialized")
            return
        }

        let overlayLayer = CALayer()
        overlayLayer.name = "DetectionOverlay"
        overlayLayer.masksToBounds = true
        overlayLayer.anchorPoint = normalizedCenterPoint
        overlayLayer.bounds = captureDeviceBounds
        overlayLayer.position = CGPoint(x: rootLayer.bounds.midX, y: rootLayer.bounds.midY)

        let faceRectangleShapeLayer = CAShapeLayer()
        faceRectangleShapeLayer.name = "RectangleOutlineLayer"
        faceRectangleShapeLayer.bounds = captureDeviceBounds
        faceRectangleShapeLayer.anchorPoint = normalizedCenterPoint
        faceRectangleShapeLayer.position = captureDeviceBoundsCenterPoint
        faceRectangleShapeLayer.fillColor = nil
        faceRectangleShapeLayer.strokeColor = UIColor.green.withAlphaComponent(0.7).cgColor
        faceRectangleShapeLayer.lineWidth = 5
        faceRectangleShapeLayer.shadowOpacity = 0.7
        faceRectangleShapeLayer.shadowRadius = 5

        let faceLandmarksShapeLayer = CAShapeLayer()
        faceLandmarksShapeLayer.name = "FaceLandmarksLayer"
        faceLandmarksShapeLayer.bounds = captureDeviceBounds
        faceLandmarksShapeLayer.anchorPoint = normalizedCenterPoint
        faceLandmarksShapeLayer.position = captureDeviceBoundsCenterPoint
        faceLandmarksShapeLayer.fillColor = nil
        faceLandmarksShapeLayer.lineWidth = 3
        faceLandmarksShapeLayer.shadowOpacity = 0.7
        faceLandmarksShapeLayer.shadowRadius = 5

        overlayLayer.addSublayer(faceRectangleShapeLayer)
        faceRectangleShapeLayer.addSublayer(faceLandmarksShapeLayer)
        rootLayer.addSublayer(overlayLayer)

        self.detectionOverlayLayer = overlayLayer
        self.detectedFaceRectangleShapeLayer = faceRectangleShapeLayer
        self.detectedFaceLandmarksShapeLayer = faceLandmarksShapeLayer

        self.updateLayerGeometry()
    }

    fileprivate func updateLayerGeometry() {
        guard let overlayLayer = self.detectionOverlayLayer,
            let rootLayer = self.rootLayer,
            let previewLayer = self.previewLayer
            else {
                return
        }

        CATransaction.setValue(NSNumber(value: true), forKey: kCATransactionDisableActions)

        let videoPreviewRect = previewLayer.layerRectConverted(fromMetadataOutputRect: CGRect(x: 0, y: 0, width: 1, height: 1))

        var rotation: CGFloat
        var scaleX: CGFloat
        var scaleY: CGFloat

        // Rotate the layer into screen orientation.
        switch UIDevice.current.orientation {
        case .portraitUpsideDown:
            rotation = 180
            scaleX = videoPreviewRect.width / captureDeviceResolution.width
            scaleY = videoPreviewRect.height / captureDeviceResolution.height

        case .landscapeLeft:
            rotation = 90
            scaleX = videoPreviewRect.height / captureDeviceResolution.width
            scaleY = scaleX

        case .landscapeRight:
            rotation = -90
            scaleX = videoPreviewRect.height / captureDeviceResolution.width
            scaleY = scaleX

        default:
            rotation = 0
            scaleX = videoPreviewRect.width / captureDeviceResolution.width
            scaleY = videoPreviewRect.height / captureDeviceResolution.height
        }

        // Scale and mirror the image to ensure upright presentation.
        let affineTransform = CGAffineTransform(rotationAngle: radiansForDegrees(rotation))
            .scaledBy(x: scaleX, y: -scaleY)
        overlayLayer.setAffineTransform(affineTransform)

        // Cover entire screen UI.
        let rootLayerBounds = rootLayer.bounds
        overlayLayer.position = CGPoint(x: rootLayerBounds.midX, y: rootLayerBounds.midY)
    }

    fileprivate func addPoints(in landmarkRegion: VNFaceLandmarkRegion2D, to path: CGMutablePath, applying affineTransform: CGAffineTransform, closingWhenComplete closePath: Bool) {
        let pointCount = landmarkRegion.pointCount
        if pointCount > 1 {
            let points: [CGPoint] = landmarkRegion.normalizedPoints
            path.move(to: points[0], transform: affineTransform)
            path.addLines(between: points, transform: affineTransform)
            if closePath {
                path.addLine(to: points[0], transform: affineTransform)
                path.closeSubpath()
            }
        }
    }

    fileprivate func addIndicators(to faceRectanglePath: CGMutablePath, faceLandmarksPath: CGMutablePath, for faceObservation: VNFaceObservation) {
        let displaySize = self.captureDeviceResolution

        _ = VNImageRectForNormalizedRect(faceObservation.boundingBox, Int(displaySize.width), Int(displaySize.height))


        print (faceObservation.boundingBox.width.description)

        temp(width: faceObservation.boundingBox.width)
        self.currentFaceWidth = faceObservation.boundingBox.width

    }

    /// - Tag: DrawPaths
    fileprivate func drawFaceObservations(_ faceObservations: [VNFaceObservation]) {
        guard let faceRectangleShapeLayer = self.detectedFaceRectangleShapeLayer,
            let faceLandmarksShapeLayer = self.detectedFaceLandmarksShapeLayer
            else {
                return
        }

        CATransaction.begin()

        CATransaction.setValue(NSNumber(value: true), forKey: kCATransactionDisableActions)

        let faceRectanglePath = CGMutablePath()
        let faceLandmarksPath = CGMutablePath()

        for faceObservation in faceObservations {
            self.addIndicators(to: faceRectanglePath,
                               faceLandmarksPath: faceLandmarksPath,
                               for: faceObservation)
        }

        faceRectangleShapeLayer.path = faceRectanglePath
        faceLandmarksShapeLayer.path = faceLandmarksPath

        self.updateLayerGeometry()

        CATransaction.commit()
    }

    // MARK: AVCaptureVideoDataOutputSampleBufferDelegate
    /// - Tag: PerformRequests
    // Handle delegate method callback on receiving a sample buffer.
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {

        if !self.recordInProcess {
        var requestHandlerOptions: [VNImageOption: AnyObject] = [:]

        let cameraIntrinsicData = CMGetAttachment(sampleBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil)
        if cameraIntrinsicData != nil {
            requestHandlerOptions[VNImageOption.cameraIntrinsics] = cameraIntrinsicData
        }

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("Failed to obtain a CVPixelBuffer for the current output frame.")
            return
        }

        let exifOrientation = self.exifOrientationForCurrentDeviceOrientation()

        guard let requests = self.trackingRequests, !requests.isEmpty else {
            // No tracking object detected, so perform initial detection
            let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                                            orientation: exifOrientation,
                                                            options: requestHandlerOptions)

            do {
                guard let detectRequests = self.detectionRequests else {
                    return
                }
                try imageRequestHandler.perform(detectRequests)
            } catch let error as NSError {
                NSLog("Failed to perform FaceRectangleRequest: %@", error)
            }
            return
        }

        do {
            try self.sequenceRequestHandler.perform(requests,
                                                    on: pixelBuffer,
                                                    orientation: exifOrientation)
        } catch let error as NSError {
            NSLog("Failed to perform SequenceRequest: %@", error)
        }

        // Setup the next round of tracking.
        var newTrackingRequests = [VNTrackObjectRequest]()
        for trackingRequest in requests {

            guard let results = trackingRequest.results else {
                return
            }

            guard let observation = results[0] as? VNDetectedObjectObservation else {
                return
            }

            if !trackingRequest.isLastFrame {
                if observation.confidence > 0.3 {
                    trackingRequest.inputObservation = observation
                } else {
                    trackingRequest.isLastFrame = true
                }
                newTrackingRequests.append(trackingRequest)
            }
        }
        self.trackingRequests = newTrackingRequests

        if newTrackingRequests.isEmpty {
            // Nothing to track, so abort.
            return
        }

        // Perform face landmark tracking on detected faces.
        var faceLandmarkRequests = [VNDetectFaceLandmarksRequest]()

        // Perform landmark detection on tracked faces.
        for trackingRequest in newTrackingRequests {

            let faceLandmarksRequest = VNDetectFaceLandmarksRequest(completionHandler: { (request, error) in

                if error != nil {
                    print("FaceLandmarks error: \(String(describing: error)).")
                }

                guard let landmarksRequest = request as? VNDetectFaceLandmarksRequest,
                    let results = landmarksRequest.results as? [VNFaceObservation] else {
                        return
                }

                // Perform all UI updates (drawing) on the main queue, not the background queue on which this handler is being called.
                    DispatchQueue.main.async {
                        self.drawFaceObservations(results)
                    }
            })

            guard let trackingResults = trackingRequest.results else {
                return
            }

            guard let observation = trackingResults[0] as? VNDetectedObjectObservation else {
                return
            }
            let faceObservation = VNFaceObservation(boundingBox: observation.boundingBox)
            faceLandmarksRequest.inputFaceObservations = [faceObservation]

            // Continue to track detected facial landmarks.
            faceLandmarkRequests.append(faceLandmarksRequest)

            let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                                            orientation: exifOrientation,
                                                            options: requestHandlerOptions)

            do {
                try imageRequestHandler.perform(faceLandmarkRequests)
            } catch let error as NSError {
                NSLog("Failed to perform FaceLandmarkRequest: %@", error)
            }
        }
        }
    }
}
