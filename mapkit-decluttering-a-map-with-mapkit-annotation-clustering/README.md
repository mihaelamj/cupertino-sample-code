# Decluttering a Map with MapKit Annotation Clustering

Enhance the readability of a map by replacing overlapping annotations with a clustering annotation view.

## Overview

TANDm is a fictional bike sharing app that uses annotation clustering to provide an uncluttered map. The app shows how MapKit automatically groups two or more annotations into a single annotation when spacing on the map doesn't permit each annotation to be visible without overlapping. This enhances the readability of the map by replacing overlapping annotations with a clustering annotation view.

## Annotation Clustering

To group annotations into a cluster, set the [`clusteringIdentifier`][1] property to the same value on each annotation view in the group. For example, to show overlapping unicycle annotations in a clustering annotation view, TANDm sets `clusteringIdentifier` on each instance of [`UnicycleAnnotationView`][2] to `"unicycle"`.

[1]:https://developer.apple.com/documentation/mapkit/mkannotationview/2867297-clusteringidentifier
[2]:x-source-tag://UnicycleAnnotationView

``` swift
override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
    super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
    clusteringIdentifier = "unicycle"
}
```
[View in Source](x-source-tag://ClusterIdentifier)

## Display Priority

To determine how an annotation view behaves when it overlaps another annotation view, set its [`displayPriority`][3] property. In the sample app, the map view is likely to hide the unicycle annotation if it overlaps with another annotation because the unicycle annotation view has a display priority of [`defaultLow`][4], while the display priorities for bicycle and tricycle are set to [`defaultHigh`][5]. Here's an example of setting the display priority while preparing an instance of [`BicycleAnnotationView`][8] for reuse:

[3]:https://developer.apple.com/documentation/mapkit/mkannotationview/2867298-displaypriority
[4]:https://developer.apple.com/documentation/mapkit/mkfeaturedisplaypriority/2867295-defaultlow
[5]:https://developer.apple.com/documentation/mapkit/mkfeaturedisplaypriority/2867300-defaulthigh

``` swift
override func prepareForDisplay() {
    super.prepareForDisplay()
    displayPriority = .defaultHigh
    markerTintColor = UIColor.bicycleColor
    glyphImage = #imageLiteral(resourceName: "bicycle")
}
```
[View in Source](x-source-tag://DisplayConfiguration)

## Custom Clustering Annotation Views

Customize the behavior and appearance of a clustering annotation view by subclassing [`MKAnnotationView`][6]; for instance, to display hints about the annotations within the cluster. TANDm, for example, uses the custom clustering annotation view [`ClusterAnnotationView`][7] to show the ratio between bicycles and tricycles at a location.

[6]:https://developer.apple.com/documentation/mapkit/mkannotationview
[7]:x-source-tag://ClusterAnnotationView
[8]:x-source-tag://BicycleAnnotationView

``` swift
override func prepareForDisplay() {
    super.prepareForDisplay()
    
    if let cluster = annotation as? MKClusterAnnotation {
        let totalBikes = cluster.memberAnnotations.count
        
        if count(cycleType: .unicycle) > 0 {
            image = drawUnicycleCount(count: totalBikes)
        } else {
            let tricycleCount = count(cycleType: .tricycle)
            image = drawRatioBicycleToTricycle(tricycleCount, to: totalBikes)
        }
        
        if count(cycleType: .unicycle) > 0 {
            displayPriority = .defaultLow
        } else {
            displayPriority = .defaultHigh
        }
    }
}
```
[View in Source](x-source-tag://CustomCluster)
