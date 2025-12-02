/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The in-app profile picker to switch between profiles.
*/

import UIKit

private let profileCellIdentifier = "ProfileCell"

class ProfilePickerViewController: UIViewController {
    private let tableView: UITableView
    private let profileData: ProfileData

    init(profileData: ProfileData) {
        self.profileData = profileData
        tableView = UITableView(frame: .zero, style: .grouped)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Choose a Profile"
        label.textColor = .white
        label.font = .preferredFont(forTextStyle: .headline)
        view.addSubview(label)

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: profileCellIdentifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.remembersLastFocusedIndexPath = true
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.topAnchor.constraint(equalTo: view.topAnchor, constant: 200),
            label.heightAnchor.constraint(equalToConstant: 46),

            tableView.widthAnchor.constraint(equalToConstant: 600),
            tableView.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 40),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
            ])

        // Prevents someone from skipping picking a profile by pressing the Menu button.
        let menuRecognizer = UITapGestureRecognizer()
        menuRecognizer.allowedPressTypes = [UIPress.PressType.menu.rawValue as NSNumber]
        view.addGestureRecognizer(menuRecognizer)
    }
}

extension ProfilePickerViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return profileData.allProfiles.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: profileCellIdentifier, for: indexPath)
        let profile = profileData.allProfiles[indexPath.row]
        cell.textLabel?.text = profile.name
        cell.textLabel?.textColor = .white
        cell.textLabel?.textAlignment = .center
        cell.contentView.backgroundColor = profile.color
        return cell
    }
}

extension ProfilePickerViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let profile = profileData.allProfiles[indexPath.row]
        profileData.select(profile)
        dismiss(animated: true)
    }

    func indexPathForPreferredFocusedView(in tableView: UITableView) -> IndexPath? {
        let selectedRow = profileData.allProfiles.firstIndex { $0.identifier == profileData.selectedProfile?.identifier } ?? 0
        return IndexPath(row: selectedRow, section: 0)
    }
}
