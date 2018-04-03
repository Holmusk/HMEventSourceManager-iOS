//
//  HMMockEventStreamManager.swift
//  HMEventSourceManagerTests
//
//  Created by Hai Pham on 21/9/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import RxSwift
import SwiftFP
import SwiftUtilities
@testable import HMEventSourceManager

public final class HMMockEventSourceManager: HMSSEManagerType {
    public let manager: HMSSEManager
    public var addDefaultParamsInterceptor: ((Req) -> Void)?
    
    public init(_ manager: HMSSEManager) {
        self.manager = manager
    }
    
    public var newlineCharacters: [String] {
        return manager.newlineCharacters
    }
    
    public func addDefaultParams(_ request: Req) -> Req {
        let newRequest = manager.addDefaultParams(request)
        addDefaultParamsInterceptor?(newRequest)
        return newRequest
    }
    
    public func isReachableStream() -> Observable<Bool> {
        return manager.isReachableStream()
    }
    
    public func triggerReachable() -> AnyObserver<Bool> {
        return manager.triggerReachable()
    }
    
    public func lastEventIdForKey(_ key: String) -> String? {
        return manager.lastEventIdForKey(key)
    }
    
    public func storeLastEventIdWithKey(_ key: String, _ value: String) {
        return manager.storeLastEventIdWithKey(key, value)
    }
    
    public func openConnection<O>(_ request: Req, _ obs: O) -> Disposable where
        O: ObserverType, O.E == Try<HMSSEvent<Data>>
    {
        return manager.openConnection(request, obs)
    }
}
