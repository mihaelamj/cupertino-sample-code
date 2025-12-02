/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implementation of a view controller for the scroll view and document view.
*/

import Cocoa

class DocumentViewController: NSViewController {
    let viewModel = DocumentViewModel()
    private let scrollView = NSScrollView()
    private var documentView: DocumentView
    
    required init?(coder decoder: NSCoder) {
        documentView = DocumentView(viewModel: viewModel)
        super.init(coder: decoder)
        setupDocumentView()
        setupScrollView()
        setupConstraints()
    }
    
    func setupDocumentView() {
        documentView.textLayoutManager = viewModel.textLayoutManager
        documentView.updateContentSizeIfNeeded()
        let attrStr = NSAttributedString(string: """
Release Party Invitation

Hi Huan,

We are throwing a release party and board game night! \
Join us for a relaxed evening filled with good food, cocktails, fun, and board games. \
It’s going to be a blast!

Date: Tuesday, April 1st; Time: 7 pm

RSVP Now! We would love to see you there.
""")
        viewModel.replaceText(inRange: NSRange(location: 0, length: 0), with: attrStr, applyingDefaultAttributes: true)
    }
    
    func setupScrollView() {
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.documentView = documentView
    }
    
    func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        NSLayoutConstraint.activate([
            documentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            documentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            documentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            documentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor)
        ])
    }
    
    @objc
    func formatBold(_ sender: Any) {
        if viewModel.firstSelectedAttributedString.length > 0 {
            viewModel.setFontWeight(viewModel.selectedTextFontWeight == .bold ? .regular : .bold)
        }
    }
}

extension DocumentViewController: NSToolbarItemValidation {
    func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
        if item.itemIdentifier == NSToolbarItem.Identifier.fontStyleBold {
            var buttonShade = NSColor.systemGray
            if viewModel.selectedTextFontWeight == .bold {
                buttonShade = NSColor.systemBlue
            }
            let configuration = NSImage.SymbolConfiguration(paletteColors: [buttonShade])
            item.image = item.image?.withSymbolConfiguration(configuration)
            return viewModel.firstSelectedAttributedString.length > 0
        }
        
        return false
    }
}
