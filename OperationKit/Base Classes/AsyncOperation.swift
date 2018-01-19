//
//  AsyncOperation.swift
//  OperationKit
//
//  Created by Florian Schliep on 19.01.18.
//  Copyright © 2018 Florian Schliep. All rights reserved.
//

import Foundation

open class AsyncOperation<ResultType, ErrorType: Error>: Operation<ResultType, ErrorType> {
 
    // MARK: - NSOperation
    
    @objc private dynamic var flo_executing: Bool = false
    @objc private dynamic var flo_finished: Bool = false
    
    override open class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        var paths = super.keyPathsForValuesAffectingValue(forKey: key)
        switch key {
        case "isFinished":
            paths.insert("flo_finished")
        case "isExecuting":
            paths.insert("flo_executing")
        default:
            break
        }
        
        return paths
    }
    
    final public override var isConcurrent: Bool {
        return true
    }
    
    final public override var isAsynchronous: Bool {
        return true
    }
    
    final public override var isExecuting: Bool {
        return self.flo_executing
    }
    
    final public override var isFinished: Bool {
        return self.flo_finished
    }
    
    open override func cancel() {
        super.cancel()
        self.flo_executing = false
        self.flo_finished = true
    }
    
    final public override func start() {
        guard !self.isCancelled else { return }
        
        self.flo_executing = true
        self.startOperation()
    }
    
    // MARK: - Execution
    
    func startOperation() {
        fatalError("AsyncOperation is an abstract class! You must provide an implementation of startOperation in your subclass.")
    }
    
    final public override func finish(withError error: ErrorType) {
        guard !self.isCancelled else { return }
        
        self.callbackQueue.async() { [weak self] in
            self?.failureHandler?(error)
            self?.flo_executing = false
            self?.flo_finished = true
        }
    }
    
    final public override func finish(withResult result: ResultType) {
        guard !self.isCancelled else { return }
        
        self.callbackQueue.async() { [weak self] in
            self?.successHandler?(result)
            self?.flo_executing = false
            self?.flo_finished = true
        }
    }
    
}
