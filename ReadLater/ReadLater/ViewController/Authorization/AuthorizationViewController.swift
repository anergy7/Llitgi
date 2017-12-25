//
//  AuthorizationViewController.swift
//  ReadLater
//
//  Created by Xavi Moll on 24/12/2017.
//  Copyright © 2017 xmollv. All rights reserved.
//

import UIKit

class AuthorizationViewController: ViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.dataProvider.perform(endpoint: .getList) { (result: Result<[ArticleImplementation]>) in
            dump(result)
        }
    }

}
