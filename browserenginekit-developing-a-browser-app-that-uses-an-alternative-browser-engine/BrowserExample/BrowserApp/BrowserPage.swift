/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A complete browser page with tabs, forward and back buttons, and other standard browser UI elements.
*/

import CustomBrowserEngine
import SwiftUI

private var bookmarks: [WebViewDestination] = [
  .localFile(Bundle.main.url(forResource: "index", withExtension: "html")!),
  .url(URL(string: "https://apple.com")!)
]

// MARK: -

struct TabContentView: View {
  
  @ObservedObject var tab: TabViewModel
  
  var body: some View {
    if let error = tab.error {
      VStack {
        Image(systemName: "exclamationmark.triangle")
        Text(error.localizedDescription)
      }
    } else {
      WebViewRepresentable(webView: tab.webView)
    }
  }
}

// MARK: -

struct BrowserPage: View {
  
  @Namespace var namespace
  
  @EnvironmentObject var alertManager: AlertManager
    
  @ObservedObject var model: BrowserPageViewModel
    
  @State private var showBookmarks: Bool = false
  
  @State private var isSearching: Bool = false
    
  var body: some View {
    Group {
      if model.showTabs {
        tabsView
      } else if let tab = model.selectedtab {
        tabView(tab)
      } else {
        tabsView
      }
    }
  }
  
  @ViewBuilder
  private func tabView(_ tab: TabViewModel) -> some View {
    TabContentView(tab: tab)
      .matchedGeometryEffect(id: tab.id, in: namespace)
      .scrollDismissesKeyboard(.interactively)
      .searchable(text: $model.searchBarString,
                  isPresented: $isSearching,
                  placement: .navigationBarDrawer(displayMode: .always),
                  prompt: Text("Enter URL"))
      .searchSuggestions { makeSearchSuggestions() }
      .onSubmit(of: .search, onSearchSubmit)
      .toolbar {
        ToolbarItemGroup(placement: .bottomBar) {
          backButton
          Spacer()
          forwardButton
          Spacer()
          shareButton
          Spacer()
          bookmarksButton
          Spacer()
          showTabsButton
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
          if model.isLoading {
            ProgressView()
          }
          refreshButton
        }
      }
      .sheet(isPresented: $showBookmarks, content: {
        makeBookmarksSheetContent()
      })
  }
  
  @ViewBuilder
  private var tabsView: some View {
    Group {
      if model.tabs.isEmpty {
        Text("Tap the \(Image(systemName: "plus")) button to create a new tab")
          .font(.callout)
          .foregroundStyle(.secondary)
      } else {
        ScrollView {
          LazyVGrid(columns: tabsListGridItems) {
            ForEach(model.tabs) { tab in
              makeTabView(for: tab)
            }
          }
          .padding(.horizontal)
        }
      }
    }
    .navigationTitle("\(model.tabs.count) Tabs")
    .toolbar {
      ToolbarItem {
        newTabButton
      }
    }
  }
  
  private var tabsListGridItems: [GridItem] {
    return [
      GridItem(.adaptive(minimum: 230, maximum: 400)),
      GridItem(.adaptive(minimum: 230, maximum: 400))
    ]
  }
  
  @ViewBuilder
  private func makeTabView(for tab: TabViewModel) -> some View {
    Button(action: {
      withAnimation {
        model.activateTab(tab)
      }
    }, label: {
      ZStack(alignment: .topLeading) {
        VStack {
          RoundedRectangle(cornerRadius: 10)
            .matchedGeometryEffect(id: tab.id, in: namespace)
            .frame(height: 250)
          Text(tab.displayName)
            .lineLimit(1)
            .fontWeight((tab == model.selectedtab) ? .bold : .regular)
        }
        closeTabButton(id: tab.id)
          .padding(5)
          .labelStyle(.iconOnly)
          .tint(.secondary)
      }
    })
  }
  
  @ViewBuilder
  private func closeTabButton(id: UUID) -> some View {
    Button {
      withAnimation {
        model.closeTab(id: id)
      }
    } label: {
      Label("Close", systemImage: "xmark.circle.fill")
    }
  }
  
  @ViewBuilder
  private func makeBookmarksSheetContent() -> some View {
    NavigationStack {
      BookmarksList(bookmarks: bookmarks) {
        model.load($0)
        showBookmarks = false
      }
      .navigationTitle("Bookmarks")
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          DismissButton(isPresented: $showBookmarks)
        }
      }
    }
  }
  
  private func makeSearchSuggestions() -> some View {
    ForEach(bookmarks, id: \.self) {
      if let url = $0.url {
        Text(verbatim: $0.displayName)
          .searchCompletion(url.absoluteString)
      }
    }
  }
  
  private var newTabButton: some View {
    Button {
      createNewTab()
    } label: {
      Label("New Tab", systemImage: "plus")
    }
  }
  
  private var refreshButton: some View {
    Button {
      model.refresh()
    } label: {
      Label("Relaod", systemImage: "arrow.clockwise")
    }
    .disabled(model.isLoading)
    .help("Reload the current page")
  }
  
  private var bookmarksButton: some View {
    Button {
      showBookmarks = true
    } label: {
      Label("Bookmkars", systemImage: "book")
    }
    .help("Show bookmarks")
  }
  
  private var forwardButton: some View {
    Button {
      model.go(.forward)
    } label: {
      Label("Forward", systemImage: "chevron.forward")
    }
    .disabled(!model.canGoForward)
    .help("Show the next page")
  }
  
  private var backButton: some View {
    Button {
      model.go(.back)
    } label: {
      Label("Back", systemImage: "chevron.backward")
    }
    .disabled(!model.canGoBack)
    .help("Show the previous page")
  }
  
  private var shareButton: some View {
    ActivityViewButton(configuration: getShareButtonConfiguration)
      .disabled(model.searchBarString.isEmpty)
      .help("Share")
  }
  
  private var showTabsButton: some View {
    Button {
      withAnimation {
        model.setShowTabs(true)
      }
    } label: {
      Label("Show Tabs", systemImage: "square.on.square")
    }
    .help("Show all tabs")
  }
  
  private func getShareButtonConfiguration() -> ActivityViewControllerConfiguration {
    var items: [Any] = []
    if let url = URL(string: model.searchBarString) {
      let item = HomeScreenBookmarkItem(url: url, title: "Bookmark")
      items.append(item)
      items.append(url)
    }
    return .activityItems(items, applicationActivities: [])
  }
  
  private func createNewTab() {
    Task {
      do {
        try await model.createNewTab(activate: false)
      } catch let error {
        alertManager.present(error: error, title: "Failed to create tab")
      }
    }
  }
  
  private func onSearchSubmit() {
    if let url = URL(string: model.searchBarString, encodingInvalidCharacters: false) {
      isSearching = false
      let destination: WebViewDestination = url.isFileURL ? .localFile(url) : .url(url)
      model.load(destination)
    } else {
      alertManager.present(title: "Search failed", message: "Please enter a valid URL")
    }
  }
}

// MARK: -

/// A basic SwiftUI wrapper around a custom ``WebView``
///
private struct WebViewRepresentable: UIViewRepresentable {
  
  var webView: WebView
  
  func makeUIView(context: Context) -> WebView {
    return makeWebView()
  }
  
  func updateUIView(_ uiView: WebView, context: Context) { }
  
  func makeWebView() -> WebView {
    return webView
  }
}

// MARK: -

private struct BookmarksList: View {
  
  var bookmarks: [WebViewDestination]
  
  var onSelect: (WebViewDestination) -> Void
  
  var body: some View {
    List {
      ForEach(bookmarks, id: \.self) { bookmark in
        makeLink(for: bookmark)
      }
    }
  }
  
  @ViewBuilder
  private func makeLink(for bookmark: WebViewDestination) -> some View {
    Button {
      onSelect(bookmark)
    } label: {
      VStack(alignment: .leading) {
        Text(bookmark.displayName)
        if let url = bookmark.url {
          Text(url.absoluteString)
            .font(.caption)
            .tint(Color.secondary)
        }
      }
    }
  }
}

// MARK: -

private struct DismissButton: View {
  
  @Binding var isPresented: Bool
  
  var body: some View {
    Button("Done") {
      withAnimation {
        isPresented = false
      }
    }
    .buttonStyle(.plain)
    .foregroundColor(.accentColor)
  }
}

