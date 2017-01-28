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
    @IBOutlet weak var brightnessLabel: UILabel!
    @IBOutlet weak var captureButton: UIButton!
    
    @IBOutlet weak var contrastView: UIView!
    @IBOutlet weak var brightnessView: UIView!
    @IBOutlet weak var contrastSlider: UIImageView!
    @IBOutlet weak var brightnessSlider: UIImageView!
    
    let camera = MTLCamera()
    let filterGroup = MTLFilterGroup()
    
    let luminance = Luminance()
    let pixellate = Pixellate()
    let haze = Haze()
    let brightness = Brightness()
    let contrast = Contrast()
    let crop = Crop()
    
    let sliderTicLength: CGFloat = 10.0
    
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
        filterGroup += brightness
        filterGroup += contrast
        
        brightnessLabel.transform = CGAffineTransform(rotationAngle: CGFloat.pi/2.0)
        brightnessSlider.transform = CGAffineTransform(rotationAngle: 3*CGFloat.pi/2.0)
    }
    
    @IBAction func contrastDownButtonPressed(_ sender: UIButton) {
        contrast.contrast = max(0.3, contrast.contrast + 0.05)
        contrastSlider.center = CGPoint(x: contrastSlider.center.x - sliderTicLength, y: contrastSlider.center.y)
    }
    
    @IBAction func contrastUpButtonPressed(_ sender: UIButton) {
        contrast.contrast = max(0.3, contrast.contrast - 0.05)
        contrastSlider.center = CGPoint(x: contrastSlider.center.x + sliderTicLength, y: contrastSlider.center.y)
    }
    
    @IBAction func brightnessDownButtonPressed(_ sender: UIButton) {
        brightness.brightness = max(0.3, brightness.brightness - 0.05)
        brightnessSlider.center = CGPoint(x: brightnessSlider.center.x, y: brightnessSlider.center.y + sliderTicLength)
    }
    
    @IBAction func brightnessUpButtonPressed(_ sender: UIButton) {
        brightness.brightness = max(0.3, brightness.brightness + 0.05)
        brightnessSlider.center = CGPoint(x: brightnessSlider.center.x, y: brightnessSlider.center.y - sliderTicLength)
    }
    
    
    @IBAction func captureButtonPressed(_ sender: UIButton) {
        
        camera.takePhoto { (image, error) in
            guard let image = image, error == nil else {
                return
            }
            
            BitCamAlbum.sharedInstance.savePhoto(image)
        }
        
    }
    
    
}
