//
//  HMEventSourceManager+URLSession.swift
//  HMEventSourceManager
//
//  Created by Hai Pham on 21/9/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import RxSwift
import SwiftUtilities

public extension HMEventSourceManager {
    public func openSSEConnection() -> Observable<Try<Data>> {
        var additionalHeaders = self.additionalHeaders()
        additionalHeaders["Accept"] = "text/event-stream"
        additionalHeaders["Cache-Control"] = "no-cache"
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = TimeInterval(INT_MAX)
        config.timeoutIntervalForResource = TimeInterval(INT_MAX)
        config.httpAdditionalHeaders = additionalHeaders
        
        let queue = OperationQueue()
        return Observable.create({self.openSSEConnection(config, queue, $0)})
    }
    
    func openSSEConnection<O>(_ configuration: URLSessionConfiguration,
                              _ queue: OperationQueue,
                              _ obs: O) -> Disposable where
        O: ObserverType, O.E == Try<Data>
    {
        let delegate = HMURLSessionSSEDelegate.builder()
            .with(didReceiveResponse: { debugPrint($0) })
            .with(didReceiveData: { obs.onNext(Try.success($0)) })
            .with(didCompleteWithError: {
                if let error = $0 {
                    obs.onNext(Try.failure(error))
                }
            })
            .build()
        
        let urlSession = URLSession(configuration: configuration,
                                    delegate: delegate,
                                    delegateQueue: queue)
        
        let url = self.targetURL()
        let task = urlSession.dataTask(with: url)
        task.resume()
        
        return Disposables.create(with: {
            task.cancel()
            urlSession.invalidateAndCancel()
        })
    }
}
