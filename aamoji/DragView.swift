import Cocoa

class ShortcutProvider: NSObject, NSItemProviderWriting {
    static var writableTypeIdentifiersForItemProvider = [kUTTypePropertyList as String]
    
    func loadData(withTypeIdentifier _: String, forItemProviderCompletionHandler completionHandler: @escaping (Data?, Error?) -> Void) -> Progress? {
        return nil
    }
}

public var plistIcon: NSImage {
    let image = NSWorkspace.shared.icon(forFileType: kUTTypePropertyList as String)
    image.size = NSSize(width: 64, height: 64)
    return image
}

class DragView: NSControl, NSDraggingSource {
    var outputURL: URL?
    
    func getOutputURL() -> URL{
        if outputURL != nil { return outputURL! }
        let url = try! FileManager.default.url(
            for: .itemReplacementDirectory,
            in: .userDomainMask,
            appropriateFor: Bundle.main.bundleURL,
            create: true
        ).appendingPathComponent("aamoji Text Substitutions.plist")
        try! PropertyListSerialization.data(fromPropertyList: aamojiEntries(), format: .binary, options: 0).write(to: url)
        return url
    }
    
    deinit {
        if let url = outputURL {
            try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
        }
    }

    func draggingSession(_: NSDraggingSession, sourceOperationMaskFor _: NSDraggingContext) -> NSDragOperation {
        .move
    }
    override func mouseDown(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        window?.trackEvents(matching: [.leftMouseUp, .leftMouseDragged], timeout: NSEvent.foreverDuration, mode: .eventTracking, handler: { (event, stop) in
            guard let event = event else { return }
            
            if event.type == .leftMouseUp {
                stop.pointee = true
            } else {
                let movedLocation = convert(event.locationInWindow, from: nil)
                if abs(movedLocation.x - location.x) > 3 || abs(movedLocation.y - location.y) > 3 {
                    stop.pointee = true
                    let draggingItem = NSDraggingItem(pasteboardWriter: getOutputURL() as NSURL)
                    draggingItem.setDraggingFrame(CGRect(origin: CGPoint(x: movedLocation.x - plistIcon.size.width / 2, y: movedLocation.y - plistIcon.size.height / 2), size: plistIcon.size), contents: plistIcon)
                    beginDraggingSession(with: [draggingItem], event: event, source: self)
                }
            }
        })
    }
}
