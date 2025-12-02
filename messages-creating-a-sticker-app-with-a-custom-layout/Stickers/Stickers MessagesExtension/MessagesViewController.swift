/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
MessagesViewController displays the custom collection of MSStickers.
*/

import UIKit
import Messages

class MessagesViewController: MSMessagesAppViewController {
    
    private enum SectionType: String, CaseIterable {
        case texts = "Texts"
        case pictures = "Pictures"
        case animals = "Animals"
        case trees = "Trees"
        case days = "Happy Days"
    }
    
    private var collectionView: UICollectionView!
    private var datasource: UICollectionViewDiffableDataSource<SectionType, MSSticker>!
    
    private static var fiveItemSection: NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.2), heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(60))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 10
        return section
    }
    
    private static var oneItemSection: NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 0)
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(40))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        return section
    }
    
    private static var twoItemSection: NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalWidth(0.5))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        return section
    }
    
    // Creates a custom layout using section providers.
    private static func createLayout() -> UICollectionViewLayout {
        let sectionProvider = { (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            let headerFooterSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: sectionIndex < 2 ? .absolute(64) : .estimated(44))
            
            switch sectionIndex {
                // texts
                case 0:
                    let textSection = MessagesViewController.oneItemSection
                    let textSectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
                        layoutSize: headerFooterSize, elementKind: TextSupplementaryView.reuseIdentifier, alignment: .topLeading)
                    textSection.boundarySupplementaryItems = [textSectionHeader]
                    return textSection
                // pictures
                case 1:
                    let pictureSection = MessagesViewController.twoItemSection
                    let pictureSectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
                        layoutSize: headerFooterSize, elementKind: PictureSupplementaryView.reuseIdentifier, alignment: .topLeading)
                    pictureSection.boundarySupplementaryItems = [pictureSectionHeader]
                    return pictureSection
                // animals
                case 2:
                    let animalSection = MessagesViewController.fiveItemSection
                    let titleSectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
                        layoutSize: headerFooterSize, elementKind: TitleSupplementaryView.reuseIdentifier, alignment: .topLeading)
                    animalSection.boundarySupplementaryItems = [titleSectionHeader]
                    return animalSection
                // trees
                case 3:
                    let treeSection = MessagesViewController.fiveItemSection
                    let titleSectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
                        layoutSize: headerFooterSize, elementKind: TitleSupplementaryView.reuseIdentifier, alignment: .topLeading)
                    treeSection.boundarySupplementaryItems = [titleSectionHeader]
                    return treeSection
                // days
                case 4:
                    let daySection = MessagesViewController.oneItemSection
                    let titleSectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
                        layoutSize: headerFooterSize, elementKind: TitleSupplementaryView.reuseIdentifier, alignment: .topLeading)
                    daySection.boundarySupplementaryItems = [titleSectionHeader]
                    return daySection
                default: return nil
            }
        }
        return UICollectionViewCompositionalLayout(sectionProvider: sectionProvider)
    }
    
    private func setupCollection() {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: MessagesViewController.createLayout())
        collectionView.backgroundColor = .systemGroupedBackground
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewCell, MSSticker> { (cell, indexPath, item) in
            cell.contentConfiguration = CustomContentConfiguration(sticker: item)
        }
        
        datasource = UICollectionViewDiffableDataSource<SectionType, MSSticker>(
            collectionView: collectionView, cellProvider: { (collectionView, indexPath, item) -> UICollectionViewCell? in
                return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
            }
        )
        
        let titleHeaderRegistration = UICollectionView.SupplementaryRegistration
        <TitleSupplementaryView>(elementKind: TitleSupplementaryView.reuseIdentifier) {
            (supplementaryView, string, indexPath) in
            supplementaryView.label.text = SectionType.allCases[indexPath.section].rawValue
        }
        
        let textHeaderRegistration = UICollectionView.SupplementaryRegistration
        <TextSupplementaryView>(elementKind: TextSupplementaryView.reuseIdentifier) {
            (supplementaryView, string, indexPath) in
            supplementaryView.field.delegate = self
        }
        
        let pictureHeaderRegistration = UICollectionView.SupplementaryRegistration
        <PictureSupplementaryView>(elementKind: PictureSupplementaryView.reuseIdentifier) {
            (supplementaryView, string, indexPath) in
            supplementaryView.button.addTarget(self, action: #selector(self.pickImage), for: .touchDown)
        }
        
        datasource.supplementaryViewProvider = { (view, kind, index) in
            switch index.section {
                case 0:
                    return self.collectionView.dequeueConfiguredReusableSupplementary(
                        using: textHeaderRegistration, for: index)
                case 1:
                    return self.collectionView.dequeueConfiguredReusableSupplementary(
                        using: pictureHeaderRegistration, for: index)
                default:
                    return self.collectionView.dequeueConfiguredReusableSupplementary(
                        using: titleHeaderRegistration, for: index)
            }
        }
    }
    
    private func populateCollection() {
        var snapshot = NSDiffableDataSourceSnapshot<SectionType, MSSticker>()
        snapshot.appendSections(SectionType.allCases)
        
        snapshot.appendItems(["animal-1", "animal-2", "animal-3", "animal-4"].compactMap({ (name) -> MSSticker? in
            guard let url = Bundle.main.url(forResource: name, withExtension: "png") else {
                return nil
            }
            return try? MSSticker(contentsOfFileURL: url, localizedDescription: name)
        }), toSection: .animals)
        
        snapshot.appendItems(["tree-1", "tree-2", "tree-3", "tree-4"].compactMap({ (name) -> MSSticker? in
            guard let url = Bundle.main.url(forResource: name, withExtension: "png") else {
                return nil
            }
            return try? MSSticker(contentsOfFileURL: url, localizedDescription: name)
        }), toSection: .trees)
        
        snapshot.appendItems(["Happy " + formatter.string(from: Date())].compactMap({ (name) -> MSSticker? in
            let label = UILabel()
            label.text = name
            guard let image = label.image(),
                  let data = image.pngData(),
                  let baseURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last,
                  let url = URL(string: "\(baseURL.appendingPathComponent("\(name).png"))"),
                  (try? data.write(to: url)) != nil else {
                print("write failed")
                return nil
            }
            return try? MSSticker(contentsOfFileURL: url, localizedDescription: name)
        }), toSection: .days)
        
        datasource.apply(snapshot, animatingDifferences: true, completion: nil)
    }
    
    @objc
    private func pickImage() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true, completion: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupCollection()
        populateCollection()
    }

}

extension MessagesViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: false) {
            if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                var snapshot = self.datasource.snapshot()
                snapshot.appendItems([image].compactMap({ (image) -> MSSticker? in
                    let name = UUID().uuidString
                    guard let data = image.pngData(),
                          let baseURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last,
                          let url = URL(string: "\(baseURL.appendingPathComponent("\(name).png"))"),
                          (try? data.write(to: url)) != nil else {
                        print("write failed")
                        return nil
                    }
                    return try? MSSticker(contentsOfFileURL: url, localizedDescription: name)
                }), toSection: .pictures)
                self.datasource.apply(snapshot, animatingDifferences: true, completion: nil)
            }
        }
    }
}

extension MessagesViewController: UITextFieldDelegate {
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        requestPresentationStyle(.expanded)
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let text = textField.text, text.isEmpty != true {
            var snapshot = datasource.snapshot()
            snapshot.appendItems([text].compactMap({ (name) -> MSSticker? in
                let label = UILabel()
                label.text = name
                guard let image = label.image(),
                      let data = image.pngData(),
                      let baseURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last,
                      let url = URL(string: "\(baseURL.appendingPathComponent("\(name).png"))"),
                      (try? data.write(to: url)) != nil else {
                    print("write failed")
                    return nil
                }
                return try? MSSticker(contentsOfFileURL: url, localizedDescription: name)
            }), toSection: .texts)
            
            datasource.apply(snapshot, animatingDifferences: true) {
                textField.text = ""
            }
        }
        textField.resignFirstResponder()
        return true
    }
    
}

extension MessagesViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let convo = activeConversation, let sticker = datasource.itemIdentifier(for: indexPath) {
            convo.insert(sticker, completionHandler: nil)
        }
    }
}
