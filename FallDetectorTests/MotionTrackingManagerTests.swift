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
        let deviceMotionManagerMock = DeviceMotionManagerMock(active: false, available: true, timeInterval: 1.0)
        let sut = MotionTrackingManager(motionManager: deviceMotionManagerMock, operationQueue: .main)
        XCTAssertEqual(sut.isTracking, false)
    }
    
    func testWhenDeviceMotionActiveThenTrackingIsTrue() throws {
        let deviceMotionManagerMock = DeviceMotionManagerMock(active: true, available: true, timeInterval: 1.0)
        let sut = MotionTrackingManager(motionManager: deviceMotionManagerMock, operationQueue: .main)
        XCTAssertEqual(sut.isTracking, true)
    }
    
    func testWhenStartCalledAndDeviceMotionIsUnavailableThenThrowsError() throws {
        let deviceMotionManagerMock = DeviceMotionManagerMock(active: false, available: false, timeInterval: 1.0)
        let sut = MotionTrackingManager(motionManager: deviceMotionManagerMock, operationQueue: .main)
        XCTAssertThrowsError(try sut.start()) { error in
            XCTAssertEqual(error as! MotionTrackingError, MotionTrackingError.unavailable)
        }
    }
}

//TODO: Generate test classes with Sourcery
final class MotionTrackingDelegateMock: MotionTrackingDelegate {
    func didMotionTrackingStart() {
        
    }
    
    func didMotionTrackingStop() {
        
    }
    
    func didMotionTrackingUpdates(rawData: AccelerometerRawData) {
        
    }
    
    func motionTrackingErrored(with error: MotionTrackingError) {
        
    }
}

//TODO: Generate test classes with Sourcery
final class DeviceMotionManagerMock: DeviceMotionManagerProtocol {
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
