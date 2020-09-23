//
//  Router.swift
//  SimpleBrowser
//
//  Created by Jozef Lipovsky on 2019-08-03.
//  Copyright © 2019 JoLi. All rights reserved.
//

import Foundation

struct Endpoint {
    let path: String
    let queryItems: [URLQueryItem]
}

enum Router {
    case searchResults(query: String?)
    case searchSuggestions(query: String?)
    
    var url: URL? {
        switch self {
        case .searchResults:
            return self.caseURL(scheme: scheme, host: host, endpoint: endpoint)
            
        case .searchSuggestions:
            return self.caseURL(scheme: scheme, host: host, endpoint: endpoint)
        }
    }
    
    var scheme: String {
        switch self {
        case .searchResults(_),
             .searchSuggestions(_):
            return "https"
        }
    }
    
    var host: String {
        switch self {
        case .searchResults(_):
            return "onbibi.com"
            
        case .searchSuggestions(_):
            return "api.bing.com"
        }
    }
    
    var endpoint: Endpoint {
        switch self {
        case .searchResults(let query):
            return Endpoint(path: "/search", queryItems: [URLQueryItem(name: "q", value: query)])
            
        case .searchSuggestions(let query):
            return Endpoint(path: "/osjson.aspx", queryItems: [URLQueryItem(name: "query", value: query)])
        }
    }
    
    func caseURL(scheme: String, host: String, endpoint: Endpoint) -> URL? {
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.path = endpoint.path
        components.queryItems = endpoint.queryItems
        return components.url
    }
}
