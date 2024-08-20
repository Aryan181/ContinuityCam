//
//  MaterialView.swift
//  Continuity Camera Sample
//
//  Created by Aryan Mahindra
//  Copyright © 2023 Your Organization. All rights reserved.
//

import SwiftUI

/// A SwiftUI wrapper around NSVisualEffectView to provide a blurred, translucent background effect.
struct MaterialView: NSViewRepresentable {
    // MARK: - NSViewRepresentable
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = .behindWindow
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        // The view doesn't need to be updated after creation.
    }
}

// MARK: - Preview

struct MaterialView_Previews: PreviewProvider {
    static var previews: some View {
        MaterialView()
            .frame(width: 200, height: 100)
            .previewLayout(.sizeThatFits)
    }
}
