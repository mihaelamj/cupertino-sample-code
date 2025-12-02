/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class that implements `UITableViewDataSource` and displays `sampleData` in `CustomCell` instances.
*/

import UIKit

// This file isn't central to the sample. See `CustomCell.setUpLabelsAndConstraints()`, which is the main focus of this sample.

class CustomDataSource: NSObject, UITableViewDataSource {

    /// The sample data for this data source is pairs of "number of words" and "the partial sentence with that many words".
    let sampleData: [(numberOfWords: Int, sentence: String)] = [
        (1, "The"),
        (2, "The quick"),
        (3, "The quick brown"),
        (4, "The quick brown fox"),
        (5, "The quick brown fox jumps"),
        (6, "The quick brown fox jumps over"),
        (7, "The quick brown fox jumps over the"),
        (8, "The quick brown fox jumps over the lazy"),
        (9, "The quick brown fox jumps over the lazy dog")
    ]
    
    /**
     Registers the custom cell(s) that this data source uses with the table view.
 
     - Parameter tableView: The table view to register the cells with.
     */
    func registerCells(with tableView: UITableView) {
        tableView.register(CustomCell.self, forCellReuseIdentifier: CustomCell.reuseIdentifier)
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sampleData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CustomCell.reuseIdentifier, for: indexPath) as? CustomCell else {
            fatalError("""
                Expected `\(CustomCell.self)` type for reuseIdentifier "\(CustomCell.reuseIdentifier)".
                Ensure that the `\(CustomCell.self)` class was registered with the table view (being passed from the view controller).
                """
            )
        }
        
        let (numberOfWords, sentence) = sampleData[indexPath.row]
        
        /*
         This cell shows the `wordCount` in a phrase, for example: "First word", "First 2 words", "First 3 words", etc.
         To correctly handle pluralization (word vs. words) it uses localized strings with a `Localizable.stringsdict` file.
         */
        let headline = String.localizedStringWithFormat(NSLocalizedString("FirstNumberOfWords", comment: "First %d word(s)"),
                                                        numberOfWords)
        
        cell.headlineLabel.text = headline
        cell.bodyLabel.text = sentence
        
        return cell
    }
}
