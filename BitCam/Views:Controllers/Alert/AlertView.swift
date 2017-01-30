//
//  AlertView.swift
//  BitCam
//
//  Created by Mohssen Fathi on 1/29/17.
//  Copyright © 2017 mohssenfathi. All rights reserved.
//

import UIKit

class AlertView: NSObject {

    typealias AlertViewButtonPressedCallback = ((AlertView, Int) -> ())
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var dimView: UIView!
    @IBOutlet weak var buttonView: UIView!
    @IBOutlet var view: UIView!
    
    @IBOutlet weak var buttonViewHeight: NSLayoutConstraint!
    @IBOutlet weak var contentViewVerticalConstraint: NSLayoutConstraint!
    
    var callback: AlertViewButtonPressedCallback?
    
    init(title: String?, message: String?) {
        super.init()
        
        commonInit()
        self.title = title
        self.message = message
    }
    
    func commonInit() {
        
        Bundle.main.loadNibNamed("AlertView", owner: self, options: nil)
        
        contentViewVerticalConstraint.constant = view.frame.height
        
        let bgv = UIView()
        bgv.backgroundColor = .white
        backgroundView = bgv
        
        if let window = window {
            
            view.frame = window.bounds
            view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            window.addSubview(view)
        }
    }
    
    var title: String? {
        didSet {
            titleLabel.text = title
        }
    }
    
    var message: String? {
        didSet {
            messageLabel.text = message
        }
    }
    
    var buttons = [UIButton]() {
        didSet { reloadButtons() }
    }
    
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
                contentView.insertSubview(backgroundView, at: 0)
            }
        }
    }
    
    var window: UIWindow? {
        return UIApplication.shared.keyWindow
    }
    
    func reloadButtons() {
        
        for subview in buttonView.subviews { subview.removeFromSuperview() }
        
        if buttons.count == 0 {
            buttonViewHeight.constant = 0.0
            return
        }
        
        buttonViewHeight.constant = 50.0
        
        let width = buttonView.frame.width / CGFloat(buttons.count)
        
        for (i, button) in buttons.enumerated() {
            
            button.frame = CGRect(x: width * CGFloat(i), y: 0, width: width, height: buttonViewHeight.constant)
            button.titleLabel?.textAlignment = .center
            button.contentVerticalAlignment = .center
            buttonView.addSubview(button)
            
            button.addTarget(self, action: #selector(AlertView.buttonPressed(_:)), for: .touchUpInside)
        }
        
    }
    
    func buttonPressed(_ sender: UIButton) {
        
        guard let index = buttons.index(of: sender) else { return }
        callback?(self, index)
    }
    
    func show(animated: Bool, completion: (() -> ())?) {
        
        titleLabel.text = title
        messageLabel.text = message
        
        if view.superview == nil {
            guard let window = window else { return }
                
            view.frame = window.bounds
            view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            window.addSubview(view)
        }

        if !animated {
            contentViewVerticalConstraint.constant = 0.0
            dimView.alpha = 1.0
            return
        }
        
        animate(duration: 0.2, {
            
            self.dimView.alpha = 1.0
            
        }, completion: {
            
            self.contentViewVerticalConstraint.constant = 0.0
            self.view.setNeedsLayout()
            
            self.animate(duration: 0.4, {
                
                self.view.layoutIfNeeded()
                
            }, completion: {
                
                completion?()
            })
        })
    }
    
    func hide(animated: Bool, completion: (() -> ())?) {
        
        if !animated {
            contentViewVerticalConstraint.constant = view.frame.height
            dimView.alpha = 0.0
            return
        }

        contentViewVerticalConstraint.constant = view.frame.height
        view.setNeedsLayout()
        
        animate(duration: 0.4, {
            
            self.view.layoutIfNeeded()
            self.dimView.alpha = 1.0
            
        }, completion: {
            
            self.view.removeFromSuperview()
            completion?()
        })
    }
    
    func animate(duration: CGFloat, _ animation: @escaping (() -> ()), completion: (() -> ())?) {
        
        UIView.animate(withDuration: 0.3, delay: 0.0, options: .beginFromCurrentState, animations: { 
            
            animation()
            
        }) { (finished) in
            
            completion?()
        }
        
    }

    
}

