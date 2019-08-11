//
//  APIClientTests.swift
//  SimpleBrowserTests
//
//  Created by Jozef Lipovsky on 2019-08-03.
//  Copyright © 2019 JoLi. All rights reserved.
//

import XCTest
@testable import SimpleBrowser

class APIClientTests: XCTestCase {
    var apiClient: APIClient<TestDecodableObject>!
    var mockSession: MockURLSession!

    override func setUp() {
        mockSession = MockURLSession()
        apiClient = APIClient(session: mockSession)
    }

    override func tearDown() {
        mockSession = nil
        apiClient = nil
    }
    
    func testRequest_shouldUseExpectedURL() {
        apiClient.request(with: URL(string: "https://api.bing.com")) { (object, error) in }
        XCTAssertEqual(mockSession.url, URL(string: "https://api.bing.com"))
    }
    
    func testRequest_withValidURL_shouldReturnDataTask() {
        let expectedDataTask = apiClient.request(with: URL(string: "www.google.com")) { (object, error) in }
        XCTAssertNotNil(expectedDataTask)
    }
    
    func testRequest_shouldCallResumeForCreatedDataTask() {
        apiClient.request(with: Router.searchSuggestions(query: "random string").url) { (object, error) in }
        XCTAssertTrue(mockSession.dataTask.resumeFunctionWasCalled)
    }
    
    func testRequest_withInvalidURL_shouldFailWithErrorAndNoDecodableTestObject() {
        let errorExpectation = expectation(description: "Error")
        var expectedError: Error?
        let objectExpectation = expectation(description: "Decoded Object")
        var expectedObject: TestDecodableObject?
        let expectedDataTask = apiClient.request(with: nil) { (object, error) in
            expectedObject = object
            expectedError = error
            errorExpectation.fulfill()
            objectExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 1) { (error) in
            XCTAssertNil(expectedObject)
            XCTAssertNil(expectedDataTask)
            XCTAssertNotNil(expectedError)
        }
    }
    
    func testRequest_withSuccessAndValidResponseData_shouldReturnDecodableTestObject() {
        let validJSON = """
        {
            "host":"localhost",
            "port":3030,
            "paginate":{
                "default":10,
                "max":50
            }
        }
        """
    
        let mockResponse = HTTPURLResponse(url: URL(string: "www.google.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        mockSession.dataTask = MockSessionDataTask(data: Data(validJSON.utf8), urlResponse: mockResponse, error: nil)
        
        let errorExpectation = expectation(description: "Error")
        var expectedError: Error?
        let objectExpectation = expectation(description: "Decoded Object")
        var expectedObject: TestDecodableObject?
        apiClient.request(with: URL(string: "www.google.com")) { (object, error) in
            expectedObject = object
            expectedError = error
            errorExpectation.fulfill()
            objectExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 1) { (error) in
            XCTAssertNil(expectedError)
            XCTAssertNotNil(expectedObject)
        }
    }
    
    func testRequest_withSuccessButInvalidResponseData_shouldFailWithErrorAndNoDecodableTestObject() {
        let invalidJSON = """
        {
            "port":3030,
            "paginate":{
                "default":10,
                "max":50
            }
        }
        """
        
        let mockResponse = HTTPURLResponse(url: URL(string: "www.google.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
        mockSession.dataTask = MockSessionDataTask(data: Data(invalidJSON.utf8), urlResponse: mockResponse, error: nil)
        
        let errorExpectation = expectation(description: "Error")
        var expectedError: Error?
        let objectExpectation = expectation(description: "Decoded Object")
        var expectedObject: TestDecodableObject?
        apiClient.request(with: URL(string: "www.google.com")) { (object, error) in
            expectedObject = object
            expectedError = error
            errorExpectation.fulfill()
            objectExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 1) { (error) in
            XCTAssertNotNil(expectedError)
            XCTAssertNil(expectedObject)
        }
    }
    
    func testRequest_withResponseErrorStatusCode_shouldFailWithErrorAndNoDecodableTestObject() {
        
        let mockResponse = HTTPURLResponse(url: URL(string: "www.google.com")!, statusCode: 500, httpVersion: nil, headerFields: nil)
        mockSession.dataTask = MockSessionDataTask(data: Data(), urlResponse: mockResponse, error: nil)
        
        let errorExpectation = expectation(description: "Error")
        var expectedError: Error?
        let objectExpectation = expectation(description: "Decoded Object")
        var expectedObject: TestDecodableObject?
        apiClient.request(with: URL(string: "www.google.com")) { (object, error) in
            expectedObject = object
            expectedError = error
            errorExpectation.fulfill()
            objectExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 1) { (error) in
            XCTAssertNotNil(expectedError)
            XCTAssertNil(expectedObject)
        }
    }
    
    func testRequest_withError_shouldFailWithErrorAndNoDecodableTestObject() {
        
        let error = NSError(domain: "", code: 111, userInfo: [NSLocalizedDescriptionKey: "Unit test Error"])
        mockSession.dataTask = MockSessionDataTask(data: nil, urlResponse: nil, error: error)
        
        let errorExpectation = expectation(description: "Error")
        var expectedError: Error?
        let objectExpectation = expectation(description: "Decoded Object")
        var expectedObject: TestDecodableObject?
        apiClient.request(with: URL(string: "www.google.com")) { (object, error) in
            expectedObject = object
            expectedError = error
            errorExpectation.fulfill()
            objectExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 1) { (error) in
            XCTAssertNotNil(expectedError)
            XCTAssertNil(expectedObject)
        }
    }
}


extension APIClientTests {
    
    struct TestDecodableObject: Decodable {
        let host: String
        let port: Int
        let paginate: [String: Int]
    }
    
    class MockURLSession: SessionProtocol {
        var url: URL?
        var dataTask = MockSessionDataTask(data: nil, urlResponse: nil, error: nil)
        
        
        func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
            self.url = url
            dataTask.completionHandler = completionHandler
            return dataTask
        }
    }
    
    class MockSessionDataTask: URLSessionDataTask {
        private(set) var resumeFunctionWasCalled = false
        private let data: Data?
        private let urlResponse: URLResponse?
        private let taskError: Error?
        
        typealias CompletionHandler = (Data?, URLResponse?, Error?)
            -> Void
        var completionHandler: CompletionHandler?
        
        init(data: Data?, urlResponse: URLResponse?, error: Error?) {
            self.data = data
            self.urlResponse = urlResponse
            self.taskError = error
        }
        
        override func resume() {
            resumeFunctionWasCalled = true
            self.completionHandler?(self.data, self.urlResponse, self.taskError)
        }
    }
}


