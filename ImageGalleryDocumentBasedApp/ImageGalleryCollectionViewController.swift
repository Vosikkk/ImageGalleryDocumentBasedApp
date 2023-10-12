//
//  ImageGalleryCollectionViewController.swift
//  ImageGalleryDocumentBasedApp
//
//  Created by Саша Восколович on 12.10.2023.
//

import UIKit

class ImageGalleryCollectionViewController: UICollectionViewController {

    // MARK: - Properties
   
    private var scale: CGFloat = 1 {
        didSet {
            collectionView?.collectionViewLayout.invalidateLayout()
        }
    }
    
    private var gapItems: CGFloat {
        return (flowLayout?.minimumInteritemSpacing)! * CGFloat((Constants.columnCount - 1.0))
    }
    private var gapSection: CGFloat {
        return (flowLayout?.sectionInset.right)! * 2.0
    }
    
    private var boundsColectionWidth: CGFloat {
        return (collectionView?.bounds.width)!
    }
    
    var imageCollection = ImageGallery() {
        didSet {
           collectionView?.reloadData()
        }
    }
   
    private var flowLayout: UICollectionViewFlowLayout? {
           return collectionView?.collectionViewLayout as? UICollectionViewFlowLayout
    }
    private var predefinedWidth: CGFloat {
        let width = floor((boundsColectionWidth - gapItems - gapSection) / CGFloat(Constants.columnCount)) * scale
        return min(max(width, boundsColectionWidth * Constants.minWidthRation), boundsColectionWidth)
    }
    private var garbageView = GarbageView()
    
    var document: ImageGalleryDocument?
    
    
    // MARK: - Controller life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView?.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(zoom)))
        collectionView!.dropDelegate = self
        collectionView!.dragDelegate = self
        
        if let url = try? FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true).appending(path: "Untitled.json") {
            document = ImageGalleryDocument(fileURL: url)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let navBounds = navigationController?.navigationBar.bounds {
            garbageView.frame = CGRect(x: navBounds.width * 0.6, y: 0.0, width: navBounds.width * 0.4, height: navBounds.height)
            let barButton = UIBarButtonItem(customView: garbageView)
            navigationItem.rightBarButtonItem = barButton
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        document?.open { success in
            if success {
                self.title = self.document?.localizedName
                self.imageCollection = self.document?.imageGallery ?? ImageGallery()
            }
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        flowLayout?.invalidateLayout()
    }
    
    
    @IBAction func save(_ sender: UIBarButtonItem? = nil) {
        document?.imageGallery = imageCollection
        if document?.imageGallery != nil {
            document?.updateChangeCount(.done)
        }
    }
    
   
    @IBAction func done(_ sender: UIBarButtonItem) {
        save()
        document?.close()
    }
    
    
    
    
    // MARK: - private functions
    
    @objc private func zoom(_ gesture: UIPinchGestureRecognizer) {
        if gesture.state == .changed {
            scale *= gesture.scale
            gesture.scale = 1.0
        }
    }
    private func dragItems(at indexPath: IndexPath) -> [UIDragItem] {
        if let itemCell = collectionView.cellForItem(at: indexPath) as? ImageCollectionViewCell, let image = itemCell.imageGallery.image {
            let dragItem = UIDragItem(itemProvider: NSItemProvider(object: image))
            dragItem.localObject = indexPath //imageCollection.images[indexPath.item]
            return [dragItem]
        } else {
            return []
        }
    }
    
    // MARK: - Navigation

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            switch identifier {
            case "Show Image":
                if let imageCell = sender as? ImageCollectionViewCell,
                   let indexPath = collectionView?.indexPath(for: imageCell),
                   let imageMVC = segue.destination as? ImageViewController {
                    imageMVC.imageURL = imageCollection.images[indexPath.item].url
                }
            default: break
            }
        }
    }
    

    // MARK: - UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageCollection.images.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Image Cell", for: indexPath)
        if let imageCell = cell as? ImageCollectionViewCell {
            // if we've couldn't load image so make error image with the same size
            imageCell.changeAspectRatio = { [weak self] in
                if let aspectRatio = self?.imageCollection.images[indexPath.item].aspectRatio, aspectRatio < 0.95 || aspectRatio > 1.05 {
                    self?.imageCollection.images[indexPath.item].aspectRatio = 1.0
                    self?.flowLayout?.invalidateLayout()
                }
            }
            imageCell.imageURL = imageCollection.images[indexPath.item].url
        }
    
        return cell
    }
    
    // MARK: Nested type
   
    struct Constants {
        static let columnCount = 3.0
        static let minWidthRation = CGFloat(0.03)
    }
}


// MARK: - UICollectionViewDelegateFlowLayout

extension ImageGalleryCollectionViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Make each image with the same width
        let width = predefinedWidth
        let aspectRatio = CGFloat(imageCollection.images[indexPath.item].aspectRatio)
        return CGSize(width: width, height: width / aspectRatio)
    }
}

// MARK: - UICollectionViewDropDelegate

extension ImageGalleryCollectionViewController: UICollectionViewDropDelegate {
    
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        let isSelf = session.localDragSession?.localContext as? UICollectionView == collectionView
        
        // outside is copy, inside is move(change destination)
        return UICollectionViewDropProposal(operation: isSelf ? .move : .copy, intent: .insertAtDestinationIndexPath)
    }
    
    
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        let isSelf = session.localDragSession?.localContext as? UICollectionView == collectionView
        if isSelf {
            // we are in collection so we need take only image
            return session.canLoadObjects(ofClass: UIImage.self)
        } else {
            // outside of program so we need url else
            return session.canLoadObjects(ofClass: UIImage.self) && session.canLoadObjects(ofClass: URL.self)
        }
    }

    
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        let destanationIndexPath = coordinator.destinationIndexPath ?? IndexPath(item: 0, section: 0)
        for item in coordinator.items {
            if let sourceIndexPath = item.sourceIndexPath {
                // local drag
                // Synchronize reloading of the collection
                collectionView.performBatchUpdates {
                    let dragedImage = imageCollection.images.remove(at: sourceIndexPath.item)
                    imageCollection.images.insert(dragedImage, at: destanationIndexPath.item)
                    collectionView.deleteItems(at: [sourceIndexPath])
                    collectionView.insertItems(at: [destanationIndexPath])
                
                }
                coordinator.drop(item.dragItem, toItemAt: destanationIndexPath)
    
            } else {
                // Drag from outside
                // Move image to the second prototype our image from outside
                let placeHolderContext = coordinator.drop(item.dragItem, to: UICollectionViewDropPlaceholder(insertionIndexPath: destanationIndexPath, reuseIdentifier: "PlaceHolderCell"))
               
                var imageURLLocal: URL?
                var aspectRatioLocal: Double?
                //Load image, not main thread
                item.dragItem.itemProvider.loadObject(ofClass: UIImage.self) { provider, error in
                    DispatchQueue.main.async {
                        if let image = provider as? UIImage {
                            aspectRatioLocal = Double(image.size.width) / Double(image.size.height)
                        }
                    }
                }
                // Load URL
                item.dragItem.itemProvider.loadObject(ofClass: NSURL.self) { provider, error in
                    DispatchQueue.main.async {
                        if let url = provider as? URL {
                            imageURLLocal = url.imageURL
                        }
                        if imageURLLocal != nil, aspectRatioLocal != nil {
                            // everything ok so add image to the collection
                            placeHolderContext.commitInsertion { insertionIndexPath in
                                self.imageCollection.images.insert(ImageModel(url: imageURLLocal!, aspectRatio: aspectRatioLocal!), at: insertionIndexPath.item)// because recieved image and url is async so destination variable may changed
                            }
                        } else {
                            placeHolderContext.deletePlaceholder()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - UICollectionViewDragDelegate

extension ImageGalleryCollectionViewController: UICollectionViewDragDelegate {
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        // Hey dropSessionDidUpdate it's drag from my app, so move it bro
        session.localContext = collectionView
        return dragItems(at: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        return dragItems(at: indexPath)
    }
}

