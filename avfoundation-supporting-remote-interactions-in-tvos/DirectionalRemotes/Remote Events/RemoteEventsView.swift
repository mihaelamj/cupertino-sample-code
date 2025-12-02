/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that displays a collection of remote events.
*/

import UIKit
class RemoteEventsView: UIView {

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.isUserInteractionEnabled = false

        collectionView.dataSource = self
        collectionView.delegate = self

        collectionView.register(RemoteEventsCell.self, forCellWithReuseIdentifier: RemoteEventsCell.identifier)

        return collectionView
    }()

    private lazy var remoteEventsOnScreen: [RemoteEvent] = {
        // Play, pause, and play/pause events all map to the play/pause item on
        // screen, so only present the play/pause item.
        RemoteEvent.allCases.filter { remoteEventToPresent in
            let isPlayOrPauseEvent = remoteEventToPresent == .play || remoteEventToPresent == .pause
            return !isPlayOrPauseEvent
        }
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        commonInit()
    }

    private func commonInit() {
        setupViews()
        setupLayout()
    }

    private func setupViews() {
        self.addSubview(collectionView)
    }

    private func setupLayout() {
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: self.topAnchor, constant: 60),
            collectionView.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.9),
            collectionView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            collectionView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -60)
        ])
    }

    // MARK: Public functions

    /// Updates the UI of the appropriate cell to indicate receipt of a remote event.
    ///
    /// The cell blinks if the state is `nil`.
    ///
    /// - Parameter remoteEvent: The `RemoteEvent` received.
    /// - Parameter state: The state of the `RemoteEvent` received, if any.
    func remoteEventReceived(_ remoteEvent: RemoteEvent, withState state: UIGestureRecognizer.State?) {
        // In the Remote Events module, play, pause, and play/pause events all
        // map to the play/pause item.
        let isPlayOrPauseEvent = remoteEvent == .play || remoteEvent == .pause
        let remoteEventToHighlight = isPlayOrPauseEvent ? .playPause : remoteEvent

        guard let remoteEventIdx = remoteEventsOnScreen.firstIndex(of: remoteEventToHighlight), let cell = collectionView.cellForItem(at: IndexPath(item: remoteEventIdx, section: 0)) as? RemoteEventsCell else { return }

        if state == .began {
            cell.highlight()

        } else if state == .ended {
            cell.removeHighlight()

        } else {
            cell.blink()
        }
    }
}

// MARK: UICollectionViewDelegateFlowLayout methods

extension RemoteEventsView: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 250, height: 150)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 30.0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }

}

// MARK: UICollectionViewDataSource methods

extension RemoteEventsView: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return remoteEventsOnScreen.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RemoteEventsCell.identifier, for: indexPath) as? RemoteEventsCell ?? RemoteEventsCell()

        let remoteEvent = remoteEventsOnScreen[indexPath.item]
        cell.textLabel.text = remoteEvent.rawValue

        return cell
    }
}
