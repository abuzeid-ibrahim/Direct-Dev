//
//  UITableView+Appearance.swift
//  Direct
//
//  Created by abuzeid on 5/31/19.
//  Copyright © 2019 abuzeid. All rights reserved.
//

import UIKit
extension UITableView {
    func defaultSeperator() {
        tableFooterView = UIView()
        separatorColor = UIColor.appVeryLightGray
        separatorStyle = .singleLine
    }
     func noSeperator() {
        tableFooterView = UIView()
        separatorColor = UIColor.clear
        separatorStyle = .none
    }
}
