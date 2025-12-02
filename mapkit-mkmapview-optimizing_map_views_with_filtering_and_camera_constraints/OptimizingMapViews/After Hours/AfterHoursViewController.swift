/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The view controller responsible for the After Hours view.
*/

import MapKit

/**
 This class facilitates search and autocompletion. The responsibility to
 display autocompletions and search results is delegated to the two child
 view controllers: the map view controller and completions view controller.
 */
class AfterHoursViewController: UIViewController, MKLocalSearchCompleterDelegate, UISearchBarDelegate {

    @IBOutlet private var searchBar: UISearchBar!
    @IBOutlet private var completionsContainer: UIView!

    /**
     Create one filter to share between search and autocomplete.
    */
    private let pointOfInterestFilter = MKPointOfInterestFilter(including: [.nightlife, .restaurant])

    private let searchCompleter = MKLocalSearchCompleter()
    private var search: MKLocalSearch?

    private var mapViewController: MapViewController?
    private var completionsViewController: CompletionsViewController?

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        /*
         Apply the point of interest filter to include cafes, bakeries,
         nightlife and restaurants.
        */
        searchCompleter.pointOfInterestFilter = pointOfInterestFilter

        /*
         For this feature, address results are not relevant. Limit
         completions to points of interest by setting the .pointOfInterest
         result type.
        */
        searchCompleter.resultTypes = .pointOfInterest

        /*
         Provide the search engine with a hint of the region of interest. This
         constant is declared in Constants.swift.
        */
        searchCompleter.region = .search

        searchCompleter.delegate = self
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        searchCompleter.cancel()
        search?.cancel()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "MapEmbed":
            mapViewController = segue.destination as? MapViewController
        case "CompletionsEmbed":
            completionsViewController = segue.destination as? CompletionsViewController
            self.completionsViewController?.selectionHandler = { [weak self](completion) in
                self?.search(for: completion)
            }
        default:
            super.prepare(for: segue, sender: sender)
        }
    }

    // MARK: - Search

    private func search(for query: String) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        configureRequest(request)
        search(request)
    }

    private func search(for completion: MKLocalSearchCompletion) {
        let request = MKLocalSearch.Request(completion: completion)
        configureRequest(request)
        search(request)
    }

    private func configureRequest(_ request: MKLocalSearch.Request) {
        /*
         Apply the point of interest filter to include cafes, bakeries,
         nightlife and restaurants.
        */
        request.pointOfInterestFilter = pointOfInterestFilter

        /*
         For this feature, address results are not relevant. Limit
         the results to points of interest by setting the .pointOfInterest
         result type.
        */
        request.resultTypes = .pointOfInterest

        /*
         Provide the search engine with a hint of the region of interest. This
         constant is declared in Constants.swift.
        */
        request.region = .search
    }

    private func search(_ request: MKLocalSearch.Request) {
        searchCompleter.cancel()
        completionsContainer.isHidden = true
        searchBar.resignFirstResponder()

        search = MKLocalSearch(request: request)
        search?.start { [weak self](response, error) in

            if let error = error {
                self?.handleSearchError(error)
            } else if let response = response {
                self?.mapViewController?.show(mapItems: response.mapItems)
            }

            self?.search = nil
        }
    }

    private func handleSearchError(_ error: Error) {
        let message = "\(error.localizedDescription)\n\nPlease try again later"
        let alert = UIAlertController(title: "An Error Occurred", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self] _ in
            self?.completionsContainer.isHidden = false
        }))
        present(alert, animated: true, completion: nil)
    }

    // MARK: - MKLocalSearchCompleterDelegate

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        completionsViewController?.searchCompletions = completer.results
        completionsContainer.isHidden = completer.results.isEmpty
    }

    // MARK: - UISearchBarDelegate

    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        if let completionsCount = completionsViewController?.searchCompletions.count {
            completionsContainer.isHidden = completionsCount <= 0
        }
        return true
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.count < searchCompleter.queryFragment.count {
            completionsViewController?.searchCompletions = [MKLocalSearchCompletion]()
        }

        /*
         For this app's use case, completions based on less than 3
         characters are likely to be too inaccurate, so it is better to avoid
         showing them.
        */
        if searchText.count >= 3 {
            searchCompleter.queryFragment = searchText
        } else {
            completionsContainer.isHidden = true
        }
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let query = searchBar.text {
            search(for: query)
        }
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = nil
        searchBar.resignFirstResponder()

        completionsContainer.isHidden = true
        completionsViewController?.searchCompletions = [MKLocalSearchCompletion]()

        searchCompleter.queryFragment = ""
        searchCompleter.cancel()
        search?.cancel()
    }
}
