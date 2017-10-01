//
//  HMURLSessionSSEDelegate.swift
//  HMEventSourceManager
//
//  Created by Hai Pham on 21/9/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import RxSwift
import SwiftUtilities

public final class HMURLSessionSSEDelegate: NSObject {
    public typealias ResponseDisposition = URLSession.ResponseDisposition
    public typealias DidReceiveData = (URLSessionDataTask, Data) -> Void
    public typealias DidReceiveResponse = (URLSessionDataTask, URLResponse) -> Void
    public typealias DidCompleteWithError = (URLSessionTask, Error?) -> Void
    fileprivate var didReceiveData: DidReceiveData?
    fileprivate var didReceiveResponse: DidReceiveResponse?
    fileprivate var didCompleteWithError: DidCompleteWithError?
    fileprivate let operation: OperationQueue
    
    deinit {
        debugPrint("Deinit \(self)")
    }
    
    public func removeCallbacks() {
        operation.cancelAllOperations()
        didReceiveData = nil
        didReceiveResponse = nil
        didCompleteWithError = nil
    }
    
    fileprivate override init() {
        let operation = OperationQueue()
        operation.underlyingQueue = DispatchQueue.global(qos: .background)
        self.operation = operation
    }
}

extension HMURLSessionSSEDelegate: BuildableType {
    public static func builder() -> Builder {
        return Builder()
    }
    
    public final class Builder {
        fileprivate let delegate: HMURLSessionSSEDelegate
        
        fileprivate init() {
            delegate = HMURLSessionSSEDelegate()
        }
        
        /// Set the didReceiveData instance.
        ///
        /// - Parameter didReceiveData: A DidReceiveData instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(didReceiveData: DidReceiveData?) -> Self {
            delegate.didReceiveData = didReceiveData
            return self
        }
        
        /// Set the didReceiveResponse instance.
        ///
        /// - Parameter didReceiveResponse: A DidReceiveResponse instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(didReceiveResponse: DidReceiveResponse?) -> Self {
            delegate.didReceiveResponse = didReceiveResponse
            return self
        }
        
        /// Set the didCompleteWithError instance.
        ///
        /// - Parameter didCompleteWithError: A DidCompleteWithError instance.
        /// - Returns: The current Builder instance.
        @discardableResult
        public func with(didCompleteWithError: DidCompleteWithError?) -> Self {
            delegate.didCompleteWithError = didCompleteWithError
            return self
        }
    }
}

extension HMURLSessionSSEDelegate.Builder: BuilderType {
    public typealias Buildable = HMURLSessionSSEDelegate
    
    @discardableResult
    public func with(buildable: Buildable?) -> Self {
        if let buildable = buildable {
            return self
                .with(didReceiveData: buildable.didReceiveData)
                .with(didCompleteWithError: buildable.didCompleteWithError)
                .with(didReceiveResponse: buildable.didReceiveResponse)
        } else {
            return self
        }
    }
    
    public func build() -> Buildable {
        return delegate
    }
}

extension HMURLSessionSSEDelegate: URLSessionDataDelegate {
    public func urlSession(_ session: URLSession,
                           dataTask: URLSessionDataTask,
                           didReceive data: Data) {
        operation.addOperation({[weak self] in
            self?.didReceiveData?(dataTask, data)
        })
    }
    
    public func urlSession(_ session: URLSession,
                           dataTask: URLSessionDataTask,
                           didReceive response: URLResponse,
                           completionHandler: @escaping (ResponseDisposition) -> Void) {
        operation.addOperation({[weak self] in
            completionHandler(.allow)
            self?.didReceiveResponse?(dataTask, response)
        })
    }
    
    public func urlSession(_ session: URLSession,
                           task: URLSessionTask,
                           didCompleteWithError error: Error?) {
        operation.addOperation({[weak self] in
            self?.didCompleteWithError?(task, error)
        })
    }
}
