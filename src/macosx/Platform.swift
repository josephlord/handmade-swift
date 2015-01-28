//
//  Platform.swift
//  Handmade
//
//  Created by David Owens II on 1/28/15.
//
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var view: GraphicsBufferView!

    func applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication) -> Bool {
        return true
    }
}

class GraphicsBufferView : NSView {
    let colors = [NSColor.blackColor(), NSColor.grayColor(), NSColor.whiteColor()]
    var colorIndex = 0;
    
    override func drawRect(dirtyRect: NSRect) {
        colorIndex += 1;
        if colorIndex == colors.count - 1 {
            colorIndex = 0
        }
        println("colorIndex: \(colorIndex)")
        colors[colorIndex].setFill()
        NSRectFill(self.bounds)
    }
}