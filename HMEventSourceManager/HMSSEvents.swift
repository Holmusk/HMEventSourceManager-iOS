//
//  HMSSEvents.swift
//  HMEventSourceManager
//
//  Created by Hai Pham on 22/9/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

import SwiftUtilities

/// Utility class for HMSSEvent.
public final class HMSSEvents {
    
    /// Get all available event data from a SSE Sequence.
    ///
    /// - Parameter events: A Sequence of HMSSEvent.
    /// - Returns: An Array of T.
    public static func eventData<S,T>(_ events: S) -> [T] where
        S: Sequence, S.Iterator.Element == HMSSEvent<T>
    {
        return events.flatMap({$0.value})
    }
    
    /// Check if any event in a Sequence contains some data.
    ///
    /// - Parameter events: A Sequence of HMSSEvent.
    /// - Returns: A Bool value.
    public static func hasData<S,T>(_ events: S) -> Bool where
        S: Sequence, S.Iterator.Element == HMSSEvent<T>
    {
        return events.any({$0.value != nil})
    }
    
    private init() {}
}
