/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implement the main view controller. In this class, you implement
		a custom ConnectionProbeDelegate protocol to receive probe results.
*/

import UIKit
import Network

class ViewController: UITableViewController {

	var currentProbe: ConnectionProbe?
	@IBOutlet weak var typeChooser: UISegmentedControl!
	@IBOutlet weak var hostLabel: UILabel!
	@IBOutlet weak var portLabel: UILabel!
	@IBOutlet weak var hostField: UITextField!
	@IBOutlet weak var portField: UITextField!
	@IBOutlet weak var resultField: UITextView!
	@IBOutlet weak var dnsSwitch: UISwitch!
	@IBOutlet weak var tlsSwitch: UISwitch!

	let probeTypes: [ProbeType] = [.tls, .dtls, .websocket]

	func runProbe() {

		// Dismiss the keyboard.
		self.view.endEditing(true)

		// Cancel existing probes.
		if let currentProbe = self.currentProbe {
			currentProbe.cancel()
			self.currentProbe = nil
		}

		// Set up a new probe.
		let probeType = probeTypes[typeChooser.selectedSegmentIndex]
		var endpoint: NWEndpoint
		switch probeType {
		case .tls, .dtls:
			// Note that TLS and DTLS use hosts and ports.
			guard let hostString = hostField.text,
				let portString = portField.text,
				let port = NWEndpoint.Port(portString) else {
				return
			}
			endpoint = NWEndpoint.hostPort(host: NWEndpoint.Host(hostString), port: port)
		case .websocket:
			// Note that WebSocket uses a URL.
			guard let urlString = hostField.text,
				let url = URL(string: urlString) else {
				return
			}
			endpoint = NWEndpoint.url(url)
		}

		self.currentProbe = ConnectionProbe(to: endpoint, as: probeType, delegate: self)
		if let probe = self.currentProbe {
			probe.useLegacyTLSVersion = !tlsSwitch.isOn
			probe.disableOptimisticDNS = !dnsSwitch.isOn
			self.resultField.text = "Running probe..."
			probe.start()
		}
	}

	@IBAction func probeTypeChanged(_ sender: Any) {
		switch probeTypes[typeChooser.selectedSegmentIndex] {
		case .websocket:
			// Adjust the fields for WebSocket to show a URL field, not a host and port.
			self.hostLabel.text = "URL"
			self.hostField.placeholder = "wss://www.example.com/path"
		default:
			self.hostLabel.text = "Host"
			self.hostField.placeholder = "www.example.com"
		}
		self.hostField.text = ""
		self.portField.text = ""
		self.tableView.reloadData()
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		// Handle the user tapping on "Run Probe".
		if indexPath.section == 3 && indexPath.row == 0 {
			runProbe()
		}
		self.tableView.deselectRow(at: indexPath, animated: true)
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if section == 1 && probeTypes[typeChooser.selectedSegmentIndex] == .websocket {
			return 1
		} else {
			return super.tableView(tableView, numberOfRowsInSection: section)
		}
	}
}

extension NWConnection.EstablishmentReport.Resolution {
	// Create a summary string for a resolution step.
	func resolutionDescription() -> String {
		switch source {
		case .query:
			return "Resolved from query in \(duration)s\n"
		case .cache:
			return "Resolved from cache in \(duration)s\n"
		case .expiredCache:
			return "Resolved from expired cache in \(duration)s\n"
		default:
			return ""
		}
	}
}

extension ViewController: ConnectionProbeDelegate {
	// When a new report comes in, display a summary.
	func reportComplete(_ result: Result<NWConnection.EstablishmentReport, NWError>) {
		switch result {
		case .success(let report):
			var summary = "Connected in \(report.duration)s\n"
			if let resolution = report.resolutions.first {
				summary.append(resolution.resolutionDescription())
			}
			for handshake in report.handshakes where handshake.definition == NWProtocolTLS.definition {
				summary.append("TLS took \(handshake.handshakeDuration)s")
			}
			self.resultField.text = summary
		case .failure(let error):
			self.resultField.text = "Received error \(error.localizedDescription)"
		}
	}
}
