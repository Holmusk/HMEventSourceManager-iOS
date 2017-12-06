//
//  HMSSEManagerType.swift
//  HMEventSourceManager
//
//  Created by Hai Pham on 21/9/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import RxSwift
import SwiftUtilities

/// Classes that implement this protocol must be able to handle SSE events.
public protocol HMSSEManagerType: ReactiveCompatible {
    typealias Req = HMSSERequest
    typealias Result = HMSSEData
    typealias Event = HMSSEvent
    
    var newlineCharacters: [String] { get }
    
    func addDefaultParams(_ request: Req) -> Req
    
    func isReachableStream() -> Observable<Bool>
    
    func triggerReachable() -> AnyObserver<Bool>
    
    /// Get the last event ID in local storage.
    func lastEventIdForKey(_ key: String) -> String?

    /// Store the last event ID in local storage.
    func storeLastEventIdWithKey(_ key: String, _ value: String)
    
    /// Open a SSE connection.
    ///
    /// - Parameters:
    ///   - request: A Req instance.
    ///   - obs: An ObserverType instance.
    /// - Returns: A Disposable instance.
    func openConnection<O>(_ request: Req, _ obs: O) -> Disposable where
        O: ObserverType, O.E == Try<Event<Data>>
}

public extension HMSSEManagerType {
    public static var acceptKey: String { return "Accept" }
    public static var cacheControlKey: String { return "Cache-Control" }
    public static var lastEventIdKey: String { return "Last-Event-Id" }
    public static var noCache: String { return "no-cache" }
    public static var textEventStream: String { return "text/event-stream" }
    
    /// Get a unique URL identifier to access last event id in local storage.
    ///
    /// - Parameter url: A URL instance.
    /// - Returns: A String value.
    func uniqueURLIdentifier(_ url: URL) -> String {
        let host = url.host ?? ""
        let scheme = url.scheme ?? ""
        let port = url.port ?? 0
        let relativePath = url.relativePath
        return "\(scheme).\(host).\(port).\(relativePath)"
    }
    
    /// Get a unique last event id key that corresponds to a URL.
    ///
    /// - Parameter url: A URL instance.
    /// - Returns: A String value.
    func lastEventIdKey(_ url: URL) -> String {
        return "com.holmusk.HMEventSourceManager.\(uniqueURLIdentifier(url))"
    }
    
    /// Get the last event ID key for a request.
    ///
    /// - Parameter request: A Req instance.
    /// - Returns: A String value.
    func lastEventIdKey(_ request: Req) -> String {
        do {
            let url = try request.url()
            return self.lastEventIdKey(url)
        } catch let error {
            debugException(error.localizedDescription)
            return ""
        }
    }
    
    /// Get the last event ID for a request.
    ///
    /// - Parameter request: A Req instance.
    /// - Returns: A String value.
    func lastEventId(_ request: Req) -> String? {
        let lastEventIdKey = self.lastEventIdKey(request)
        return lastEventIdForKey(lastEventIdKey)
    }
    
    /// /// Store the last event ID in local storage.
    ///
    /// - Parameters:
    ///   - request: A Req instance.
    ///   - events: A Sequence of Event.
    func storeLastEventId<S>(_ request: Req, _ events: S) where
        S: Sequence, S.Iterator.Element == Event<Result>
    {
        if let id = HMSSEvents.eventData(events).flatMap({$0.id}).last {
            let lastEventIdKey = self.lastEventIdKey(request)
            storeLastEventIdWithKey(lastEventIdKey, id)
        }
    }
    
    /// Get a cloned request with some default parameters.
    ///
    /// - Parameter request: A Req instance.
    /// - Returns: A Req instance.
    func addDefaultParams(_ request: Req) -> Req {
        let cls = Self.self
        
        return request.cloneBuilder()
            .add(header: cls.textEventStream, forKey: cls.acceptKey)
            .add(header: cls.noCache, forKey: cls.cacheControlKey)
            .add(header: lastEventId(request), forKey: cls.lastEventIdKey)
            .build()
    }
    
    /// Get a URLSessionConfiguration to use with SSE URLSession.
    ///
    /// - Parameter request: A Req instance.
    /// - Returns: A URLSessionConfiguration instance.
    func urlSessionConfig(_ request: Req) -> URLSessionConfiguration {
        let config = URLSessionConfiguration.default
        
        // Note: Do not use Int.max here as it is an invalid timeout interval.
        config.timeoutIntervalForRequest = TimeInterval(INT_MAX)
        config.timeoutIntervalForResource = TimeInterval(INT_MAX)
        config.httpAdditionalHeaders = request.additionalHeaders()
        return config
    }
}

public extension HMSSEManagerType {
    
    /// Extract events from some data.
    ///
    /// - Parameter data: A Data instance.
    /// - Returns: An Array of String.
    fileprivate func extractEvents(_ data: Data) -> [String] {
        Preconditions.checkNotRunningOnMainThread(nil)
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
        Preconditions.checkNotRunningOnMainThread(nil)
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
    
    /// Parse some events into the appropriate Event.
    ///
    /// - Parameter events: A String Array.
    /// - Returns: A Event Array.
    fileprivate func parseEventStream(_ events: [String]) -> [Event<Result>] {
        Preconditions.checkNotRunningOnMainThread(nil)
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
    /// - Returns: A Event Array.
    fileprivate func parseEventStream(_ data: Data) -> [Event<Result>] {
        Preconditions.checkNotRunningOnMainThread(nil)
        return parseEventStream(extractEvents(data))
    }
    
    /// Parse an event from a String. We need to scan the delimiters to identify
    /// the id, event and data.
    ///
    /// - Parameter eventString: A String value.
    /// - Returns: A Event instance.
    fileprivate func parseEvent(_ eventString: String) -> Event<Result> {
        Preconditions.checkNotRunningOnMainThread(nil)
        
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
        
        return Event.dataReceived(data)
    }
    
    fileprivate func parseKeyValuePair(_ line: String) -> (NSString?, NSString?) {
        Preconditions.checkNotRunningOnMainThread(nil)
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
//        let separators = CharacterSet(charactersIn: ":")
//
//        if let milli = eventString.components(separatedBy: separators).last {
//            let milliseconds = milli.trimmingCharacters(in: CharacterSet.whitespaces)
//        }
        
        return Event.dummy
    }
}

public extension HMSSEManagerType {
    fileprivate func isConnectedStream() -> Observable<Void> {
        return isReachableStream().filter({$0}).map(toVoid)
    }
    
    fileprivate func isDisconnectedStream() -> Observable<Void> {
        return isReachableStream().filter({!$0}).map(toVoid)
    }
}

public extension HMSSEManagerType {
    
    /// Create a SSE stream Observable.
    ///
    /// - Parameters:
    ///   - request: A Req instance.
    ///   - qos: The QoSClass instance to perform work on.
    /// - Returns: An Observable instance.
    func sseObservable(_ request: Req, _ qos: DispatchQoS.QoSClass)
        -> Observable<Try<Event<Data>>>
    {
        return Observable
            .create({self.openConnection(self.addDefaultParams(request), $0)})
            .subscribeOnConcurrent(qos: qos)
            .observeOnConcurrent(qos: qos)
    }
}

// MARK: - Infinite retry SSE.
public extension HMSSEManagerType {
    
    /// Open a new SSE connection that retries infinitely.
    ///
    /// - Parameters:
    ///   - request: A Req instance.
    ///   - sseObs: A SSE connection creator Observable.
    /// - Returns: An Observable instance.
    public func inifiniteRetrySSE<SO>(_ request: Req, _ sseObs: SO)
        -> Observable<[Event<Result>]> where
        SO: ObservableConvertibleType, SO.E == Try<Event<Data>>
    {
        let delay = request.retryDelay()
        let retryScheduler = ConcurrentDispatchQueueScheduler(qos: .background)
        
        return sseObs.asObservable()
            .map({try $0.getOrThrow()})
            .delayRetry(delay: delay, scheduler: retryScheduler)
            .map({event -> [Event<Result>] in
                if let value = event.value {
                    return self.parseEventStream(value)
                } else {
                    return [event.cast(to: HMSSEData.self)]
                }
            })
    }
}

// MARK: - Reachability aware SSE.
public extension HMSSEManagerType {
    
    /// Open a new SSE connection that listens to connectivity changes and
    /// terminates when connectivity is not available.
    ///
    /// - Parameters:
    ///   - request: A Req instance.
    ///   - sseObs: A SSE connection creator Observable.
    /// - Returns: An Observable instance.
    public func reachabilityAwareSSE<SO>(_ request: Req, _ sseObs: SO)
        -> Observable<[Event<Result>]> where
        SO: ObservableConvertibleType, SO.E == Try<Event<Data>>
    {
        return inifiniteRetrySSE(request, sseObs).takeUntil(isDisconnectedStream())
    }
}

// MARK: - Retry on connectivity SSE.
public extension HMSSEManagerType {
    
    /// Open a new SSE connection only when there is internet connectivity.
    ///
    /// - Parameters:
    ///   - request: A Req instance.
    ///   - sseFn: A SSE connection creator Function.
    /// - Returns: An Observable instance.
    public func retryOnConnectivitySSE<SO>(_ request: Req,
                                           _ sseFn: @escaping (Req) -> SO)
        -> Observable<[Event<Result>]> where
        SO: ObservableConvertibleType, SO.E == [Event<Result>]
    {
        return isConnectedStream().flatMapLatest({sseFn(request)})
    }
    
    /// Open a new SSE connection only when there is internet connectivity.
    ///
    /// - Parameter:
    ///   - request: A Req instance.
    ///   - sseObs: The SSE Observable.
    /// - Returns: An Observable instance.
    public func retryOnConnectivitySSE<SO>(_ request: Req, _ sseObs: SO)
        -> Observable<[Event<Result>]> where
        SO: ObservableConvertibleType, SO.E == Try<HMSSEvent<Data>>
    {
        return retryOnConnectivitySSE(request, {self.reachabilityAwareSSE($0, sseObs)})
    }
}

public extension HMSSEManagerType {
    
    /// Open a SSE connection and saves the last event ID every time a new batch
    /// of events arrives.
    ///
    /// - Parameters:
    ///   - request: A Req instance.
    ///   - sseObs: The SSE stream creator function.
    /// - Returns: An Observable instance.
    public func openConnection<SO>(_ request: Req, _ sseObs: SO)
        -> Observable<[Event<Result>]> where
        SO: ObservableConvertibleType, SO.E == [Event<Result>]
    {
        return sseObs.asObservable()
            
            // A bit of side effect here to store last event ID. We don't need
            // the updated request object here because we are simply taking the
            // URL.
            .doOnNext({self.storeLastEventId(request, $0)})
    }
    
    /// Open a SSE connection and saves the last event ID every time a new batch
    /// of events arrives.
    ///
    /// - Parameters:
    ///   - request: A Req instance.
    ///   - sseFn: Function to create a SSE Observable.
    /// - Returns: An Observable instance.
    public func openConnection<SO>(_ request: Req, _ sseFn: (Req) -> SO)
        -> Observable<[Event<Result>]> where
        SO: ObservableConvertibleType, SO.E == [Event<Result>]
    {
        return openConnection(request, sseFn(request))
    }
    
    /// Open a SSE connection and saves the last event ID every time a new batch
    /// of events arrives.
    ///
    /// - Parameters:
    ///   - request: A Req instance.
    ///   - sseObs: The SSE Observable.
    /// - Returns: An Observable instance.
    public func openConnection<SO>(_ request: Req, _ sseObs: SO)
        -> Observable<[Event<Result>]> where
        SO: ObservableConvertibleType, SO.E == Try<HMSSEvent<Data>>
    {
        let sseFn: (Req) -> Observable<[Event<Result>]>
        
        switch request.sseStreamStrategy() {
        case .retryOnError: sseFn = {self.inifiniteRetrySSE($0, sseObs)}
        case .retryOnConnectivity: sseFn = {self.retryOnConnectivitySSE($0, sseObs)}
        }
        
        return openConnection(request, sseFn)
    }
    
    /// Open a SSE connection and saves the last event ID every time a new batch
    /// of events arrives.
    ///
    /// - Parameters:
    ///   - request: A Req instance.
    ///   - qos: The QoSClass to perform work on.
    /// - Returns: An Observable instance.
    public func openConnection(_ request: Req, _ qos: DispatchQoS.QoSClass)
        -> Observable<[Event<Result>]>
    {
        return openConnection(request, sseObservable(request, qos))
    }
}
