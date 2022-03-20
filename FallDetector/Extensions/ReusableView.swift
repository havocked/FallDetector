//
//  ReusableView.swift
//  FallDetector
//
//  Created by Nataniel Martin on 3/17/22.
//

import UIKit

/** Adds a default identifier for the class using it (useful for a UITableViewCell, for registering and dequeuing **/

public protocol ReusableView: AnyObject {
    static var defaultReuseIdentifier: String { get }
}

public extension ReusableView where Self: UIView {
    static var defaultReuseIdentifier: String {
        return NSStringFromClass(self).components(separatedBy: ".").last!
    }
}
