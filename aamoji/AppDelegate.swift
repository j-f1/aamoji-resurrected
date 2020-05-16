//
//  AppDelegate.swift
//  aamoji
//
//  Created by Nate Parrott on 5/19/15.
//  Copyright (c) 2015 Nate Parrott. All rights reserved.
//

import Cocoa
import SwiftUI
import WebKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!

    func applicationWillFinishLaunching(_: Notification) {
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        iconView.image = plistIcon
    }
    
    @IBOutlet weak var iconView: NSImageView!
    @IBOutlet var headline: NSTextField!
    @IBOutlet var subtitle: NSTextField!
    
    @IBOutlet var shortcutsListWindow: NSWindow!
    @IBOutlet var shortcutsListWebview: WKWebView!

    @IBAction func launchNotes(_ sender: NSButton) {
        let launchDelay = NSWorkspace.shared.terminateApp(bundleID: "com.apple.Notes") ? 1 : 0
        if let notesPath = NSWorkspace.shared.absolutePathForApplication(withBundleIdentifier: "com.apple.Notes") {
            delay(.seconds(launchDelay)) { () -> () in
                NSWorkspace.shared.launchApplication(notesPath)
            }
        }
    }

    @IBAction func launchSysPrefs(_ sender: NSButton) {
        // doesn’t actually open the keyboard prefs, sadly
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.keyboard")!)
    }

    @IBAction func showShortcutsList(_ sender: NSButton) {
        shortcutsListWebview.loadHTMLString(shortcutListHTML(), baseURL: URL(string: "about:blank"))
        shortcutsListWindow.makeKeyAndOrderFront(sender)
    }
}
