//
//  MotionTrackingManagerTests.swift
//  FallDetectorTests
//
//  Created by Nataniel Martin on 3/20/22.
//

import XCTest
import CoreMotion
@testable import FallDetector

class MotionTrackingManagerTests: XCTestCase {
    func testWhenDeviceMotionNotActiveThenTrackingIsFalse() throws {
        let motionManager = TestDeviceMotionManager(active: false, available: true, timeInterval: 1.0)
        let sut = MotionTrackingManager(motionManager: motionManager, operationQueue: .main)
        XCTAssertEqual(sut.isTracking, false)
    }
    
    func testWhenDeviceMotionActiveThenTrackingIsTrue() throws {
        let motionManager = TestDeviceMotionManager(active: true, available: true, timeInterval: 1.0)
        let sut = MotionTrackingManager(motionManager: motionManager, operationQueue: .main)
        XCTAssertEqual(sut.isTracking, true)
    }
    
    func testWhenDeviceMotionIsUnavailableAndStartCalledThenThrowsError() throws {
        let motionManager = TestDeviceMotionManager(active: false, available: false, timeInterval: 1.0)
        let sut = MotionTrackingManager(motionManager: motionManager, operationQueue: .main)
        XCTAssertThrowsError(try sut.start()) { error in
            XCTAssertEqual(error as! MotionTrackingError, MotionTrackingError.unavailable)
        }
    }
    
    func testSmth() throws {
        let motionManager = TestDeviceMotionManager(active: false, available: true, timeInterval: 1.0)
        let sut = MotionTrackingManager(motionManager: motionManager, operationQueue: .main)
        let delegate = TestMotionTrackingDelegate()
        sut.delegate = delegate
        try! sut.start()
        
        motionManager.triggerHandler(with: nil, error: nil)
    }
}

final class TestMotionTrackingDelegate: MotionTrackingDelegate {
    func didMotionTrackingStart() {
        
    }
    
    func didMotionTrackingStop() {
        
    }
    
    func didMotionTrackingUpdates(rawData: AccelerometerRawData) {
        
    }
    
    func motionTrackingErrored(with error: MotionTrackingError) {
        
    }
}

final class TestDeviceMotionManager: DeviceMotionManagerProtocol {
    var isAccelerometerActive: Bool {
        return active
    }
    
    var isAccelerometerAvailable: Bool {
        return available
    }
    
    var accelerometerUpdateInterval: TimeInterval = 0.0
    
    private let active: Bool
    private let available: Bool
    private let timeInterval: TimeInterval
    private var handler: CMAccelerometerHandler? = nil
    
    init(active: Bool, available: Bool, timeInterval: TimeInterval) {
        self.active = active
        self.available = available
        self.timeInterval = timeInterval
    }
    
    func startAccelerometerUpdates(to queue: OperationQueue, withHandler handler: @escaping CMAccelerometerHandler) {
        self.handler = handler
    }
    
    func stopAccelerometerUpdates() {
        
    }
    
    func triggerHandler(with data: CMAccelerometerData?, error: Error?) {
        handler?(data, error)
    }
}
