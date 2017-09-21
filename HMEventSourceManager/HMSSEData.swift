//
//  HMSSEData.swift
//  HMEventSourceManager
//
//  Created by Hai Pham on 22/9/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

/// Use this to represent SSE data.
public struct HMSSEData {
    public let id: String?
    public let event: String?
    public let data: String?
    
    public init(id: String?, event: String?, data: String?) {
        self.id = id
        self.event = event
        self.data = data
    }
}

extension HMSSEData: CustomStringConvertible {
    public var description: String {
        return ""
            + "id: \(String(describing: id)), "
            + "event: \(String(describing: event)), "
            + "data: \(String(describing: data))"
    }
}

extension HMSSEData: Hashable {
    public var hashValue: Int {
        let idHash = id?.hashValue ?? 0
        let eventHash = event?.hashValue ?? 0
        let dataHash = data?.hashValue ?? 0
        return idHash + eventHash + dataHash
    }
}

extension HMSSEData: Equatable {
    public static func ==(lhs: HMSSEData, rhs: HMSSEData) -> Bool {
        return lhs.id == rhs.id &&
            lhs.event == rhs.event &&
            lhs.data == rhs.data
    }
}
