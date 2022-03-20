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

protocol EventPredictorProtocol {
    func generateNewPrediction(x: MLMultiArray, y: MLMultiArray, z: MLMultiArray, currentState: MLMultiArray) throws -> EventPrediction
}

struct EventPredictor: EventPredictorProtocol {
    private let classifier: FallActivityClassifier
    
    init() {
        self.classifier = try! FallActivityClassifier(configuration: .init())
    }
    
    func generateNewPrediction(x: MLMultiArray, y: MLMultiArray, z: MLMultiArray, currentState: MLMultiArray) throws -> EventPrediction {
        let modelPrediction = try classifier.prediction(
            x: x,
            y: y,
            z: z,
            stateIn: currentState
        )
        let newPrediction = EventPrediction(
            state: EventPrediction.State(rawValue: modelPrediction.label)!,
            stateOut: modelPrediction.stateOut,
            precision: modelPrediction.labelProbability[modelPrediction.label]!,
            timestamp: .now
        )
        return newPrediction
    }
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
        
        currentIndexInPredictionWindow = 0
        self.accelerometerY = try! MLMultiArray(shape: [configuration.predictionWindowSize as NSNumber], dataType: .double)
        accelerometerX = try! MLMultiArray(shape: [configuration.predictionWindowSize as NSNumber], dataType: .double)
        accelerometerY = try! MLMultiArray(shape: [configuration.predictionWindowSize as NSNumber], dataType: .double)
        accelerometerZ = try! MLMultiArray(shape: [configuration.predictionWindowSize as NSNumber], dataType: .double)
        currentState = try! MLMultiArray(
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
        self.accelerometerX[self.currentIndexInPredictionWindow] = data.x as NSNumber
        self.accelerometerY[self.currentIndexInPredictionWindow] = data.y as NSNumber
        self.accelerometerZ[self.currentIndexInPredictionWindow] = data.z as NSNumber
        
        // Update prediction array index
        self.currentIndexInPredictionWindow += 1
        
        // If data array is full - execute a prediction
        if self.currentIndexInPredictionWindow >= configuration.predictionWindowSize {
            self.processNewPrediction()
            // Start a new prediction window from scratch
            self.currentIndexInPredictionWindow = 0
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
                    self.delegate?.fallDetectorUpdate(newFallEvent: fallEvent)
                    savedBeginFallPrediction = nil
                }
            default:
                print("Nothing to do")
            }
            
            lastEventPredicted = newPrediction
            currentState = newPrediction.stateOut
            self.delegate?.fallDetectorUpdate(newPrediction: newPrediction)
        } catch let err {
            print("Prediction Error - Reason: \(err)")
        }
    }
}
