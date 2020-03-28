//
//  AamojiInserter+HTML.swift
//  aamoji
//
//  Created by Nate Parrott on 5/19/15.
//  Copyright (c) 2015 Nate Parrott. All rights reserved.
//

import Foundation

extension AamojiInserter {
    func shortcutListHTML() -> String {
        let template = try! String(contentsOf: Bundle.main.url(forResource: "ShortcutListTemplate", withExtension: "html")!)
        
        var shortcutsForEmoji = [String: [String]]()
        for entry in aamojiEntries() {
            let emoji = entry[ReplacementReplaceWithKey] as! String
            let shortcut = entry[ReplacementShortcutKey] as! String
            shortcutsForEmoji[emoji] = (shortcutsForEmoji[emoji] ?? []) + [shortcut]
        }
        
        var html = ""
        for (emoji, shortcuts) in shortcutsForEmoji {
            let allShortcuts = shortcuts.joined(separator: ", ")
            html += "<li><span class='emoji'>\(emoji)</span> \(allShortcuts)</li>\n"
        }
        
        return template.replacingOccurrences(of: "<!--SHORTCUTS-->", with: html)
    }
}
