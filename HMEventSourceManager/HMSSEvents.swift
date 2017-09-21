//
//  HMSSEvents.swift
//  HMEventSourceManager
//
//  Created by Hai Pham on 22/9/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

/// Utility class for HMSSEvent.
public final class HMSSEvents {
    
    /// Get all available values from a SSE Sequence.
    ///
    /// - Parameter events: A Sequence of HMSSEvent.
    /// - Returns: An Array of T.
    public static func values<S,T>(_ events: S) -> [T] where
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
