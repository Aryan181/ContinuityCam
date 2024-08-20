//
//  HandPoseProcessor.swift
//  Continuity Camera Sample
//
//  Created by Aryan Mahindra
//  Copyright © 2023 Your Organization. All rights reserved.
//

import Vision
import SwiftUI
import AppKit

/// A class responsible for processing hand pose observations and controlling the cursor.
class HandPoseProcessor: ObservableObject {
    // MARK: - Published Properties
    
    /// Indicates whether the cursor control is currently active.
    @Published var isCursorControlActive = false
    
    /// The current position of the cursor, normalized to [0, 1] range.
    @Published var cursorPosition: CGPoint = .zero
    
    // MARK: - Private Properties
    
    /// The position where the pinch gesture started.
    private var pinchStartPosition: CGPoint?
    
    /// The cursor position when the pinch gesture started.
    private var cursorStartPosition: CGPoint = .zero
    
    /// The threshold distance between thumb and index finger to activate/deactivate the cursor control.
    private let pinchThreshold: CGFloat = 0.05
    
    /// Sensitivity factor for cursor movement.
    private let sensitivity: CGFloat = 1.2  // Adjusted for more natural movement
    
    /// Small dead zone to prevent unintended movements.
    private let deadZone: CGFloat = 0.001
    
    /// Enum to represent the current state of the trackpad simulation.
    private enum TrackpadState {
        case inactive, active
    }
    
    /// The current state of the trackpad simulation.
    private var trackpadState: TrackpadState = .inactive
    
    // MARK: - Public Methods
    
    /// Processes a hand pose observation to control the cursor.
    /// - Parameter observation: The VNHumanHandPoseObservation to process.
    func processHandPose(_ observation: VNHumanHandPoseObservation) {
        guard let indexTip = try? observation.recognizedPoints(.indexFinger)[.indexTip],
              let thumbTip = try? observation.recognizedPoints(.thumb)[.thumbTip] else {
            deactivateTrackpad()
            return
        }
        
        guard indexTip.confidence > 0.7 && thumbTip.confidence > 0.7 else {
            deactivateTrackpad()
            return
        }
        
        let indexPosition = CGPoint(x: indexTip.location.x, y: indexTip.location.y)
        let thumbPosition = CGPoint(x: thumbTip.location.x, y: thumbTip.location.y)
        
        let pinchDistance = indexPosition.distance(to: thumbPosition)
        
        switch trackpadState {
        case .inactive:
            if pinchDistance < pinchThreshold {
                activateTrackpad(at: indexPosition)
            }
        case .active:
            if pinchDistance > pinchThreshold {
                deactivateTrackpad()
            } else {
                updateCursorPosition(indexPosition)
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Activates the trackpad simulation at the given position.
    /// - Parameter position: The position where the trackpad is activated.
    private func activateTrackpad(at position: CGPoint) {
        trackpadState = .active
        pinchStartPosition = position
        cursorStartPosition = cursorPosition
        isCursorControlActive = true
    }
    
    /// Deactivates the trackpad simulation.
    private func deactivateTrackpad() {
        trackpadState = .inactive
        pinchStartPosition = nil
        isCursorControlActive = false
    }
    
    /// Updates the cursor position based on the current hand position.
    /// - Parameter currentPosition: The current position of the hand.
    private func updateCursorPosition(_ currentPosition: CGPoint) {
        guard let startPosition = pinchStartPosition else { return }
        
        let deltaX = (currentPosition.x - startPosition.x) * sensitivity
        let deltaY = (currentPosition.y - startPosition.y) * sensitivity
        
        // Apply dead zone
        if abs(deltaX) < deadZone && abs(deltaY) < deadZone {
            return
        }
        
        let newX = cursorStartPosition.x + deltaX
        let newY = cursorStartPosition.y - deltaY // Invert Y-axis
        
        cursorPosition = CGPoint(
            x: max(0, min(newX, 1)),
            y: max(0, min(newY, 1))
        )
        
        moveCursor()
    }
    
    /// Moves the system cursor to the calculated position.
    private func moveCursor() {
        let screenFrame = NSScreen.main?.frame ?? .zero
        let cursorX = cursorPosition.x * screenFrame.width
        let cursorY = cursorPosition.y * screenFrame.height
        
        CGWarpMouseCursorPosition(CGPoint(x: cursorX, y: cursorY))
    }
}

// MARK: - CGPoint Extension

extension CGPoint {
    /// Calculates the distance between two points.
    /// - Parameter point: The point to calculate the distance to.
    /// - Returns: The distance between the two points.
    func distance(to point: CGPoint) -> CGFloat {
        return sqrt(pow(x - point.x, 2) + pow(y - point.y, 2))
    }
}
