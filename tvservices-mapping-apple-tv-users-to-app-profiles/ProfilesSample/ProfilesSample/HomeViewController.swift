/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main UI of the app, showing what's relevant for the current profile and what's new for all users.
*/

import UIKit

private let headerElementKind = "HeaderElementKind"
private let headerIdentifier = "HeaderIdentifier"
private let posterCellIdentifier = "PosterCell"

class HomeViewController: UIViewController {
    private let profileData: ProfileData
    private var collectionView: UICollectionView?

    init(profileData: ProfileData) {
        self.profileData = profileData
        super.init(nibName: nil, bundle: nil)
        title = "Home"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black

        let collectionView = UICollectionView(frame: view.frame, collectionViewLayout: _layout())
        collectionView.dataSource = self
        collectionView.register(PosterCollectionViewCell.self, forCellWithReuseIdentifier: posterCellIdentifier)
        collectionView.register(SectionHeader.self, forSupplementaryViewOfKind: headerElementKind, withReuseIdentifier: headerIdentifier)
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 100, right: 0)
        view.addSubview(collectionView)
        self.collectionView = collectionView

        tabBarObservedScrollView = collectionView

        NotificationCenter.default.addObserver(self, selector: #selector(handleProfileDidChange), name: .selectedProfileDidChange, object: nil)
    }

    private func _layout() -> UICollectionViewLayout {
        let posterItemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                    heightDimension: .fractionalHeight(1.0))
        let posterItem = NSCollectionLayoutItem(layoutSize: posterItemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .absolute(150), heightDimension: .absolute(225))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [posterItem])

        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        section.contentInsets = NSDirectionalEdgeInsets(top: 20, leading: 30, bottom: 40, trailing: 30)
        section.interGroupSpacing = 40.0

        let sectionHeaderSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(50))
        let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: sectionHeaderSize,
                                                                        elementKind: headerElementKind,
                                                                        alignment: .top)
        section.boundarySupplementaryItems = [sectionHeader]

        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        configuration.scrollDirection = .vertical
        return UICollectionViewCompositionalLayout(section: section, configuration: configuration)
    }

    @objc
    private func handleProfileDidChange() {
        collectionView?.reloadData()
    }
}

// MARK: UICollectionViewDataSource
extension HomeViewController: UICollectionViewDataSource {
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return profileData.selectedProfile?.sections.count ?? 0
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let profile = profileData.selectedProfile else {
            return 0
        }

        return profile.sections[section].symbols.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: posterCellIdentifier, for: indexPath) as! PosterCollectionViewCell

        if let profile = profileData.selectedProfile {
            cell.color = profile.color
            cell.symbol = profile.sections[indexPath.section].symbols[indexPath.item]
        }

        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == headerElementKind else {
            fatalError("HeaderElementKind is the only supplementary view supported. Got: \(kind)")
        }

        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                     withReuseIdentifier: headerIdentifier,
                                                                     for: indexPath) as! SectionHeader

        if let profile = profileData.selectedProfile {
            header.title = profile.sections[indexPath.section].name
        }
        return header
    }
}

private class SectionHeader: UICollectionReusableView {

    var title: String? {
        didSet {
            label.text = title
        }
    }

    private let label: UILabel

    override init(frame: CGRect) {
        label = UILabel(frame: .zero)
        super.init(frame: frame)
        addSubview(label)

        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = .white

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10)
            ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
