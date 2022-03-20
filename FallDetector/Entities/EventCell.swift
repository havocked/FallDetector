//
//  EventCell.swift
//  FallDetector
//
//  Created by Nataniel Martin on 3/17/22.
//

import Foundation
import UIKit

final class EventCell: UITableViewCell, ReusableView {
    
    private let leftLabel: UILabel = {
        let leftTitle = UILabel(frame: .zero)
        return leftTitle
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(leftLabel)
        setupConstraints()
    }
    
    private func setupConstraints() {
        leftLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let constraints = [
            leftLabel.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            leftLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            leftLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            leftLabel.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    func setup(viewModel: EventCellViewModel) {
        leftLabel.text = viewModel.title
    }
}
