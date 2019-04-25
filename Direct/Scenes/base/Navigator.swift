//
//  Navigator.swift
//  Direct
//
//  Created by abuzeid on 4/25/19.
//  Copyright © 2019 abuzeid. All rights reserved.
//

import UIKit
enum Destination{
    case loginView, signupView
}

protocol Navigator {
    func show(_ destination:Destination)
}

final class AppNavigator:Navigator{
    
    var rootController:RootNavigationViewController
    init(root:RootNavigationViewController) {
        self.rootController  = root
    }
    func show(_ destination: Destination) {
        let vc  = controller(of: destination)
        self.rootController.pushViewController(vc, animated: true)
    }
    func controller(of dest: Destination)->UIViewController{
        switch dest {
        case .loginView:
            let auth = UserAuthViewController()
            auth.showView(.login)
            return auth
        case .signupView:
            let auth = UserAuthViewController()
            auth.showView(.signup)
            return auth
        }
    }
}


