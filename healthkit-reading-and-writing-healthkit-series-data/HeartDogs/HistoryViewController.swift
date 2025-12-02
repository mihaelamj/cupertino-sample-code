/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view controller that  fetches HealthKit data associated with previously games and displays it in a table view.
*/

import UIKit
import HealthKit

class HistoryViewController: UITableViewController, HealthStoreContainer {

    // The `HKHealthStore` that this view controller uses to query data.
    // This property is set by the app delegate.
    var healthStore: HKHealthStore!

    private var gameSessions = [[String: Any]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        fetchDataForGameSessions()
    }
    
    // MARK: - Fetch Data
    
    private func fetchDataForGameSessions() {
        if let currentGameSessions = UserDefaults.standard.array(forKey: "games") as? [[String: Any]] {
            guard currentGameSessions.count != gameSessions.count else {
                // There are no new game sessions, so we do not need to fetch data.
                return
            }
            gameSessions = currentGameSessions
        }
        
        let group = DispatchGroup()
        for index in gameSessions.indices {
            group.enter()
            fetchDataForGameSession(index) { (success, error) in
                print("Fetched Data -- Success: ", success, " Error: ", error ?? "nil")
                group.leave()
            }
        }
        group.notify(queue: DispatchQueue.main, work: DispatchWorkItem {
            self.tableView.reloadData()
        })
    }

    private func fetchDataForGameSession(_ gameSessionIndex: Int, completion : @escaping (Bool, Error?) -> Void) {
        guard let gameIdentifier = gameSessions[gameSessionIndex]["identifier"] as? String else {
            return
        }
        // Only get samples that have the matching gameIdentifier.
        let predicate = HKQuery.predicateForObjects(withMetadataKey: HKMetadataKeyExternalUUID, allowedValues: [gameIdentifier])
        // The array of HealthKit samples that are associated with the game.
        var gameHealthData = [Detailable]()
        
        // Query for the max, min and average values for the specified heart rate sample.
        let heartRateStatisticsQuery = HKStatisticsQuery(quantityType: HKObjectType.quantityType(forIdentifier: .heartRate)!,
                                                         quantitySamplePredicate: predicate,
                                                         options: [.discreteMax, .discreteMin, .discreteAverage]) {
            (query, statistics, error) in
            
            guard let statistics = statistics else {
                completion(false, error)
                return
            }
            gameHealthData.append(statistics)
            
            // Query for the heartbeat samples from the specified heartbeat series.
            let heartbeatSeriesSampleQuery = HKSampleQuery(sampleType: HKSeriesType.heartbeat(),
                                                           predicate: predicate,
                                                           limit: HKObjectQueryNoLimit, sortDescriptors: nil) {
                query, results, error in
                
                guard let samples = results, let sample = samples.first as? HKHeartbeatSeriesSample else {
                    completion(false, error)
                    return
                }
                gameHealthData.append(sample)
                // Add this game's health data to the array of game sessions.
                self.gameSessions[gameSessionIndex]["objects"] = gameHealthData
                
                completion(true, nil)
            }
            self.healthStore.execute(heartbeatSeriesSampleQuery)
        }
        healthStore.execute(heartRateStatisticsQuery)
    }

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let detailableItem = (gameSessions[indexPath.section]["objects"] as? [Any])?[indexPath.row] as? Detailable
                guard let controller = segue.destination as? DetailViewController else {
                    return
                }
                controller.healthStore = healthStore
                controller.detailableItem = detailableItem
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return gameSessions.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (gameSessions[section]["objects"] as? [Any])?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        let gameSession = gameSessions[section]
        if let startDate = gameSession["startDate"] as? Date, let score = gameSession["score"] as? Int {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .medium
            dateFormatter.locale = Locale(identifier: "en_US")
            if score > 1 {
                return "\(score) points on " + dateFormatter.string(from: startDate)
            }
            return "\(score) point on " + dateFormatter.string(from: startDate)
        }

        return "Game " + String(section + 1)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        let object = (gameSessions[indexPath.section]["objects"] as? [Any])?[indexPath.row] as? Detailable
        cell.textLabel!.text = object?.summaryString
        
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }
}

