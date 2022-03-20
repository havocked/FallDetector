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
    private let fileIoManager: FileIOProtocol
    
    weak var delegate: ManagerDelegate? = nil

    private var fallEvents: [FallEvent] {
        didSet {
            fileIoManager.saveToDisk(fallEvents: fallEvents)
            delegate?.updateState(shouldRefreshData: true, shouldActionButtonNeedUpdate: false, activityDescription: nil)
        }
    }
    
    private var sortedFallEvent: [FallEvent] {
        return fallEvents.sorted(by: { $0.date.compare($1.date) == .orderedDescending })
    }
    
    //TODO: change type of dependency injection to protocol for test usage
    init(motionTrackingManager: MotionTrackingProtocol =  MotionTrackingManager(),
         fallDetector: FallDetectorProtocol = FallDetectorManager(configuration: .init(predictionWindowSize: 50, shape: 400)),
         dateFormatter: DateFormatterProtocol = CustomDateFormatter(),
         fileIoManager: FileIOProtocol = FileIOManager()) {
        self.fallEvents = fileIoManager.readFromDisk()
        self.motionTracker = motionTrackingManager
        self.fallDetector = fallDetector
        self.dateFormatter = dateFormatter
        self.fileIoManager = fileIoManager
        self.motionTracker.delegate = self
        self.fallDetector.delegate = self
    }
    
    func numberOfSections() -> Int {
        return 1
    }
    
    func title(for: Section) -> String {
        return "\("TOTAL_EVENTS".localized) - \(sortedFallEvent.count)"
    }
    
    func actionTitle() -> String {
        if motionTracker.isTracking {
            return "ACTION_BUTTON_STOP".localized.uppercased()
        } else {
            return "ACTION_BUTTON_START".localized.uppercased()
        }
    }
    
    func numberOfRows() -> Int {
        return sortedFallEvent.count
    }
    
    func cellViewModel(for indexPath: IndexPath) -> EventCellViewModel {
        let fallEvent = sortedFallEvent[indexPath.row]
        let model = EventCellViewModel(fallEvent: fallEvent, dateFormatter: dateFormatter)
        return model
    }
    
    // TODO: Only for testing purposes, To remove when no longer needed
    func didPressAdd() {
        let newFallEvent = FallEvent(date: Date.now, dropTimeElapsed: Double(Int.random(in: 1..<10000)))
        fallEvents.append(newFallEvent)
    }
    
    func didPressDelete() {
        let confirmDeleteActionHandler: DeleteActionHandler = { [weak self] in
            self?.fallEvents.removeAll()
        }
        delegate?.showActionSheet(
            deleteTitle: "ACTION_SHEET_DELETE_TITLE".localized,
            cancelTitle: "ACTION_SHEET_CANCEL_TITLE".localized,
            message: "ACTION_SHEET_DELETE_MESSAGE".localized,
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
                delegate?.showAlert(
                    title: "ALERT_ERROR_TITLE".localized,
                    message: "\("ALERT_ERROR_MESSAGE".localized) - Reason: Unavailable on this device",
                    actionTitle: "ALERT_OK_TITLE".localized
                )
            case .motionError(message: let message):
                delegate?.showAlert(
                    title: "ALERT_ERROR_TITLE".localized,
                    message: "\("ALERT_ERROR_MESSAGE".localized) - Reason: \(message)",
                    actionTitle: "ALERT_OK_TITLE".localized
                )
            }
        } catch {
            delegate?.showAlert(
                title: "ALERT_ERROR_TITLE".localized,
                message: "\("ALERT_ERROR_MESSAGE".localized) - Reason: Unknown",
                actionTitle: "ALERT_OK_TITLE".localized
            )
        }
    }
    
    private func stopMotionTracker() {
        motionTracker.stop()
        fallDetector.resetState()
    }
    
    /** MotionTracking delegates **/
    func didMotionTrackingStart() {
        delegate?.updateState(
            shouldRefreshData: false,
            shouldActionButtonNeedUpdate: true,
            activityDescription: nil
        )
    }
    
    func didMotionTrackingUpdates(rawData: AccelerometerRawData) {
        fallDetector.handle(data: rawData)
    }
    
    func didMotionTrackingStop() {
        delegate?.updateState(shouldRefreshData: false, shouldActionButtonNeedUpdate: true, activityDescription: nil)
    }
    
    func motionTrackingErrored(with error: MotionTrackingError) {
        delegate?.showAlert(
            title: "ALERT_ERROR_TITLE".localized,
            message: "\("ALERT_ERROR_MESSAGE".localized) - Reason: \(error)",
            actionTitle: "ALERT_OK_TITLE".localized
        )
    }
    
    /** FallDetector delegates **/
    func fallDetectorUpdate(newFallEvent: FallEvent) {
        fallEvents.append(newFallEvent)
        delegate?.showAlert(
            title: "ALERT_FALL_TITLE".localized,
            message: "ALERT_FALL_MESSAGE".localized,
            actionTitle: "ALERT_OK_TITLE"
        )
    }
    
    func fallDetectorUpdate(newPrediction: EventPrediction) {
        let formattedPrediction = "\(newPrediction.state) - precision: \(round(newPrediction.precision * 100))%"
        delegate?.updateState(shouldRefreshData: false, shouldActionButtonNeedUpdate: false, activityDescription: formattedPrediction)
    }
}
