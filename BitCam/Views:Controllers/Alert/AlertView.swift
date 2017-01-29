//
//  AlertView.swift
//  BitCam
//
//  Created by Mohssen Fathi on 1/29/17.
//  Copyright © 2017 mohssenfathi. All rights reserved.
//

import UIKit

class AlertView: NSObject {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet var view: UIView!
    
    var title: String?
    var message: String?
    
    var backgroundView: UIView? {
        willSet {
            if let backgroundView = backgroundView {
                backgroundView.removeFromSuperview()
            }
        }
        didSet {
            if let backgroundView = backgroundView {
                backgroundView.frame = contentView.bounds
                backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                contentView.addSubview(backgroundView)
            }
        }
    }
    
    init(title: String?, message: String?) {
        super.init()
        
        self.title = title
        self.message = message
    }
    
    
    func commonInit() {
        
        Bundle.main.loadNibNamed("AlertView", owner: self, options: nil)
        
    }
    
    
    func show(animated: Bool, completion: (() -> ())) {
        
    }
    
    func hide(animated: Bool, completion: (() -> ())) {
        
    }
}
