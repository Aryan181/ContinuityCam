import Foundation
import AVFoundation
import Combine
import Vision
import CoreImage

/// Main class responsible for managing camera operations, including device setup, session management, and video processing.
@MainActor
class Camera: NSObject, ObservableObject {
    
    // MARK: - Nested Types
    
    enum Error: Swift.Error {
        case noVideoDeviceAvailable
        case noAudioDeviceAvailable
        case setupFailed
    }
    
    enum State: @unchecked Sendable {
        case unknown
        case unauthorized
        case failed
        case running
        case stopped
    }
    
    // MARK: - Properties
    
    private(set) var isSetup = false
    private(set) var isAuthorized = false
    private(set) var isRunning = false
    
    private let session = AVCaptureSession()
    
    private var activeVideoInput: AVCaptureDeviceInput? {
        didSet {
            guard let device = activeVideoInput?.device else { return }
            updateVideoFormats(for: device)
            updateVideoEffectsState(for: device)
            if device.uniqueID != selectedVideoDevice.id {
                selectedVideoDevice = Device(id: device.uniqueID, name: device.localizedName)
            }
        }
    }
    private var activeAudioInput: AVCaptureDeviceInput? {
        didSet {
            guard let device = activeAudioInput?.device, device.uniqueID != selectedVideoDevice.id else { return }
            selectedAudioDevice = Device(id: device.uniqueID, name: device.localizedName)
        }
    }
    
    private var videoDiscoverySession: AVCaptureDevice.DiscoverySession!
    private var audioDiscoverySession: AVCaptureDevice.DiscoverySession!
    
    private let preferredCameraObserver = PreferredCameraObserver()
    private let videoEffectsObserver = VideoEffectsObserver()
    
    private var subscriptions = Set<AnyCancellable>()
    
    @Published private(set) var state = State.unknown
    @Published var isAutomaticCameraSelectionEnabled = true
    @Published private(set) var videoDevices = [Device]()
    @Published private(set) var audioDevices = [Device]()
    @Published private(set) var videoFormats = [VideoFormat]()
    @Published var selectedVideoDevice = Device.invalid
    @Published var selectedAudioDevice = Device.invalid
    @Published var selectedVideoFormat = VideoFormat.invalid
    @Published private(set) var isCenterStageSupported = false
    @Published var isCenterStageEnabled = false {
        didSet {
            guard isCenterStageEnabled != AVCaptureDevice.isCenterStageEnabled else { return }
            AVCaptureDevice.centerStageControlMode = .cooperative
            AVCaptureDevice.isCenterStageEnabled = isCenterStageEnabled
        }
    }
    @Published private(set) var isPortraitEffectSupported = false
    @Published private(set) var isPortraitEffectEnabled = false
    @Published private(set) var isStudioLightSupported = false
    @Published private(set) var isStudioLightEnabled = false
    
    lazy var preview: CameraPreview = {
        CameraPreview(session: session)
    }()
    
    private var videoOutput: AVCaptureVideoDataOutput?
    private var handPoseRequest = VNDetectHumanHandPoseRequest()
    @Published var handPoseProcessor = HandPoseProcessor()
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupObservers()
    }
    
    // MARK: - Public Methods
    
    /// Starts the camera session after authorization.
    func start() async {
        guard await authorize() else {
            self.state = .unauthorized
            return
        }
        do {
            try setup()
            startSession()
        } catch {
            state = .failed
        }
    }
    
    // MARK: - Private Methods
    
    private func setupObservers() {
        preferredCameraObserver.$systemPreferredCamera.dropFirst().removeDuplicates().compactMap({ $0 }).sink { [weak self] captureDevice in
            guard let self = self, self.isSetup else { return }
            Task { await self.systemPreferredCameraChanged(to: captureDevice) }
        }.store(in: &subscriptions)
        
        videoEffectsObserver.$isCenterStageEnabled.receive(on: RunLoop.main).assign(to: \.isCenterStageEnabled, on: self).store(in: &subscriptions)
        videoEffectsObserver.$isPortraitEffectEnabled.receive(on: RunLoop.main).assign(to: \.isPortraitEffectEnabled, on: self).store(in: &subscriptions)
        videoEffectsObserver.$isStudioLightEnabled.receive(on: RunLoop.main).assign(to: \.isStudioLightEnabled, on: self).store(in: &subscriptions)
        
        $selectedVideoDevice.merge(with: $selectedAudioDevice).dropFirst().removeDuplicates().sink { [weak self] device in
            guard let self = self, self.isSetup else { return }
            self.selectDevice(device)
        }.store(in: &subscriptions)
        
        $selectedVideoFormat.dropFirst().sink { [weak self] format in
            self?.selectFormat(format)
        }.store(in: &subscriptions)
        
        $isAutomaticCameraSelectionEnabled.sink { [weak self] isEnabled in
            guard isEnabled, let systemPreferredCamera = AVCaptureDevice.systemPreferredCamera else { return }
            Task { await self?.selectCaptureDevice(systemPreferredCamera) }
        }.store(in: &subscriptions)
    }
    
    private func authorize() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        isAuthorized = status == .authorized
        if status == .notDetermined {
            isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
        }
        return isAuthorized
    }
    
    private func setup() throws {
        guard !isSetup else { return }
        
        setupDeviceDiscovery()
        
        session.beginConfiguration()
        
        session.sessionPreset = .high
        try setupInputs()
        
        session.commitConfiguration()
        isSetup = true
    }
    
    private func setupDeviceDiscovery() {
        videoDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .externalUnknown],
                                                                 mediaType: .video,
                                                                 position: .unspecified)
        audioDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInMicrophone, .externalUnknown],
                                                                 mediaType: .audio,
                                                                 position: .unspecified)
        videoDiscoverySession.publisher(for: \.devices).sink { devices in
            self.videoDevices = devices.map { Device(id: $0.uniqueID, name: $0.localizedName) }
        }.store(in: &subscriptions)
        
        audioDiscoverySession.publisher(for: \.devices).sink { devices in
            self.audioDevices = devices.map { Device(id: $0.uniqueID, name: $0.localizedName) }
        }.store(in: &subscriptions)
    }
    
    private func setupInputs() throws {
        let videoCaptureDevice = try defaultVideoCaptureDevice
        activeVideoInput = try addInput(for: videoCaptureDevice)
        
        isCenterStageEnabled = videoCaptureDevice.isCenterStageActive
        isPortraitEffectEnabled = videoCaptureDevice.isPortraitEffectActive
        isStudioLightEnabled = videoCaptureDevice.isStudioLightActive
        
        let audioDevice = try defaultAudioCaptureDevice
        activeAudioInput = try addInput(for: audioDevice)
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoProcessingQueue"))
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }
        self.videoOutput = videoOutput

        handPoseRequest.maximumHandCount = 1
    }
    
    private var defaultVideoCaptureDevice: AVCaptureDevice {
        get throws {
            if let device = AVCaptureDevice.systemPreferredCamera {
                return device
            } else {
                throw Error.noVideoDeviceAvailable
            }
        }
    }
    
    private var defaultAudioCaptureDevice: AVCaptureDevice {
        get throws {
            guard let audioDevice = audioDiscoverySession.devices.first else {
                throw Error.noAudioDeviceAvailable
            }
            return audioDevice
        }
    }
    
    private func addInput(for device: AVCaptureDevice) throws -> AVCaptureDeviceInput {
        let input = try AVCaptureDeviceInput(device: device)
        if session.canAddInput(input) {
            session.addInput(input)
        } else {
            throw Error.setupFailed
        }
        return input
    }
    
    private func resetToDefaultDevices() {
        session.beginConfiguration()
        defer {
            session.commitConfiguration()
        }
        session.inputs.forEach { input in
            session.removeInput(input)
        }
        do {
            try setupInputs()
        } catch {
            print(error)
        }
    }
    
    private func startSession() {
        Task.detached(priority: .userInitiated) {
            guard await !self.isRunning else { return }
            self.session.startRunning()
            await MainActor.run {
                self.isRunning = self.session.isRunning
                self.state = .running
            }
        }
    }
    
    private func selectDevice(_ device: Device) {
        Task {
            let captureDevice = findCaptureDevice(for: device)
            await selectCaptureDevice(captureDevice, isUserSelection: true)
        }
    }
    
    private func findCaptureDevice(for device: Device) -> AVCaptureDevice {
        let allDevices = videoDiscoverySession.devices + audioDiscoverySession.devices
        guard let device = allDevices.first(where: { $0.uniqueID == device.id }) else {
            fatalError("Couldn't find capture device for Device selection.")
        }
        return device
    }
    
    private func systemPreferredCameraChanged(to captureDevice: AVCaptureDevice) async {
        guard isActiveVideoInputDeviceConnected else {
            resetToDefaultDevices()
            return
        }
        
        if isAutomaticCameraSelectionEnabled {
            await selectCaptureDevice(captureDevice)
        }
    }
    
    private var isActiveVideoInputDeviceConnected: Bool {
        activeVideoInput?.device.isConnected ?? false
    }
    
    private func selectCaptureDevice(_ device: AVCaptureDevice, isUserSelection: Bool = false) async {
        guard activeVideoInput?.device != device, activeAudioInput?.device != device else { return }
        
        let mediaType = device.hasMediaType(.video) ? AVMediaType.video : .audio
        guard let currentInput = mediaType == .video ? activeVideoInput : activeAudioInput else { return }
        
        session.beginConfiguration()
        defer {
            session.commitConfiguration()
        }
        
        do {
            session.removeInput(currentInput)
            
            let newInput = try addInput(for: device)
            
            if mediaType == .video {
                activeVideoInput = newInput
                if isUserSelection {
                    AVCaptureDevice.userPreferredCamera = device
                }
            } else {
                activeAudioInput = newInput
            }
        } catch {
            session.addInput(currentInput)
        }
    }
    
    private func selectFormat(_ format: VideoFormat) {
        guard let device = activeVideoInput?.device,
              let newFormat = device.formats.first(where: { $0.formatName == format.name }) else { return }
        do {
            try device.lockForConfiguration()
            device.activeFormat = newFormat
            device.unlockForConfiguration()
        } catch {
            print("Error setting format")
        }
    }
    
    private func updateVideoFormats(for captureDevice: AVCaptureDevice) {
        videoFormats = captureDevice.formats.compactMap { format in
            VideoFormat(id: format.formatName, name: format.formatName)
        }
        selectedVideoFormat = videoFormats.first(where: { $0.name == captureDevice.activeFormat.formatName }) ?? VideoFormat.invalid
        isCenterStageSupported = captureDevice.activeFormat.isCenterStageSupported
    }
    
    private func updateVideoEffectsState(for captureDevice: AVCaptureDevice) {
        let format = captureDevice.activeFormat
        isCenterStageSupported = format.isCenterStageSupported
        isPortraitEffectSupported = format.isPortraitEffectSupported
        isStudioLightSupported = format.isStudioLightSupported
        
        isCenterStageEnabled = AVCaptureDevice.isCenterStageEnabled
        isPortraitEffectEnabled = AVCaptureDevice.isPortraitEffectEnabled
        isStudioLightEnabled = AVCaptureDevice.isStudioLightEnabled
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension Camera: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        do {
            try handler.perform([handPoseRequest])
            if let results = handPoseRequest.results, !results.isEmpty {
                DispatchQueue.main.async {
                    self.handPoseProcessor.processHandPose(results[0])
                }
            }
        } catch {
            print("Failed to perform hand pose detection: \(error)")
        }
    }
}

// MARK: - Supporting Types

struct Device: Hashable, Identifiable {
    static let invalid = Device(id: "-1", name: "No camera available")
    let id: String
    let name: String
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

struct VideoFormat: Hashable, Identifiable {
    static let invalid = VideoFormat(id: "-1", name: "invalid")
    let id: String
    let name: String
}

extension AVCaptureDevice.Format {
    var formatName: String {
        let size = formatDescription.dimensions
        guard let formatName = formatDescription.extensions[.formatName]?.propertyListRepresentation as? String else {
            return "Unnamed \(size.width) x \(size.height)"
        }
        return "\(formatName), \(size.width) x \(size.height)"
    }
}
