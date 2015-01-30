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

struct Pixel {
    var red: Byte       = 0x00
    var green: Byte     = 0x00
    var blue: Byte      = 0x00
    var alpha: Byte     = 0xFF
}

struct OffscreenBuffer {
    var pixels: [Pixel] = []
    
    var width: Int = 0
    var height: Int = 0
    
    let bitsPerComponent: UInt  = 8
    let bitsPerPixel: UInt      = 32
    let bytesPerPixel: UInt     = 4
    
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGBitmapInfo.ByteOrderDefault
}


final class GraphicsBufferView : NSView {
    final var buffer = OffscreenBuffer()
    
    final var offsetX = 0
    final var offsetY = 0
    
    func timerUpdate() {
        offsetX = offsetX &+ 1
        offsetY = offsetY &+ 2
        
        self.needsDisplay = true
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
        let start = CACurrentMediaTime()

        
        renderWeirdGradient(offsetX, offsetY)

        // TODO(owensd): This will crash if there is no context
        let context = NSGraphicsContext.currentContext()!.CGContext
        
        let size = buffer.pixels.count * Int(buffer.bytesPerPixel)
        let data = NSData(bytesNoCopy: &buffer.pixels, length: size, freeWhenDone: false)
        let provider = CGDataProviderCreateWithCFData(data)
        
        let width = UInt(buffer.width)
        let height = UInt(buffer.height)
        let bytesPerRow = buffer.bytesPerPixel * UInt(buffer.width)
        let image = CGImageCreate(
            width, height,
            buffer.bitsPerComponent, buffer.bitsPerPixel,
            bytesPerRow,
            buffer.colorSpace,
            buffer.bitmapInfo,
            provider, nil, true, kCGRenderingIntentDefault)

        let rect = CGRect(x: 0, y: 0, width: buffer.width, height: buffer.height)
        CGContextDrawImage(context, rect, image)
        
        let elapsed = CACurrentMediaTime() - start
        println("elapsed: \(elapsed)")
    }

    func renderWeirdGradient(blueOffset: Int, _ greenOffset: Int) {
        for var y = 0, height = buffer.height; y < height; y++ {
            let row = y * buffer.width
            for var x = 0, width = buffer.width; x < width; x++ {
                // Simply using the "FAST" code block changes the timing from 1.2s
                // per call to 0.37s per call.
                
                // ---- SLOW CODE BLOCK
                // buffer.pixels[row + x].green = Byte((y + greenOffset) & 0xFF)
                // buffer.pixels[row + x].blue = Byte((y + blueOffset) & 0xFF)
                // ---- END SLOW CODE BLOCK
                
                // ---- FASTER CODE BLOCK
                 let pixel = Pixel(
                     red: 0,
                     green: Byte((y + greenOffset) & 0xFF),
                     blue: Byte((x + blueOffset) & 0xFF),
                     alpha: 255)

                 buffer.pixels[row + x] = pixel
                // ---- END FASTER CODE BLOCK
            }
        }
        
        self.needsDisplay = true
    }
}

extension GraphicsBufferView: NSWindowDelegate {
    
    func updateBuffer(newWidth: CGFloat, _ newHeight: CGFloat) {
        buffer.width = Int(self.bounds.width)
        buffer.height = Int(self.bounds.height)

        let black = Pixel(red: 0, green: 0, blue: 0, alpha: 255)
        buffer.pixels = [Pixel](count: buffer.width * buffer.height, repeatedValue: black)
        
        renderWeirdGradient(0, 0)
    }
    
    func windowDidResize(notification: NSNotification) {
        updateBuffer(self.bounds.width, self.bounds.height)
    }
}