//
//  SyncOperation.swift
//  OperationKit
//
//  Created by Florian Schliep on 19.01.18.
//  Copyright © 2018 Florian Schliep. All rights reserved.
//

import Foundation

open class SyncOperation<ResultType, ErrorType: Error>: Operation<ResultType, ErrorType> {
    
    // MARK: - NSOperation
    
    final public override var isConcurrent: Bool {
        return false
    }
    
    final public override var isAsynchronous: Bool {
        return false
    }
    
    // MARK: - Execution
    
    final public override func finish(withError error: ErrorType) {
        guard !self.isCancelled else { return }
        
        self.callbackQueue.safeSync {
            self.failureHandler?(error)
        }
    }
    
    final public override func finish(withResult result: ResultType) {
        guard !self.isCancelled else { return }
        
        self.callbackQueue.safeSync {
            self.successHandler?(result)
        }
    }
    
}

extension DispatchQueue {
    var isCurrentQueue: Bool {
        return (__dispatch_queue_get_label(nil) == __dispatch_queue_get_label(self))
    }
    
    func safeSync(execute block: () -> Void) {
        if self.isCurrentQueue {
            block()
        } else {
            self.sync(execute: block)
        }
    }
}
