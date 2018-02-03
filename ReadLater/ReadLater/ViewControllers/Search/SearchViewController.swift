//
//  SearchViewController.swift
//  ReadLater
//
//  Created by Xavi Moll on 03/02/2018.
//  Copyright © 2018 xmollv. All rights reserved.
//

import UIKit

class SearchViewController: ViewController {

    //MARK:- IBOutlets
    @IBOutlet private var searchTextField: UITextField!
    @IBOutlet private var tableView: UITableView!
    //MARK:- Private properties
    private var searchResults: [Item] = []
    
    //MARK:- Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.configureSearchTextField()
        self.configureTableView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.searchTextField.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.searchTextField.resignFirstResponder()
    }
    
    private func configureSearchTextField() {
        self.searchTextField.delegate = self
        self.searchTextField.attributedPlaceholder = NSAttributedString(string: "Search", attributes: [NSAttributedStringKey.foregroundColor: UIColor.black])
    }
    
    private func configureTableView() {
        self.tableView.register(ListCell.self)
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.tableFooterView = UIView()
    }

}

//MARK:- UITextFieldDelegate
extension SearchViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        self.searchResults.removeAll()
        self.tableView.reloadData()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let text = textField.text, let textRange = Range(range, in: text) {
            let finalText = text.replacingCharacters(in: textRange, with: string)
            if finalText == "" {
                self.searchResults.removeAll()
            } else {
                self.searchResults = self.dataProvider.search(finalText)
            }
        } else {
            self.searchResults.removeAll()
        }
        self.tableView.reloadData()
        return true
    }
}

//MARK:- UITableViewDataSource
extension SearchViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = self.searchResults[indexPath.row]
        let cell: ListCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
        cell.configure(with: item)
        return cell
    }
    
}

//MARK:- UITableViewDelegate
extension SearchViewController: UITableViewDelegate {
    
}

