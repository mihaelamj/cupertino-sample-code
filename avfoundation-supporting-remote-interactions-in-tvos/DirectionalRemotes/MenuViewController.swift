/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The initial view controller that presents a menu.
*/

import TVUIKit
class MenuViewController: UIViewController {

    @IBOutlet weak var systemPlayerButton: UIButton!
    @IBOutlet weak var customPlayerButton: UIButton!
    @IBOutlet weak var remoteEventsButton: UIButton!
    @IBOutlet weak var guideButton: UIButton!
        
    @IBAction func selectedButton(_ button: UIButton) {
        var viewControllerToPresent: UIViewController?

        switch button {
        case systemPlayerButton:
            viewControllerToPresent = SystemPlayerViewController()

        case customPlayerButton:
            viewControllerToPresent = CustomPlayerViewController()

        case remoteEventsButton:
            viewControllerToPresent = RemoteEventsViewController()

        case guideButton:
            let guideViewController = GuideViewController(delegate: self)
            viewControllerToPresent = guideViewController

        default:
            print("Not supported.")
        }

        guard let viewControllerToPresent = viewControllerToPresent else { return }
        self.navigationController?.pushViewController(viewControllerToPresent, animated: true)
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        commonInit()
    }

    /// Performs the actions to initialize the menu view controller.
    private func commonInit() {
        setupGuideButtonObserver()
    }

    // MARK: Guide button methods

    /// Adds an observer to the default notification center to handle the guide button press.
    private func setupGuideButtonObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(guideButtonPressed), name: .guideButtonPressed, object: nil)
    }

    /// Handles a guide button press.
    @objc private func guideButtonPressed() {
        guard let visibleViewController = self.navigationController?.visibleViewController else { return }

        // Don't handle the guide button press if the custom player or remote
        // events screen is presented, because they'll handle it.
        let shouldHandleGuidePress = !visibleViewController.isKind(of: CustomPlayerViewController.self) && !visibleViewController.isKind(of: RemoteEventsViewController.self)
        guard shouldHandleGuidePress else { return }

        // Handle a guide button press if the guide is presented.
        if visibleViewController.isKind(of: GuideViewController.self) {
            handleGuideButtonPressWhileGuideIsPresented()
            return
        }

        var currentChannelIdx: Int?
        // If the system player is presented, get the index of the playing item
        // to highlight it in the guide screen.
        let isSystemPlayerPresented = visibleViewController.isKind(of: SystemPlayerViewController.self)
        if isSystemPlayerPresented, let systemPlayerViewController = visibleViewController as? SystemPlayerViewController {
            currentChannelIdx = systemPlayerViewController.currentChannelIdx
        }

        let guideViewController = GuideViewController(currentChannelIdx: currentChannelIdx, delegate: self)
        self.navigationController?.pushViewController(guideViewController, animated: true)
    }

    /// Handles a guide button press if the guide is presented.
    private func handleGuideButtonPressWhileGuideIsPresented() {
        guard let navigationController = self.navigationController else { return }

        // A guide button press only dismisses the guide view controller if
        // the previously presented screen is the system player.
        
        // The first -1 is for the 0-index, and the second -1 is to get the
        // penultimate item.
        let previouslyPresentedViewControllerIdx = navigationController.viewControllers.count - 1 - 1
        
        // Make sure the index is in bounds.
        guard previouslyPresentedViewControllerIdx >= 0 else { return }
        
        let previouslyPresentedViewController = navigationController.viewControllers[previouslyPresentedViewControllerIdx]
        if previouslyPresentedViewController.isKind(of: SystemPlayerViewController.self) {
            self.navigationController?.popViewController(animated: true)
        }
    }
}

// MARK: GuideReporting methods

extension MenuViewController: GuideReporting {
    func selectedChannelId(_ channelId: Int) {
        guard let navigationController = self.navigationController else { return }

        // Pop all view controllers on the stack until the menu view controller
        // displays.
        navigationController.popToViewController(self, animated: false)

        // Play the selected content using the system player.
        let systemPlayer = SystemPlayerViewController(channelIdToPlay: channelId)
        self.navigationController?.pushViewController(systemPlayer, animated: false)
    }
}
