//
//  ViewController.swift
//  ReadLater
//
//  Created by Xavi Moll on 24/12/2017.
//  Copyright © 2017 xmollv. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    let factory: ViewControllerFactory
    let dataProvider: DataProvider
    
    required init(factory: ViewControllerFactory, dataProvider: DataProvider) {
        self.dataProvider = dataProvider
        self.factory = factory
        super.init(nibName: String(describing: type(of: self)), bundle: Bundle(for: type(of: self)))
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("Dependency Injection required")
    }

}
