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
    let pixellate = Pixellate()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        mtlView.contentMode = .scaleAspectFit
        camera --> filterGroup --> mtlView
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
