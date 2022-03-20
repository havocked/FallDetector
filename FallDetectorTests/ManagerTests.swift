//
//  ManagerTests.swift
//  FallDetectorTests
//
//  Created by Nataniel Martin on 3/17/22.
//

import XCTest
@testable import FallDetector

class ManagerTests: XCTestCase {
    func testInitWithEmptyData() throws {
        let fileManagerMock = FileIoManagerMock(fallEvents: [])
        let manager = Manager(fileIoManager: fileManagerMock)
        XCTAssertEqual(manager.numberOfSections(), 1)
        XCTAssertEqual(manager.numberOfRows(), 0)
        XCTAssertEqual(manager.title(for: 0), "Total - 0 events")
    }
    
    func testInitWithSomeData() throws {
        let fallEvents: [FallEvent] = [.init(date: Date(timeIntervalSince1970: 123456789), dropTimeElapsed: 12345)]
        let fileManagerMock = FileIoManagerMock(fallEvents: fallEvents)
        let manager = Manager(fileIoManager: fileManagerMock)
        let testingCellViewModel = EventCellViewModel(title: "Nov 29, 1973 at 10:33 PM - 12.345s")
        XCTAssertEqual(manager.numberOfSections(), 1)
        XCTAssertEqual(manager.numberOfRows(), 1)
        XCTAssertEqual(manager.title(for: 0), "Total - 1 events")
        XCTAssertEqual(manager.cellViewModel(for: .init(row: 0, section: 0)), testingCellViewModel)
    }
    
    func testInitReturnsCorrectNumberOfSections() throws {
        let fallEvents: [FallEvent] = [
            .init(date: .now, dropTimeElapsed: 1234),
            .init(date: .now, dropTimeElapsed: 1234),
            .init(date: .now, dropTimeElapsed: 1234),
            .init(date: .now, dropTimeElapsed: 1234),
            .init(date: .now, dropTimeElapsed: 1234),
            .init(date: .now, dropTimeElapsed: 1234)
        ]
        let fileManagerMock = FileIoManagerMock(fallEvents: fallEvents)
        let manager = Manager(fileIoManager: fileManagerMock)
        XCTAssertEqual(manager.numberOfSections(), 1)
    }
    
    func testWhenDataSetReturnsCorrectNumberOfRows() throws {
        let fallEvents: [FallEvent] = [
            .init(date: .now, dropTimeElapsed: 1234),
            .init(date: .now, dropTimeElapsed: 1234),
            .init(date: .now, dropTimeElapsed: 1234),
            .init(date: .now, dropTimeElapsed: 1234),
            .init(date: .now, dropTimeElapsed: 1234),
            .init(date: .now, dropTimeElapsed: 1234)
        ]
        let fileManagerMock = FileIoManagerMock(fallEvents: fallEvents)
        let manager = Manager(fileIoManager: fileManagerMock)
        XCTAssertEqual(manager.numberOfRows(), 6)
    }
    
    func testWhenDeletePressedThenShowActionSheetCalled() throws  {
        let expectation = expectation(description: "Show ActionSheet")
        expectation.expectedFulfillmentCount = 1
        
        let manager = Manager()
        let managerDelegateMock = ManagerDelegateMock()
        managerDelegateMock.showActionSheetCalled = { deleteTitle, cancelTitle, message, _ in
            XCTAssertEqual(deleteTitle, "Delete")
            XCTAssertEqual(cancelTitle, "Cancel")
            XCTAssertEqual(message, "Sure you want to delete?")
            expectation.fulfill()
        }
        manager.delegate = managerDelegateMock
        manager.didPressDelete()
        waitForExpectations(timeout: 0.3)
    }
    
    func testWhenDeleteConfirmedReturnsCorrectNumberOfRows() throws {
        let fallEvents: [FallEvent] = [
            .init(date: .now, dropTimeElapsed: 1234),
            .init(date: .now, dropTimeElapsed: 1234),
            .init(date: .now, dropTimeElapsed: 1234),
            .init(date: .now, dropTimeElapsed: 1234),
            .init(date: .now, dropTimeElapsed: 1234),
            .init(date: .now, dropTimeElapsed: 1234)
        ]
        let fileManagerMock = FileIoManagerMock(fallEvents: fallEvents)
        let manager = Manager(fileIoManager: fileManagerMock)
        let managerDelegateMock = ManagerDelegateMock()
        managerDelegateMock.showActionSheetCalled = { _, _, _, confirmDeleteHandler in
            confirmDeleteHandler()
        }
        manager.delegate = managerDelegateMock
        
        manager.didPressDelete()
        
        XCTAssertEqual(manager.numberOfRows(), 0)
    }

    func testWhenConfirmDeletePressedThenUpdateStateCalled() throws {
        let expectation = expectation(description: "Update State called")
        expectation.expectedFulfillmentCount = 1
        
        let manager = Manager()
        let managerDelegateMock = ManagerDelegateMock()
        managerDelegateMock.updateStateCalled = { shouldRefreshData, shouldActionButtonNeedUpdate, activityDescription  in
            XCTAssertTrue(shouldRefreshData)
            XCTAssertFalse(shouldActionButtonNeedUpdate)
            XCTAssertNil(activityDescription)
            expectation.fulfill()
        }
        
        managerDelegateMock.showActionSheetCalled = { _, _, _, confirmDeleteHandler in
            confirmDeleteHandler()
        }
        manager.delegate = managerDelegateMock
        manager.didPressDelete()
        waitForExpectations(timeout: 0.3)
    }
    
    func testWhenFallDetectedThenShowAlertCalled() {
        let expectation = expectation(description: "Show Alert called")
        expectation.expectedFulfillmentCount = 1
        
        let fallDetectorMock = FallDetectorMock()
        let sut = Manager(fallDetector: fallDetectorMock)
        let delegateMock = ManagerDelegateMock()
        sut.delegate = delegateMock
        
        delegateMock.showAlertCalled = { title, message, actionTitle in
            XCTAssertEqual(title, "Fall detection")
            XCTAssertEqual(message, "A Fall has been detected")
            XCTAssertEqual(actionTitle, "Ok")
            expectation.fulfill()
        }
        
        fallDetectorMock.delegate?.fallDetectorUpdate(newFallEvent: .init(date: .now, dropTimeElapsed: 1234))
        waitForExpectations(timeout: 0.3)
    }
}

//TODO: Generate test classes with Sourcery
final class ManagerDelegateMock: ManagerDelegate {

    var updateStateCalled: ((Bool, Bool, String?) -> ())? = nil
    var showAlertCalled: ((String, String, String) -> ())? = nil
    var showActionSheetCalled: ((String, String, String, DeleteActionHandler) -> ())? = nil
    
    func updateState(shouldRefreshData: Bool, shouldActionButtonNeedUpdate: Bool, activityDescription: String?) {
        updateStateCalled?(shouldRefreshData, shouldActionButtonNeedUpdate, activityDescription)
    }
    
    func showAlert(title: String, message: String, actionTitle: String) {
        showAlertCalled?(title, message, actionTitle)
    }
    
    func showActionSheet(deleteTitle: String, cancelTitle: String, message: String, actionHandler: @escaping DeleteActionHandler) {
        showActionSheetCalled?(deleteTitle, cancelTitle, message, actionHandler)
    }
}

//TODO: Generate test classes with Sourcery
final class FileIoManagerMock: FileIOProtocol {
    private var fallEvents: [FallEvent]
    
    init(fallEvents: [FallEvent]) {
        self.fallEvents = fallEvents
    }
    
    func saveToDisk(fallEvents: [FallEvent]) {
        self.fallEvents = fallEvents
    }
    
    func readFromDisk() -> [FallEvent] {
        return fallEvents
    }
}

//TODO: Generate test classes with Sourcery
final class FallDetectorMock: FallDetectorProtocol {
    var delegate: FallDetectorDelegate?
    
    func resetState() {}
    
    func handle(data: AccelerometerRawData) {}
}
