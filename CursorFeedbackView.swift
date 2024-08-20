//
//  CursorFeedbackView.swift
//  Continuity Camera Sample
//
//  Created by Aryan Mahindra
//  Copyright © 2023 Your Organization. All rights reserved.
//

import SwiftUI

/// A SwiftUI view that provides visual feedback for the cursor position based on hand pose detection.
struct CursorFeedbackView: View {
    /// The hand pose processor that provides cursor position and state information.
    @ObservedObject var handPoseProcessor: HandPoseProcessor
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if handPoseProcessor.isCursorControlActive {
                    // Outer circle for cursor feedback
                    Circle()
                        .stroke(Color.green, lineWidth: 2)
                        .frame(width: 40, height: 40)
                        .position(
                            x: handPoseProcessor.cursorPosition.x * geometry.size.width,
                            y: handPoseProcessor.cursorPosition.y * geometry.size.height
                        )
                    
                    // Inner circle for precise cursor position
                    Circle()
                        .fill(Color.green.opacity(0.5))
                        .frame(width: 10, height: 10)
                        .position(
                            x: handPoseProcessor.cursorPosition.x * geometry.size.width,
                            y: handPoseProcessor.cursorPosition.y * geometry.size.height
                        )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0.1), value: handPoseProcessor.cursorPosition)
        }
    }
}

// MARK: - Preview

struct CursorFeedbackView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a mock HandPoseProcessor for preview purposes
        let mockProcessor = HandPoseProcessor()
        mockProcessor.isCursorControlActive = true
        mockProcessor.cursorPosition = CGPoint(x: 0.5, y: 0.5)
        
        return CursorFeedbackView(handPoseProcessor: mockProcessor)
            .frame(width: 300, height: 300)
            .previewLayout(.sizeThatFits)
    }
}
