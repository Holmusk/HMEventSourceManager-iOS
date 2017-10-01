//
//  HMSSEManager+Extension.swift
//  HMEventSourceManager
//
//  Created by Hai Pham on 21/9/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import RxSwift
import RxReachability
import SwiftUtilities

extension HMSSEManager: HMSSEManagerType {
    public func isReachableStream() -> Observable<Bool> {
        return self.isReachable.distinctUntilChanged()
    }
    
    public func triggerReachable() -> AnyObserver<Bool> {
        return self.isReachable.asObserver()
    }
    
    public func lastEventIdForKey(_ key: String) -> String? {
        return userDefaults().string(forKey: key)
    }
    
    public func storeLastEventIdWithKey(_ key: String, _ value: String) {
        userDefaults().set(value, forKey: key)
    }
    
    /// DidReceiveData callback.
    public func didReceiveData<O>(_ task: URLSessionDataTask,
                                  _ data: Data,
                                  _ obs: O) where
        O: ObserverType, O.E == HMSSEvent<Data>
    {
        // When the connection is first opened, there might be a dummy event
        // with 1 byte that we can ignore so as not to push two concurrent
        // events onto the observer.
        if data.count > 1 {
            obs.onNext(HMSSEvent.dataReceived(data))
        }
    }
    
    /// DidReceiveResponse callback.
    public func didReceiveResponse<E,O>(_ task: URLSessionDataTask,
                                        _ response: URLResponse,
                                        _ obs: O) where
        O: ObserverType, O.E == HMSSEvent<E>
    {
        obs.onNext(HMSSEvent<E>.connectionOpened)
    }
    
    /// DidCompleteWithError callback.
    public func didCompleteWithError<O>(_ task: URLSessionTask,
                                        _ error: Error?,
                                        _ obs: O) where
        O: ObserverType, O.E == HMSSEvent<Data>
    {
        if let error = error as NSError?, error.code != 999 {
            obs.onError(error)
        } else if error == nil {
            // We throw error here as well to access retryWhen.
            obs.onError(Exception("Data transfer completed - resubscribing."))
        } else {
            obs.onCompleted()
        }
    }
    
    /// Open a SSE connection.
    public func openConnection<O>(_ request: Request, _ obs: O) -> Disposable where
        O: ObserverType, O.E == HMSSEvent<Data>
    {
        let newRequest = requestWithDefaultParams(request)
        let config = urlSessionConfig(newRequest)
        let queue = OperationQueue()
        
        do {
            let url = try newRequest.url()
            
            let delegate = HMURLSessionSSEDelegate.builder()
                .with(didReceiveResponse: {self.didReceiveResponse($0.0, $0.1, obs)})
                .with(didReceiveData: {self.didReceiveData($0.0, $0.1, obs)})
                .with(didCompleteWithError: {self.didCompleteWithError($0.0, $0.1, obs)})
                .build()
            
            let urlSession = URLSession(configuration: config,
                                        delegate: delegate,
                                        delegateQueue: queue)
            
            let task = urlSession.dataTask(with: url)
            
            task.resume()
            
            return Disposables.create(with: {
                delegate.removeCallbacks()
                urlSession.invalidateAndCancel()
            })
        } catch let error {
            obs.onError(error)
            return Disposables.create()
        }
    }
}
