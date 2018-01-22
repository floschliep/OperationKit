//
//  NetworkDataOperation.swift
//  OperationKit
//
//  Created by Florian Schliep on 22.01.18.
//  Copyright © 2018 Florian Schliep. All rights reserved.
//

import Foundation

open class NetworkDataOperation<ResultType>: NetworkOperation<ResultType, Data> {
    public final override func createTask(with request: URLRequest, using session: URLSession) -> URLSessionTask {
        return session.dataTask(with: request) { [weak self] receivedData, response, taskError in
            guard let `self` = self else { return }
            guard !self.isCancelled else { return }
            
            do {
                if let error = taskError {
                    throw error
                }
                guard let data = receivedData else {
                    throw NetworkOperationError.emptyResponse
                }
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkOperationError.invalidResponse
                }
                let result = try self.evaluate(result: data, response: httpResponse)
                self.finish(withResult: result)
            } catch let error as NSErrorConvertible {
                self.finish(withError: error.nsError)
            }
        }
    }
}
