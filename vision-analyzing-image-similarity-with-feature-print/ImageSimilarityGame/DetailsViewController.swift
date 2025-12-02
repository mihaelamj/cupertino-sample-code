/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
ViewController to display the similarity graph of the contestant's images.
*/

import UIKit

class DetailsCell: UICollectionViewCell {
    static let reuseIdentifier = "DetailsCell"
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var label: UILabel!

    override var isSelected: Bool {
        didSet {
            super.isSelected = isSelected
            contentView.backgroundColor = isSelected ? contentView.tintColor : nil
        }
    }
}

class DetailsBackgroundView: UICollectionReusableView {
    static let reuseIdentifier = "DetailsBackground"
    
    private var pathLayer = CAShapeLayer()
    private let barWidth = CGFloat(14)
    private lazy var halfBarWidth = barWidth / 2
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupPathLayer()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupPathLayer()
    }
    
    private func setupPathLayer() {
        pathLayer.strokeColor = tintColor.cgColor
        pathLayer.fillColor = tintColor.cgColor
        pathLayer.lineWidth = 2
        self.layer.addSublayer(pathLayer)
    }
    
    func setNodeCoordinates(_ coords: [IndexPath: CGPoint]) {
        // Align with super layer
        pathLayer.frame = self.layer.bounds
        // Create new empty path
        let path = UIBezierPath()
        // Coordinates of original are at index path (0, 0)
        let originalCoord = coords[IndexPath(item: 0, section: 0)]!
        // Add lines to nodes
        for (_, coord) in coords {
            path.move(to: originalCoord)
            path.addLine(to: coord)
        }
        // Assign new path to layer
        pathLayer.path = path.cgPath
    }
}

class DetailsViewController: UICollectionViewController {
    
    var nodes = [(url: URL?, label: String, distance: Float)]()
    var detailsLayout: DetailsLayout {
        guard let detailsLayout = collectionViewLayout as? DetailsLayout else {
            fatalError("Unexpected layout type.")
        }
        return detailsLayout
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        collectionView.register(DetailsBackgroundView.self,
                                forSupplementaryViewOfKind: DetailsLayout.backgroundViewKind,
                                withReuseIdentifier: DetailsBackgroundView.reuseIdentifier)
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return nodes.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DetailsCell.reuseIdentifier, for: indexPath)
        guard let detailsCell = cell  as? DetailsCell else {
            fatalError("Unexpected cell type.")
        }
        
        let node = nodes[indexPath.item]
        if let url = node.url {
            detailsCell.imageView.image = UIImage(contentsOfFile: url.path)
        }
        detailsCell.label.text = node.label
        
        return detailsCell
    }
    
    override func collectionView(_ collectionView: UICollectionView,
                                 viewForSupplementaryElementOfKind kind: String,
                                 at indexPath: IndexPath) -> UICollectionReusableView {
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: DetailsLayout.backgroundViewKind,
                                                                   withReuseIdentifier: DetailsBackgroundView.reuseIdentifier,
                                                                   for: indexPath)
        guard let backgroundView = view as? DetailsBackgroundView else {
            fatalError("Unexpected background view type.")
        }
        
        backgroundView.setNodeCoordinates(detailsLayout.cellCenters)
        return backgroundView
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        var title = "Details"
        var prompt = "Tap on image to see distance value"
        if indexPath.item > 0 {
            let node = nodes[indexPath.item]
            title = node.label
            prompt = "Distance: \(node.distance)"
        }
        navigationItem.title = title
        navigationItem.prompt = prompt
    }
    
    @IBAction func toggleLayout(_ sender: Any) {
        guard let detailsLayout = collectionViewLayout as? DetailsLayout else {
            return
        }
        detailsLayout.appearance = (detailsLayout.appearance == .vertical) ? .circular : .vertical
        collectionView.reloadData()
    }
}

class DetailsLayout: UICollectionViewLayout {

    static let backgroundViewKind = "DetailsLayoutBackgroundViewKind"
    private var cellAttributes = [IndexPath: UICollectionViewLayoutAttributes]()
    
    enum Appearance {
        case vertical
        case circular
    }
    
    var appearance = Appearance.vertical {
        didSet {
            invalidateLayout()
        }
    }
    var cellCenters: [IndexPath: CGPoint] {
        return cellAttributes.mapValues({ $0.center })
    }
    
    func prepareCircularLayout(for collectionView: UICollectionView, detailsViewController: DetailsViewController) {
        let safeArea = collectionView.frame.inset(by: collectionView.safeAreaInsets)
        let itemSize = CGFloat(80)
        let halfItemSize = itemSize / 2
        let layoutMargin = CGFloat(8)
        let numberOfItems = collectionView.numberOfItems(inSection: 0)
        var shortestDistance = detailsViewController.nodes[1].distance
        let longestDistance = detailsViewController.nodes.last!.distance
        if shortestDistance == longestDistance {
            shortestDistance = 0
        }
        let centerPoint = CGPoint(x: safeArea.width / 2, y: safeArea.height / 2)
        let maxRadius = CGFloat(safeArea.width / 2 - layoutMargin - halfItemSize)
        let minRadius = CGFloat(itemSize + layoutMargin)
        let radiusRange = maxRadius - minRadius
        let angleStep = CGFloat.pi * 2 / CGFloat(numberOfItems - 1)
        var angle = -CGFloat.pi / 2
        for idx in 0 ..< numberOfItems {
            let node = detailsViewController.nodes[idx]
            let nodePosition: CGPoint
            if idx == 0 {
                nodePosition = centerPoint
            } else {
                let nodeDistance = CGFloat((node.distance - shortestDistance) / (longestDistance - shortestDistance))
                let point = CGPoint(x: minRadius + radiusRange * nodeDistance, y: 0)
                let transform = CGAffineTransform(translationX: centerPoint.x, y: centerPoint.y).rotated(by: angle)
                let rotatedPoint = point.applying(transform)
                nodePosition = CGPoint(x: round(rotatedPoint.x), y: round(rotatedPoint.y))
                angle += angleStep
            }
            let idxPath = IndexPath(item: idx, section: 0)
            let attrs = UICollectionViewLayoutAttributes(forCellWith: idxPath)
            attrs.size = CGSize(width: itemSize, height: itemSize)
            attrs.center = nodePosition
            cellAttributes[idxPath] = attrs
        }
    }
    
    func prepareVerticalLayout(for collectionView: UICollectionView, detailsViewController: DetailsViewController) {
        let safeArea = collectionView.frame.inset(by: collectionView.safeAreaInsets)
        let itemSize = CGFloat(80)
        let halfItemSize = itemSize / 2
        let layoutMargin = CGFloat(8)
        let numberOfItems = collectionView.numberOfItems(inSection: 0)
        var shortestDistance = detailsViewController.nodes[1].distance
        let longestDistance = detailsViewController.nodes.last!.distance
        if shortestDistance == longestDistance {
            shortestDistance = 0
        }
        let bottomPoint = CGPoint(x: safeArea.width / 2, y: safeArea.height - layoutMargin - halfItemSize)
        let topPoint = CGPoint(x: safeArea.width / 2, y: layoutMargin * 2 + itemSize)
        let verticalRange = bottomPoint.y - topPoint.y
        var leftSidedCell = true
        for idx in 0 ..< numberOfItems {
            let node = detailsViewController.nodes[idx]
            let horizontalPosition: CGFloat
            let verticalPosition: CGFloat
            if idx == 0 {
                horizontalPosition = safeArea.width / 2
                verticalPosition = layoutMargin + halfItemSize
            } else {
                horizontalPosition = (leftSidedCell ? layoutMargin + halfItemSize : safeArea.width - layoutMargin - halfItemSize)
                verticalPosition = topPoint.y + verticalRange * CGFloat((node.distance - shortestDistance) / (longestDistance - shortestDistance))
            }
            let idxPath = IndexPath(item: idx, section: 0)
            let attrs = UICollectionViewLayoutAttributes(forCellWith: idxPath)
            attrs.size = CGSize(width: itemSize, height: itemSize)
            attrs.center = CGPoint(x: horizontalPosition, y: verticalPosition)
            cellAttributes[idxPath] = attrs
            leftSidedCell.toggle()
        }
    }
    
    override func prepare() {
        cellAttributes.removeAll()
        guard let collectionView = collectionView, let detailsVC = collectionView.dataSource as? DetailsViewController else {
            return
        }

        switch appearance {
        case .vertical:
            prepareVerticalLayout(for: collectionView, detailsViewController: detailsVC)
        case .circular:
            prepareCircularLayout(for: collectionView, detailsViewController: detailsVC)
        }
    }
    
    override var collectionViewContentSize: CGSize {
        if let collectionView = collectionView {
            return collectionView.bounds.inset(by: collectionView.safeAreaInsets).size
        } else {
            return super.collectionViewContentSize
        }
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attrs = cellAttributes[indexPath]
        return attrs
    }
    
    override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard elementKind == DetailsLayout.backgroundViewKind, indexPath == IndexPath(item: 0, section: 0) else {
            // This layout only supports single background supplementary view
            return nil
        }
        let attrs = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: elementKind, with: indexPath)
        if let collectionView = collectionView {
            attrs.frame = collectionView.frame
        }
        attrs.zIndex = -1
        return attrs
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        // all items and background are visible at all times
        let cellAttrs = Array(cellAttributes.values)
        let backgroundAttrs = layoutAttributesForSupplementaryView(ofKind: DetailsLayout.backgroundViewKind, at: IndexPath(item: 0, section: 0))!
        return [backgroundAttrs] + cellAttrs
    }
}
