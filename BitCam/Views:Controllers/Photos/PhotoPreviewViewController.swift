//
//  PhotoPreviewViewController.swift
//  LumenCamera
//
//  Created by Mohssen Fathi on 10/30/16.
//  Copyright © 2016 mohssenfathi. All rights reserved.
//

import UIKit
import Photos

protocol PhotoPreviewViewControllerDelegate {
    func copy (_ previewController: PhotoPreviewViewController, image: UIImage)
    func share(_ previewController: PhotoPreviewViewController, image: UIImage)
}

class PhotoPreviewViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var arrowButton: UIButton!
    @IBOutlet weak var informationViewHeight: NSLayoutConstraint!
    @IBOutlet weak var informationOffset: NSLayoutConstraint!
    @IBOutlet weak var minimumImageHeight: NSLayoutConstraint!
    
    var asset: PHAsset?
    var image: UIImage?
    var metadata = [[String : Any]]()
    var actionItems = [UIPreviewActionItem]()
    
    var delegate: PhotoPreviewViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let asset = asset {
            
            MetadataFormatter.sharedFormatter.formatMetadata(asset, completion: { metadata in
                self.metadata = metadata
                self.informationViewHeight.constant = 60.0 * CGFloat(metadata.count)
                self.tableView.reloadData()
            })
            
            PhotosManager.sharedManager.imageForAsset(asset, size: CGSize(width: 1000, height: 1000), progress: { (progress, error, stop, info) in
                
            }, completion: { (image) in

                self.image = image
                self.imageView.image = image
                
                if let image = image {
                    self.minimumImageHeight.constant = self.view.frame.width * (image.size.height / image.size.width)
                }
            })
        }
        
        if traitCollection.forceTouchCapability == .available {
            setupActionItems()
            registerForPreviewing(with: self, sourceView: self.view)
        }
        
        //let shareButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(PhotoPreviewViewController.share))
        
        let shareButton = UIBarButtonItem(image: #imageLiteral(resourceName: "share"), style: UIBarButtonItemStyle.plain, target: self
            , action: #selector(PhotoPreviewViewController.share))
        
        shareButton.tintColor = .white
        self.navigationItem.rightBarButtonItem = shareButton
        navigationController?.navigationBar.tintColor = .white
        
        tableView.rowHeight = 60.0
        informationViewHeight.constant = 60.0 * CGFloat(metadata.count)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if navigationController != nil {
            informationOffset.constant = view.frame.height - 44.0
            imageView.contentMode = .scaleAspectFit
            arrowButton.isHidden = false
        }
        else {
            informationOffset.constant = preferredContentSize.height
            imageView.contentMode = .scaleAspectFill
            arrowButton.isHidden = true
        }
        
        arrowButton.transform = CGAffineTransform(rotationAngle: .pi)
    }
    
    func share() {
        
        guard let image = image else { return }
        guard let imageData = UIImageJPEGRepresentation(image, 1.0) else { return }
        
        let activityController = UIActivityViewController(activityItems: [imageData], applicationActivities: nil)
        self.present(activityController, animated: true, completion: nil)
        
    }
    
    @IBAction func arrowButtonPressed(_ sender: UIButton) {

        var transform: CGAffineTransform!
        var offset: CGPoint!
        
        if sender.transform.isIdentity {
            offset = CGPoint(x: 0, y: 0)
            transform = CGAffineTransform(rotationAngle: .pi)
        }
        else {
            offset = CGPoint(x: 0, y: tableView.superview!.frame.maxY - view.frame.height + 44.0)
            transform = .identity
        }
        
        UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.7, options: .beginFromCurrentState, animations: {
            self.arrowButton.transform = transform
        }, completion: nil)
        
        scrollView.setContentOffset(offset, animated: true)
    }
}

extension PhotoPreviewViewController: UIViewControllerPreviewingDelegate {
    
    @available(iOS 9.0, *)
    public func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        present(viewControllerToCommit, animated: true, completion: nil)
    }

    @available(iOS 9.0, *)
    public func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        return nil
    }
    
    override var previewActionItems: [UIPreviewActionItem] {
        return actionItems
    }
    
    func setupActionItems() {
        
        
        let copyAction = UIPreviewAction(title: "Copy", style: .default, handler: { (action, viewController) in
            guard let image = self.image else { return }
            self.delegate?.copy(self, image: image)
        })
        
        let shareAction = UIPreviewAction(title: "Share", style: .default, handler: { (action, viewController) in
            guard let image = self.image else { return }
            self.delegate?.share(self, image: image)
        })
        
        actionItems = [copyAction, shareAction]
        
    }
    
}

extension PhotoPreviewViewController: UIScrollViewDelegate {
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
     
        UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.7, options: .beginFromCurrentState, animations: {
            
            self.arrowButton.transform = (velocity.y > 0.0) ? .identity : CGAffineTransform(rotationAngle: CGFloat.pi)
            
        }, completion: nil)
        
    }
    
}


extension PhotoPreviewViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return metadata.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        let titleLabel = cell.viewWithTag(101) as! UILabel
        let valueLabel = cell.viewWithTag(102) as! UILabel
        
        let dict = metadata[(indexPath as NSIndexPath).row] as! [String : String]
        titleLabel.text = dict["title"]?.capitalized
        valueLabel.text = dict["value"]
        
        return cell
        
    }
    
}

extension PhotosViewController: UITableViewDelegate {
    
}
