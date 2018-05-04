//
//  ListViewController.swift
//  llitgi
//
//  Created by Xavi Moll on 25/12/2017.
//  Copyright © 2017 xmollv. All rights reserved.
//

import UIKit
import SafariServices

enum TypeOfList {
    case myList
    case favorites
    case archive
}

class ListViewController: ViewController {

    //MARK:- IBOutlets
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var addButton: UIButton!
    @IBOutlet private var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private var tableView: UITableView!
    
    //MARK: Private properties
    private let typeOfList: TypeOfList
    private let swipeActionManager: ListSwipeActionManager
    private var dataSource: ListDataSource?
    private var cellHeights: [IndexPath : CGFloat] = [:]
    
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(self.pullToRefresh), for: .valueChanged)
        return refreshControl
    }()
    
    //MARK:- Lifecycle
    required init(factory: ViewControllerFactory, dependencies: Dependencies, type: TypeOfList) {
        self.typeOfList = type
        self.swipeActionManager = ListSwipeActionManager(dataProvider: dependencies.dataProvider)
        super.init(factory: factory, dependencies: dependencies)
    }
    
    @available(*, unavailable)
    required init(factory: ViewControllerFactory, dependencies: Dependencies) {
        fatalError("init(factory:dataProvider:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.pullToRefresh),
                                               name: .UIApplicationDidBecomeActive,
                                               object: nil)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.registerForPreviewing(with: self, sourceView: self.tableView)
        self.configureUI(for: self.typeOfList)
        self.configureTableView()
        self.pullToRefresh()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.deselectRow(with: self.transitionCoordinator, animated: animated)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    //MARK: Public methods
    func scrollToTop() {
        guard let numberOfItems = self.dataSource?.numberOfItems(), numberOfItems > 0 else { return }
        let firstIndexPath = IndexPath(row: 0, section: 0)
        self.tableView.scrollToRow(at: firstIndexPath, at: .top, animated: true)
    }
    
    //MARK: Private methods
    private func configureUI(for type: TypeOfList) {
        let title: String
        switch type {
        case .myList:
            title = L10n.Titles.myList
        case .favorites:
            title = L10n.Titles.favorites
            self.addButton.isHidden = true
        case .archive:
            title = L10n.Titles.archive
            self.addButton.isHidden = true
        }
        self.titleLabel.text = title
    }
    
    private func configureTableView() {
        self.dataSource = ListDataSource(tableView: self.tableView,
                                         userPreferences: self.userPreferences,
                                         typeOfList: self.typeOfList,
                                         notifier: self.dataProvider.notifier(for: self.typeOfList))
        self.tableView.register(ListCell.self)
        self.tableView.delegate = self
        self.tableView.dataSource = self.dataSource
        self.tableView.tableFooterView = UIView()
        self.tableView.refreshControl = self.refreshControl
        if self.typeOfList == .myList {
            self.userPreferences.badgeDelegate = self
        }
    }
    
    @objc private func pullToRefresh() {
        self.dataProvider.syncLibrary { [weak self] (result: Result<[Item]>) in
            guard let strongSelf = self else { return }
            switch result {
            case .isSuccess: break
            case .isFailure(let error):
                if let pocketError = error as? PocketAPIError {
                    switch pocketError {
                    case .invalidRequest:
                        guard let tabBar = strongSelf.tabBarController as? TabBarController  else { return }
                        strongSelf.userPreferences.displayBadge(with: 0)
                        strongSelf.dataProvider.clearLocalStorage()
                        tabBar.setupAuthFlow()
                    default: break
                    }
                }
                Logger.log(error.localizedDescription, event: .error)
            }
            strongSelf.refreshControl.endRefreshing()
        }
    }
    
    private func safariViewController(at indexPath: IndexPath) -> SFSafariViewController? {
        guard let url = self.dataSource?.item(at: indexPath)?.url else { return nil }
        let cfg = SFSafariViewController.Configuration()
        cfg.entersReaderIfAvailable = self.userPreferences.openReaderMode
        let sfs = SFSafariViewController(url: url, configuration: cfg)
        sfs.preferredControlTintColor = .black
        return sfs
    }
    
    @IBAction private func addButtonTapped(_ sender: UIButton) {
        sender.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, animations: {
            sender.transform = .identity
        }, completion: nil)
        
        self.activityIndicator.isHidden = false
        self.addButton.isHidden = true
        guard let url = UIPasteboard.general.url else {
            self.activityIndicator.isHidden = true
            self.addButton.isHidden = false
            
            let errorTitle = L10n.General.errorTitle
            let errorMessage = L10n.Add.invalidPasteboard
            
            let errorAlert = UIAlertController(title: errorTitle, message: errorMessage, preferredStyle: .alert)
            let dimissTitle = L10n.General.dismiss
            errorAlert.addAction(UIAlertAction(title: dimissTitle, style: .default) { [weak self] (action) in
                self?.dismiss(animated: true, completion: nil)
            })
            self.present(errorAlert, animated: true, completion: nil)
            return
        }
        
        self.dataProvider.performInMemoryWithoutResultType(endpoint: .add(url)) { [weak self] (result: EmptyResult) in
            guard let strongSelf = self else { return }
            strongSelf.activityIndicator.isHidden = true
            strongSelf.addButton.isHidden = false
            switch result {
            case .isSuccess:
                strongSelf.pullToRefresh()
            case .isFailure(let error):
                Logger.log(error.localizedDescription, event: .error)
            }
        }
    }
    
    @IBAction func searchButtonTapped(_ sender: UIButton) {
        sender.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, animations: {
            sender.transform = .identity
        }, completion: nil)
        
        let search: SearchViewController =  self.factory.instantiate()
        self.present(search, animated: true, completion: nil)
    }

}

//MARK:- UITableViewDelegate
extension ListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        self.cellHeights[indexPath] = cell.frame.size.height
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let height = self.cellHeights[indexPath] else { return UITableViewAutomaticDimension }
        return height
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch self.userPreferences.openLinksWith {
        case .safariViewController:
            guard let sfs = self.safariViewController(at: indexPath) else { return }
            self.present(sfs, animated: true, completion: nil)
        case .safari:
            guard let url = self.dataSource?.item(at: indexPath)?.url else { return }
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let item = self.dataSource?.item(at: indexPath) else { return nil }
        let actions = self.swipeActionManager.buildLeadingActions(for: item)
        return UISwipeActionsConfiguration(actions: actions)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let item = self.dataSource?.item(at: indexPath) else { return nil }
        let actions = self.swipeActionManager.buildTrailingActions(for: item)
        return UISwipeActionsConfiguration(actions: actions)
    }
}

//MARK:- UIViewControllerPreviewingDelegate
extension ListViewController: UIViewControllerPreviewingDelegate {
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = self.tableView.indexPathForRow(at: location) else { return nil }
        previewingContext.sourceRect = self.tableView.rectForRow(at: indexPath)
        let sfs = self.safariViewController(at: indexPath)
        return sfs
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        self.present(viewControllerToCommit, animated: true, completion: nil)
    }
}

extension ListViewController: BadgeDelegate {
    func displayBadgeEnabled() {
        self.tableView.reloadData()
    }
}
