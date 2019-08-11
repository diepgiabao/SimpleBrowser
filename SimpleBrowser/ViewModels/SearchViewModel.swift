//
//  SearchViewModel.swift
//  SimpleBrowser
//
//  Created by Jozef Lipovsky on 2019-08-03.
//  Copyright © 2019 JoLi. All rights reserved.
//

import Foundation

class SearchViewModel {
    private let apiClient: APIClient<SearchSuggestions>
    private var currentTask: URLSessionDataTask?
    private var currentSearchSuggestions: SearchSuggestions?
    private var currentURL: URL?
    
    init(apiClient: APIClient<SearchSuggestions>) {
        self.apiClient = apiClient
    }
    
    convenience init() {
        self.init(apiClient: APIClient())
    }
    
    func search(query: String?, completion: @escaping (Error?) -> ()) {
        guard query?.isEmpty == false else {
            currentSearchSuggestions = nil
            completion(nil)
            return
        }
        
        currentTask?.cancel()
        currentTask = apiClient.request(with: Router.searchSuggestions(query: query).url) { [weak self] (searchSuggestions, error) in
            if let error = error as NSError? {
                if error.code == NSURLErrorCancelled {
                    print("Cancelling search task for query:\(query ?? "")")
                } else {
                    completion(error)
                }
                return
            }
            
            self?.currentSearchSuggestions = searchSuggestions
            completion(nil)
        }
    }
    
    func numberOfRows() -> Int {
        return currentSearchSuggestions?.suggestions.count ?? 0
    }
    
    func suggestion(at indexPath: IndexPath) -> String {
        return currentSearchSuggestions?.suggestions[indexPath.row] ?? ""
    }
    
    func searchResultURL(forSuggestionAt indexPath: IndexPath) -> URL? {
        return Router.searchResults(query: currentSearchSuggestions?.suggestions[indexPath.row]).url
    }
    
    func searchResultURL(forSearchQuery query: String?) -> URL? {
        return Router.searchResults(query: query).url
    }
    
    func updateCurrentURL(with url: URL?) {
        currentURL = url
    }
    
    func searchSuggestionURLString(hostOnly: Bool) -> String? {
        return hostOnly ? currentURL?.host : currentURL?.absoluteString
    }
}
