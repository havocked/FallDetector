//
//  AccelerometerRawData.swift
//  FallDetector
//
//  Created by Nataniel Martin on 3/19/22.
//

import CoreMotion

struct AccelerometerRawData {
    let x: Double
    let y: Double
    let z: Double
    let timestamp: TimeInterval
}

extension AccelerometerRawData {
    init(data: CMAccelerometerData) {
        self.init(
            x: data.acceleration.x,
            y: data.acceleration.y,
            z: data.acceleration.z,
            timestamp: data.timestamp
        )
    }
}
