//
//  CameraPreview.swift
//  Continuity Camera Sample
//
//  Created by Aryan Mahindra
//  Copyright © 2023 Your Organization. All rights reserved.
//

import SwiftUI
import AVFoundation

/// A SwiftUI view that provides a preview of the content the camera captures.
struct CameraPreview: NSViewRepresentable {
    // MARK: - Properties
    
    private let session: AVCaptureSession
    
    // MARK: - Initialization
    
    /// Initializes a new CameraPreview with the given AVCaptureSession.
    /// - Parameter session: The AVCaptureSession to use for the preview.
    init(session: AVCaptureSession) {
        self.session = session
    }
    
    // MARK: - NSViewRepresentable
    
    func makeNSView(context: Context) -> CaptureVideoPreview {
        CaptureVideoPreview(session: session)
    }
    
    func updateNSView(_ nsView: CaptureVideoPreview, context: Context) {
        // The view isn't configurable, so no updates are needed.
    }
}

/// A custom NSView that displays the camera preview.
class CaptureVideoPreview: NSView {
    // MARK: - Initialization
    
    /// Initializes a new CaptureVideoPreview with the given AVCaptureSession.
    /// - Parameter session: The AVCaptureSession to use for the preview.
    init(session: AVCaptureSession) {
        super.init(frame: .zero)
        setupPreviewLayer(with: session)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Private Methods
    
    private func setupPreviewLayer(with session: AVCaptureSession) {
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.connection?.automaticallyAdjustsVideoMirroring = false
        previewLayer.backgroundColor = .black
        
        // Make this a layer-hosting view.
        layer = previewLayer
        wantsLayer = true
    }
}
