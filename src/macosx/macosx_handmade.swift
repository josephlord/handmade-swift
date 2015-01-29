//
//  macosx_handmade.swift
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
    var buffer = UnsafeMutablePointer<UInt8>.null()
    var bufferWidth: UInt = 200
    var bufferHeight: UInt = 300
    let bitsPerComponent: UInt = 8
    let bitsPerPixel: UInt = 32
    let bytesPerPixel: UInt = 4
    
    var offsetX = 0
    var offsetY = 0
    
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGBitmapInfo.ByteOrderDefault
    
    func timerUpdate() {
        renderWeirdGradient(offsetX, offsetY)
        
        offsetX = offsetX &+ 1
        offsetY = offsetY &+ 2
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)

        // TODO(owensd): This is a pretty hacky way to set this up, and is a bit
        // slower than I had anticipated. However, I'm on a retina display, so that's
        // a whole lot more pixels being processed as well...
        let timer = NSTimer.scheduledTimerWithTimeInterval(
            1.0/60.0,
            target: self,
            selector: Selector("timerUpdate"),
            userInfo: nil,
            repeats: true)
        
        updateBuffer(self.bounds.width, self.bounds.height)
    }
    
    override func drawRect(dirtyRect: NSRect) {
        // TODO(owensd): This will crash if there is no context
        let context = NSGraphicsContext.currentContext()!.CGContext
        
        let data = NSData(bytes: buffer, length: Int(bufferWidth * bufferHeight * bytesPerPixel))
        let provider = CGDataProviderCreateWithCFData(data)
        
        let image = CGImageCreate(
            bufferWidth, bufferHeight, bitsPerComponent, bitsPerPixel, bytesPerPixel * bufferWidth,
            colorSpace,
            bitmapInfo,
            provider, nil, true, kCGRenderingIntentDefault)

        let rect = CGRect(x: 0, y: 0, width: Int(bufferWidth), height: Int(bufferHeight))
        CGContextDrawImage(context, rect, image)
    }

    func renderWeirdGradient(blueOffset: Int, _ greenOffset: Int) {
        let pixels = UnsafeMutablePointer<UInt32>(buffer)
        
        for var y: UInt = 0; y < bufferHeight; y++ {
            let row = y * bufferWidth
            for var x: UInt = 0; x < bufferWidth; x++ {
                let red = UInt32(0)
                let green = UInt32(y + greenOffset)
                let blue = UInt32(x + blueOffset)
                let alpha = UInt32(0)
                
                pixels[Int(row + x)] = UInt32(alpha << 24 | blue << 16 | green << 8 | red)
                
            }
        }
        
        self.needsDisplay = true
    }
}

extension GraphicsBufferView: NSWindowDelegate {
    
    func updateBuffer(newWidth: CGFloat, _ newHeight: CGFloat) {
        if buffer != nil {
            buffer.dealloc(Int(bufferWidth * bufferHeight * bytesPerPixel))
        }

        bufferWidth = UInt(self.bounds.width)
        bufferHeight = UInt(self.bounds.height)
        
        buffer = UnsafeMutablePointer<UInt8>.alloc(Int(bufferWidth * bufferHeight * bytesPerPixel))
        memset(buffer, 255, bufferWidth * bufferHeight * bytesPerPixel)
        
        renderWeirdGradient(0, 0)
    }
    
    func windowDidResize(notification: NSNotification) {
        updateBuffer(self.bounds.width, self.bounds.height)
    }
}