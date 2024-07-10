//
//  QuietTestApp.swift
//  QuietTest
//
//  Created by Hunter Wyatt on 7/9/24.
//

import SwiftUI

@main
struct QuietTestApp: App {
    var body: some Scene {
        WindowGroup {
            // Replace ContentView with your ViewController wrapped in UIHostingController
            ViewControllerWrapper()
        }
    }
}

// Helper struct to wrap ViewController in UIHostingController
struct ViewControllerWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = ViewController()
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Update the view controller if needed
    }
}
