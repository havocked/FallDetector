//
//  MotionTrackingManager.swift
//  FallDetector
//
//  Created by Nataniel Martin on 3/17/22.
//

import CoreMotion

enum MotionTrackingError: Error, Equatable {
    case unavailable
    case motionError(message: String)
}

protocol MotionTrackingDelegate: AnyObject {
    func didMotionTrackingStart()
    func didMotionTrackingStop()
    func didMotionTrackingUpdates(rawData: AccelerometerRawData)
    func motionTrackingErrored(with error: MotionTrackingError)
}

protocol MotionTrackingProtocol: AnyObject {
    var isTracking: Bool { get }
    var delegate: MotionTrackingDelegate? { get set}
    
    func start() throws
    func stop()
}

protocol DeviceMotionManagerProtocol: AnyObject {
    var isAccelerometerActive: Bool { get }
    var isAccelerometerAvailable: Bool { get }
    var accelerometerUpdateInterval: TimeInterval { get set }
    
    func startAccelerometerUpdates(to queue: OperationQueue, withHandler handler: @escaping CMAccelerometerHandler)
    func stopAccelerometerUpdates()
}

extension CMMotionManager: DeviceMotionManagerProtocol {}

final class MotionTrackingManager: MotionTrackingProtocol {
    private let motionManager: DeviceMotionManagerProtocol
    private let operationQueue: OperationQueue
    
    var isTracking: Bool {
        return motionManager.isAccelerometerActive
    }
    
    weak var delegate: MotionTrackingDelegate? = nil

    init(motionManager: DeviceMotionManagerProtocol = CMMotionManager(), operationQueue: OperationQueue = .main) {
        self.motionManager = motionManager
        self.operationQueue = operationQueue
    }
    
    func start() throws {
        guard motionManager.isAccelerometerAvailable else {
            throw MotionTrackingError.unavailable
        }
       
        motionManager.accelerometerUpdateInterval = 1.0 / 100.0
        motionManager.startAccelerometerUpdates(
            to: operationQueue,
            withHandler: handleAccelerometerUpdates
        )
        delegate?.didMotionTrackingStart()
    }
    
    func stop() {
        motionManager.stopAccelerometerUpdates()
        delegate?.didMotionTrackingStop()
    }
    
    private func handleError(error: Error?) {
        if let error = error {
            delegate?.motionTrackingErrored(with: .motionError(message: "\(error)"))
        } else {
            delegate?.motionTrackingErrored(with: .motionError(message: "Unknown Error"))
        }
    }
    
    private func handleAccelerometerUpdates(data: CMAccelerometerData?, error: Error?) {
        guard let data = data else {
            return handleError(error: error)
        }
        let rawData = AccelerometerRawData(data: data)
        delegate?.didMotionTrackingUpdates(rawData: rawData)
    }
}
