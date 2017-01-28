//
//  SobelEdgeDetection.swift
//  Pods
//
//  Created by Mohssen Fathi on 4/8/16.
//
//

import UIKit

struct SobelEdgeDetectionUniforms: Uniforms {
    var edgeStrength: Float = 0.5;
}

public
class SobelEdgeDetection: MTLFilter {
    
    var uniforms = SobelEdgeDetectionUniforms()
    
    public var edgeStrength: Float = 0.5 {
        didSet {
            clamp(&edgeStrength, low: 0, high: 1)
            needsUpdate = true
        }
    }
    
    public init() {
        super.init(functionName: "sobelEdgeDetection")
        title = "Sobel Edge Detection"
        properties = [MTLProperty(key: "edgeStrength", title: "Edge Strength")]
        update()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func update() {
        if self.input == nil { return }
        uniforms.edgeStrength = edgeStrength * 3.0 + 0.2
        updateUniforms(uniforms: uniforms)
    }
    
}

