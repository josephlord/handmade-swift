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
    
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGBitmapInfo(CGImageAlphaInfo.PremultipliedFirst.rawValue)
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
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

        CGContextDrawImage(context, CGRect(x: 0, y: 0, width: Int(bufferWidth), height: Int(bufferHeight)), image)
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
    }
    
    func windowDidResize(notification: NSNotification) {
        updateBuffer(self.bounds.width, self.bounds.height)
    }
}