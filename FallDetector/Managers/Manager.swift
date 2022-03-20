//
//  Manager.swift
//  FallDetector
//
//  Created by Nataniel Martin on 3/17/22.
//

import Foundation

typealias Section = Int
typealias DeleteActionHandler = () -> ()

protocol ManagerProtocol {
    func title(for: Section) -> String
    func actionTitle() -> String
    func numberOfSections() -> Int
    func numberOfRows() -> Int
    func cellViewModel(for indexPath: IndexPath) -> EventCellViewModel
    func didPressAdd() // TODO: Only for testing purposes, To remove when no longer needed
    func didPressDelete()
    func didPressAction()
}

protocol ManagerDelegate: AnyObject {
    func updateState(shouldRefreshData: Bool, shouldActionButtonNeedUpdate: Bool, activityDescription: String?)
    func showAlert(title: String, message: String, actionTitle: String)
    func showActionSheet(deleteTitle: String, cancelTitle: String, message: String, actionHandler: @escaping DeleteActionHandler)
}

final class Manager: ManagerProtocol, MotionTrackingDelegate, FallDetectorDelegate {
    private let motionTracker: MotionTrackingProtocol
    private let fallDetector: FallDetectorProtocol
    private let dateFormatter: DateFormatterProtocol
    private let fileIoController: FileIOProtocol
    
    weak var delegate: ManagerDelegate? = nil

    private var data: [FallEvent] {
        didSet {
            delegate?.updateState(shouldRefreshData: true, shouldActionButtonNeedUpdate: false, activityDescription: nil)
        }
    }
    
    //TODO: change type of dependency injection to protocol for test usage
    init(data: [FallEvent],
         motionTrackingManager: MotionTrackingProtocol =  MotionTrackingManager(),
         fallDetector: FallDetectorProtocol = FallDetectorManager(configuration: .init(predictionWindowSize: 50, shape: 400)),
         dateFormatter: DateFormatterProtocol = DateFormatter(),
         fileIoController: FileIOProtocol = FileIOManager()) {
        self.data = data
        self.motionTracker = motionTrackingManager
        self.fallDetector = fallDetector
        self.dateFormatter = dateFormatter
        self.fileIoController = fileIoController
        self.motionTracker.delegate = self
        self.fallDetector.delegate = self
    }
    
    func numberOfSections() -> Int {
        return 1
    }
    
    func title(for: Section) -> String {
        return "Total - \(data.count) events"
    }
    
    func actionTitle() -> String {
        if motionTracker.isTracking {
            return "Stop".uppercased()
        } else {
            return "Start".uppercased()
        }
    }
    
    func numberOfRows() -> Int {
        return data.count
    }
    
    func cellViewModel(for indexPath: IndexPath) -> EventCellViewModel {
        let fallEvent = data[indexPath.row]
        let model = EventCellViewModel(fallEvent: fallEvent, dateFormatter: dateFormatter)
        return model
    }
    
    // TODO: Only for testing purposes, To remove when no longer needed
    func didPressAdd() {
        let newFallEvent = FallEvent(date: Date.now, dropTimeElapsed: Double(Int.random(in: 1..<10000)))
        data.append(newFallEvent)
    }
    
    func didPressDelete() {
        let confirmDeleteActionHandler: () -> () = { [weak self] in
            self?.data.removeAll()
        }
        delegate?.showActionSheet(
            deleteTitle: "Delete",
            cancelTitle: "Cancel",
            message: "Sure you want to delete?",
            actionHandler: confirmDeleteActionHandler
        )
    }
    
    func didPressAction() {
        motionTracker.isTracking ? stopMotionTracker() : startMotionTracker()
    }
    
    private func startMotionTracker() {
        do {
            try motionTracker.start()
        } catch let error as MotionTrackingError {
            switch error {
            case .unavailable:
                delegate?.showAlert(title: "Error", message: "Failed starting Motion Tracker - Reason: Unavailable on this device", actionTitle: "Ok")
            case .motionError(message: let message):
                delegate?.showAlert(title: "Error", message: "Failed starting Motion Tracker - Reason: \(message)", actionTitle: "Ok")
            }
        } catch {
            delegate?.showAlert(title: "Error", message: "Failed starting Motion Tracker - Reason: Unknown", actionTitle: "Ok")
        }
    }
    
    private func stopMotionTracker() {
        motionTracker.stop()
        fallDetector.resetState()
    }
    
    /** MotionTracking delegates **/
    func didMotionTrackingStart() {
        delegate?.updateState(shouldRefreshData: false, shouldActionButtonNeedUpdate: true, activityDescription: nil)
    }
    
    func didMotionTrackingUpdates(rawData: AccelerometerRawData) {
        fallDetector.handle(data: rawData)
    }
    
    func didMotionTrackingStop() {
        delegate?.updateState(shouldRefreshData: false, shouldActionButtonNeedUpdate: true, activityDescription: nil)
    }
    
    func motionTrackingErrored(with error: MotionTrackingError) {
        delegate?.showAlert(title: "Error", message: "Error: \(error)", actionTitle: "Ok")
    }
    
    /** FallDetector delegates **/
    func fallDetectorUpdate(newFallEvent: FallEvent) {
        data.append(newFallEvent)
        fileIoController.append(fallEvent: newFallEvent)
        delegate?.updateState(shouldRefreshData: true, shouldActionButtonNeedUpdate: false, activityDescription: nil)
    }
    
    func fallDetectorUpdate(newPrediction: EventPrediction) {
        delegate?.updateState(shouldRefreshData: false, shouldActionButtonNeedUpdate: false, activityDescription: "\(newPrediction.state) - precision: \(round(newPrediction.precision * 100))%")
    }
}
