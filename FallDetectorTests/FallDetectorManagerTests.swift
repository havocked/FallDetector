//
//  FallDetectorManagerTests.swift
//  FallDetectorTests
//
//  Created by Nataniel Martin on 3/19/22.
//

import XCTest
import CoreML
@testable import FallDetector

class FallDetectorManagerTests: XCTestCase {
    
    func testWhenHandlingSamplesThenNewPredictionCalledRightAmount() {
        let queue =  DispatchQueue.main
        let predictionSize = 50
        let shape = 400
        let numberOfSamples = 260
        let configuration = FallDetectorManager.Configuration(predictionWindowSize: predictionSize, shape: shape)
        let sut = FallDetectorManager(operationQueue: queue, configuration: configuration)
        let delegateMock = FallDetectorDelegateMock()
        sut.delegate = delegateMock
        for _ in 0...numberOfSamples {
            sut.handle(data: .init(x: 1, y: 1, z: 1, timestamp: 1234))
        }
        
        XCTAssertEqual(delegateMock.fallDetectorUpdateNewPredictionMethodCalled.count, numberOfSamples / predictionSize)
    }
    
    /// number of samples required to process a new prediction is 50
    /// if we handle 49 samples, reset and handle a new sample, the SUT should not try a new prediction.
    /// Because his new index is reset to 0
    func testWhenResetBeforeProcessingPredictionThenUpdateNotCalled() {
        let queue =  DispatchQueue.main
        let predictionSize = 50
        let shape = 400
        let configuration = FallDetectorManager.Configuration(predictionWindowSize: predictionSize, shape: shape)
        let sut = FallDetectorManager(operationQueue: queue, configuration: configuration)
        let delegateMock = FallDetectorDelegateMock()
        sut.delegate = delegateMock
        for _ in 0...48 {
            sut.handle(data: .init(x: 1, y: 1, z: 1, timestamp: 1234))
        }
        
        sut.resetState()
        sut.handle(data: .init(x: 1, y: 1, z: 1, timestamp: 1234))
        
        XCTAssertEqual(delegateMock.fallDetectorUpdateNewPredictionMethodCalled.count, 0)
    }
    
    func testWhenFallDetectedThenGeneratesNewFallEvent() {
        // Setup SUT
        let eventPredictorMock = EventPredictorMock(nextPrediction: .init(state: .noFall, stateOut: .init(), precision: 100, timestamp: .init(timeIntervalSince1970: 1234)))
        let sut = FallDetectorManager(
            operationQueue: .main,
            configuration: .init(predictionWindowSize: 1, shape: 400),
            eventPredictor: eventPredictorMock)
        let delegateMock = FallDetectorDelegateMock()
        sut.delegate = delegateMock
        
        // Simulate data input
        sut.handle(data: .init(x: 1, y: 1, z: 1, timestamp: 1))
        sut.handle(data: .init(x: 1, y: 1, z: 1, timestamp: 1000))
        
        // Force EventPredictor to predict fall or no fall for testing purposes
        eventPredictorMock.nextPrediction = .init(state: .fall, stateOut: .init(), precision: 100, timestamp: .init(timeIntervalSince1970: 1500))
        sut.handle(data: .init(x: 1, y: 1, z: 1, timestamp: 1500))
        sut.handle(data: .init(x: 1, y: 1, z: 1, timestamp: 2000))
        eventPredictorMock.nextPrediction = .init(state: .noFall, stateOut: .init(), precision: 100, timestamp: .init(timeIntervalSince1970: 2500))
        sut.handle(data: .init(x: 1, y: 1, z: 1, timestamp: 2500))
        sut.handle(data: .init(x: 1, y: 1, z: 1, timestamp: 3000))
        sut.handle(data: .init(x: 1, y: 1, z: 1, timestamp: 3500))
        
        // Verify delegate is called with right data
        XCTAssertEqual(delegateMock.fallDetectorUpdateNewFallMethodCalled.count, 1)
        XCTAssertEqual(delegateMock.fallDetectorUpdateNewFallMethodCalled[0].dropTimeElapsed, 1000)
    }
}

// TODO: Replace with Sourcery generated code
final class FallDetectorDelegateMock: FallDetectorDelegate {
    var fallDetectorUpdateNewPredictionMethodCalled: [EventPrediction] = []
    var fallDetectorUpdateNewFallMethodCalled: [FallEvent] = []
    
    func fallDetectorUpdate(newPrediction: EventPrediction) {
        fallDetectorUpdateNewPredictionMethodCalled.append(newPrediction)
    }
    
    func fallDetectorUpdate(newFallEvent: FallEvent) {
        fallDetectorUpdateNewFallMethodCalled.append(newFallEvent)
    }
}

final class EventPredictorMock: EventPredictorProtocol {
    
    var nextPrediction: EventPrediction
    
    init(nextPrediction: EventPrediction) {
        self.nextPrediction = nextPrediction
    }
    
    func generateNewPrediction(x: MLMultiArray, y: MLMultiArray, z: MLMultiArray, currentState: MLMultiArray) throws -> EventPrediction {
        return nextPrediction
    }
}
