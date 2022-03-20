//
//  MainViewController.swift
//  FallDetector
//
//  Created by Nataniel Martin on 3/17/22.
//

import UIKit

class MainViewController: UIViewController {

    private let manager: ManagerProtocol
    
    private var eventTableView: UITableView = {
        let eventTableView = UITableView(frame: .zero)
        eventTableView.backgroundColor = .white
        return eventTableView
    }()
    
    private var stateLabel: UILabel = {
        let label = UILabel(frame: .zero)
        return label
    }()
    
    private var actionButton: UIButton = {
        var configuration = UIButton.Configuration.gray()
        configuration.cornerStyle = .large
        configuration.baseForegroundColor = UIColor.systemPink
        configuration.buttonSize = .large
        configuration.title = "Start".uppercased()
        
        let actionButton = UIButton(configuration: configuration, primaryAction: nil)
        return actionButton
    }()
    
    init(manager: Manager) {
        self.manager = manager
        super.init(nibName: nil, bundle: nil)
        manager.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(eventTableView)
        view.addSubview(stateLabel)
        view.addSubview(actionButton)
        setupConstraints()
        
        title = "Fall detector"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .trash,
            target: self,
            action: #selector(rightBarButtonTapped)
        )
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(leftBarButtonTapped)
        )
        eventTableView.register(EventCell.self)
        eventTableView.dataSource = self
        eventTableView.delegate = self
        
        setupActionButton()
    }
    
    private func setupConstraints() {
        eventTableView.translatesAutoresizingMaskIntoConstraints = false
        stateLabel.translatesAutoresizingMaskIntoConstraints = false
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        
        let constraints = [
            eventTableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            eventTableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            eventTableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            stateLabel.topAnchor.constraint(equalTo: eventTableView.bottomAnchor, constant: 12),
            stateLabel.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            actionButton.topAnchor.constraint(equalTo: stateLabel.bottomAnchor, constant: 12),
            actionButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            actionButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    @objc func leftBarButtonTapped() {
        manager.didPressAdd()
    }
    
    @objc func rightBarButtonTapped() {
        manager.didPressDelete()
    }
    
    private func setupActionButton() {
        let action = UIAction { [weak self] action in
            self?.manager.didPressAction()
        }
        actionButton.configurationUpdateHandler = { [weak self] button in
            var newConfiguration = button.configuration
            newConfiguration?.title = self?.manager.actionTitle()
            button.configuration = newConfiguration
        }
        actionButton.addAction(action, for: .touchUpInside)
    }
}

extension MainViewController: ManagerDelegate {
    func updateState(shouldRefreshData: Bool, shouldActionButtonNeedUpdate: Bool, activityDescription: String?) {
        if shouldRefreshData {
            eventTableView.reloadData()
        }
        
        if shouldActionButtonNeedUpdate {
            actionButton.setNeedsUpdateConfiguration()
        }
        
        if let activityDescription = activityDescription {
            stateLabel.text = activityDescription
        }
    }
    
    func showAlert(title: String, message: String, actionTitle: String) {
        let okAction = UIAlertAction(title: actionTitle, style: .default)
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(okAction)
        present(alert, animated: true)
    }
    
    func showActionSheet(deleteTitle: String, cancelTitle: String, message: String, actionHandler: @escaping () -> ()) {
        let confirmDeleteAction = UIAlertAction(title: deleteTitle, style: .destructive) { _ in
            actionHandler()
        }
        let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel)
        let actionSheet = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        actionSheet.addAction(confirmDeleteAction)
        actionSheet.addAction(cancelAction)
        present(actionSheet, animated: true)
    }
}

extension MainViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return manager.numberOfSections()
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return manager.title(for: section)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return manager.numberOfRows()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: EventCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
        cell.setup(viewModel: manager.cellViewModel(for: indexPath))
        return cell
    }
}
