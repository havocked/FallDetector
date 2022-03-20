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
        let manager = Manager(data: [])
        XCTAssertEqual(manager.numberOfSections(), 1)
        XCTAssertEqual(manager.numberOfRows(), 0)
        XCTAssertEqual(manager.title(for: 0), "Total - 0 events")
    }
    
    func testInitWithSomeData() throws {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        let manager = Manager(data: [.init(date: Date(timeIntervalSince1970: 123456789), dropTimeElapsed: 12345)], dateFormatter: dateFormatter)
        let testingCellViewModel = EventCellViewModel(title: "Nov 29, 1973 at 10:33 PM - 12.345s")
        XCTAssertEqual(manager.numberOfSections(), 1)
        XCTAssertEqual(manager.numberOfRows(), 1)
        XCTAssertEqual(manager.title(for: 0), "Total - 1 events")
        XCTAssertEqual(manager.cellViewModel(for: .init(row: 0, section: 0)), testingCellViewModel)
    }
    
    func testInitReturnsCorrectNumberOfSections() throws {
        let manager = Manager(data: [
            .init(date: .now, dropTimeElapsed: 1234),
            .init(date: .now, dropTimeElapsed: 1234),
            .init(date: .now, dropTimeElapsed: 1234),
            .init(date: .now, dropTimeElapsed: 1234),
            .init(date: .now, dropTimeElapsed: 1234),
            .init(date: .now, dropTimeElapsed: 1234)
        ])
        XCTAssertEqual(manager.numberOfSections(), 1)
    }
    
    func testWhenDataSetReturnsCorrectNumberOfRows() throws {
        let manager = Manager(data: [
            .init(date: .now, dropTimeElapsed: 1234),
            .init(date: .now, dropTimeElapsed: 1234),
            .init(date: .now, dropTimeElapsed: 1234),
            .init(date: .now, dropTimeElapsed: 1234),
            .init(date: .now, dropTimeElapsed: 1234),
            .init(date: .now, dropTimeElapsed: 1234)
        ])
        XCTAssertEqual(manager.numberOfRows(), 6)
    }
    
    func testWhenDeletePressedThenShowActionSheetCalled() throws  {
        let expectation = expectation(description: "Show ActionSheet")
        expectation.expectedFulfillmentCount = 1
        
        let manager = Manager(data: [])
        let managerDelegate = ManagerDelegateTest()
        managerDelegate.showActionSheetCalled = { deleteTitle, cancelTitle, message, _ in
            XCTAssertEqual(deleteTitle, "Delete")
            XCTAssertEqual(cancelTitle, "Cancel")
            XCTAssertEqual(message, "Sure you want to delete?")
            expectation.fulfill()
        }
        manager.delegate = managerDelegate
        manager.didPressDelete()
        waitForExpectations(timeout: 0.3)
    }
    
    func testWhenDeleteConfirmedReturnsCorrectNumberOfRows() throws {
        let manager = Manager(data: [
            .init(date: .now, dropTimeElapsed: 1234),
            .init(date: .now, dropTimeElapsed: 1234),
            .init(date: .now, dropTimeElapsed: 1234),
            .init(date: .now, dropTimeElapsed: 1234),
            .init(date: .now, dropTimeElapsed: 1234),
            .init(date: .now, dropTimeElapsed: 1234)
        ])
        let managerDelegate = ManagerDelegateTest()
        managerDelegate.showActionSheetCalled = { _, _, _, confirmDeleteHandler in
            confirmDeleteHandler()
        }
        manager.delegate = managerDelegate
        
        manager.didPressDelete()
        
        XCTAssertEqual(manager.numberOfRows(), 0)
    }

    func testWhenConfirmDeletePressedThenUpdateStateCalled() throws {
        let expectation = expectation(description: "Update State called")
        expectation.expectedFulfillmentCount = 1
        
        let manager = Manager(data: [])
        let managerDelegate = ManagerDelegateTest()
        managerDelegate.updateStateCalled = { shouldRefreshData, shouldActionButtonNeedUpdate, activityDescription  in
            XCTAssertTrue(shouldRefreshData)
            XCTAssertFalse(shouldActionButtonNeedUpdate)
            XCTAssertNil(activityDescription)
            expectation.fulfill()
        }
        
        managerDelegate.showActionSheetCalled = { _, _, _, confirmDeleteHandler in
            confirmDeleteHandler()
        }
        manager.delegate = managerDelegate
        manager.didPressDelete()
        waitForExpectations(timeout: 0.3)
    }
}

//TODO: Generate test classes with Sourcery
class ManagerDelegateTest: ManagerDelegate {

    var updateStateCalled: ((Bool, Bool, String?) -> ())? = nil
    var showAlertCalled: ((String, String) -> ())? = nil
    var showActionSheetCalled: ((String, String, String, DeleteActionHandler) -> ())? = nil
    
    func updateState(shouldRefreshData: Bool, shouldActionButtonNeedUpdate: Bool, activityDescription: String?) {
        updateStateCalled?(shouldRefreshData, shouldActionButtonNeedUpdate, activityDescription)
    }
    
    func showAlert(title: String, message: String, actionTitle: String) {
        
    }
    
    func showActionSheet(deleteTitle: String, cancelTitle: String, message: String, actionHandler: @escaping DeleteActionHandler) {
        showActionSheetCalled?(deleteTitle, cancelTitle, message, actionHandler)
    }
}
