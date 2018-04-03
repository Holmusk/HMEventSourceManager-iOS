//
//  HMSSERequestType.swift
//  HMEventSourceManager
//
//  Created by Hai Pham on 6/12/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

/// SSE request type.
public protocol HMSSERequestType {
  func retryDelay() -> TimeInterval

  func urlString() throws -> String

  func additionalHeaders() -> [String : Any]

  func sseStreamStrategy() -> HMSSEStrategy
}
