//
//  Crop.swift
//  Pods
//
//  Created by Mohssen Fathi on 10/31/16.
//
//

public
class Crop: MTLFilter {

    public init() {
        super.init(functionName: "crop")
        title = "Crop"
        properties = [MTLProperty(key: "x", title: "X"),
                      MTLProperty(key: "y", title: "Y"),
                      MTLProperty(key: "width", title: "Width"),
                      MTLProperty(key: "height", title: "Height"),
                      MTLProperty(key: "cropRegion", title: "Crop Region", propertyType: .rect),
                      MTLProperty(key: "fit"       , title: "Fit"        , propertyType: .bool)]
        
        needsUpdate = true
        
        update()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    override public func process() {
        
        guard let inputTexture = input?.texture else { return }
        
        input?.processIfNeeded()
        
        let newX = Int(cropRegion.origin.x * CGFloat(inputTexture.width))
        let newY = Int(cropRegion.origin.y * CGFloat(inputTexture.height))
        let newWidth  = Int(cropRegion.size.width * CGFloat(inputTexture.width))
        let newHeight = Int(cropRegion.size.height * CGFloat(inputTexture.height))
        
        if newWidth <= 1 || newHeight <= 1 { return }
        
        guard texture != nil else {
            texture = input?.texture
            return
        }
        
        if texture?.width != newWidth || texture?.height != newHeight {
            let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: newWidth, height: newHeight, mipmapped: false)
            texture = device.makeTexture(descriptor: textureDescriptor)
        }
        
        let commandBuffer = context.commandQueue.makeCommandBuffer()
        let blitCommandEncoder = commandBuffer.makeBlitCommandEncoder()
        
        blitCommandEncoder.copy(from: inputTexture,
                                sourceSlice: 0,
                                sourceLevel: 0,
                                sourceOrigin: MTLOrigin(x: newX, y: newY, z: 0),
                                sourceSize: MTLSize(width: newWidth, height: newHeight, depth: 1),
                                to: texture!,
                                destinationSlice: 0,
                                destinationLevel: 0,
                                destinationOrigin: MTLOrigin(x: 0, y: 0, z: 0))
        
        blitCommandEncoder.endEncoding()
        
        commandBuffer.addCompletedHandler({ (commandBuffer) in
            
            if self.continuousUpdate { return }
            if let input = self.input {
                if input.continuousUpdate { return }
            }
            self.needsUpdate = false
            
        })
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
    }
    
    
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
            

            needsUpdate = true
        }
    }
    
    
}
