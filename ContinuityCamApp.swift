//
//  ContinuityCamApp.swift
//  Continuity Camera Sample
//
//  Created by Aryan Mahindra
//  Copyright © 2023 Your Organization. All rights reserved.
//

import SwiftUI

/// The main app structure for the Continuity Camera Sample application.
@main
struct ContinuityCamApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .navigationTitle("Continuity Camera Sample")
                .frame(minWidth: 800, minHeight: 600)
        }
    }
}
