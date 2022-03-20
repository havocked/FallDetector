//
//  FallDetectorManager.swift
//  FallDetector
//
//  Created by Nataniel Martin on 3/19/22.
//

import CoreML

protocol FallDetectorDelegate: AnyObject {
    func fallDetectorUpdate(newFallEvent: FallEvent)
    func fallDetectorUpdate(newPrediction: EventPrediction)
}

protocol FallDetectorProtocol: AnyObject {
    var delegate: FallDetectorDelegate? { get set }
    
    func resetState()
    func handle(data: AccelerometerRawData)
}

final class FallDetectorManager: FallDetectorProtocol {
    struct Configuration {
        let predictionWindowSize: Int
        let shape: Int
    }
    
    weak var delegate: FallDetectorDelegate? = nil
    private let operationQueue: DispatchQueue
    private let configuration: Configuration
    private let eventPredictor: EventPredictorProtocol
    
    private var currentIndexInPredictionWindow: Int
    private var currentState: MLMultiArray
    private var lastEventPredicted: EventPrediction? = nil
    private var savedBeginFallPrediction: EventPrediction? = nil // for later computation of 'drop time'
    
    private var accelerometerX: MLMultiArray
    private var accelerometerY: MLMultiArray
    private var accelerometerZ: MLMultiArray
    
    init(operationQueue: DispatchQueue = DispatchQueue.global(qos: .default), configuration: Configuration, eventPredictor: EventPredictorProtocol = EventPredictor()) {
        self.operationQueue = operationQueue
        self.configuration = configuration
        self.eventPredictor = eventPredictor
        self.currentIndexInPredictionWindow = 0
       
        self.accelerometerX = try! MLMultiArray(shape: [configuration.predictionWindowSize as NSNumber], dataType: .double)
        self.accelerometerY = try! MLMultiArray(shape: [configuration.predictionWindowSize as NSNumber], dataType: .double)
        self.accelerometerZ = try! MLMultiArray(shape: [configuration.predictionWindowSize as NSNumber], dataType: .double)
        self.currentState = try! MLMultiArray(
            shape: [configuration.shape as NSNumber],
            dataType: MLMultiArrayDataType.double
        )
    }
    
    func resetState() {
        currentIndexInPredictionWindow = 0
        
        accelerometerX = try! MLMultiArray(shape: [configuration.predictionWindowSize as NSNumber], dataType: .double)
        accelerometerY = try! MLMultiArray(shape: [configuration.predictionWindowSize as NSNumber], dataType: .double)
        accelerometerZ = try! MLMultiArray(shape: [configuration.predictionWindowSize as NSNumber], dataType: .double)
        currentState = try! MLMultiArray(
            shape: [configuration.shape as NSNumber],
            dataType: MLMultiArrayDataType.double
        )
        lastEventPredicted = nil
        savedBeginFallPrediction = nil
    }
    
    func handle(data: AccelerometerRawData) {
        accelerometerX[currentIndexInPredictionWindow] = data.x as NSNumber
        accelerometerY[currentIndexInPredictionWindow] = data.y as NSNumber
        accelerometerZ[currentIndexInPredictionWindow] = data.z as NSNumber
        
        // Update prediction array index
        currentIndexInPredictionWindow += 1
        
        // If Prediction window filled, process new prediction
        if currentIndexInPredictionWindow >= configuration.predictionWindowSize {
            processNewPrediction()
            // Reset index to start new prediction window
            currentIndexInPredictionWindow = 0
        }
    }
    
    private func processNewPrediction() {
        do {
            let newPrediction = try eventPredictor.generateNewPrediction(x: accelerometerX, y: accelerometerY, z: accelerometerZ, currentState: currentState)
            switch (lastEventPredicted?.state, newPrediction.state) {
            case (.noFall, .fall):
                savedBeginFallPrediction = newPrediction
            case (.fall, .noFall):
                if let beginFallPrediction = savedBeginFallPrediction {
                    let dropTimeElapsed = newPrediction.timestamp.timeIntervalSince1970 - beginFallPrediction.timestamp.timeIntervalSince1970
                    let fallEvent = FallEvent(date: newPrediction.timestamp, dropTimeElapsed: dropTimeElapsed)
                    delegate?.fallDetectorUpdate(newFallEvent: fallEvent)
                    savedBeginFallPrediction = nil
                }
            default:
                print("Nothing to do")
            }
            
            lastEventPredicted = newPrediction
            currentState = newPrediction.stateOut
            delegate?.fallDetectorUpdate(newPrediction: newPrediction)
        } catch let error {
            print("Prediction Error - Reason: \(error)")
        }
    }
}
