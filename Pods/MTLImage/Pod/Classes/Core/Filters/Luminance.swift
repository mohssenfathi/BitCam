//
//  Luminance.swift
//  Pods
//
//  Created by Mohssen Fathi on 1/28/17.
//
//

struct LuminanceUniforms: Uniforms {
    var threshold1: Float = 0.2
    var threshold2: Float = 0.4
    var threshold3: Float = 0.6
    var threshold4: Float = 0.8
}

public
class Luminance: MTLFilter {
    
    var uniforms = LuminanceUniforms()
    
    public var threshold1: Float = 0.2 {
        didSet { setNeedsUpdate() }
    }
    
    public var threshold2: Float = 0.4 {
        didSet { setNeedsUpdate() }
    }
    
    public var threshold3: Float = 0.6 {
        didSet { setNeedsUpdate() }
    }
    
    public var threshold4: Float = 0.8 {
        didSet { setNeedsUpdate() }
    }
    
    public init() {
        super.init(functionName: "luminance")
        title = "Luminance"
        properties = [MTLProperty(key: "threshold1", title: "Threshold 1"),
                      MTLProperty(key: "threshold2", title: "Threshold 2"),
                      MTLProperty(key: "threshold3", title: "Threshold 3"),
                      MTLProperty(key: "threshold4", title: "Threshold 4")]
        update()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func update() {
        if self.input == nil { return }
        
        uniforms.threshold1 = threshold1
        uniforms.threshold2 = threshold2
        uniforms.threshold3 = threshold3
        uniforms.threshold4 = threshold4
        
        updateUniforms(uniforms: uniforms)
    }
    
}
