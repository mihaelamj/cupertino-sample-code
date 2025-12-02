/*
See LICENSE folder for this sample’s licensing information.

Abstract:
`ItineraryViewController` displays a list of all the stops on the tour,
 along with a snapshot of each destination.
*/

import UIKit
import MapKit

class ItineraryViewController: UIViewController {
    
    /// The standard size of a snapshot image.
    private static let thumbnailSize = CGSize(width: 128, height: 128)
    
    /// The tour itinerary.
    private var itinerary: Itinerary!
    
    /// Results of creating Look Around snapshot images.
    private var lookAroundSnapshotResults = MapDataResults<MapItemID, UIImage>()
    
    @IBOutlet private weak var startButton: UIButton!
    
    /// The collection view showing the stops.
    private weak var collectionView: UICollectionView!
    
    /// The collection view's data source.
    private var dataSource: UICollectionViewDiffableDataSource<Section, ItineraryStop>!
    
    /// The single section identifier of the cells in this collection view's data source.
    private enum Section {
        case main
    }
    
    /// Configures the collection view and loads the itinerary that it displays.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure the collection view.
        createCollectionView()
        configureDataSource()
        
        // Load the itinerary data asynchronously, then update the collection view when done.
        Task { @MainActor in
            itinerary = await Itinerary()
            var snapshot = NSDiffableDataSourceSectionSnapshot<ItineraryStop>()
            snapshot.append(itinerary.stops)
            await dataSource.apply(snapshot, to: .main, animatingDifferences: false)
        }
    }
    
    /// Creates the collection view initially.
    private func createCollectionView() {
        let listConfiguration = UICollectionLayoutListConfiguration(appearance: .plain)
        let layout = UICollectionViewCompositionalLayout.list(using: listConfiguration)
        
        let collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        view.insertSubview(collectionView, belowSubview: startButton)
        collectionView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        collectionView.allowsSelection = false
        self.collectionView = collectionView
    }
    
    /// Configures the data source for this collection view.
    private func configureDataSource() {
        
        // Register the cell configuration function.
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, ItineraryStop>(handler: configureCell)
        
        // Set the collection view's data source to use the cell registration function when providing cells.
        dataSource = UICollectionViewDiffableDataSource<Section, ItineraryStop>(collectionView: collectionView) { collectionView, indexPath, item in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }
    }
    
    /// Configures a collection view cell for a stop on the itinerary.
    private func configureCell(cell: UICollectionViewListCell, indexPath: IndexPath, item: ItineraryStop) {
        
        // Set up the cell content configuration.
        var content = cell.defaultContentConfiguration()
        content.text = item.title
        content.imageProperties.reservedLayoutSize = ItineraryViewController.thumbnailSize
        content.imageProperties.maximumSize = ItineraryViewController.thumbnailSize
        
        // Choose an initial image, depending on whether a snapshot has been created,
        // could not be created, or has not yet been created.
        switch lookAroundSnapshotResults.availableResult(for: item.mapItemID) {
            
        case .success(let image):
            
            // The snapshot has been created.
            content.image = image
            content.secondaryText = nil
            
        case .failure:
            
            // Creation of the snapshot failed.
            content.imageProperties.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 40)
            content.imageProperties.tintColor = .lightGray
            content.image = UIImage(systemName: "mappin.slash.circle.fill")
            content.secondaryText = "Look Around is unavailable for this location"
            
        case nil:
            
            // The snapshot creation is pending or has not been started.
            content.imageProperties.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 40)
            content.imageProperties.tintColor = .lightGray
            content.image = UIImage(systemName: "binoculars")
            content.secondaryText = nil
            
            // Asynchronously attempt to create the snapshot.
            Task {
                /*
                 Create the snapshot from a Look Around scene, if possible. Note that this task doesn't need to do
                 anything with the result, because it's not needed until the cell is actually updated, when
                 `configureCell(cell:indexPath:item:)` is called again.
                 */
                _ = await lookAroundSnapshotResults.result(for: item.mapItemID) { @MainActor [self] in
                    
                    // Check if a Look Around scene is available.
                    if let lookaroundScene = try await itinerary.lookAroundScene(for: item.mapItemID) {
                        
                        // Use the specified image size.
                        let snapshotOptions = MKLookAroundSnapshotter.Options()
                        snapshotOptions.size = ItineraryViewController.thumbnailSize
                        
                        // Turn off all point of interest labels in the snapshot.
                        snapshotOptions.pointOfInterestFilter = MKPointOfInterestFilter.excludingAll
                        
                        // Set the resolution for the snapshot to the display scale, which is part of the trait collection.
                        snapshotOptions.traitCollection = traitCollection
                        
                        // Create the snapshot.
                        return try await MKLookAroundSnapshotter(scene: lookaroundScene, options: snapshotOptions).snapshot.image
                    }
                    
                    // Otherwise, store an error.
                    else {
                        throw MapDataError.sceneRequestFailed(item.mapItemID, item.mapItem.placemark.title)
                    }
                }
                
                // Update the cell with the snapshot.
                var updatedSnapshot = dataSource.snapshot()
                updatedSnapshot.reconfigureItems([item])
                await dataSource.apply(updatedSnapshot, animatingDifferences: true)
            }
        }
        
        // Use the new content configuration.
        cell.contentConfiguration = content
    }
    
    /// Prepares for a segue to the tour view controller.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "showTourMap" else { return }
        guard let tourViewController = segue.destination as? TourViewController else { return }
        
        // Inject the itinerary into the tour view controller.
        tourViewController.itinerary = itinerary
    }
}
