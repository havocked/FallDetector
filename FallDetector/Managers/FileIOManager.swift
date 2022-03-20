//
//  FileIOManager.swift
//  FallDetector
//
//  Created by Nataniel Martin on 3/20/22.
//

import Foundation

protocol FileIOProtocol {
    func saveToDisk(fallEvents: [FallEvent])
    func readFromDisk() -> [FallEvent]
}

// TODO: Convert Filemanager Depency to protocol for unit testing purposes
struct FileIOManager: FileIOProtocol {
    
    private enum Constants {
        static let documentName = "fallEvents.json"
    }
    private let fileManager: FileManager
    
    var pathWithFileName: URL? {
        guard let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        let pathWithFilename = documentDirectory.appendingPathComponent(Constants.documentName)
        if !fileManager.fileExists(atPath: pathWithFilename.path) {
            guard fileManager.createFile(atPath: pathWithFilename.path, contents: nil) else {
                return nil
            }
        }
        return pathWithFilename
    }
    
    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }
    
    func saveToDisk(fallEvents: [FallEvent]) {
        guard let path = pathWithFileName else {
            return
        }
        do {
            let jsonEncoder = JSONEncoder()
            let encodedFallEvents = try jsonEncoder.encode(fallEvents)
            try encodedFallEvents.write(to: path)

        } catch let error {
            print("Error saving from disk - Reason: \(error)")
        }
    }
    
    func readFromDisk() -> [FallEvent] {
        guard let path = pathWithFileName else {
            return []
        }
        
        do {
            let data = try! Data(contentsOf: path)
            let decoder = JSONDecoder()
            let fallEvents: [FallEvent] = try decoder.decode([FallEvent].self, from: data)
            return fallEvents
        } catch let error {
            print("Error reading from disk - Reason: \(error)")
            return []
        }
    }
}
