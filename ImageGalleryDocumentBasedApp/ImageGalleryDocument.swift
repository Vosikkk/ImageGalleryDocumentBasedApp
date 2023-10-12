//
//  ImageGalleryDocument.swift
//  ImageGalleryDocumentBasedApp
//
//  Created by Саша Восколович on 12.10.2023.
//

import UIKit

class ImageGalleryDocument: UIDocument {
    
    
    var imageGallery: ImageGallery?
    
    
    override func contents(forType typeName: String) throws -> Any {
        return imageGallery?.json ?? Data()
    }
    
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        if let json = contents as? Data {
            imageGallery = ImageGallery(json: json)
        }
    }
}

