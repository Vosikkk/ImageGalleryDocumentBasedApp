//
//  ImageCollectionViewCell.swift
//  ImageGalleryDocumentBasedApp
//
//  Created by Саша Восколович on 12.10.2023.
//

import UIKit

class ImageCollectionViewCell: UICollectionViewCell {
    
    // MARK: - Outlets
    
    @IBOutlet weak var imageGallery: UIImageView!
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    // MARK: - properties
   
    var imageURL: URL? {
        didSet { updateUI() }
    }
    
    var changeAspectRatio: (() -> Void)?
    
    // MARK: - private function
    
    private func updateUI() {
        if let url = imageURL {
            imageGallery.image = nil
            spinner?.startAnimating()
            DispatchQueue.global(qos: .userInitiated).async {
                let urlContents = try? Data(contentsOf: url)
                DispatchQueue.main.async {
                    if let imageData = urlContents, url == self.imageURL, let image = UIImage(data: imageData) {
                        self.imageGallery?.image = image
                    } else {
                        // if image wasn't loaded so show error image
                        self.imageGallery?.image = "Error 😡".emojiToImage()
                        self.changeAspectRatio?()
                    }
                    self.spinner?.stopAnimating()
                }
            }
        }
    }
}
