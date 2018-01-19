//
//  Operation.swift
//  OperationKit
//
//  Created by Florian Schliep on 19.01.18.
//  Copyright © 2018 Florian Schliep. All rights reserved.
//

import Foundation

open class Operation<ResultType, ErrorType: Error>: Foundation.Operation {
    
    open var failureHandler: ((ErrorType) -> Void)?
    open var successHandler: ((ResultType) -> Void)?
    open var callbackQueue = DispatchQueue.main
    
    public func finish(withError error: ErrorType) {
        fatalError("Operation is an abstract class, you must provide an implementation in your subclass!")
    }
    
    public func finish(withResult result: ResultType) {
        fatalError("Operation is an abstract class, you must provide an implementation in your subclass!")
    }
    
}
