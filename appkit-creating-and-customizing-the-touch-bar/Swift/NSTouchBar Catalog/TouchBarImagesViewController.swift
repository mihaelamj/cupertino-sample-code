/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
View controller responsible for showing images you can use in an NSTouchBar.
*/

import Cocoa

class TouchBarImagesViewController: NSViewController {
    
    @IBOutlet weak var theCollectionView: NSCollectionView!
    static let sectionHeaderElementKind = "section-header-element-kind"
    private var dataSource: NSCollectionViewDiffableDataSourceReference! = nil
    
    @IBOutlet weak var touchBarLabel: NSTextField!
    @IBOutlet weak var touchBarButton: NSButton!
    
    // NSImageName template images:
    let imageNames = [
        NSImage.touchBarAddDetailTemplateName,
            // for showing additional detail for an item.
        NSImage.touchBarAddTemplateName,
            // for creating a new item.
        NSImage.touchBarAlarmTemplateName,
            // for setting or showing an alarm.
        NSImage.touchBarAudioInputMuteTemplateName,
            // for muting audio input or denoting muted audio input.
        NSImage.touchBarAudioInputTemplateName,
            // for denoting audio input.
        NSImage.touchBarAudioOutputMuteTemplateName,
            // for muting audio output or for denoting muted audio output.
        NSImage.touchBarAudioOutputVolumeHighTemplateName,
            // for setting the audio output volume to a high level, or for denoting a high-level setting.
        NSImage.touchBarAudioOutputVolumeLowTemplateName,
            // for setting the audio output volume to a low level, or for denoting a low-level setting.
        NSImage.touchBarAudioOutputVolumeMediumTemplateName,
            // for setting the audio output volume to a medium level, or for denoting a medium-level setting.
        NSImage.touchBarAudioOutputVolumeOffTemplateName,
            // for setting the audio output volume to silent, or for denoting a setting of silent.
        NSImage.touchBarBookmarksTemplateName,
            // for showing app-specific bookmarks.
        NSImage.touchBarColorPickerFillName,
            // for showing a color picker so the user can select a fill color.
        NSImage.touchBarColorPickerFontName,
            // for showing a color picker so the user can select a text color.
        NSImage.touchBarColorPickerStrokeName,
            // for showing a color picker so the user can select a stroke color.
        NSImage.touchBarCommunicationAudioTemplateName,
            // for initiating or denoting audio communication.
        NSImage.touchBarCommunicationVideoTemplateName,
            // for initiating or denoting video communication.
        NSImage.touchBarComposeTemplateName,
            // for opening a new document or a new view in edit mode.
        NSImage.touchBarDeleteTemplateName,
            // for deleting the current or selected item.
        NSImage.touchBarDownloadTemplateName,
            // for downloading an item.
        NSImage.touchBarEnterFullScreenTemplateName,
            // for entering full-screen mode.
        NSImage.touchBarExitFullScreenTemplateName,
            // for exiting full-screen mode.
        NSImage.touchBarFastForwardTemplateName,
            // for moving forward through media playback or slides.
        NSImage.touchBarFolderCopyToTemplateName,
            // for copying an item to a destination.
        NSImage.touchBarFolderMoveToTemplateName,
            // for moving an item to a destination.
        NSImage.touchBarFolderTemplateName,
            // for opening or representing a folder.
        NSImage.touchBarGetInfoTemplateName,
            // for showing information about an item.
        NSImage.touchBarGoBackTemplateName,
            // for returning to the previous screen or location.
        NSImage.touchBarGoDownTemplateName,
            // for moving to the next item in a list.
        NSImage.touchBarGoForwardTemplateName,
            // for moving to the next screen or location.
        NSImage.touchBarGoUpTemplateName,
            // for moving to the previous item in a list.
        NSImage.touchBarHistoryTemplateName,
            // for showing history information, such as recent downloads.
        NSImage.touchBarIconViewTemplateName,
            // for showing items in an icon view.
        NSImage.touchBarListViewTemplateName,
            // for showing items in a list view.
        NSImage.touchBarMailTemplateName,
            // for creating an email message.
        NSImage.touchBarNewFolderTemplateName,
            // for creating a new folder.
        NSImage.touchBarNewMessageTemplateName,
            // for creating a new message or for denoting the use of messaging.
        NSImage.touchBarOpenInBrowserTemplateName,
            // for opening an item in the user’s browser.
        NSImage.touchBarPauseTemplateName,
            // for pausing media playback or slides.
        NSImage.touchBarPlayheadTemplateName,
            // for the play position for horizontal time-based controls.
        NSImage.touchBarPlayPauseTemplateName,
            // for toggling between playing and pausing media or slides.
        NSImage.touchBarPlayTemplateName,
            // for starting or resuming playback of media or slides.
        NSImage.touchBarQuickLookTemplateName,
            // for opening an item in Quick Look.
        NSImage.touchBarRecordStartTemplateName,
            // for starting recording.
        NSImage.touchBarRecordStopTemplateName,
            // for stopping recording or stopping playback of media or slides.
        NSImage.touchBarRefreshTemplateName,
            // for refreshing displayed data.
        NSImage.touchBarRewindTemplateName,
            // for moving backward through media or slides.
        NSImage.touchBarRotateLeftTemplateName,
            // for rotating an item counterclockwise.
        NSImage.touchBarRotateRightTemplateName,
            // for rotating an item clockwise.
        NSImage.touchBarSearchTemplateName,
            // for showing a search field or for initiating a search.
        NSImage.touchBarShareTemplateName,
            // for sharing content with others directly or through social media.
        NSImage.touchBarSidebarTemplateName,
            // for showing a sidebar in the current view.
        NSImage.touchBarSkipAhead15SecondsTemplateName,
            // for skipping ahead 15 seconds during media playback.
        NSImage.touchBarSkipAhead30SecondsTemplateName,
            // for skipping ahead 30 seconds during media playback.
        NSImage.touchBarSkipAheadTemplateName,
            // for skipping to the next chapter or location during media playback.
        NSImage.touchBarSkipBack15SecondsTemplateName,
            // for skipping back 15 seconds during media playback.
        NSImage.touchBarSkipBack30SecondsTemplateName,
            // for skipping back 30 seconds during media playback.
        NSImage.touchBarSkipBackTemplateName,
            // for skipping to the previous chapter or location during media playback.
        NSImage.touchBarSkipToEndTemplateName,
            // for skipping to the end of media playback.
        NSImage.touchBarSkipToStartTemplateName,
            // for skipping to the start of media playback.
        NSImage.touchBarSlideshowTemplateName,
            // for starting a slideshow.
        NSImage.touchBarTagIconTemplateName,
            // for applying a tag to an item.
        NSImage.touchBarTextBoldTemplateName,
            // for making selected text bold.
        NSImage.touchBarTextBoxTemplateName,
            // for inserting a text box.
        NSImage.touchBarTextCenterAlignTemplateName,
            // for centering text.
        NSImage.touchBarTextItalicTemplateName,
            // for making selected text italic.
        NSImage.touchBarTextJustifiedAlignTemplateName,
            // for fully justifying text.
        NSImage.touchBarTextLeftAlignTemplateName,
            // for aligning text to the left.
        NSImage.touchBarTextListTemplateName,
            // for inserting a list or converting text to list form.
        NSImage.touchBarTextRightAlignTemplateName,
            // for aligning text to the right.
        NSImage.touchBarTextStrikethroughTemplateName,
            // for striking through text.
        NSImage.touchBarTextUnderlineTemplateName,
            // for underlining text.
        NSImage.touchBarUserAddTemplateName,
            // for creating a new user account.
        NSImage.touchBarUserGroupTemplateName,
            // for showing or representing a group of users.
        NSImage.touchBarUserTemplateName
            // for showing or representing user information.
    ]
    
    // Transportation SF Symbols.
    let symbolNames = [
        "car",
        "car.fill",
        "car.circle",
        "car.circle.fill",
        "bolt.car",
        "bolt.car.fill",
        "car.2",
        "car.2.fill",
        "bus",
        "bus.fill",
        "bus.doubledecker",
        "bus.doubledecker.fill",
        "tram",
        "tram.fill",
        "tram.circle",
        "tram.circle.fill",
        "tram.tunnel.fill",
        "bicycle",
        "bicycle.circle",
        "bicycle.circle.fill",
        "figure.walk",
        "figure.walk.circle",
        "figure.walk.circle.fill",
        "figure.wave",
        "figure.wave.circle",
        "figure.wave.circle.fill",
        "airplane",
        "airplane.circle",
        "airplane.circle.fill"
    ]
    
    // MARK: View Controller Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        touchBarLabel.isHidden = true
        touchBarButton.isHidden = true
        
        configureHierarchy()
        configureDataSource()
        
        theCollectionView.delegate = self // To detect collection view selection changes.
    }

}

// MARK: - NSCollectionView

extension TouchBarImagesViewController {
    private func createLayout() -> NSCollectionViewLayout {
        let itemSize =
            NSCollectionLayoutSize(widthDimension: .absolute(34), heightDimension: .absolute(34))
        let item =
            NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize =
            NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(34))
        let group =
            NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 5
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10)

        let headerFooterSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                      heightDimension: .absolute(40))
        let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerFooterSize,
            elementKind: TouchBarImagesViewController.sectionHeaderElementKind,
            alignment: .top)
        section.boundarySupplementaryItems = [sectionHeader]

        let layout = NSCollectionViewCompositionalLayout(section: section)
        return layout
    }
    
    private func configureHierarchy() {
        let itemNib = NSNib(nibNamed: "CollectionViewItem", bundle: nil)
        theCollectionView.register(itemNib, forItemWithIdentifier: CollectionViewItem.reuseIdentifier)

        let titleSupplementaryNib = NSNib(nibNamed: "TitleSupplementaryView", bundle: nil)
        theCollectionView.register(titleSupplementaryNib,
                    forSupplementaryViewOfKind: TouchBarImagesViewController.sectionHeaderElementKind,
                    withIdentifier: TitleSupplementaryView.reuseIdentifier)
        theCollectionView.collectionViewLayout = createLayout()
    }
    
    private func configureDataSource() {
        dataSource = NSCollectionViewDiffableDataSourceReference(collectionView: theCollectionView) {
                (collectionView: NSCollectionView,
                indexPath: IndexPath,
                identifier: Any) -> NSCollectionViewItem? in
                let item = self.theCollectionView.makeItem(withIdentifier: CollectionViewItem.reuseIdentifier, for: indexPath)
            item.imageView?.image =
                indexPath.section == 0 ? NSImage(named: self.imageNames[indexPath.item]) :
                NSImage(systemSymbolName: self.symbolNames[indexPath.item], accessibilityDescription: "")

            return item
        }
        dataSource.supplementaryViewProvider = {
            (collectionView: NSCollectionView, kind: String, indexPath: IndexPath) -> NSView? in
            if let supplementaryView = self.theCollectionView.makeSupplementaryView(
                ofKind: kind,
                withIdentifier: TitleSupplementaryView.reuseIdentifier,
                for: indexPath) as? TitleSupplementaryView {
                if indexPath.section == 0 {
                    supplementaryView.label.stringValue = "Template Images"
                } else {
                    supplementaryView.label.stringValue = "Transportation SF Symbols"
                }
                return supplementaryView
            } else {
                fatalError("Cannot create new supplementary")
            }
        }

        // Set the collection view data.
        let snapshot = NSDiffableDataSourceSnapshotReference()
        
        var itemOffset = 0
        snapshot.appendSections(withIdentifiers: [NSNumber(value: 0)])
        snapshot.appendItems(withIdentifiers: Array(itemOffset..<itemOffset + imageNames.count).map {
            NSNumber(value: $0)
        })
        itemOffset += imageNames.count
        
        snapshot.appendSections(withIdentifiers: [NSNumber(value: 1)])
        snapshot.appendItems(withIdentifiers: Array(itemOffset..<itemOffset + symbolNames.count).map {
            NSNumber(value: $0)
        })
        
        dataSource.applySnapshot(snapshot, animatingDifferences: false)
    }

}

extension TouchBarImagesViewController: NSCollectionViewDelegate {
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        let indexPathArray = Array(indexPaths)
        let selectedItem = indexPathArray[0]
        
        var imageStringValue = ""
        var imageValue = NSImage()
        if selectedItem.section == 0 {
            imageStringValue = imageNames[selectedItem.item]
            imageValue = NSImage(named: imageNames[selectedItem.item])!
        } else {
            imageStringValue = symbolNames[selectedItem.item]
            imageValue = NSImage(systemSymbolName: symbolNames[selectedItem.item], accessibilityDescription: "")!
        }
        
        // Change the button and label in the NSTouchBar as feedback.
        touchBarLabel.stringValue = imageStringValue
        touchBarLabel.isHidden = false
        touchBarButton.image = imageValue
        touchBarButton.isHidden = false
    }
    
    func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>) {
        // Draw the unselected collection view item.
        touchBarButton.image = nil
        touchBarButton.isHidden = true
        touchBarLabel.stringValue = ""
        touchBarLabel.isHidden = true
    }

}

class TitleSupplementaryView: NSView {
    @IBOutlet weak var label: NSTextField!
    static let reuseIdentifier = NSUserInterfaceItemIdentifier("title-supplementary-reuse-identifier")
}

