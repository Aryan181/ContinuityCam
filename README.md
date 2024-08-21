# Continuity Camera Mouse Tracker

## Project Motivation

The **Continuity Camera Mouse Tracker** project aims to revolutionize computer interaction for individuals with physical limitations, particularly those suffering from *carpal tunnel syndrome*. By leveraging advanced camera technology and machine learning, we seek to **replace traditional physical input devices** with intuitive gesture controls.

### Objective

Our primary objective is to develop a system that uses *finger tracking and universal gesture control* to:
1. Replace the physical mouse
2. Perform keyboard shortcuts

This approach allows users to navigate their computers and execute complex commands without the need for traditional input devices, significantly reducing strain on hands and wrists.

### Target Audience

While our initial focus is on individuals with *carpal tunnel syndrome*, our ultimate goal is to broaden our user base to include:
- Designers
- Mechanical engineers working with CAD software
- Any professional who requires precise cursor control but struggles with traditional input devices

## Key Technological Exploits

1. **Low-Latency Camera Feed Streaming**: 
   - Utilizes an iPhone's camera feed
   - Streams data to a MacBook via Bluetooth with minimal latency

2. **Powerful On-Device Processing**:
   - Leverages the computational power of M1 chips in MacBooks
   - Runs sophisticated machine learning models for real-time hand tracking

3. **Future Enhancements**:
   - Potential to stream depth and infrared data from iPhone's TrueDepth camera
   - Aims to emulate and potentially surpass Ultraleap's hand tracking capabilities

## Project Architecture and Components

### 1. Camera Module (Camera.swift)
- Manages camera operations and video processing
- Utilizes AVFoundationKit for seamless camera access and control

### 2. Device Observers (DeviceObservers.swift)
- Monitors changes in camera effects and system preferences
- Implements Key-Value Observing (KVO) for real-time updates

### 3. Hand Pose Processor (HandPoseProcessor.swift)
- Utilizes Vision framework for hand pose detection
- Translates hand movements into cursor control and gesture commands

### 4. User Interface Components
- **CursorFeedbackView (CursorFeedbackView.swift)**: Provides visual feedback for cursor position
- **ContentView (ContentView.swift)**: Main SwiftUI view orchestrating the app's UI
- **CameraPreview (CameraPreview.swift)**: Displays real-time camera feed
- **ConfigurationView (ConfigurationView.swift)**: Allows users to configure camera and gesture settings

### 5. Utility Components
- **MaterialView (MaterialView.swift)**: Enhances UI with blurred, translucent effects
- **ContinuityCamApp (ContinuityCamApp.swift)**: Defines the main application structure

## Key Challenges and Solutions

1. **Real-time Hand Pose Detection**
   - *Challenge*: Accurate and efficient hand tracking in real-time
   - *Solution*: Implemented Vision framework's VNDetectHumanHandPoseRequest

2. **Gesture-to-Command Translation**
   - *Challenge*: Interpreting hand gestures as mouse movements and keyboard shortcuts
   - *Solution*: Developed a robust gesture recognition system in HandPoseProcessor.swift

3. **Low-Latency Video Streaming**
   - *Challenge*: Minimizing delay between iPhone camera and MacBook processing
   - *Solution*: Optimized Bluetooth data transfer and leveraged M1 chip's processing power

4. **Accessibility-Focused UI**
   - *Challenge*: Creating an interface usable by individuals with limited hand mobility
   - *Solution*: Designed an intuitive, gesture-controlled configuration interface

## Future Improvements

1. **Enhanced Gesture Recognition**: Implement more complex gestures for advanced controls
2. **Cross-Platform Support**: Extend functionality to iOS and iPadOS
3. **Depth and Infrared Integration**: Utilize TrueDepth camera data for more precise tracking
4. **Industry-Specific Modules**: Develop specialized gesture sets for CAD software, video editing, etc.
5. **Machine Learning Optimization**: Continuously improve hand tracking accuracy and efficiency

## Getting Started

To run this project:

1. Ensure you have Xcode 14.0 or later installed
2. Clone the repository
3. Open the `.xcodeproj` file in Xcode
4. Build and run the project on a Mac running macOS 13.0 or later
5. Connect an iPhone or iPad running iOS 16.0 or later to use as a Continuity Camera

*Note: This project requires a Mac with Apple Silicon or Intel processor and an iOS device compatible with the Continuity Camera feature.*


## Application Flow

The following flowchart illustrates the main function calls and their relationships from app launch to mouse movement:

```mermaid
flowchart TD
    A[App Launch] --> B[ContinuityCamApp.body]
    B --> C[ContentView.init]
    C --> D[Camera.init]
    C --> E[ContentView.body]
    E --> F[CameraPreview.init]
    E --> G[ConfigurationView.init]
    D --> H[Camera.start]
    H --> I[Camera.authorize]
    I --> J[Camera.setup]
    J --> K[Camera.setupDeviceDiscovery]
    J --> L[Camera.setupInputs]
    L --> M[Camera.addInput]
    L --> N[AVCaptureVideoDataOutput.setSampleBufferDelegate]
    H --> O[Camera.startSession]
    O --> P[AVCaptureSession.startRunning]
    N --> Q[Camera.captureOutput]
    Q --> R[VNImageRequestHandler.perform]
    R --> S[HandPoseProcessor.processHandPose]
    S --> T{Is pinch detected?}
    T -->|Yes| U[HandPoseProcessor.activateTrackpad]
    T -->|No| V[HandPoseProcessor.deactivateTrackpad]
    U --> W[HandPoseProcessor.updateCursorPosition]
    W --> X[HandPoseProcessor.moveCursor]
    X --> Y[CGWarpMouseCursorPosition]
```

This flowchart demonstrates how the app integrates various components to achieve hand gesture-based cursor control using the Continuity Camera feature.


 
## Vision Framework Process Flow

The following flowchart illustrates how the Vision framework is used in this app for hand pose detection and cursor control:

```mermaid
flowchart TD
    A[Camera Capture] -->|CMSampleBuffer| B[Extract CVPixelBuffer]
    B --> C[Create VNImageRequestHandler]
    C --> D[Create VNDetectHumanHandPoseRequest]
    D --> E[Perform VNDetectHumanHandPoseRequest]
    E -->|VNHumanHandPoseObservation| F[HandPoseProcessor]
    F --> G{Extract Finger Points}
    G -->|Success| H[Calculate Pinch Distance]
    G -->|Failure| M[Deactivate Trackpad]
    H --> I{Pinch Detected?}
    I -->|Yes| J[Activate/Update Trackpad]
    I -->|No| M
    J --> K[Calculate Cursor Position]
    K --> L[Move System Cursor]
    
    style A fill:#f9d5e5,stroke:#333,stroke-width:2px
    style E fill:#eeac99,stroke:#333,stroke-width:2px
    style F fill:#e06377,stroke:#333,stroke-width:2px
    style L fill:#5b9aa0,stroke:#333,stroke-width:2px
```

This process repeats for each video frame, allowing for real-time hand tracking and cursor control. The Vision framework handles the complex task of detecting and tracking hand poses, while the app's custom logic interprets these poses to simulate trackpad-like behavior.
```



