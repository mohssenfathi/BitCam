//
//  Crop.swift
//  Pods
//
//  Created by Mohssen Fathi on 5/12/16.
//
//

import UIKit

struct Crop1Uniforms: Uniforms {
    var x: Float = 0.0
    var y: Float = 0.0
    var width: Float = 0.0
    var height: Float = 0.0
    var fit: Int = 1
}

public
class Crop1: MTLFilter {
    
    var uniforms = Crop1Uniforms()
   
    public var x: Float = 0.0 {
        didSet {
            clamp(&x, low: 0.0, high: 1.0)
            needsUpdate = true
        }
    }
    public var y: Float = 0.0 {
        didSet {
            clamp(&y, low: 0.0, high: 1.0)
            needsUpdate = true
        }
    }
    public var width: Float = 1.0 {
        didSet {
            clamp(&width, low: 0.0, high: 1.0)
            needsUpdate = true
        }
    }
    public var height: Float = 1.0 {
        didSet {
            clamp(&height, low: 0.0, high: 1.0)
            needsUpdate = true
        }
    }
    
    
    public var fit: Bool = true {
        didSet {
            needsUpdate = true
        }
    }

    public var cropRegion: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1) {
        didSet {
            assert(cropRegion.size.width  <= 1.0)
            assert(cropRegion.size.height <= 1.0)
            assert(cropRegion.origin.x    >= 0.0)
            assert(cropRegion.origin.y    >= 0.0)
            
//            internalTexture = nil
            needsUpdate = true
        }
    }
    
    public init() {
        super.init(functionName: "crop")
        title = "Crop"
        properties = [MTLProperty(key: "x", title: "X"),
                      MTLProperty(key: "y", title: "Y"),
                      MTLProperty(key: "width", title: "Width"),
                      MTLProperty(key: "height", title: "Height"),
                      MTLProperty(key: "cropRegion", title: "Crop Region", propertyType: .rect),
                      MTLProperty(key: "fit"       , title: "Fit"        , propertyType: .bool)]
        
        update()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func update() {
        if self.input == nil { return }

//        uniforms.x = x
//        uniforms.y = y
//        uniforms.width = width
//        uniforms.height = height
        
        uniforms.x = Float(cropRegion.origin.x)
        uniforms.y = Float(cropRegion.origin.y)
        uniforms.width = Float(cropRegion.size.width)
        uniforms.height = Float(cropRegion.size.height)
        uniforms.fit = fit ? 1 : 0
        
        updateUniforms(uniforms: uniforms)
    }
    
    
    func updateCroppedTexture() {

        guard let inputTexture = input?.texture else {
            return
        }
        
        let newX = Int(cropRegion.origin.x * CGFloat(inputTexture.width))
        let newY = Int(cropRegion.origin.y * CGFloat(inputTexture.height))
        let newWidth  = Int(cropRegion.size.width * CGFloat(inputTexture.width))
        let newHeight = Int(cropRegion.size.height * CGFloat(inputTexture.height))
        
        if newWidth <= 1 || newHeight <= 1 { return }
        
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: newWidth, height: newHeight, mipmapped: false)
        let newTexture = device.makeTexture(descriptor: textureDescriptor)
        
        let commandBuffer = self.context.commandQueue.makeCommandBuffer()
        let blitCommandEncoder = commandBuffer.makeBlitCommandEncoder()
        
        blitCommandEncoder.copy(from: inputTexture,
                                           sourceSlice: 0,
                                           sourceLevel: 0,
                                           sourceOrigin: MTLOrigin(x: newX, y: newY, z: 0),
                                           sourceSize: MTLSize(width: newWidth, height: newHeight, depth: 1),
                                           to: newTexture,
                                           destinationSlice: 0,
                                           destinationLevel: 0,
                                           destinationOrigin: MTLOrigin(x: 0, y: 0, z: 0))
        
        blitCommandEncoder.endEncoding()
        commandBuffer.commit()
        
        texture = newTexture
    }
    
//    public override var texture: MTLTexture? {
//        get {
//            if texture == nil {
//                updateCroppedTexture()
//            }
//            return texture
//        }
//    }
}
