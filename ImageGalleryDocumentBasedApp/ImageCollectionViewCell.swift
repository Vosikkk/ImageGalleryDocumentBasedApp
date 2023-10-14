//
//  ImageCollectionViewCell.swift
//  ImageGalleryDocumentBasedApp
//
//  Created by Саша Восколович on 12.10.2023.
//

import UIKit

let cache = URLCache.shared


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
        guard let url = imageURL else { return }
        imageGallery.image = nil
        let request = URLRequest(url: url)
        spinner?.startAnimating()
        DispatchQueue.global(qos: .userInitiated).async {
            if let data = cache.cachedResponse(for: request)?.data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    print("cache")
                    self.imageGallery?.transition(to: image)
                    self.spinner.stopAnimating()
                }
            } else {
                URLSession.shared.dataTask(with: request) { data, response, error in
                    print("network")
                    if let data = data,
                        let response = response, ((response as? HTTPURLResponse)?.statusCode ?? 500) < 300 || (response.url?.absoluteString.hasPrefix("file"))!,
                        let image = UIImage(data: data),
                        url == self.imageURL {
                        let cacheData = CachedURLResponse(response: response, data: data)
                        cache.storeCachedResponse(cacheData, for: request)
                        DispatchQueue.main.async {
                            self.imageGallery.image = image
                            self.spinner.stopAnimating()
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.spinner.stopAnimating()
                            self.imageGallery.image = "Error 😡".emojiToImage()
                            self.changeAspectRatio?()
                        }
                    }
                }.resume()
            }
        }
        spinner.stopAnimating()
    }
}
