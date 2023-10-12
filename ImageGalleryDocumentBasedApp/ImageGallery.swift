//
//  ImageGallery.swift
//  ImageGalleryDocumentBasedApp
//
//  Created by Саша Восколович on 12.10.2023.
//

import Foundation
struct ImageModel: Codable {
    
    var url: URL
    var aspectRatio: Double
    
}

struct ImageGallery: Codable {
    
    var json: Data? {
        return try? JSONEncoder().encode(self)
    }
    var images = [ImageModel]()
    
    mutating func add(image: ImageModel) {
        images.append(image)
    }
    
    init() {
        self.images = [ImageModel]()
    }
    
    init?(json: Data) {
        if let newValue = try? JSONDecoder().decode(ImageGallery.self, from: json) {
            self = newValue
        } else {
            return nil
        }
    }
}
