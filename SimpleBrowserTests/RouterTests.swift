//
//  RouterTests.swift
//  SimpleBrowserTests
//
//  Created by Jozef Lipovsky on 2019-08-03.
//  Copyright © 2019 JoLi. All rights reserved.
//

import XCTest
@testable import SimpleBrowser

class RouterTests: XCTestCase {

    func testURL_shouldReturnCorrectURLForEachCase() {
        let expectedSearchResultsRouterURL = URL(string: "https://bing.com/search?q=abc%20def")
        let searchResultsRouter = Router.searchResults(query: "abc def")
        XCTAssertEqual(searchResultsRouter.url, expectedSearchResultsRouterURL)
        
        let expectedSearchSuggestionsRouterURL = URL(string: "https://api.bing.com/osjson.aspx?query=qwe%202123%20asd")
        let searchSuggestionsRouter = Router.searchSuggestions(query: "qwe 2123 asd")
        XCTAssertEqual(searchSuggestionsRouter.url, expectedSearchSuggestionsRouterURL)
    }
}
