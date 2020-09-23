//
//  SearchViewModelTests.swift
//  SimpleBrowserTests
//
//  Created by Jozef Lipovsky on 2019-08-04.
//  Copyright © 2019 JoLi. All rights reserved.
//

import XCTest
@testable import SimpleBrowser

class SearchViewModelTests: XCTestCase {
    var mockAPIClient: MockAPIClient!
    var viewModel: SearchViewModel!

    override func setUp() {
        mockAPIClient = MockAPIClient()
        viewModel = SearchViewModel(apiClient: mockAPIClient)
    }

    override func tearDown() {
        viewModel = nil
        mockAPIClient = nil
    }

    func testSearchQuery_withEmptyQuery_shouldReturnWithNoErrorAndWithoutHittingAPI() {
        viewModel.search(query: "") { (error) in
            XCTAssertNil(error)
        }

        XCTAssertFalse(mockAPIClient.requestWasPerformed)
    }
    
    func testSearchQuery_withSuccess_shouldSetCurrentSearchSuggestions() {
        mockAPIClient.shouldSimulateSuccess = true
        viewModel.search(query: "firefox") { (error) in }
        XCTAssertTrue(self.mockAPIClient.requestWasPerformed)
        
        XCTAssertEqual(viewModel.numberOfRows(), 12)
        XCTAssertEqual(viewModel.suggestion(at: IndexPath(row: 3, section: 0)), "firefox browser")
        
        let searchQueryResultURL = viewModel.searchResultURL(forSearchQuery: "test query")
        XCTAssertNotNil(searchQueryResultURL)
        XCTAssertEqual(searchQueryResultURL, URL(string: "https://onbibi.com/search?q=test%20query"))
        
        let searchSuggestionResultURL = viewModel.searchResultURL(forSuggestionAt: IndexPath(row: 7, section: 0))
        XCTAssertNotNil(searchSuggestionResultURL)
        XCTAssertEqual(searchSuggestionResultURL, URL(string: "https://bing.com/search?q=firefox%20download%20chrome"))
    }
    
    func testSearchQuery_withNoRequestError_shouldReturnWithoutError() {
        mockAPIClient.shouldSimulateSuccess = true
        viewModel.search(query: "qwe") { (error) in
            XCTAssertNil(error)
        }
        XCTAssertTrue(self.mockAPIClient.requestWasPerformed)
    }
    
    func testSearchQuery_withCancelledRequest_shouldPerformRequestButShouldNotSetCurrentSearchSuggestions() {
        mockAPIClient.shouldSimulateSuccess = true
        mockAPIClient.shouldSimulateCancelledRequest = true
        viewModel.search(query: "qwe") { (error) in
            XCTFail("Cancelled requests should be silently ignored, completion should not be called.")
        }
        XCTAssertTrue(self.mockAPIClient.requestWasPerformed)
        XCTAssertEqual(self.viewModel.numberOfRows(), 0)
    }
    
    func testSearchQuery_withRequestError_shouldReturnWithError() {
        mockAPIClient.shouldSimulateSuccess = false
        viewModel.search(query: "asd qwe") { (error) in
            XCTAssertNotNil(error)
        }

        XCTAssertTrue(self.mockAPIClient.requestWasPerformed)
    }
    
    func testCurrentURLUpdate() {
        XCTAssertNil(viewModel.searchSuggestionURLString(hostOnly: true))
        
        let firstURL = URL(string: "https://google.com/randomPath")
        viewModel.updateCurrentURL(with: firstURL)
        XCTAssertNotNil(viewModel.searchSuggestionURLString(hostOnly: true))
        XCTAssertEqual(viewModel.searchSuggestionURLString(hostOnly: true), firstURL?.host)
        XCTAssertEqual(viewModel.searchSuggestionURLString(hostOnly: false), firstURL?.absoluteString)
        
        let secondURL = URL(string: "https://bing.com/anotherRandomPath")
        viewModel.updateCurrentURL(with: secondURL)
        XCTAssertEqual(viewModel.searchSuggestionURLString(hostOnly: true), secondURL?.host)
        XCTAssertEqual(viewModel.searchSuggestionURLString(hostOnly: false), secondURL?.absoluteString)
    }
}

extension SearchViewModelTests {
    class MockAPIClient: APIClient<SearchSuggestions> {
        private(set) var requestWasPerformed = false
        var shouldSimulateSuccess = false
        var shouldSimulateCancelledRequest = false

        override func request(with url: URL?, completion: @escaping (SearchSuggestions?, Error?) -> ()) -> URLSessionDataTask? {
            requestWasPerformed = true
            
            if shouldSimulateSuccess {
                if shouldSimulateCancelledRequest {
                    completion(nil, NSError(domain: "", code: NSURLErrorCancelled, userInfo: [NSLocalizedDescriptionKey: "Unit test request cancelled"]))
                } else {
                     completion(searchSuggestions, nil)
                }
            } else {
                completion(nil, NSError(domain: "", code: 111, userInfo: [NSLocalizedDescriptionKey: "Unit test Error"]))
            }
            
            return URLSessionDataTask()
        }
        
        private var searchSuggestions: SearchSuggestions {
            let validJSON = """
        [
        "firefox",
            [
                "firefox",
                "firefox download",
                "firefox download windows 10",
                "firefox browser",
                "firefox download windows 7",
                "firefox quantum",
                "firefox esr",
                "firefox download chrome",
                "firefox add-ons",
                "firefox nightly",
                "firefox youtube",
                "firefox download windows"
            ]
        ]
        """
            
            let data = Data(validJSON.utf8)
            return try! JSONDecoder().decode(SearchSuggestions.self, from: data)
        }
    }
}
