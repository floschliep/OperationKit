//
//  NetworkOperationTests.swift
//  OperationKitTests
//
//  Created by Florian Schliep on 13.02.18.
//  Copyright © 2018 Florian Schliep. All rights reserved.
//

import XCTest
import OHHTTPStubs
@testable import OperationKit

private struct SomeObject: Codable {
    let magicNumber: Int
}

private class MockNetworkOperation: NetworkOperation<SomeObject, Data> {
    
    private(set) var task: URLSessionTask?
    private(set) var preparedRequest: URLRequest?
    private(set) var usedSession: URLSession?
    private(set) var usedRequest: URLRequest?
    
    override func prepareRequest(_ request: inout URLRequest) throws {
        self.preparedRequest = request
    }
    
    override func createTask(with request: URLRequest, using session: URLSession) -> URLSessionTask {
        self.usedSession = session
        self.usedRequest = request
        
        self.task = session.dataTask(with: request) { [weak self] data, response, error in
            guard let `self` = self else { return }
            do {
                if let error = error {
                    throw error
                } else {
                    let result = try self.evaluate(result: data!, response: response as! HTTPURLResponse)
                    self.finish(withResult: result)
                }
            } catch let error as NSError {
                self.finish(withError: error)
            }
        }
        return self.task!
    }
    
}

class NetworkOperationTests: XCTestCase {
    
    let operationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.underlyingQueue = DispatchQueue.global(qos: .background)
        
        return queue
    }()
    let urlSession = URLSession(configuration: .default)
    
    override func setUp() {
        super.setUp()
        
        stub(condition: isHost("example1.com")) { _ in
            return OHHTTPStubsResponse(jsonObject: ["magicNumber": 123], statusCode: 200, headers: nil)
        }
        stub(condition: isHost("example2.com")) { _ in
            return OHHTTPStubsResponse(error: NSError(domain: "com.example.test", code: 404, userInfo: nil))
        }
        stub(condition: isHost("example3.com")) { _ in
            let response = OHHTTPStubsResponse()
            response.responseTime = 1
            response.requestTime = 1
            
            return response
        }
    }
    
    override func tearDown() {
        super.tearDown()
        OHHTTPStubs.removeAllStubs()
    }
    
    func testSuccess() {
        var failureHandlerCalled = false
        var result: SomeObject? = nil
        var httpResonse: HTTPURLResponse? = nil
        let expectation = self.expectation(description: "call success handler")
        
        let operation = NetworkDataOperation(url: URL(string: "http://example1.com")!, urlSession: self.urlSession) { data, response -> SomeObject in
            httpResonse = response
            return try JSONDecoder().decode(SomeObject.self, from: data)
        }
        operation.failureHandler = { _ in
            failureHandlerCalled = true
        }
        operation.successHandler = { object in
            result = object
            expectation.fulfill()
        }
        self.operationQueue.addOperation(operation)
        self.waitForExpectations(timeout: 1, handler: nil)
        
        XCTAssertTrue(operation.urlSession == self.urlSession)
        
        XCTAssertFalse(failureHandlerCalled)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.magicNumber, 123)
        
        XCTAssertNotNil(httpResonse)
        XCTAssertEqual(httpResonse?.statusCode, 200)
    }
    
    func testFailure() {
        var operationError: NSError? = nil
        var successHandlerCalled = false
        let expectation = self.expectation(description: "call failure handler")
        let url = URL(string: "http://example2.com")!
        
        let operation = MockNetworkOperation(url: url, urlSession: self.urlSession) { data, _ in
            return try JSONDecoder().decode(SomeObject.self, from: data)
        }
        operation.failureHandler = { error in
            operationError = error
            expectation.fulfill()
        }
        operation.successHandler = { _ in
            successHandlerCalled = true
        }
        self.operationQueue.addOperation(operation)
        self.waitForExpectations(timeout: 1, handler: nil)
        
        XCTAssertTrue(operation.usedSession === self.urlSession)
        XCTAssertTrue(operation.preparedRequest == operation.usedRequest)
        
        XCTAssertFalse(successHandlerCalled)
        XCTAssertNotNil(operationError)
        XCTAssertEqual(operationError?.domain, "com.example.test")
        
        XCTAssertNotNil(operation.preparedRequest)
        XCTAssertEqual(operation.preparedRequest?.url, url)
        
        XCTAssertNotNil(operation.task)
        XCTAssertEqual(operation.task?.state, .completed)
    }
    
    func testCancellation() {
        var successHandlerCalled = false
        var failureHandlerCalled = false
        let expectation = self.expectation(description: "call completion block")
        
        let operation = MockNetworkOperation(url: URL(string: "http://example3.com")!, urlSession: self.urlSession) { data, _ in
            return try JSONDecoder().decode(SomeObject.self, from: data)
        }
        operation.failureHandler = { _ in
            failureHandlerCalled = true
        }
        operation.successHandler = { _ in
            successHandlerCalled = true
        }
        operation.completionBlock = {
            expectation.fulfill()
        }
        
        self.operationQueue.addOperation(operation)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            operation.cancel()
            XCTAssertEqual(operation.task?.state, .canceling)
        }
        self.waitForExpectations(timeout: 1, handler: nil)
        
        XCTAssertTrue(operation.urlSession == self.urlSession)
        XCTAssertFalse(successHandlerCalled)
        XCTAssertFalse(failureHandlerCalled)
    }
    
    func testDownloadOperation() {
        var failureHandlerCalled = false
        var result: SomeObject? = nil
        let expectation = self.expectation(description: "call success handler")
        
        let operation = NetworkDownloadOperation(url: URL(string: "http://example1.com")!, urlSession: self.urlSession) { url, response -> SomeObject in
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(SomeObject.self, from: data)
        }
        operation.failureHandler = { _ in
            failureHandlerCalled = true
        }
        operation.successHandler = { object in
            result = object
            expectation.fulfill()
        }
        self.operationQueue.addOperation(operation)
        self.waitForExpectations(timeout: 1, handler: nil)
        
        XCTAssertTrue(operation.urlSession == self.urlSession)
        XCTAssertFalse(failureHandlerCalled)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.magicNumber, 123)
    }
    
}
