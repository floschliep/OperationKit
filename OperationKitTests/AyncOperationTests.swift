//
//  AyncOperationTests.swift
//  OperationKitTests
//
//  Created by Florian Schliep on 21.01.18.
//  Copyright © 2018 Florian Schliep. All rights reserved.
//

import XCTest
@testable import OperationKit

private class MockOperation: AsyncOperation<Bool, NSError> {
    let result: Bool?
    var onExecute: (() -> Void)?
    
    init(result: Bool?) {
        self.result = result
    }
    
    override func execute() {
        self.onExecute?()
        
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.15) { [weak self] in
            if let result = self?.result {
                self?.finish(withResult: result)
            } else {
                self?.finish(withError: NSError(domain: "com.example.test", code: 0, userInfo: nil))
            }
        }
    }
}

class AyncOperationTests: XCTestCase {

    let operationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.underlyingQueue = DispatchQueue.global(qos: .background)
        
        return queue
    }()
    
    func testProperties() {
        let operation = MockOperation(result: nil)
        XCTAssertTrue(operation.isConcurrent)
        XCTAssertTrue(operation.isAsynchronous)
        XCTAssertFalse(operation.isExecuting)
        XCTAssertFalse(operation.isFinished)
    }
    
    func testSuccess() {
        let successExpectation = self.expectation(description: "callback with result on queue")
        let executeExpectation = self.expectation(description: "start execution")
        let expectedResult = true
        
        let operation = MockOperation(result: expectedResult)
        operation.successHandler = { operationResult in
            XCTAssertEqual(operationResult, expectedResult)
            XCTAssertTrue(Thread.current.isMainThread)
            successExpectation.fulfill()
        }
        operation.failureHandler = { _ in
            XCTFail()
        }
        operation.onExecute = { [unowned operation] in
            XCTAssertTrue(operation.isExecuting)
            XCTAssertFalse(operation.isFinished)
            executeExpectation.fulfill()
        }
        self.operationQueue.addOperation(operation)
        
        self.waitForExpectations(timeout: 1, handler: nil)
        
        XCTAssertFalse(operation.isExecuting)
        XCTAssertTrue(operation.isFinished)
    }
    
    func testFailure() {
        let successExpectation = self.expectation(description: "callback with result on queue")
        let executeExpectation = self.expectation(description: "start execution")
        let queue = DispatchQueue(label: "com.example.queue")
        
        let operation = MockOperation(result: nil)
        operation.callbackQueue = queue
        operation.successHandler = { operationResult in
            XCTFail()
        }
        operation.failureHandler = { _ in
            // compare the current queue to the expected queue
            XCTAssertEqual(__dispatch_queue_get_label(nil), __dispatch_queue_get_label(queue))
            successExpectation.fulfill()
        }
        operation.onExecute = { [unowned operation] in
            XCTAssertTrue(operation.isExecuting)
            XCTAssertFalse(operation.isFinished)
            executeExpectation.fulfill()
        }
        self.operationQueue.addOperation(operation)
        
        self.waitForExpectations(timeout: 1, handler: nil)
        
        XCTAssertFalse(operation.isExecuting)
        XCTAssertTrue(operation.isFinished)
    }

    func testCancellationBeforeStart() {
        let expectation = self.expectation(description: "call completion")
        
        let operation = MockOperation(result: true)
        operation.onExecute = {
            XCTFail()
        }
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
        
        XCTAssertFalse(operation.isExecuting)
        XCTAssertTrue(operation.isFinished)
        XCTAssertTrue(operation.isCancelled)
        
        self.waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testCancellationWithSuccess() {
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            operation.cancel()
        }
        
        self.waitForExpectations(timeout: 1, handler: nil)
        
        XCTAssertFalse(operation.isExecuting)
        XCTAssertTrue(operation.isFinished)
        XCTAssertTrue(operation.isCancelled)
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.075) {
            operation.cancel()
        }
        
        self.waitForExpectations(timeout: 1, handler: nil)
        
        XCTAssertFalse(operation.isExecuting)
        XCTAssertTrue(operation.isFinished)
        XCTAssertTrue(operation.isCancelled)
    }
    
}
