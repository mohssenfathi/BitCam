//
//  CameraViewController.swift
//  BitCam
//
//  Created by Mohssen Fathi on 1/28/17.
//  Copyright © 2017 mohssenfathi. All rights reserved.
//

import UIKit
import Photos
import MTLImage

class CameraViewController: UIViewController {

    @IBOutlet weak var mtlView: MTLView!
    @IBOutlet weak var brightnessLabel: UILabel!
    @IBOutlet weak var captureButton: UIButton!
    
    @IBOutlet weak var contrastView: UIView!
    @IBOutlet weak var brightnessView: UIView!
    @IBOutlet weak var contrastIndicator: UIImageView!
    @IBOutlet weak var brightnessIndicator: UIImageView!
    
    @IBOutlet weak var contrastUpButton: UIButton!
    @IBOutlet weak var contrastDownButton: UIButton!
    @IBOutlet weak var brightnessUpButton: UIButton!
    @IBOutlet weak var brightnessDownButton: UIButton!
    
    @IBOutlet weak var brightnessIndicatorConstraint: NSLayoutConstraint!
    @IBOutlet weak var contrastIndicatorConstraint: NSLayoutConstraint!
    
    let camera = MTLCamera()
    let filterGroup = MTLFilterGroup()
    
    let luminance = Luminance()
    let pixellate = Pixellate()
    let haze = Haze()
    let brightness = Brightness()
    let contrast = Contrast()
    let crop = Crop()
    
    var brightnessIndicatorRange: CGFloat = 100
    var contrastIndicatorRange: CGFloat = 100
    var indicatorSteps: Float = 12.0
    
    let alertView = BitCamAlertView(title: "", message: "")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        brightnessIndicatorRange = brightnessDownButton.frame.minY - brightnessUpButton.frame.maxY - 20.0
        contrastIndicatorRange = contrastUpButton.frame.minX - contrastDownButton.frame.maxX + 20
        
        updateContrastIndicator(with: 0.5)
        updateBrightnessIndicator(with: 0.5)
    }
    
    func alertButton(with title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.tintColor = .black
        button.titleLabel?.font = UIFont(name: "VCROSDMono", size: 20.0)
        return button
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
        brightnessIndicator.transform = CGAffineTransform(rotationAngle: -CGFloat.pi/2.0)
    }
    
//  MARK: - Actions
    
    @IBAction func contrastDownButtonPressed(_ sender: UIButton) {
        contrast.contrast = max(0.3, contrast.contrast - 0.6/indicatorSteps)
        updateContrastIndicator(with: CGFloat(Tools.convert(contrast.contrast, oldMin: 0.3, oldMax: 0.6, newMin: 0.0, newMax: 1.0)))
    }
    
    @IBAction func contrastUpButtonPressed(_ sender: UIButton) {
        contrast.contrast = min(0.6, contrast.contrast + 0.6/indicatorSteps)
        updateContrastIndicator(with: CGFloat(Tools.convert(contrast.contrast, oldMin: 0.3, oldMax: 0.6, newMin: 0.0, newMax: 1.0)))
    }
    
    @IBAction func brightnessDownButtonPressed(_ sender: UIButton) {
        brightness.brightness = max(0.3, brightness.brightness - 0.6/indicatorSteps)
        updateBrightnessIndicator(with: CGFloat(Tools.convert(brightness.brightness, oldMin: 0.3, oldMax: 0.6, newMin: 0.0, newMax: 1.0)))
    }
    
    @IBAction func brightnessUpButtonPressed(_ sender: UIButton) {
        brightness.brightness = min(0.6, brightness.brightness + 0.6/indicatorSteps)
        updateBrightnessIndicator(with: CGFloat(Tools.convert(brightness.brightness, oldMin: 0.3, oldMax: 0.6, newMin: 0.0, newMax: 1.0)))
    }
    
    @IBAction func libraryButtonPressed(_ sender: UIButton) {
     

        if PhotosManager.sharedManager.authorizationStatus() == .authorized  {
            performSegue(withIdentifier: "photos", sender: self)
            return
        }
        
        PhotosManager.sharedManager.requestAuthorization { (status) in
            
            if status == PHAuthorizationStatus.authorized {
                self.performSegue(withIdentifier: "photos", sender: self)
            }
            else {
                // Yell at user
            }
            
        }
    }
    
    @IBAction func captureButtonPressed(_ sender: UIButton) {
        
        if checkAuthorization() == false {
            return
        }
        
        animatePictureTaken()
        
        camera.takePhoto { (image, error) in
            guard let image = image, error == nil else {
                return
            }
            
            BitCamAlbum.sharedInstance.savePhoto(image)
        }
        
    }
    
    func checkAuthorization() -> Bool {
        
        let status = PhotosManager.sharedManager.authorizationStatus()
        
        if status == .denied {
            
            alertView.title = "Library Access"
            alertView.message = "BitCam needs access to your photo library. Please allow access in the Settings app."
            alertView.buttons = [alertButton(with: "[Open Settings]")]
            alertView.callback = { alertView, index in
                
                alertView.hide(animated: true, completion: {
                    
                    if let appSettings = URL(string: UIApplicationOpenSettingsURLString) {
                        UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
                    }
                })
            }
            
            alertView.show(animated: true, completion: nil)
            
            return false
        }
        else if status != .authorized {
            
            alertView.title = "Library Access"
            alertView.message = "BitCam needs access to your photo library. Please select \"OK\" on the following prompt."
            alertView.buttons = [alertButton(with: "[CLOSE]")]
            alertView.callback = { alertView, index in
                alertView.hide(animated: true, completion: {
                    PhotosManager.sharedManager.requestAuthorization(completion: nil)
                })
            }
            
            alertView.show(animated: true, completion: nil)
            
            return false
        }

        return true
    }
    
    
//  MARK: - Slider Indicators

    func updateBrightnessIndicator(with percentage: CGFloat) {
        brightnessIndicatorConstraint.constant = brightnessIndicatorRange * percentage
    }
    
    func updateContrastIndicator(with percentage: CGFloat) {
        contrastIndicatorConstraint.constant = contrastIndicatorRange * percentage + 4 // Gross, I know
    }
    
    func animate(duration: CGFloat, _ animation: @escaping (() -> ())) {
        UIView.animate(withDuration: TimeInterval(duration), delay: 0.0, options: .beginFromCurrentState, animations: {
            animation()
        }, completion: nil)
    }
    
// MARK: - Animation
    
    func animatePictureTaken() {
        let animationView = UIView(frame: CGRect(x: 0, y: 0, width: mtlView.frame.size.width, height: mtlView.frame.size.height))
        animationView.backgroundColor = UIColor.white
        animationView.alpha = 0.0
        
        mtlView.addSubview(animationView)
        captureButton.isEnabled = false
        
        UIView.animate(withDuration: 0.1, animations: {
            animationView.alpha = 0.8
        }) { (finished) in
            UIView.animate(withDuration: 0.2, animations: {
                animationView.alpha = 0.0
            }, completion: { (finished) in
                animationView.removeFromSuperview()
                self.captureButton.isEnabled = true
            })
        }
    }

}
