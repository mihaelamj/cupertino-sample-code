/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The hosting configuration example.
*/

import UIKit
import SwiftUI

// An enum representing the sections of this collection view.
private enum HealthSection: Int, CaseIterable {
    case heartRate
    case healthCategories
    case sleep
    case steps
}

// A struct that stores the static data used in this example.
private struct StaticData {
    lazy var heartRateItems = HeartRateData.generateRandomData(quantity: 3)
    lazy var healthCategories = HealthCategory.allCases
    lazy var sleepItems = SleepData.generateRandomData(quantity: 4)
    lazy var stepItems = StepData.generateRandomData(days: 7)
}

class HostingConfigurationViewController: UIViewController, UICollectionViewDataSource {
    
    // The static data being displayed by this view controller.
    private var data = StaticData()
    
    // The collection view which will display the custom cells.
    private var collectionView: UICollectionView!
    
    override func loadView() {
        setUpCollectionView()
        view = collectionView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "SwiftUI in Cells"
        view.maximumContentSizeCategory = .extraExtraExtraLarge
    }
    
    // Creates the collection view with a compositional layout, which contains multiple sections of different layouts.
    private func setUpCollectionView() {
        let layout = UICollectionViewCompositionalLayout { [unowned self] sectionIndex, layoutEnvironment in
            switch HealthSection(rawValue: sectionIndex)! {
            case .heartRate:
                return createOrthogonalScrollingSection()
            case .healthCategories:
                return createListSection(layoutEnvironment)
            case .sleep:
                return createGridSection()
            case .steps:
                return createListSection(layoutEnvironment)
            }
        }
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemGroupedBackground
        collectionView.allowsSelection = false
        collectionView.dataSource = self
    }
    
    private struct LayoutMetrics {
        static let horizontalMargin = 16.0
        static let sectionSpacing = 10.0
        static let cornerRadius = 10.0
    }
    
    // Returns a compositional layout section for cells that will scroll orthogonally.
    private func createOrthogonalScrollingSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(100))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.8), heightDimension: .estimated(100))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        group.contentInsets = .zero
        group.contentInsets.leading = LayoutMetrics.horizontalMargin
        
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .groupPaging
        section.contentInsets = .zero
        section.contentInsets.trailing = LayoutMetrics.horizontalMargin
        section.contentInsets.bottom = LayoutMetrics.sectionSpacing
        return section
    }
    
    // Returns a compositional layout section for cells in a grid.
    private func createGridSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .estimated(120))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(120))
        let group = NSCollectionLayoutGroup.horizontalGroup(with: groupSize, repeatingSubitem: item, count: 2)
        group.interItemSpacing = .fixed(8)
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 8
        section.contentInsets = .zero
        section.contentInsets.leading = LayoutMetrics.horizontalMargin
        section.contentInsets.trailing = LayoutMetrics.horizontalMargin
        section.contentInsets.bottom = LayoutMetrics.sectionSpacing
        return section
    }
    
    // Returns a compositional layout section for cells in a list.
    private func createListSection(_ layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        let section = NSCollectionLayoutSection.list(using: config, layoutEnvironment: layoutEnvironment)
        section.contentInsets = .zero
        section.contentInsets.leading = LayoutMetrics.horizontalMargin
        section.contentInsets.trailing = LayoutMetrics.horizontalMargin
        section.contentInsets.bottom = LayoutMetrics.sectionSpacing
        return section
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        HealthSection.allCases.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch HealthSection(rawValue: section)! {
        case .heartRate:
            return data.heartRateItems.count
        case .healthCategories:
            return data.healthCategories.count
        case .sleep:
            return data.sleepItems.count
        case .steps:
            return data.stepItems.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch HealthSection(rawValue: indexPath.section)! {
        case .heartRate:
            let item = data.heartRateItems[indexPath.item]
            return collectionView.dequeueConfiguredReusableCell(using: heartRateCellRegistration, for: indexPath, item: item)
        case .healthCategories:
            let item = data.healthCategories[indexPath.item]
            return collectionView.dequeueConfiguredReusableCell(using: healthCategoryCellRegistration, for: indexPath, item: item)
        case .sleep:
            let item = data.sleepItems[indexPath.item]
            return collectionView.dequeueConfiguredReusableCell(using: sleepCellRegistration, for: indexPath, item: item)
        case .steps:
            let item = data.stepItems[indexPath.item]
            return collectionView.dequeueConfiguredReusableCell(using: stepCountCellRegistration, for: indexPath, item: item)
        }
    }
    
    // A cell registration that configures a custom cell with a SwiftUI heart rate view.
    private var heartRateCellRegistration: UICollectionView.CellRegistration<UICollectionViewCell, HeartRateData> = {
        .init { cell, indexPath, item in
            cell.contentConfiguration = UIHostingConfiguration {
                HeartRateCellView(data: item)
            }
            .margins(.horizontal, LayoutMetrics.horizontalMargin)
            .background {
                RoundedRectangle(cornerRadius: LayoutMetrics.cornerRadius, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
            }
        }
    }()
    
    // A cell registration that configures a custom list cell with a SwiftUI health category view.
    private var healthCategoryCellRegistration: UICollectionView.CellRegistration<UICollectionViewListCell, HealthCategory> = {
        .init { cell, indexPath, item in
            cell.contentConfiguration = UIHostingConfiguration {
                HealthCategoryCellView(healthCategory: item)
            }
        }
    }()
    
    // A cell registration that configures a custom cell with a SwiftUI sleep view.
    private var sleepCellRegistration: UICollectionView.CellRegistration<UICollectionViewCell, SleepData> = {
        .init { cell, indexPath, item in
            cell.contentConfiguration = UIHostingConfiguration {
                SleepCellView(data: item)
            }
            .margins(.horizontal, LayoutMetrics.horizontalMargin)
            .background {
                RoundedRectangle(cornerRadius: LayoutMetrics.cornerRadius, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
            }
        }
    }()
    
    // A cell registration that configures a custom list cell with a SwiftUI step count view.
    private var stepCountCellRegistration: UICollectionView.CellRegistration<UICollectionViewListCell, StepData> = {
        .init { cell, indexPath, item in
            cell.contentConfiguration = UIHostingConfiguration {
                StepCountCellView(data: item)
            }
        }
    }()
    
}

