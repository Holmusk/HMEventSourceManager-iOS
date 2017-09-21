//
//  HMEventSourceManagerType.swift
//  HMEventSourceManager
//
//  Created by Hai Pham on 21/9/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import HMRequestFramework
import RxSwift
import SwiftUtilities

/// Classes that implement this protocol must be able to handle SSE events.
public protocol HMEventSourceManagerType: ReactiveCompatible {
    typealias Request = HMNetworkRequest
    typealias Result = HMSSEData
    typealias Event = HMSSEvent
    
    var newlineCharacters: [String] { get }
    
    func isReachableStream() -> Observable<Bool>
    
    func triggerReachable() -> AnyObserver<Bool>
    
    /// DidReceiveData callback.
    func didReceiveData<O>(_ task: URLSessionDataTask,
                           _ data: Data,
                           _ obs: O) where
        O: ObserverType, O.E == HMSSEvent<Data>
    
    /// DidReceiveResponse callback.
    func didReceiveResponse<E,O>(_ task: URLSessionDataTask,
                                 _ response: URLResponse,
                                 _ obs: O) where
        O: ObserverType, O.E == HMSSEvent<E>
    
    /// DidCompleteWithError callback.
    func didCompleteWithError<O>(_ task: URLSessionTask,
                                 _ error: Error?,
                                 _ obs: O) where
        O: ObserverType, O.E == HMSSEvent<Data>
    
    /// Open a SSE connection.
    ///
    /// - Parameters:
    ///   - request: A Request instance.
    ///   - obs: An ObserverType instance.
    /// - Returns: A Disposable instance.
    func openConnection<O>(_ request: Request, _ obs: O) -> Disposable where
        O: ObserverType, O.E == HMSSEvent<Data>
}

public extension HMEventSourceManagerType {
    
    /// Get a cloned request with some default parameters.
    ///
    /// - Parameter request: A Request instance.
    /// - Returns: A Request instance.
    func requestWithDefaultParams(_ request: Request) -> Request {
        return request.cloneBuilder()
            .with(operation: .get)
            .add(header: "text/event-stream", forKey: "Accept")
            .add(header: "no-cache", forKey: "Cache-Control")
            .build()
    }
    
    /// Get a URLSessionConfiguration to use with SSE URLSession.
    ///
    /// - Parameter request: A Request instance.
    /// - Returns: A URLSessionConfiguration instance.
    func urlSessionConfig(_ request: Request) -> URLSessionConfiguration {
        let config = URLSessionConfiguration.default
        
        // Note: Do not use Int.max here as it is an invalid timeout interval.
        config.timeoutIntervalForRequest = TimeInterval(INT_MAX)
        config.timeoutIntervalForResource = TimeInterval(INT_MAX)
        config.httpAdditionalHeaders = request.headers()
        return config
    }
}

public extension HMEventSourceManagerType {
    
    /// Extract events from some data.
    ///
    /// - Parameter data: A Data instance.
    /// - Returns: An Array of String.
    fileprivate func extractEvents(_ data: Data) -> [String] {
        var events = [String]()
        let encoding = String.Encoding.utf8.rawValue
        
        // Find first occurrence of delimiter
        var searchRange = Range(uncheckedBounds: (lower: 0, upper: data.count))
        
        while let foundRange = searchForEventInRange(data, searchRange) {
            if foundRange.lowerBound > searchRange.lowerBound {
                let dataChunk = data.subdata(in: Range(uncheckedBounds: (
                    lower: searchRange.lowerBound,
                    upper: foundRange.lowerBound
                )))
                
                if let event = NSString(data: dataChunk, encoding: encoding) {
                    events.append(event as String)
                }
            }
            
            // Search for next occurrence of delimiter
            searchRange = Range(uncheckedBounds: (lower: foundRange.upperBound,
                                                  upper: data.count))
        }
        
        return events
    }
    
    /// Search for event in a range using predefined delimiters.
    ///
    /// - Parameters:
    ///   - data: A Data instance.
    ///   - searchRange: A Range instance.
    /// - Returns: A Range instance.
    fileprivate func searchForEventInRange(_ data: Data,
                                           _ searchRange: Range<Data.Index>)
        -> Range<Data.Index>?
    {
        let newlineCharacters = self.newlineCharacters
        let encoding = String.Encoding.utf8
        let delimiters = newlineCharacters.flatMap({"\($0)\($0)".data(using: encoding)})
        
        for delimiter in delimiters {
            if let foundRange = data.range(of: delimiter,
                                           options: Data.SearchOptions(),
                                           in: searchRange) {
                return foundRange
            }
        }
        
        return nil
    }
    
    /// Parse some events into the appropriate HMSSEvent.
    ///
    /// - Parameter events: A String Array.
    /// - Returns: A HMSSEvent Array.
    fileprivate func parseEventStream(_ events: [String]) -> [Event<Result>] {
        var parsedEvents: [Event<Result>] = []
        
        for event in events {
            guard event.isNotEmpty && !event.hasPrefix(":") else {
                continue
            }
            
            if event.contains("retry:") {
                parsedEvents.append(parseRetryTime(event))
            } else {
                parsedEvents.append(parseEvent(event))
            }
        }
        
        return parsedEvents
    }
    
    /// Parse some events from a Data instance by extracting the event stream
    /// for it beforehand.
    ///
    /// - Parameter data: A Data instance.
    /// - Returns: A HMSSEvent Array.
    fileprivate func parseEventStream(_ data: Data) -> [Event<Result>] {
        return parseEventStream(extractEvents(data))
    }
    
    /// Parse an event from a String. We need to scan the delimiters to identify
    /// the id, event and data.
    ///
    /// - Parameter eventString: A String value.
    /// - Returns: A HMSSEvent instance.
    fileprivate func parseEvent(_ eventString: String) -> Event<Result> {
        var event: [String : String] = [:]
        
        for line in eventString.components(separatedBy: CharacterSet.newlines) {
            autoreleasepool(invoking: {
                let (key, value) = self.parseKeyValuePair(line)
            
                if let key = key as String?, let value = value as String? {
                    if let eventValue = event[key] {
                        event[key] = "\(eventValue)\n\(value)"
                    } else {
                        event[key] = value
                    }
                } else if let key = key as String?, value == nil {
                    event[key] = ""
                }
            })
        }
        
        let data = HMSSEData(id: event["id"],
                             event: event["event"],
                             data: event["data"])
        
        return HMSSEvent.dataReceived(data)
    }
    
    fileprivate func parseKeyValuePair(_ line: String) -> (NSString?, NSString?) {
        var key: NSString?, value: NSString?
        let newlineCharacters = self.newlineCharacters
        let scanner = Scanner(string: line)
        scanner.scanUpTo(":", into: &key)
        scanner.scanString(":", into: nil)
        
        for newline in newlineCharacters {
            if scanner.scanUpTo(newline, into: &value) {
                break
            }
        }
        
        return (key, value)
    }
    
    fileprivate func parseRetryTime(_ eventString: String) -> Event<Result> {
        let separators = CharacterSet(charactersIn: ":")
        
        if let milli = eventString.components(separatedBy: separators).last {
            let milliseconds = milli.trimmingCharacters(in: CharacterSet.whitespaces)
            print(milliseconds)
        }
        
        return HMSSEvent.dummy
    }
}

public extension Reactive where Base: HMEventSourceManagerType {
    public typealias Request = HMEventSourceManager.Request
    typealias Result = HMEventSourceManager.Result
    typealias Event = HMEventSourceManager.Event
    
    /// We need a separate isReachable Observable because reachability.rx
    /// does not relay that last event.
    public var isReachable: Observable<Bool> {
        return base.isReachableStream()
    }
    
    public var isConnected: Observable<Void> {
        return isReachable.filter({$0}).map(toVoid)
    }
    
    public var isDisconnected: Observable<Void> {
        return isReachable.filter({!$0}).map(toVoid)
    }
    
    public var triggerReachable: AnyObserver<Bool> {
        return base.triggerReachable()
    }
    
    /// Open a new SSE connection that listens to connectivity changes and
    /// terminates when connectivity is not available.
    ///
    /// - Parameters:
    ///   - request: A Request instance.
    ///   - sseObs: A SSE connection creator Observable.
    /// - Returns: An Observable instance.
    func reachabilityAwareSSE<SO>(_ request: Request, _ sseObs: SO)
        -> Observable<[Event<Result>]> where
        SO: ObservableConvertibleType, SO.E == HMSSEvent<Data>
    {
        let newRequest = base.requestWithDefaultParams(request)
        let delay = newRequest.retryDelay()
        let retryScheduler = ConcurrentDispatchQueueScheduler(qos: .background)
        
        return sseObs.asObservable()
            .delayRetry(delay: delay, scheduler: retryScheduler)
            .map({event -> [Event<Result>] in
                if let value = event.value {
                    return self.base.parseEventStream(value)
                } else {
                    return [event.cast(to: HMSSEData.self)]
                }
            })
            .takeUntil(self.isDisconnected)
            .subscribeOn(qos: .background)
            .observeOn(qos: .background)
    }
    
    /// Open a new SSE connection only when there is internet connectivity.
    ///
    /// - Parameters:
    ///   - request: A Request instance.
    ///   - sseObs: A SSE connection creator Observable.
    /// - Returns: An Observable instance.
    func retryOnConnectivitySSE<SO>(_ request: Request, _ sseObs: SO)
        -> Observable<[Event<Result>]> where
        SO: ObservableConvertibleType, SO.E == HMSSEvent<Data>
    {
        let connectionObs = reachabilityAwareSSE(request, sseObs)
        return self.isConnected.flatMapLatest({connectionObs})
    }
    
    /// Open a new SSE connection only when there is internet connectivity.
    ///
    /// - Parameters request: A Request instance.
    /// - Returns: An Observable instance.
    func retryOnConnectivitySSE(_ request: Request) -> Observable<[Event<Result>]> {
        let sseObs = Observable.create({self.base.openConnection(request, $0)})
        return retryOnConnectivitySSE(request, sseObs)
    }
}
