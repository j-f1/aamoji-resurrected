//
//  AppDelegate.swift
//  aamoji
//
//  Created by Nate Parrott on 5/19/15.
//  Copyright (c) 2015 Nate Parrott. All rights reserved.
//

import Cocoa
import WebKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!


    func applicationWillFinishLaunching(aNotification: NSNotification) {
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        _updateUI()
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        
    }
    
    let inserter = AamojiInserter()
    
    @IBOutlet var button: NSButton!
    @IBOutlet var headline: NSTextField!
    @IBOutlet var subtitle: NSTextField!
    @IBOutlet var postInstallButtons: NSView!
    
    @IBOutlet var shortcutsListWindow: NSWindow!
    @IBOutlet var shortcutsListWebview: WKWebView!
    
    @IBAction func toggleInserted(sender: NSButton) {
        if let inserted = inserter.inserted {
            inserter.inserted = !inserted
        } else {
            print("ERROR")
        }
        _updateUI()
        delay(.milliseconds(500)) { () -> () in
            // just in case (seems to be necessary sometimes)
            self._updateUI()
        }
    }
    
    private func _updateUI() {
        if let inserted = inserter.inserted {
            button.isEnabled = true
            button.title = inserted ? "💔 Remove aamoji shortcuts 💔" : "✨ Add aamoji shortcuts 💫"
            if inserted {
                headline.stringValue = "⚡ aamoji is on ⚡"
                subtitle.stringValue = "You'll need to re-launch your apps before aamoji will work inside them."
            } else {
                headline.stringValue = "Type emoji in any app*"
                subtitle.stringValue = "Prefix the name of an emoji with \"aa\", and it'll autocorrect to the emoji itself."
            }
            postInstallButtons.isHidden = !inserted
        } else {
            button.isEnabled = false
            button.title = "🚨 Error 🚨"
        }
    }
    
    @IBAction func launchNotes(sender: NSButton) {
        let launchDelay = NSWorkspace.shared.terminateApp(bundleID: "com.apple.Notes") ? 1 : 0
        if let notesPath = NSWorkspace.shared.absolutePathForApplication(withBundleIdentifier: "com.apple.Notes") {
            delay(.seconds(launchDelay)) { () -> () in
                NSWorkspace.shared.launchApplication(notesPath)
            }
        }
    }
    
    @IBAction func showShortcutsList(sender: NSButton) {
        shortcutsListWebview.loadHTMLString(inserter.shortcutListHTML(), baseURL: URL(string: "about:blank"))
        shortcutsListWindow.makeKeyAndOrderFront(sender)
    }
}
