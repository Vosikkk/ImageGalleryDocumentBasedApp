//
//  GarbageView.swift
//  ImageGalleryDocumentBasedApp
//
//  Created by Саша Восколович on 12.10.2023.
//

import UIKit

class GarbageView: UIView {

    var garbageViewDidChange: (() -> Void)?
    
        override init(frame: CGRect) {
            super.init(frame: frame)
            setUp()
        }
        
        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
            setUp()
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            // as an array so we take first element it's our trash set frame
            if self.subviews.count > 0 {
                self.subviews[0].frame = CGRect(x: bounds.width - bounds.height, y: 0, width: bounds.height, height: bounds.height)
            }
        }
        
        // MARK: - private function
        private func setUp() {
            let dropIteraction = UIDropInteraction(delegate: self)
            addInteraction(dropIteraction)
            backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0)
            let trashImage = UIImage.imageFromSystemBarButton(.trash)
            let myButton = UIButton()
            myButton.setImage(trashImage, for: .normal)
            self.addSubview(myButton)
        }
    }


    // MARK: - Drop iteraction

    extension GarbageView: UIDropInteractionDelegate {
       
        func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
            return session.canLoadObjects(ofClass: UIImage.self)
        }
        
        func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
            if session.localDragSession != nil {
                return UIDropProposal(operation: .copy)
            } else {
                return UIDropProposal(operation: .forbidden)
            }
        }
       
        func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
           
            // It's the same app so we can recevied all information about our collection and model
            if let collectionView = session.localDragSession?.localContext as? UICollectionView,
               let images = (collectionView.dataSource as? ImageGalleryCollectionViewController)?.imageCollection.images,
               let items = session.localDragSession?.items {
                
                var indexPathes = [IndexPath]()
                var indices = [Int]()
                
                // We know how to update our model and collection
                for item in items {
                    if let indexPath = item.localObject as? IndexPath {
                        let index = indexPath.item
                        indices += [index]
                        indexPathes += [indexPath]
                    }
                }
                
                collectionView.performBatchUpdates {
                    collectionView.deleteItems(at: indexPathes)
                    (collectionView.dataSource as? ImageGalleryCollectionViewController)?.imageCollection.images = images
                        .enumerated()
                        .filter{ !indices.contains($0.offset) }
                        .map{ $0.element }
                    self.garbageViewDidChange?()
                }
            }
        }
        
        // make images which we want so small and set position on the trash
        func dropInteraction(_ interaction: UIDropInteraction, previewForDropping item: UIDragItem, withDefault defaultPreview: UITargetedDragPreview) -> UITargetedDragPreview? {
            let target = UIDragPreviewTarget(container: self,
                                             center: CGPoint(x: bounds.width - bounds.height * 1 / 2,
                                                             y: bounds.size.height * 1 / 2),
                                             transform: CGAffineTransform(scaleX: 0.1, y: 0.1))
            return defaultPreview.retargetedPreview(with: target)
        }
    }



