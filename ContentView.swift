//
//  ContentView.swift
//  Continuity Camera Sample
//
//  Created by Aryan Mahindra
//  Copyright © 2023 Your Organization. All rights reserved.
//

import SwiftUI

/// The main content view for the Continuity Camera Mouse tracker app.
struct ContentView: View {
    @StateObject private var camera = Camera()
    
    var body: some View {
        HStack(spacing: 0) {
            cameraPreview
            configurationPanel
        }
    }
    
    private var cameraPreview: some View {
        camera.preview
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                Task {
                    await camera.start()
                }
            }
    }
    
    private var configurationPanel: some View {
        ConfigurationView(camera: camera)
            .background(MaterialView())
            .frame(width: 300)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
