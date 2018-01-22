//
//  SyncOperationTests.swift
//  OperationKitTests
//
//  Created by Florian Schliep on 21.01.18.
//  Copyright © 2018 Florian Schliep. All rights reserved.
//

import XCTest
@testable import OperationKit

private class MockOperation: SyncOperation<Bool, NSError> {
    let result: Bool?
    
    init(result: Bool?) {
        self.result = result
    }
    
    override func main() {
        if let result = self.result {
            self.finish(withResult: result)
        } else {
            self.finish(withError: NSError(domain: "com.example.test", code: 0, userInfo: nil))
        }
    }
}

class SyncOperationTests: XCTestCase {
    
    let operationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.underlyingQueue = DispatchQueue.global(qos: .background)
        
        return queue
    }()

    func testProperties() {
        let operation = MockOperation(result: true)
        XCTAssertFalse(operation.isConcurrent)
        XCTAssertFalse(operation.isAsynchronous)
    }
    
    func testSuccess() {
        let result = true
        let queue = DispatchQueue(label: "com.example.queue")
        
        let expectation = self.expectation(description: "callback with result on queue")
        
        let operation = MockOperation(result: result)
        operation.callbackQueue = queue
        operation.successHandler = { operationResult in
            XCTAssertEqual(operationResult, result)
            // compare the current queue to the expected queue
            XCTAssertEqual(__dispatch_queue_get_label(nil), __dispatch_queue_get_label(queue))
            expectation.fulfill()
        }
        operation.failureHandler = { _ in
            XCTFail()
        }
        operation.start()
        
        self.waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testFailure() {
        let expectation = self.expectation(description: "callback with result on main queue")
        
        let operation = MockOperation(result: nil)
        operation.successHandler = { _ in
            XCTFail()
        }
        operation.failureHandler = { error in
            XCTAssertTrue(Thread.current.isMainThread)
            expectation.fulfill()
        }
        operation.start()
        
        self.waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testCancellectionWithSuccess() {
        let expectation = self.expectation(description: "call completion")
        
        let operation = MockOperation(result: true)
        operation.successHandler = { _ in
            XCTFail()
        }
        operation.failureHandler = { _ in
            XCTFail()
        }
        operation.completionBlock = {
            expectation.fulfill()
        }
        self.operationQueue.addOperation(operation)
        operation.cancel()
        
        self.waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testCancellationWithFailure() {
        let expectation = self.expectation(description: "call completion")
        
        let operation = MockOperation(result: nil)
        operation.successHandler = { _ in
            XCTFail()
        }
        operation.failureHandler = { _ in
            XCTFail()
        }
        operation.completionBlock = {
            expectation.fulfill()
        }
        self.operationQueue.addOperation(operation)
        operation.cancel()
        
        self.waitForExpectations(timeout: 1, handler: nil)
    }
    
}
