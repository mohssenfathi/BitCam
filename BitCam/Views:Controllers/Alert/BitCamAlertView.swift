//
//  BitCamAlertView.swift
//  BitCam
//
//  Created by Mohssen Fathi on 1/29/17.
//  Copyright © 2017 mohssenfathi. All rights reserved.
//

import UIKit

class BitCamAlertView: AlertView {

    @IBOutlet var customBackgroundView: UIView!

    override init(title: String?, message: String?) {
        super.init(title: title, message: message)
        
        Bundle.main.loadNibNamed("BitCamBackgroundView", owner: self, options: nil)
        backgroundView = customBackgroundView
    }
    
}
