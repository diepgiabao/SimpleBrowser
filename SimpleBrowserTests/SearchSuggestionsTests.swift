//
//  SearchSuggestionsTests.swift
//  SimpleBrowserTests
//
//  Created by Jozef Lipovsky on 2019-08-01.
//  Copyright © 2019 JoLi. All rights reserved.
//

import XCTest
@testable import SimpleBrowser

class SearchSuggestionsTests: XCTestCase {
    
    func testInitialization_shouldReturnValidObject() {
        let data = Data()
        do {
            let searchSuggestion = try JSONDecoder().decode(SearchSuggestions.self, from: data)
            XCTAssertNotNil(searchSuggestion)
            XCTAssertNotNil(searchSuggestion.keyWord)
            XCTAssertEqual(searchSuggestion.keyWord, "firefox")
            XCTAssertNotNil(searchSuggestion.suggestions)
            XCTAssertFalse(searchSuggestion.suggestions.isEmpty)
        } catch let error {
            XCTFail("Decoding SearchSuggestions from valid JSON should NOT throw an error: \(error.localizedDescription).")
        }
    }
    
    func testInitialization_shouldThrow() {
        let data = Data(invalidJSON.utf8)
        XCTAssertThrowsError(try JSONDecoder().decode(SearchSuggestions.self, from: data), "Decoding SearchSuggestions from invalid JSON should throw an error.")
    }
    
    
    private let invalidJSON = """
    [
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
    
    
    private let validJSON = """
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
}
