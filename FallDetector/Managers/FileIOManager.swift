//
//  FileIOManager.swift
//  FallDetector
//
//  Created by Nataniel Martin on 3/20/22.
//

import Foundation

protocol FileIOProtocol {
    func append(fallEvent: FallEvent)
    func fetchAllEvents() -> [FallEvent]
    func deleteAllEvents()
}

struct FileIOManager: FileIOProtocol {
    
    let fileManager: FileManager
    
    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }
    
    func append(fallEvent: FallEvent) {
        
    }
    
    func fetchAllEvents() -> [FallEvent] {
        return []
    }
    
    func deleteAllEvents() {
        
    }
}
