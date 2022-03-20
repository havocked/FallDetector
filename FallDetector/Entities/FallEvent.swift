//
//  FallEvent.swift
//  FallDetector
//
//  Created by Nataniel Martin on 3/17/22.
//

import Foundation

struct FallEvent: Decodable, Encodable {
    let date: Date
    let dropTimeElapsed: Double // Expressed in milliseconds
}
