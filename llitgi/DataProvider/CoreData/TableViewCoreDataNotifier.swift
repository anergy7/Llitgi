//
//  AutomaticCoreDataNotifier.swift
//  llitgi
//
//  Created by Xavi Moll on 02/12/2018.
//  Copyright © 2018 xmollv. All rights reserved.
//

import Foundation
import UIKit
import CoreData

protocol TableViewCoreDataNotifier: CoreDataNotifierDelegate {
    associatedtype T: NSManagedObject
    //The ! is due to how UITableViewController declares it's own UITableView
    var tableView: UITableView! { get set }
    var notifier: CoreDataNotifier<T> { get }
}

extension TableViewCoreDataNotifier {
    func willChangeContent() {
        self.tableView.beginUpdates()
    }
    
    func didChangeSection(_ change: CoreDataNotifierSectionChange) {
        switch change {
        case .insert(let sectionIndex):
            self.tableView.insertSections(IndexSet(integer: sectionIndex), with: .automatic)
        case .delete(let sectionIndex):
            self.tableView.deleteSections(IndexSet(integer: sectionIndex), with: .automatic)
        }
    }
    
    func didChangeObject(_ change: CoreDataNotifierChange) {
        switch change {
        case .update(let indexPath):
            self.tableView.reloadRows(at: [indexPath], with: .automatic)
        case .insert(let indexPath):
            self.tableView.insertRows(at: [indexPath], with: .automatic)
        case .delete(let indexPath):
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
        case .move(let from, let to):
            self.tableView.deleteRows(at: [from], with: .automatic)
            self.tableView.insertRows(at: [to], with: .automatic)
        }
    }
    
    func endChangingContent() {
        self.tableView.endUpdates()
    }
    
    func startNotifyingFailed(with error: Error) {
        self.notifier.startNotifying()
    }
}