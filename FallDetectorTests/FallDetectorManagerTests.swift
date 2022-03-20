//
//  FallDetectorManagerTests.swift
//  FallDetectorTests
//
//  Created by Nataniel Martin on 3/19/22.
//

import XCTest
@testable import FallDetector

class FallDetectorManagerTests: XCTestCase {
    func testExample() throws {
        let fallDetectorManager = FallDetectorManager()
        let fallDelegate = TestDelegate()
        fallDetectorManager.delegate = fallDelegate
        
        for _ in 0...100 {
            fallDetectorManager.handle(data: .init(x: 1, y: 1, z: 1, timestamp: 1234))
        }
    }
}

class TestDelegate: FallDetectorDelegate {
    var fallDetectorUpdateMethodCalled: [FallEvent] = []
    func fallDetectorUpdate(newFallEvent: FallEvent) {
        fallDetectorUpdateMethodCalled.append(newFallEvent)
    }
}
