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

struct EventPrediction {
    enum State: String {
        case noFall = "nofall"
        case fall = "fall"
    }
    
    let state: State
    let precision: Double
    let timestamp: Date
}

class FallDetectorManager {
    private struct Constants {
        static let predictionWindowSize = 50
        static let shape = 400
    }
    weak var delegate: FallDetectorDelegate? = nil
    private let operationQueue: DispatchQueue
    private let classifier: FallActivityClassifier
   
    private var currentIndexInPredictionWindow = 0
    private var currentState = try! MLMultiArray(
        shape: [Constants.shape as NSNumber],
        dataType: .double
    )
    private var lastEventPredicted: EventPrediction? = nil
    private var savedBeginFallPrediction: EventPrediction? = nil // Saving begin fall event to later compute drop time
    
    private let accelerometerX = try! MLMultiArray(shape: [Constants.predictionWindowSize] as [NSNumber], dataType: .double)
    private let accelerometerY = try! MLMultiArray(shape: [Constants.predictionWindowSize] as [NSNumber], dataType: .double)
    private let accelerometerZ = try! MLMultiArray(shape: [Constants.predictionWindowSize] as [NSNumber], dataType: .double)
    
    init(operationQueue: DispatchQueue = DispatchQueue.global(qos: .default)) {
        self.operationQueue = operationQueue
        self.classifier = try! FallActivityClassifier(configuration: .init())
    }
    
    func resetState() {
        currentIndexInPredictionWindow = 0
        currentState = try! MLMultiArray(
            shape: [Constants.shape as NSNumber],
            dataType: MLMultiArrayDataType.double
        )
        lastEventPredicted = nil
        savedBeginFallPrediction = nil
    }
    
    func handle(data: AccelerometerRawData) {
        operationQueue.async {
            self.accelerometerX[self.currentIndexInPredictionWindow] = data.x as NSNumber
            self.accelerometerY[self.currentIndexInPredictionWindow] = data.y as NSNumber
            self.accelerometerZ[self.currentIndexInPredictionWindow] = data.z as NSNumber
            
            // Update prediction array index
            self.currentIndexInPredictionWindow += 1
            
            // If data array is full - execute a prediction
            if self.currentIndexInPredictionWindow >= Constants.predictionWindowSize {
                // Move to main thread to update the UI
                DispatchQueue.main.async {
                    self.processNewPrediction()
                }
                // Start a new prediction window from scratch
                self.currentIndexInPredictionWindow = 0
            }
        }
    }
    
    func processNewPrediction() {
        do {
            let modelPrediction = try classifier.prediction(
                x: accelerometerX,
                y: accelerometerY,
                z: accelerometerZ,
                stateIn: currentState
            )
            let newPrediction = EventPrediction(
                state: EventPrediction.State(rawValue: modelPrediction.label)!,
                precision: modelPrediction.labelProbability[modelPrediction.label]!,
                timestamp: .now
            )
            
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
            currentState = modelPrediction.stateOut
            self.delegate?.fallDetectorUpdate(newPrediction: newPrediction)
        } catch let err {
            print("Prediction Error - Reason: \(err)")
        }
    }
}
