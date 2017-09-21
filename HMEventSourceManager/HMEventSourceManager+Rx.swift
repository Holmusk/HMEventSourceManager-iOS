//
//  HMEventSourceManager+Rx.swift
//  HMEventSourceManager
//
//  Created by Hai Pham on 21/9/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import RxSwift
import RxReachability
import SwiftUtilities

extension HMEventSourceManager: ReactiveCompatible {}

public extension HMEventSourceManager {
    func openSSEConnection<O>(_ request: Request,
                              _ configuration: URLSessionConfiguration,
                              _ queue: OperationQueue,
                              _ obs: O) -> Disposable where
        O: ObserverType, O.E == Data
    {
        do {
            print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>> CREATING NEW SESSION!!!!")
            let urlRequest = try request.urlRequest()
            
            let delegate = HMURLSessionSSEDelegate.builder()
                .with(didReceiveResponse: { debugPrint($0) })
                .with(didReceiveData: { obs.onNext($0) })
                .with(didCompleteWithError: {
                    if let error = $0 {
                        obs.onError(error)
                    }
                })
                .build()
            
            let urlSession = URLSession(configuration: configuration,
                                        delegate: delegate,
                                        delegateQueue: queue)
            
            let task = urlSession.dataTask(with: urlRequest)
            
            task.resume()
            
            return Disposables.create(with: {
                urlSession.invalidateAndCancel()
            })
        } catch let error {
            obs.onError(error)
            return Disposables.create()
        }
    }
}

public extension Reactive where Base == HMEventSourceManager {
    public typealias Request = HMEventSourceManager.Request
    
    /// We need a separate isReachable Observable because reachability.rx
    /// does not relay that last event.
    public var isReachable: Observable<Bool> {
        return base.isReachable.asObservable().distinctUntilChanged()
    }
    
    public var isConnected: Observable<Void> {
        return isReachable.filter({$0}).map(toVoid)
    }
    
    public var isDisconnected: Observable<Void> {
        return isReachable.filter({!$0}).map(toVoid)
    }
    
    /// Open a new SSE connection that listens to connectivity changes and
    /// terminates when connectivity is not available.
    ///
    /// - Parameters:
    ///   - request: A Request instance.
    ///   - sseObs: A SSE connection creator Observable.
    ///   - disconnectedObs: A disconnected notifier.
    ///   - terminateObs: A terminate notifier.
    /// - Returns: An Observable instance.
    func reachabilityAwareSSE<SO,TO>(_ request: Request,
                                     _ sseObs: SO,
                                     _ terminateObs: TO)
        -> Observable<Data> where
        SO: ObservableConvertibleType, SO.E == Data,
        TO: ObservableConvertibleType, TO.E == Void
    {
        let newRequest = base.requestWithDefaultParams(request)
        
        let terminateNotifier = Observable.amb([
            self.isDisconnected,
            terminateObs.asObservable()
        ])
        
        let retries = newRequest.retries()
        let delay = newRequest.retryDelay()
        let retryScheduler = ConcurrentDispatchQueueScheduler(qos: .background)
        
        return sseObs.asObservable()
            .subscribeOn(qos: .background)
            .delayRetry(retries: retries,
                        delay: delay,
                        scheduler: retryScheduler,
                        terminateObs: terminateNotifier)
            .takeUntil(terminateNotifier)
            .observeOn(qos: .background)
    }
    
    /// Open a new SSE connection only when there is internet connectivity.
    ///
    /// - Parameters:
    ///   - request: A Request instance.
    ///   - sseObs: A SSE connection creator Observable.
    ///   - connectedObs: A connected notifier.
    ///   - disconnectedObs: A disconnected notifier.
    ///   - terminateObs: An Observable instance that notifies when to stop retrying.
    /// - Returns: An Observable instance.
    public func retryOnConnectivitySSE<SO,TO>(_ request: Request,
                                              _ sseObs: SO,
                                              _ terminateObs: TO)
        -> Observable<Data> where
        SO: ObservableConvertibleType, SO.E == Data,
        TO: ObservableConvertibleType, TO.E == Void
    {
        return self.isConnected
            .flatMapLatest({self.reachabilityAwareSSE(request,
                                                      sseObs,
                                                      terminateObs)})
            .takeUntil(terminateObs.asObservable())
    }
    
    /// Open a new SSE connection only when there is internet connectivity.
    ///
    /// - Parameters:
    ///   - request: A Request instance.
    ///   - terminateObs: An Observable instance that notifies when to stop retrying.
    /// - Returns: An Observable instance.
    public func retryOnConnectivitySSE<TO>(_ request: Request,
                                           _ terminateObs: TO)
        -> Observable<Data> where
        TO: ObservableConvertibleType, TO.E == Void
    {
        let newRequest = base.requestWithDefaultParams(request)
        let config = base.urlSessionConfig(newRequest)
        let queue = OperationQueue()
        
        let sseObs = Observable<Data>.create({
            self.base.openSSEConnection(newRequest, config, queue, $0)
        })
        
        return retryOnConnectivitySSE(request, sseObs, terminateObs)
    }
}
