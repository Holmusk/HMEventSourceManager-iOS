//
//  HMSSEManager+Extension.swift
//  HMEventSourceManager
//
//  Created by Hai Pham on 21/9/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import RxSwift
import RxReachability
import SwiftFP
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
    
    /// Open a SSE connection.
    public func openConnection<O>(_ request: Req, _ obs: O) -> Disposable where
        O: ObserverType, O.E == Try<HMSSEvent<Data>>
    {
        Preconditions.checkNotRunningOnMainThread(nil)
        let config = urlSessionConfig(request)
        
        do {
            let url = try request.url()
            let delegate = HMSSEDelegate(obs)
            
            let urlSession = URLSession(configuration: config,
                                        delegate: delegate,
                                        delegateQueue: nil)
            
            let task = urlSession.dataTask(with: url)

            task.resume()
            
            return Disposables.create(with: {
                delegate.removeCallbacks()
                urlSession.invalidateAndCancel()
            })
        } catch let error {
            obs.onNext(Try.failure(error))
            return Disposables.create()
        }
    }
}
