//
//  HMSSEvent.swift
//  HMEventSourceManager
//
//  Created by Hai Pham on 21/9/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import SwiftUtilities

/// Use this enum to deliver SSE.
///
/// - connectionOpened: Broadcast when a connection is opened.
/// - dataReceived: Broadcast everytime some data is sent.
/// - dummy: Dummy default event.
public enum HMSSEvent<T> {
    case connectionOpened
    case dataReceived(T)
    case dummy
    
    /// Get the associated T value.
    public var value: T? {
        switch self {
        case .dataReceived(let value):
            return value
            
        default:
            return nil
        }
    }
    
    /// Map value type from T to T2.
    ///
    /// - Parameter f: Transform function.
    /// - Returns: A HMSSEvent instance.
    public func map<T2>(_ f: (T) throws -> T2) -> HMSSEvent<T2> {
        switch self {
        case .connectionOpened:
            return .connectionOpened
            
        case .dataReceived(let t):
            return mapValue(t, f, HMSSEvent<T2>.dataReceived)
            
        case .dummy:
            return .dummy
        }
    }
    
    /// FlatMap value type from T to T2.
    ///
    /// - Parameter f: Transform function.
    /// - Returns: A HMSSEvent instance.
    public func flatMap<T2>(_ f: (T) throws -> HMSSEvent<T2>) -> HMSSEvent<T2> {
        switch self {
        case .connectionOpened:
            return .connectionOpened
            
        case .dataReceived(let t):
            return flatMapValue(t, f)
            
        case .dummy:
            return .dummy
        }
    }
    
    /// Convenience method to cast to another type.
    ///
    /// - Parameter cls: T2 class type.
    /// - Returns: A HMSSEvent instance.
    public func cast<T2>(to cls: T2.Type) -> HMSSEvent<T2> {
        return map({
            if let t2 = $0 as? T2 {
                return t2
            } else {
                throw Exception("Unable to cast \($0) to \(cls)")
            }
        })
    }
    
    /// Convenience method to map value types and wrap the result in a HMSSEvent.
    ///
    /// - Parameters:
    ///   - t: A T instance.
    ///   - f: Transform function.
    ///   - m: Transform function.
    /// - Returns: A HMSSEvent instance.
    fileprivate func mapValue<T2>(_ t: T,
                                  _ f: (T) throws -> T2,
                                  _ m: (T2) -> HMSSEvent<T2>) -> HMSSEvent<T2> {
        if let t2 = try? f(t) {
            return m(t2)
        } else {
            return .dummy
        }
    }
    
    /// Convenience method to flatMap value types.
    ///
    /// - Parameters:
    ///   - t: A T instance.
    ///   - f: Transform function.
    /// - Returns: A HMSSEvent instance.
    fileprivate func flatMapValue<T2>(_ t: T, _ f: (T) throws -> HMSSEvent<T2>)
        -> HMSSEvent<T2>
    {
        if let event2 = try? f(t) {
            return event2
        } else {
            return .dummy
        }
    }
}
