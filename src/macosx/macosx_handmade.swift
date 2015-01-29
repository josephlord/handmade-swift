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

struct OffscreenBuffer {
    // Pixel data is packed: AABBGGRR
    var pixels = UnsafeMutablePointer<UInt8>.null()
    var sizeInBytes: Int { return Int(width * height * bytesPerPixel) }
    
    var width: UInt = 0
    var height: UInt = 0
    
    init(pixels: UnsafeMutablePointer<UInt8>, width: UInt, height: UInt) {
        self.pixels = pixels;
        self.width = width
        self.height = height
    }
    
    let bitsPerComponent: UInt = 8
    let bitsPerPixel: UInt = 32
    let bytesPerPixel: UInt = 4
    
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGBitmapInfo.ByteOrderDefault
}


class GraphicsBufferView : NSView {
    var buffer = OffscreenBuffer(pixels: UnsafeMutablePointer.null(), width: 0, height: 0)
    
    var offsetX = 0
    var offsetY = 0
    
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
        
        let data = NSData(bytes: buffer.pixels, length: buffer.sizeInBytes)
        let provider = CGDataProviderCreateWithCFData(data)
        
        let image = CGImageCreate(
            buffer.width, buffer.height,
            buffer.bitsPerComponent, buffer.bitsPerPixel,
            buffer.bytesPerPixel * buffer.width,
            buffer.colorSpace,
            buffer.bitmapInfo,
            provider, nil, true, kCGRenderingIntentDefault)

        let rect = CGRect(x: 0, y: 0, width: Int(buffer.width), height: Int(buffer.height))
        CGContextDrawImage(context, rect, image)
    }

    func renderWeirdGradient(blueOffset: Int, _ greenOffset: Int) {
        let pixels = UnsafeMutablePointer<UInt32>(buffer.pixels)
        
        for var y: UInt = 0; y < buffer.height; y++ {
            let row = y * buffer.width
            for var x: UInt = 0; x < buffer.width; x++ {
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
        if buffer.pixels != nil {
            buffer.pixels.dealloc(buffer.sizeInBytes)
        }

        buffer.width = UInt(self.bounds.width)
        buffer.height = UInt(self.bounds.height)
        
        buffer.pixels = UnsafeMutablePointer<UInt8>.alloc(buffer.sizeInBytes)
        memset(buffer.pixels, 255, UInt(buffer.sizeInBytes))
        
        renderWeirdGradient(0, 0)
    }
    
    func windowDidResize(notification: NSNotification) {
        updateBuffer(self.bounds.width, self.bounds.height)
    }
}