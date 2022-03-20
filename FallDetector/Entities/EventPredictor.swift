//
//  EventPredictor.swift
//  FallDetector
//
//  Created by Nataniel Martin on 3/20/22.
//

import CoreML

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
