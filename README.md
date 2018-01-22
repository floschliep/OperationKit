#OperationKit
`OperationKit` is an abstract generic wrapper around Foundation’s `Operation` class. It provides a common ground for operations that either produce a result or throw an error. There are 3 abstract classes for different kinds of operations — `AsyncOperation`, `SyncOperation` and `NetworkOperation` — as well as 2 concrete implementations — `NetworkDataOperation` and `NetworkDownloadOperation`.

##Usage
Operations have a generic `ResultType` and `ErrorType`. In case of success, the operations’s respective `successHandler` will be executed and the `failureHandler` in case of failure. By default the callbacks will be executed on the main queue, but you can specify any queue using the `callbackQueue` property.

Subclasses are required to provide an implementation of the `main()` method that calls either `finish(withResult:)` or `finish(withError:)` upon completion. Implementations must not call `super` and can be certain the operation is supposed to be executed (e.g. checks for cancellation are not necessary at the beginning).

The state of operations is being managed automatically by the superclass. If your operations are long-lived (e.g. network operations), it is recommended to regularly check for cancellation in order to avoid doing unnecessary work. Neither the `successHandler` nor the `failureHandler` will be executed if an operation is cancelled.

###NetworkOperation
Your subclasses of `NetworkOperation` must provide an implementation of `createTask(with:using:)` that creates an `URLSessionTask` using the provided `URLRequest` and `URLSession`.

All `NetworkOperation` classes use a closure of the type `(TaskResultType, HTTPURLResponse) throws -> ResultType` to evaluate their result, where `TaskResultType` is the type of the result produced by the `URLSessionTask` created earlier (e.g `Data`) and `ResultType` is final result type of the operation.

####NetworkDataOperation
`NetworkDataOperation` is a concrete implementation of the `NetworkOperation` whose usage speaks for itself:
```
let url = …
let operation = NetworkDataOperation(url: url, urlSession: .shared) { data, response in
	return try JSONDecoder().decode(MyObject.self, from: data)
}
operation.successHandler = { myObject in
	…            
}
```

####NetworkDownloadOperation
`NetworkDownloadOperation` is similar to `NetworkDataOperation`, but returns a temporary `URL` where the downloaded data can be found:
```
let url = …
let operation = NetworkDownloadOperation<URL>(url: url, urlSession: .shared) { tempURL, response in
	let finalFileURL = …
	try fileManager.moveItem(at: tempURL, to: finalFileURL)
            
	return finalFileURL
}
operation.successHandler = { fileURL in
	…            
}
```

##Future Plans
I plan to introduce more concrete operation implementations (e.g. file operations) in future, PRs are also welcome. I’m also not 100% happy with the error handling of `NetworkOperation`, which currently relies on `NSError`.

##Contact
Florian Schliep

- [github.com/floschliep](https://github.com/floschliep)
- [twitter.com/floschliep](https://twitter.com/floschliep)
- [floschliep.com](http://floschliep.com)

##License
`OperationKit` is available under the MIT license. See the LICENSE file for more info.
