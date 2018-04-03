//
//  TestUtil.swift
//  HMEventSourceManagerTests
//
//  Created by Hai Pham on 22/9/17.
//  Copyright © 2017 Holmusk. All rights reserved.
//

@testable import HMEventSourceManager

public extension HMSSEData {
  public static func random() -> HMSSEData {
    return HMSSEData(id: String.random(withLength: 100),
                     event: String.random(withLength: 100),
                     data: String.random(withLength: 100))
  }

  public static func randomData(_ count: Int) -> [HMSSEData] {
    return (0..<count).map({_ in self.random()})
  }
}
