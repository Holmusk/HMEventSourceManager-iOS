//
//  HMMockEventStreamManager.swift
//  HMEventSourceManagerTests
//
//  Created by Hai Pham on 21/9/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import RxSwift
import SwiftUtilities
@testable import HMEventSourceManager

public final class HMMockEventSourceManager: HMEventSourceManagerType {
    public let manager: HMEventSourceManager
    
    public init(_ manager: HMEventSourceManager) {
        self.manager = manager
    }
    
    public var newlineCharacters: [String] {
        return manager.newlineCharacters
    }
    
    public func isReachableStream() -> Observable<Bool> {
        return manager.isReachableStream()
    }
    
    public func triggerReachable() -> AnyObserver<Bool> {
        return manager.triggerReachable()
    }
    
    public func didReceiveData<O>(_ task: URLSessionDataTask,
                                  _ data: Data,
                                  _ obs: O) where
        O: ObserverType, O.E == HMSSEvent<Data>
    {
        manager.didReceiveData(task, data, obs)
    }
    
    public func didReceiveResponse<E, O>(_ task: URLSessionDataTask,
                                         _ response: URLResponse,
                                         _ obs: O) where
        O: ObserverType, O.E == HMSSEvent<E>
    {
        manager.didReceiveResponse(task, response, obs)
    }
    
    public func didCompleteWithError<O>(_ task: URLSessionTask,
                                        _ error: Error?,
                                        _ obs: O) where
        O: ObserverType, O.E == HMSSEvent<Data>
    {
        manager.didCompleteWithError(task, error, obs)
    }
    
    public func openConnection<O>(_ request: HMEventSourceManagerType.Request,
                                  _ obs: O) -> Disposable where
        O: ObserverType, O.E == HMSSEvent<Data>
    {
        return manager.openConnection(request, obs)
    }
}
