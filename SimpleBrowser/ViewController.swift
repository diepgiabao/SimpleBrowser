//
//  ViewController.swift
//  SimpleBrowser
//
//  Created by Jozef Lipovsky on 2019-07-30.
//  Copyright © 2019 JoLi. All rights reserved.
//

import UIKit
import WebKit

class ViewController: UIViewController {
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var loadingProgressView: UIProgressView!
    @IBOutlet weak var toolBarBackButton: UIBarButtonItem!
    @IBOutlet weak var toolBarForwardButton: UIBarButtonItem!
    @IBOutlet weak var toolBarReloadButton: UIBarButtonItem!
    
    private let reuseIdentifier = "SearchSuggestionsCell"
    private let viewModel = SearchViewModel()
    private var searchController: UISearchController?
    private var searchSuggestionsViewController: UITableViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    fileprivate func setupWebView() {
    webView.uiDelegate = self
    webView.translatesAutoresizingMaskIntoConstraints = false
    DispatchQueue.main.async {
        guard let url = URL(string: "https://onbibi.com/m") else { return }
        self.webView.load(URLRequest(url: url))
    }
    view.addSubview(webView)
    webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10).isActive = true
    webView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10).isActive = true
    webView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10).isActive = true
    webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 10).isActive = true
}
    
    deinit {
        webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress))
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "estimatedProgress" {
            loadingProgressView.progress = Float(webView.estimatedProgress)
        }
    }
    
    // MARK:- Private
    
    private func setupUI() {
        webView.navigationDelegate = self
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
        loadingProgressView.isHidden = true
        
        searchSuggestionsViewController = UITableViewController()
        searchSuggestionsViewController?.tableView.delegate = self
        searchSuggestionsViewController?.tableView.dataSource = self
        searchSuggestionsViewController?.tableView.register(UITableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
        
        searchController = UISearchController(searchResultsController: searchSuggestionsViewController)
        searchController?.searchBar.placeholder = NSLocalizedString("Search", comment: "Search bar placeholder")
        searchController?.searchBar.delegate = self
        searchController?.searchResultsUpdater = self
        searchController?.delegate = self
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        navigationItem.largeTitleDisplayMode = .never
        definesPresentationContext = true
        
        configureToolbarNavigation()
    }
    
    private func configureToolbarNavigation() {
        toolBarBackButton.isEnabled = webView.canGoBack
        toolBarForwardButton.isEnabled = webView.canGoForward
        toolBarReloadButton.isEnabled = webView.url != nil
    }
    
    private func configureSearchBarAfterWebViewUpdate(url: URL?) {
        viewModel.updateCurrentURL(with: url)
        searchController?.searchBar.placeholder = viewModel.searchSuggestionURLString(hostOnly: true) ?? NSLocalizedString("Search", comment: "Search bar placeholder")
    }
    
    private func reloadWebView(url: URL?) {
        guard let url = url else {
            showAlert(title: NSLocalizedString("Error", comment: "Alert Error Title"),
                      message: NSLocalizedString("Failed to construct URL for search query.", comment: "Failed to construct URL alert message"))
            return
        }
        webView.load(URLRequest(url: url))
        searchController?.isActive = false
    }
    
    private func showAlert(title: String?, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    // MARK:- IBAction
    
    @IBAction func backButtonTapped(_ sender: UIBarButtonItem) {
        if webView.canGoBack {
            webView.goBack()
        }
    }
    
    @IBAction func forwardButtonTapped(_ sender: UIBarButtonItem) {
        if webView.canGoForward {
            webView.goForward()
        }
    }
    
    @IBAction func reloadButtonTapped(_ sender: UIBarButtonItem) {
        webView.reload()
    }
}


// MARK:- UITableViewDataSource

extension ViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchController?.isActive == true ? viewModel.numberOfRows() : 0
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        cell.textLabel?.text = viewModel.suggestion(at: indexPath)
        return cell
    }
}


// MARK:- UITableViewDelegate

extension ViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        reloadWebView(url: viewModel.searchResultURL(forSuggestionAt: indexPath))
    }
}


// MARK:- UISearchResultsUpdating

extension ViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        viewModel.search(query: searchController.searchBar.text) { [weak self] (error) in
            guard error == nil else {
                self?.showAlert(title: NSLocalizedString("Error", comment: "Alert Error Title"), message: error?.localizedDescription)
                searchController.isActive = false
                return
            }
            
            self?.searchSuggestionsViewController?.tableView.reloadData()
        }
    }
}


// MARK:- UISearchControllerDelegate

extension ViewController: UISearchControllerDelegate {
    
    func willPresentSearchController(_ searchController: UISearchController) {
        searchController.searchBar.text = viewModel.searchSuggestionURLString(hostOnly: false)
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
        searchController.searchBar.placeholder = viewModel.searchSuggestionURLString(hostOnly: true) ?? NSLocalizedString("Search", comment: "Search bar placeholder")
    }
}


// MARK:- UISearchBarDelegate

extension ViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        reloadWebView(url: viewModel.searchResultURL(forSearchQuery: searchBar.text))
    }
}


// MARK:- WKNavigationDelegate

extension ViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loadingProgressView.isHidden = true
        configureToolbarNavigation()
        configureSearchBarAfterWebViewUpdate(url: webView.url)
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        loadingProgressView.isHidden = false
        configureToolbarNavigation()
        configureSearchBarAfterWebViewUpdate(url: webView.url)
    }
    
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        loadingProgressView.isHidden = true
        configureToolbarNavigation()
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        loadingProgressView.isHidden = true
        configureToolbarNavigation()
        
        if let error = error as NSError?, error.code != NSURLErrorCancelled {
            showAlert(title: NSLocalizedString("Error", comment: "Alert Error Title"), message: error.localizedDescription)
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        loadingProgressView.isHidden = true
        configureToolbarNavigation()
        
        if let error = error as NSError?, error.code != NSURLErrorCancelled {
            showAlert(title: NSLocalizedString("Error", comment: "Alert Error Title"), message: error.localizedDescription)
        }
    }
}
