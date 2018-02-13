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
            XCTAssertTrue(queue.isCurrentQueue)
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
    
    func testCurrentQueueDetection() {
        XCTAssertTrue(DispatchQueue.main.isCurrentQueue)
        
        let queue1 = DispatchQueue(label: "queue1")
        let queue2 = DispatchQueue(label: "queue2")
        
        queue1.sync {
            XCTAssertTrue(queue1.isCurrentQueue)
            XCTAssertFalse(queue2.isCurrentQueue)
            XCTAssertFalse(DispatchQueue.main.isCurrentQueue)
        }
        
        queue2.sync {
            XCTAssertTrue(queue2.isCurrentQueue)
            XCTAssertFalse(queue1.isCurrentQueue)
            XCTAssertFalse(DispatchQueue.main.isCurrentQueue)
        }
        
        queue1.sync {
            queue2.sync {
                XCTAssertTrue(queue2.isCurrentQueue)
                XCTAssertFalse(queue1.isCurrentQueue)
            }
            XCTAssertTrue(queue1.isCurrentQueue)
            XCTAssertFalse(queue2.isCurrentQueue)
        }
    }
    
    func testSafeSync() {
        let queue1 = DispatchQueue(label: "queue1")
        let queue2 = DispatchQueue(label: "queue2")
        
        var mainQueueCalled = false
        DispatchQueue.main.safeSync {
            mainQueueCalled = true
            XCTAssertTrue(DispatchQueue.main.isCurrentQueue)
        }
        XCTAssertTrue(mainQueueCalled)
        
        var queue1Called = false
        var queue2Called = false
        queue1.safeSync {
            XCTAssertTrue(queue1.isCurrentQueue)
            queue1.safeSync {
                queue1Called = true
                XCTAssertTrue(queue1.isCurrentQueue)
            }
            queue2.safeSync {
                XCTAssertTrue(queue2.isCurrentQueue)
                queue2.safeSync {
                    queue2Called = true
                    XCTAssertTrue(queue2.isCurrentQueue)
                }
            }
        }
        XCTAssertTrue(queue1Called)
        XCTAssertTrue(queue2Called)
    }
    
}
