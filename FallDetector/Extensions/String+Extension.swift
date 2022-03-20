//
//  String+Extension.swift
//  FallDetector
//
//  Created by Nataniel Martin on 3/20/22.
//

import Foundation

extension String {
    var localized: String {
        get {
            return NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: "")
        }
    }
}
