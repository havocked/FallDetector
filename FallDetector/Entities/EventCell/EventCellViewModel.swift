//
//  EventCellViewModel.swift
//  FallDetector
//
//  Created by Nataniel Martin on 3/20/22.
//

import Foundation

protocol DateFormatterProtocol {
    func string(from: Date) -> String
}

extension DateFormatter: DateFormatterProtocol {}

struct EventCellViewModel: Equatable {
    let title: String
}

extension EventCellViewModel {
    init(fallEvent: FallEvent, dateFormatter: DateFormatterProtocol) {
        let date = dateFormatter.string(from: fallEvent.date)
        let seconds = "\(fallEvent.dropTimeElapsed / 1000)s"
        let formattedString = "\(date) - \(seconds)"
        self.init(title: formattedString)
    }
}
