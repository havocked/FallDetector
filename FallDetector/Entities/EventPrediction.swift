//
//  EventPrediction.swift
//  FallDetector
//
//  Created by Nataniel Martin on 3/20/22.
//

import CoreML

struct EventPrediction {
    enum State: String {
        case noFall = "nofall"
        case fall = "fall"
    }
    
    let state: State
    let stateOut: MLMultiArray
    let precision: Double
    let timestamp: Date
}
