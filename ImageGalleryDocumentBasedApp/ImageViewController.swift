//
//  ImageViewController.swift
//  ImageGalleryDocumentBasedApp
//
//  Created by Саша Восколович on 12.10.2023.
//

import UIKit

class ImageViewController: UIViewController, UIScrollViewDelegate {

    // MARK: - properties
    
    // URL of the image to be displayed
    var imageURL: URL? {
        didSet {
            // Reset the current image when a new URL is set
            image = nil
           
            // If the view is visible, fetch and display the new image
            if view.window != nil {
                fetchImage()
            }
        }
    }
    
    // The image to be displayed in the view
    private var image: UIImage? {
        get {
            return imageView.image
        }
        set {
            // Set the image and adjust the view's content size
            imageView.image = newValue
            imageView.sizeToFit()
            scrollView?.contentSize = imageView.frame.size
            spinner?.stopAnimating()
            autoZoom = true
            zoomScaleToFit()
            
        }
    }
    
    // Image view to display the fetched image
    private var imageView = UIImageView()
    
    
    // Flag to control auto-zoom behavior
    private var autoZoom = true
    
    // UIScrollView delegate method called before zooming begins
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        autoZoom = false
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let xOffset = max((scrollView.bounds.width - scrollView.contentSize.width) * 0.5, 0)
        let yOffset = max((scrollView.bounds.height - scrollView.contentSize.height) * 0.5, 0)
        
        scrollView.contentInset = UIEdgeInsets(top: yOffset, left: xOffset, bottom: 0, right: 0)
    }
    
    // MARK: - view cycle
    
    // Called when the view appears on the screen
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if imageView.image == nil {
            fetchImage()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // Called when the view's layout changes
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Ensure the image is zoomed to fit the screen
        zoomScaleToFit()
    }

    // MARK: - Outlets
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    @IBOutlet weak var scrollView: UIScrollView! {
        didSet {
            // Configure scroll view properties
            scrollView.minimumZoomScale = 0.03
            scrollView.maximumZoomScale = 5.0
            scrollView.delegate = self
            scrollView.addSubview(imageView)
        }
    }
    
    // Returns the view to be zoomed
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    // MARK: - private functions
    
    // Fetches the image from the specified URL
    private func fetchImage() {
        autoZoom = true
        if let url = imageURL {
            spinner.startAnimating()
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                let urlContents = try? Data(contentsOf: url)
                DispatchQueue.main.async {
                    if let imageData = urlContents, url == self?.imageURL {
                        // Set the fetched image
                        self?.image = UIImage(data: imageData)
                    }
                }
            }
        }
    }
    
    // Adjusts the zoom scale to fit the image to the screen
    private func zoomScaleToFit() {
        if !autoZoom {
            return
        }
        if let sv = scrollView, image != nil && (imageView.bounds.size.width > 0) && (scrollView.bounds.size.width > 0) {
            let widthRatio = scrollView.bounds.size.width / imageView.bounds.size.width
            let heightRatio = scrollView.bounds.size.height / imageView.bounds.size.height
            sv.zoomScale = (widthRatio > heightRatio) ? widthRatio : heightRatio
             sv.contentOffset = CGPoint(x: (imageView.frame.size.width - sv.frame.size.width) / 2,
                                       y: (imageView.frame.size.height - sv.frame.size.height) / 2)
        }
    }
}
