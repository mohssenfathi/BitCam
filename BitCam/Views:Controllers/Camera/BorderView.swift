//
//  BorderView.swift
//  BitCam
//
//  Created by Mohssen Fathi on 1/28/17.
//  Copyright © 2017 mohssenfathi. All rights reserved.
//

import UIKit

class BorderView: UIView {

    var shapeLayer = CAShapeLayer()
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        updateShadowLayer()
    }

    func updateShadowLayer() {

        return
        
        if shapeLayer.superlayer != nil { return }
        
        shapeLayer.shadowRadius = -10.0
        shapeLayer.shadowColor = UIColor(white: 0.0, alpha: 1.0).cgColor
        shapeLayer.shadowOffset = CGSize(width: 0.0, height: 0.0)
        shapeLayer.shadowOpacity = 1.0
        shapeLayer.fillColor = UIColor.clear.cgColor
        
        shapeLayer.path = UIBezierPath(rect: bounds).cgPath
        
        shapeLayer.frame = bounds
        
        layer.insertSublayer(shapeLayer, at: 0)
    }
    
}
