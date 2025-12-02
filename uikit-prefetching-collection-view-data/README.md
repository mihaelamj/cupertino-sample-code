# Prefetching collection view data

Load data for collection view cells before they display.

## Overview

A collection view displays an ordered collection of cells in customizable layouts. The [`UICollectionViewDataSourcePrefetching`](https://developer.apple.com/documentation/uikit/uicollectionviewdatasourceprefetching) protocol helps provide a smoother user experience by prefetching the data necessary for upcoming collection view cells. When you enable prefetching, the collection view requests the data before it needs to display the cell. When it's time to display the cell, the data is already locally cached.

The image below shows cells outside the bounds of the collection view that have been prefetched:   

![An image that shows a collection view implementation. The collection view has a white background, and two columns of cells that each have a red background. A callout that says Displayed UICollectionView highlights the first three rows of cells. Below that, another callout that says Prefetched collection view cells highlights the last full row of cells and a partial row of cells.](Documentation/screenshot.png)

- Note: The storyboard in this project contains a collection view controller with a collection view that has Clips To Bounds disabled. With this configuration, you can visualize the cells before they display.

## Enable prefetching

The root view controller uses an instance of the `CustomDataSource` class to provide data to its [`UICollectionView`](https://developer.apple.com/documentation/uikit/uicollectionview) instance. The `CustomDataSource` class implements the `UICollectionViewDataSourcePrefetching` protocol to begin fetching the data required to populate cells.

``` swift
class CustomDataSource: NSObject, UICollectionViewDataSource, UICollectionViewDataSourcePrefetching {
```

In addition to assigning the `CustomDataSource` instance to the collection view's [`dataSource`](https://developer.apple.com/documentation/uikit/uicollectionview/1618091-datasource) property, the sample code project also assigns it to the [`prefetchDataSource`](https://developer.apple.com/documentation/uikit/uicollectionview/1771768-prefetchdatasource) property.

``` swift
// Set the collection view's data source.
collectionView.dataSource = dataSource

// Set the collection view's prefetching data source.
collectionView.prefetchDataSource = dataSource
```

## Load data asynchronously

Prefetching data is a tool to use when loading data is a slow or expensive process — for example, when fetching data over the network. In these circumstances, it's best to perform data loading asynchronously. In this sample, the `AsyncFetcher` class fetches data asynchronously, simulating a network request.

First, the sample implements the [`UICollectionViewDataSourcePrefetching`](https://developer.apple.com/documentation/uikit/uicollectionviewdatasourceprefetching) prefetch method, invoking the appropriate method on the asynchronous fetcher.

``` swift
func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
    // Begin asynchronously fetching data for the requested index paths.
    for indexPath in indexPaths {
        let model = models[indexPath.row]
        asyncFetcher.fetchAsync(model.identifier)
    }
}
```

- Note: Developers can create their own version of `AsyncFetcher` to fit their requirements. The implementation in this sample makes heavy use of [`Operation`](https://developer.apple.com/documentation/foundation/operation) and [`OperationQueue`](https://developer.apple.com/documentation/foundation/operationqueue), leveraging their ability to handle thread safety and cancellation. Developers might consider a similar approach.

When prefetching is complete, the sample adds the cell's data to the `AsyncFetcher`'s cache, so it's ready to use when the cell displays. The cell's background color changes from white to red when data is available for that cell.

``` swift
/**
 Configures the cell for display based on the model.
 
 - Parameters:
     - data: An optional `DisplayData` object to display.
 
 - Tag: Cell_Config
*/
func configure(with data: DisplayData?) {
    backgroundColor = data?.color
}
```

## Populate cells for display

Before populating a cell, the `CustomDataSource` checks for any prefetched data that it can use. If none is available, the `CustomDataSource` makes a fetch request and the cell updates in the fetch request's completion handler.

``` swift
func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Cell.reuseIdentifier, for: indexPath) as? Cell else {
        fatalError("Expected `\(Cell.self)` type for reuseIdentifier \(Cell.reuseIdentifier). Check the configuration in Main.storyboard.")
    }
    
    let model = models[indexPath.row]
    let identifier = model.identifier
    cell.representedIdentifier = identifier
    
    // Check if the `asyncFetcher` has already fetched data for the specified identifier.
    if let fetchedData = asyncFetcher.fetchedData(for: identifier) {
        // The system has fetched and cached the data; use it to configure the cell.
        cell.configure(with: fetchedData)
    } else {
        // There is no data available; clear the cell until the fetched data arrives.
        cell.configure(with: nil)

        // Ask the `asyncFetcher` to fetch data for the specified identifier.
        asyncFetcher.fetchAsync(identifier) { fetchedData in
            DispatchQueue.main.async {
                /*
                 The `asyncFetcher` has fetched data for the identifier. Before
                 updating the cell, check whether the collection view has recycled it to represent other data.
                 */
                guard cell.representedIdentifier == identifier else { return }
                
                // Configure the cell with the fetched image.
                cell.configure(with: fetchedData)
            }
        }
    }

    return cell
}
```

## Cancel unnecessary fetches

The sample implements the [`collectionView(_:cancelPrefetchingForItemsAt:)`](https://developer.apple.com/documentation/uikit/uicollectionviewdatasourceprefetching/1771769-collectionview) delegate method to cancel any in-progress data fetches that are no longer required.

``` swift
func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
    // Cancel any in-flight requests for data for the specified index paths.
    for indexPath in indexPaths {
        let model = models[indexPath.row]
        asyncFetcher.cancelFetch(model.identifier)
    }
}
```
