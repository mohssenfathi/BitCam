//
//  Straighten.swift
//  Pods
//
//  Created by Mohssen Fathi on 9/12/16.
//
//

import UIKit

struct StraightenUniforms: Uniforms {
    var angle: Float = 0.5
}

public
class Straighten: MTLFilter {
    
    var uniforms = TemplateUniforms()
    
    public var angle: Float = 0.5 {
        didSet {
            clamp(&angle, low: 0, high: 1)
            needsUpdate = true
        }
    }
    
    public init() {
        super.init(functionName: "angle")
        title = "Straighten"
        properties = [MTLProperty(key: "angle", title: "Angle")]
        update()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func update() {
        if self.input == nil { return }
        updateUniforms(uniforms: uniforms)
    }
    
}
