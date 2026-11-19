//
//  Example__macOS_App.swift
//  Example (macOS)
//
//  Created by Maxwell Talbot on 17/05/2023.
//  Copyright © 2023 Rive. All rights reserved.
//

import AppKit
import SwiftUI

@main
struct Example__macOS_App: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(
                    minWidth: KeyboardWindowSizing.minimumSize.width,
                    minHeight: KeyboardWindowSizing.minimumSize.height
                )
                .background {
                    KeyboardWindowSizing()
                        .frame(width: 0, height: 0)
                }
        }
        .defaultSize(width: 1120, height: 630)
        .windowResizability(.contentMinSize)
    }
}

private struct KeyboardWindowSizing: NSViewRepresentable {
    static let minimumSize = CGSize(width: 848, height: 477)

    func makeNSView(context: Context) -> NSView { WindowObserver() }

    func updateNSView(_ nsView: NSView, context: Context) {}

    private final class WindowObserver: NSView {
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard let window else { return }

            DispatchQueue.main.async { [weak self, weak window] in
                guard let window, self?.window === window else { return }
                let aspect = CGSize(width: 16, height: 9)
                window.contentAspectRatio = aspect
                guard !window.styleMask.contains(.fullScreen) else { return }

                // The default size does not replace a previously saved window size.
                let currentSize = window.contentRect(forFrameRect: window.frame).size
                let ratio = aspect.width / aspect.height
                let width = max(minimumSize.width, min(currentSize.width, currentSize.height * ratio))
                let size = CGSize(width: width, height: width / ratio)
                if abs(currentSize.width - size.width) > 0.5 || abs(currentSize.height - size.height) > 0.5 {
                    window.setContentSize(size)
                }
            }
        }
    }
}
