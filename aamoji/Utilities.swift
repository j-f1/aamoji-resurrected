//
//  Utilities.swift
//  aamoji
//
//  Created by Nate Parrott on 5/19/15.
//  Copyright (c) 2015 Nate Parrott. All rights reserved.
//

import AppKit

func delay(_ delay: DispatchTimeInterval, closure: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now().advanced(by: delay), execute: closure)
}

extension NSWorkspace {
    func terminateApp(bundleID: String) -> Bool {
        for app in runningApplications {
            if let appBundleID = app.bundleIdentifier {
                if appBundleID.lowercased() == bundleID.lowercased() {
                    return app.terminate()
                }
            }
        }
        return false
    }
}

extension String {
    func containsOnlyCharactersFromSet(set: CharacterSet) -> Bool {
        return self.trimmingCharacters(in: set) == ""
    }
}
