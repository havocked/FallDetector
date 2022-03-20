//
//  CustomDateFormatter.swift
//  FallDetector
//
//  Created by Nataniel Martin on 3/20/22.
//

import Foundation


protocol DateFormatterProtocol {
    func string(from: Date) -> String
}

extension CustomDateFormatter: DateFormatterProtocol {}

class CustomDateFormatter: DateFormatter {
    override init() {
        super.init()
        self.dateStyle = .medium
        self.timeStyle = .short
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
