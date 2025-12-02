/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view controller that displays a list of programs to play.
*/

import UIKit


/// A type that reports events the guide receives.
///
/// Conform to this protocol to receive updates about channel selection the guide view controller receives.
protocol GuideReporting: AnyObject {
    /// Called when a channel is selected in the guide view controller.
    ///
    /// - Parameter channelId: The ID of the selected channel.
    func selectedChannelId(_ channelId: Int)
}

/// An enumeration that provides the representation of the different scroll directions the guide supports.
enum GuideScrollDirection {
    case up, down
}
class GuideViewController: UIViewController {

    weak var delegate: GuideReporting?

    private let tvSchedule = TVSchedule.shared

    private var channelUpDownTargetIndexPath: IndexPath?
    private var channelUpDownScrollDirection: GuideScrollDirection?

    private var currentlyFocusedIndexPath: IndexPath?

    private let itemHeight: CGFloat = 180.0

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: UICollectionViewFlowLayout())
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(GuideChannelCell.self, forCellWithReuseIdentifier: GuideChannelCell.identifier)
        collectionView.register(GuideProgramCell.self, forCellWithReuseIdentifier: GuideProgramCell.identifier)
        return collectionView
    }()

    private let cellPadding: CGFloat = 6.0

    private var channelPlayingIndexPath: IndexPath?

    /// Initializes the `GuideViewController` by setting a `GuideReporting` delegate object.
    ///
    /// - Parameter delegate: A delegate object that conforms to the `GuideReporting` protocol.
    init(delegate: GuideReporting? = nil) {
        super.init(nibName: nil, bundle: nil)

        self.delegate = delegate
    }

    /// Initializes the `GuideViewController` with the index of the channel that's playing.
    ///
    /// - Parameter currentChannelIdx: The index of the channel that's playing.
    /// - Parameter delegate: A delegate object that conforms to the `GuideReporting` protocol.
    convenience init(currentChannelIdx: Int?, delegate: GuideReporting? = nil) {
        self.init(delegate: delegate)

        if let currentChannelIdx {
            // For each section, channel cell is always item 0 and program cells
            // start from 1.
            let firstProgramItemIdx = 1
            self.channelPlayingIndexPath = IndexPath(item: firstProgramItemIdx, section: currentChannelIdx)
        }
    }

    required convenience init?(coder: NSCoder) {
        self.init()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        initiallyPositionGuideToFitChannelPlaying()
    }

    /// Initially positions the guide to fit the channel playing on screen.
    private func initiallyPositionGuideToFitChannelPlaying() {
        // Only position the guide if the channel playing ID was given.
        guard let channelPlayingIndexPath = channelPlayingIndexPath else { return }

        let channelPlayingIdx = channelPlayingIndexPath.section
        let channelPlayingYOffset = itemHeight * CGFloat(channelPlayingIdx)

        collectionView.setContentOffset(CGPoint(x: 0.0, y: channelPlayingYOffset), animated: false)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        setupGestureRecognizers()
    }

    private func setupView() {
        view.addSubview(collectionView)
    }

    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        [collectionView]
    }

    // MARK: Gesture recognizers

    /// Sets up the gesture recognizers that the guide view controller requires.
    private func setupGestureRecognizers() {
        // Handle a press on channel up and down.
        addTapGestureRecognizer(toView: view, withAllowedPressTypes: [.pageUp], forTarget: self, andAction: #selector(channelUpPressed))
        addTapGestureRecognizer(toView: view, withAllowedPressTypes: [.pageDown], forTarget: self, andAction: #selector(channelDownPressed))
    }

    // MARK: Channel up and down action methods

    /// Performs a channel up action.
    @objc private func channelUpPressed() {
        // Because of the defined height of the cells, `indexPathsForVisibleItems`
        // has a maximum of 14 items on screen at any given time.
        guard let targetItemInPreviousPageSectionIdx = collectionView
            .indexPathsForVisibleItems.sorted().first?.section else { return }

        // For each page section, channel cell is always item 0 and program
        // cells start from 1.
        let firstProgramItemIdx = 1
        let targetItemIdx = currentlyFocusedIndexPath?.item ?? firstProgramItemIdx
        channelUpDownTargetIndexPath = IndexPath(
            item: targetItemIdx,
            section: targetItemInPreviousPageSectionIdx
        )
        // Scroll to the previous page for a channel up press.
        channelUpDownScrollDirection = .up

        setNeedsFocusUpdate()
        updateFocusIfNeeded()
    }

    /// Performs a channel down action.
    @objc private func channelDownPressed() {
        // Because of the defined height of the cells, `indexPathsForVisibleItems`
        // has a maximum of 14 items on screen at any given time.
        guard let targetItemInNextPageSectionIdx = collectionView.indexPathsForVisibleItems.sorted().last?.section else { return }

        // For each section, channel cell is always item 0 and program cells
        // start from 1.
        let firstProgramItemIdx = 1
        let targetItemIdx = currentlyFocusedIndexPath?.item ?? firstProgramItemIdx
        channelUpDownTargetIndexPath = IndexPath(item: targetItemIdx, section: targetItemInNextPageSectionIdx)
        // Scroll to the next page for a channel down press.
        channelUpDownScrollDirection = .down

        setNeedsFocusUpdate()
        updateFocusIfNeeded()
    }
}

// MARK: UICollectionViewDataSource methods

extension GuideViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return tvSchedule.channels.count
    }

    func indexPathForPreferredFocusedView(in collectionView: UICollectionView) -> IndexPath? {
        // If the guide is presented and `channelPlayingIndexPath` is set, use it
        // to highlight the channel that's playing.
        if let channelPlayingIndexPath {
            return channelPlayingIndexPath
        }

        return channelUpDownTargetIndexPath
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let channel = tvSchedule.channels[section]
        // The +1 is to account for the guide channel cell, which shows the
        // channel name.
        return channel.programs.count + 1
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let channel = tvSchedule.channels[indexPath.section]
        // The first item is always the guide channel cell, which shows the
        // channel name.
        let isChannelCell = indexPath.item == 0

        if isChannelCell {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GuideChannelCell.identifier, for: indexPath) as? GuideChannelCell ?? GuideChannelCell()
            cell.updateChannelName(channel.name)
            return cell

        } else { // The guide program cell.
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GuideProgramCell.identifier, for: indexPath) as? GuideProgramCell ?? GuideProgramCell()
            let programTitle = channel.programs[indexPath.item - 1].title
            cell.updateProgramTitle(programTitle)
            return cell
        }
    }
}

// MARK: UICollectionViewDelegate methods

extension GuideViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedChannelId = indexPath.section
        delegate?.selectedChannelId(selectedChannelId)
    }

    func collectionView(_ collectionView: UICollectionView, canFocusItemAt indexPath: IndexPath) -> Bool {
        // The first item is always the guide channel cell, which shows the
        // channel name.
        let isChannelCell = indexPath.item == 0
        // Never allow focus on the guide channel cell.
        return !isChannelCell
    }

    func collectionView(_ collectionView: UICollectionView, didUpdateFocusIn context: UICollectionViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        updateHighlightedChannelCell(inCollectionView: collectionView, withNextFocusedIndexPath: context.nextFocusedIndexPath)

        if let channelPlayingIndexPath, context.nextFocusedIndexPath == channelPlayingIndexPath {
            self.channelPlayingIndexPath = nil
        }

        if let channelUpDownTargetIndexPath, context.nextFocusedIndexPath == channelUpDownTargetIndexPath {
            self.channelUpDownTargetIndexPath = nil
        }
    }

    /// Updates the highlighted channel cell based on the highlighted cell.
    private func updateHighlightedChannelCell(inCollectionView collectionView: UICollectionView, withNextFocusedIndexPath nextFocusedIndexPath: IndexPath?) {
        guard currentlyFocusedIndexPath == nil || currentlyFocusedIndexPath?.section != nextFocusedIndexPath?.section else { return }

        // The item index of the channel cell.
        let channelCellItemIdx = 0

        // Remove highlight from currently focused guide channel cell.
        if let previouslyFocusedIndexPath = currentlyFocusedIndexPath {
            let previouslyFocusedChannelCell = collectionView.cellForItem(at: IndexPath(item: channelCellItemIdx, section: previouslyFocusedIndexPath.section))
            previouslyFocusedChannelCell?.isHighlighted = false
        }

        // Highlight the next focused guide channel cell.
        if let nextFocusedIndexPath {
            let nextFocusedChannelCell = collectionView.cellForItem(at: IndexPath(item: channelCellItemIdx, section: nextFocusedIndexPath.section))
            nextFocusedChannelCell?.isHighlighted = true

            currentlyFocusedIndexPath = nextFocusedIndexPath
        }
    }

    // Performs channel up and down scroll view animation.
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        // Only intervene in the `targetContentOffset` if the scroll animation was
        // triggered by a channel up or down event.
        guard let channelUpDownScrollDirection = channelUpDownScrollDirection else { return }

        // The default vertical offset value for the collection view controller.
        let scrollViewVerticalOffset: CGFloat = 145
        // The default page height value for the guide.
        let pageHeight: CGFloat = 900
        // The default page offset value.
        let pageOffset: CGFloat = 650

        let targetYOffset = CGFloat(targetContentOffset.pointee.y)
        let scrollViewYOffset = scrollView.contentOffset.y

        var newTargetYOffset: CGFloat = scrollViewYOffset
        // Moves the new target offset by one page (up or down) according to the
        // scroll direction.
        if channelUpDownScrollDirection == .down && targetYOffset > scrollViewYOffset {
            newTargetYOffset = targetYOffset + pageOffset

        } else if channelUpDownScrollDirection == .up && targetYOffset < scrollViewYOffset {
            newTargetYOffset = targetYOffset - pageOffset
        }

        let topOffset = -1 * scrollViewVerticalOffset
        
        // Check if the new page is out of bounds.
        let isScrollDownOutOfBounds = newTargetYOffset + pageHeight >= scrollView.contentSize.height
        let isScrollUpOutOfBounds = newTargetYOffset <= topOffset
        // If scrolling down and new page is out of bounds (bottom), scroll to
        // the bottom of the guide instead of scrolling to a whole new page.
        if channelUpDownScrollDirection == .down && isScrollDownOutOfBounds {
            newTargetYOffset = scrollView.contentSize.height - pageHeight - scrollViewVerticalOffset

            // If scrolling up and the new page is out of bounds (top), scroll to
            // the top of the guide instead of scrolling to a whole a new page.
        } else if channelUpDownScrollDirection == .up && isScrollUpOutOfBounds {
            newTargetYOffset = topOffset
        }

        // Update the targetContentOffset.
        targetContentOffset.pointee = CGPoint(x: 0.0, y: newTargetYOffset)

        // Reset variables.
        self.channelUpDownScrollDirection = nil
        self.channelUpDownTargetIndexPath = nil
    }
}

// MARK: UICollectionViewDelegateFlowLayout methods

extension GuideViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // For each section, channel cell is always item 0.
        let isChannelCell = indexPath.item == 0
        let itemWidth = isChannelCell ? GuideChannelCell.width : GuideProgramCell.width

        return CGSize(width: itemWidth, height: itemHeight)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: cellPadding, left: cellPadding, bottom: cellPadding, right: cellPadding)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return cellPadding
    }
}
