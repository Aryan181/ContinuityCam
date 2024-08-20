//
//  DeviceObservers.swift
//  Continuity Camera Sample
//
//  Created by Aryan Mahindra
//  Copyright © 2023 Your Organization. All rights reserved.
//

import AVFoundation

// MARK: - VideoEffectsObserver

/// An observer class that monitors the state of video effects using Key-Value Observing (KVO).
class VideoEffectsObserver: NSObject, ObservableObject, @unchecked Sendable {
    
    // MARK: - Properties
    
    /// Key path for observing Center Stage effect
    private let centerStageKeyPath = "centerStageEnabled"
    
    /// Key path for observing Portrait effect
    private let portraitEffectKeyPath = "portraitEffectEnabled"
    
    /// Key path for observing Studio Light effect
    private let studioLightKeyPath = "studioLightEnabled"
    
    /// Published property indicating whether Center Stage is enabled
    @Published private(set) var isCenterStageEnabled = false
    
    /// Published property indicating whether Portrait effect is enabled
    @Published private(set) var isPortraitEffectEnabled = false
    
    /// Published property indicating whether Studio Light effect is enabled
    @Published private(set) var isStudioLightEnabled = false
    
    // MARK: - Initialization
    
    /// Initializes the VideoEffectsObserver and sets up KVO
    override init() {
        super.init()
        AVCaptureDevice.self.addObserver(self, forKeyPath: centerStageKeyPath, options: [.new], context: nil)
        AVCaptureDevice.self.addObserver(self, forKeyPath: portraitEffectKeyPath, options: [.new], context: nil)
        AVCaptureDevice.self.addObserver(self, forKeyPath: studioLightKeyPath, options: [.new], context: nil)
    }
    
    // MARK: - KVO
    
    /// Handles changes in observed properties
    /// - Parameters:
    ///   - keyPath: The key path of the property that changed
    ///   - object: The object that had the change
    ///   - change: A dictionary that describes the change
    ///   - context: The context pointer that was provided when the observer was registered
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        switch keyPath {
        case centerStageKeyPath:
            isCenterStageEnabled = AVCaptureDevice.isCenterStageEnabled
        case portraitEffectKeyPath:
            isPortraitEffectEnabled = AVCaptureDevice.isPortraitEffectEnabled
        case studioLightKeyPath:
            isStudioLightEnabled = AVCaptureDevice.isStudioLightEnabled
        default:
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}

// MARK: - PreferredCameraObserver

/// An observer class that monitors changes in the system's preferred camera.
class PreferredCameraObserver: NSObject, ObservableObject {
    
    // MARK: - Properties
    
    /// Key path for observing the system's preferred camera
    private let systemPreferredKeyPath = "systemPreferredCamera"
    
    /// Published property holding the current system-preferred camera
    @Published private(set) var systemPreferredCamera: AVCaptureDevice?
    
    // MARK: - Initialization
    
    /// Initializes the PreferredCameraObserver and sets up KVO
    override init() {
        super.init()
        // Key-value observe the `systemPreferredCamera` class property on `AVCaptureDevice`.
        AVCaptureDevice.self.addObserver(self, forKeyPath: systemPreferredKeyPath, options: [.new], context: nil)
    }
    
    // MARK: - KVO
    
    /// Handles changes in the system's preferred camera
    /// - Parameters:
    ///   - keyPath: The key path of the property that changed
    ///   - object: The object that had the change
    ///   - change: A dictionary that describes the change
    ///   - context: The context pointer that was provided when the observer was registered
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        switch keyPath {
        case systemPreferredKeyPath:
            // Update the observer's system-preferred camera value.
            systemPreferredCamera = change?[.newKey] as? AVCaptureDevice
        default:
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}
