//
//  CameraViewController.swift
//  BitCam
//
//  Created by Mohssen Fathi on 1/28/17.
//  Copyright © 2017 mohssenfathi. All rights reserved.
//

import UIKit
import MTLImage

class CameraViewController: UIViewController {

    @IBOutlet weak var mtlView: MTLView!
    @IBOutlet var contrastSilder:UISlider!
    @IBOutlet var brightnessSlider:UISlider!
    
    let camera = MTLCamera()
    let filterGroup = MTLFilterGroup()
    
    let luminance = Luminance()
    let pixellate = Pixellate()
    let haze = Haze()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    func setup() {
        
        mtlView.contentMode = .scaleAspectFit
        
        luminance.threshold1 = 0.27
        luminance.threshold2 = 0.47
        luminance.threshold3 = 0.62
        luminance.threshold4 = 0.74
        
        haze.fade = 0.25
        
        pixellate.dotRadius = 0.1
        
        
        camera --> filterGroup --> mtlView
        
        filterGroup += luminance
        filterGroup += pixellate
        filterGroup += haze
    }
    
}
