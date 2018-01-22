//
//  NetworkOperation.swift
//  OperationKit
//
//  Created by Florian Schliep on 22.01.18.
//  Copyright © 2018 Florian Schliep. All rights reserved.
//

import Foundation

open class NetworkOperation<ResultType, TaskResultType>: AsyncOperation<ResultType, NSError> {
    
    public typealias NetworkResponseEvaluation = (TaskResultType, HTTPURLResponse) throws -> ResultType
    
    // MARK: - Properties
    
    open let url: URL
    open let urlSession: URLSession
    private var task: URLSessionTask?
    private var evaluate: NetworkResponseEvaluation
    
    // MARK: - Instantiation
    
    public override init() {
        fatalError("NetworkOperation is an abstract class! You must provide an implementation of init in your subclass!")
    }
    
    public required init(url: URL, urlSession: URLSession, evaluate: @escaping NetworkResponseEvaluation) {
        self.url = url
        self.urlSession = urlSession
        self.evaluate = evaluate
        super.init()
    }
    
    // MARK: - Abstract Logic
    
    open func prepareRequest(_ request: inout URLRequest) throws { }
    
    open func createTask(with request: URLRequest, using session: URLSession) -> URLSessionTask {
        fatalError("NetworkOperation is an abstract class! You must provide an implementation of createTask(with:using:) in your subclass.")
    }
    
    public final func evaluate(result: TaskResultType, response: HTTPURLResponse) throws -> ResultType {
        return try self.evaluate(result, response)
    }
    
    // MARK: - NSOperation
    
    open override func cancel() {
        self.task?.cancel()
        super.cancel()
    }
    
    // MARK: - Execution
    
    open override func execute() {
        // prepare request
        var request = URLRequest(url: self.url)
        do {
            try self.prepareRequest(&request)
        } catch let error as NSErrorConvertible {
            self.finish(withError: error.nsError)
            return
        } catch {
            let nsError = NSError(domain: "com.floschliep.OperationKit.UnknownError",
                                  code: 1,
                                  userInfo: [ NSLocalizedDescriptionKey: error.localizedDescription ])
            self.finish(withError: nsError)
            return
        }
        
        // start task
        self.task = self.createTask(with: request, using: self.urlSession)
        self.task!.resume()
    }
    
}

public protocol NSErrorConvertible: Error {
    var nsError: NSError { get }
}

extension NSError: NSErrorConvertible {
    public var nsError: NSError {
        return self
    }
}

enum NetworkOperationError: NSErrorConvertible {
    case emptyResponse
    case invalidResponse
    
    var message: String {
        switch self {
        case .emptyResponse:
            return NSLocalizedString("Received Empty Response", comment: "")
        case .invalidResponse:
            return NSLocalizedString("Received Invalid Response", comment: "")
        }
    }
    
    var code: Int {
        switch self {
        case .emptyResponse:
            return 11
        case .invalidResponse:
            return 12
        }
    }
    
    var nsError: NSError {
        return NSError(domain: "com.floschliep.OperationKit.NetworkOperationError",
                       code: self.code,
                       userInfo: [NSLocalizedDescriptionKey: self.message])
    }
}
