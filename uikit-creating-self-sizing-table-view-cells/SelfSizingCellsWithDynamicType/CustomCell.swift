/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A self sizing `UITableViewCell` with two labels that support Dynamic Type.
*/

import UIKit

/*
 This file is the core of this sample. It contains a custom `UITableViewCell` subclass with two labels that support Dynamic Type.
 In `CustomCell.setUpLabelsAndConstraints()`, you can see how the labels and constraints are set up so that both fonts and spacings
 are automatically adjusted when the device's content size changes.
 
 To see this in effect:
 1. Run this sample in the Simulator
 2. Open the Accessibility Inspector (Xcode > Open Developer Tool > Accessibility Inspector) and connect to the Simulator
 3. In the Settings, adjust the Font size.
 */

/// A custom table view cell with two labels (headline and body).
class CustomCell: UITableViewCell {
    
    /// The identifier used to register and dequeue cells of this class with a table view.
    static let reuseIdentifier = "CustomCell"
    
    // MARK: - Properties
    
    let headlineLabel = makeSampleLabel()
    let bodyLabel = makeSampleLabel()
    
    /**
     A convenience factory method that performs the common base configuration for both labels.
    
     - Returns: A new label with a common base configuration.
     */
    private static func makeSampleLabel() -> UILabel {
        let label = UILabel()
        
        /*
         Translation of autoresizing masks into constraints is disabled because it would conflict with the auto adjusting constraints that are
         set up in `setUpLabelsAndConstraints`. This is only needed because these labels are created programatically.
         */
        label.translatesAutoresizingMaskIntoConstraints = false
        
        // Both labels can grow to as many lines as needed.
        label.numberOfLines = 0
        return label
    }
    
    // MARK: - Initialization
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUpLabelsAndConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUpLabelsAndConstraints()
    }
    
    // MARK: -
    
    /**
     Set up labels and constraints so that both fonts and spacing automatically adjusts when the content size changes.
     
     - Note: This is the core part of this sample.
     */
    private func setUpLabelsAndConstraints() {
        /*
         The headline label uses the preferred, default `headline` font. This font is already scaled appropriately and supports Dynamic Type.
         All that's needed to have the label automatically adjust this font, is to enable `adjustsFontForContentSizeCategory`.
         */
        headlineLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        headlineLabel.adjustsFontForContentSizeCategory = true
        
        /*
         The body label uses a non-default system font. To make this font support Dynamic Type - and scale it to the current content size - the
         "un-scaled" font is used to create a scaled version that uses the `.body` text style information.
         With this scaled font variant, the label can be configured to make automatic adjustments when the content size changes.
         */
        guard let palatino = UIFont(name: "Palatino", size: 18) else {
            fatalError("""
                Failed to load the "Palatino" font.
                Since this font is included with all versions of iOS that support Dynamic Type, verify that the spelling and casing is correct.
                """
            )
        }
        bodyLabel.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: palatino)
        bodyLabel.adjustsFontForContentSizeCategory = true

        /*
         Views that make up the cell's "content" are added to its `contentView`, rather than as top level subviews of the cell, so that they are
         positioned appropriately as the cell transitions into and out of editing mode.
         */
        contentView.addSubview(bodyLabel)
        contentView.addSubview(headlineLabel)
        
        /*
         To have both labels extend the full width of the cell (within default margins); one label's leading and trailing anchors are constrained
         to the corresponding anchors of the cells `contentView` and the other label is constrained to align its leading and trailing anchors with
         the first one.
         */
        headlineLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
        headlineLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
        
        bodyLabel.leadingAnchor.constraint(equalTo: headlineLabel.leadingAnchor).isActive = true
        bodyLabel.trailingAnchor.constraint(equalTo: headlineLabel.trailingAnchor).isActive = true

        /*
         To achieve a layout that looks good at all content sizes, the spacing between elements should adjust along with the content.
         
         Since the appropriate spacing around text depends on properties of the font being used; the first baseline of the headline label is
         constrained to use a system spacing to the top of the `contentView`, rather than a regular top-anchor to top-anchor constraint.
         
         Similarly, the _last_ baseline of the body label is constrained to use a system spacing to the bottom of the `contentView`, rather than
         a bottom-anchor to bottom-anchor constraint.
         
         Since either of the two labels could wrap to multiple lines; the _last_ baseline of the top (headline) label constrained to use a system
         spacing to the _first_ baseline of the bottom (body) label.
         */
        headlineLabel.firstBaselineAnchor.constraint(equalToSystemSpacingBelow: contentView.layoutMarginsGuide.topAnchor, multiplier: 1).isActive = true
        
        contentView.layoutMarginsGuide.bottomAnchor.constraint(equalToSystemSpacingBelow: bodyLabel.lastBaselineAnchor, multiplier: 1).isActive = true
        
        bodyLabel.firstBaselineAnchor.constraint(equalToSystemSpacingBelow: headlineLabel.lastBaselineAnchor, multiplier: 1).isActive = true
    }
}

