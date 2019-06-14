//
//  PassangersInputViewViewController.swift
//  Direct
//
//  Created by abuzeid on 6/4/19.
//  Copyright © 2019 abuzeid. All rights reserved.
//

import RxSwift
import UIKit

class PassangersInputViewViewController: UIViewController {
    @IBOutlet private var containerView: UIView!
    @IBOutlet private var tabbarView: UIView!
    @IBOutlet private var tabbarWidthConstrain: NSLayoutConstraint!
    @IBOutlet var headerLbl: UILabel!
    var tabbar: TabBar!
    var visaInfo: VisaRequestParams?
    var successInputIndexes: [Int] = []
    private let disposeBag = DisposeBag()
    var defaultTabSelection = PublishSubject<Int>()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "معلومات المسافرين"
        guard let info = visaInfo else { return }
        setHeader(info)
        headerLbl.setYellowGradient()
        setupTabbar(info)
    }

    private func setHeader(_ info: VisaRequestParams) {
        if let type = info.visatypeText {
            headerLbl.text = "\(info.countryName!)-\(type)-\(info.no_of_passport!) \("passangers".localized)"
        }
    }

    var tabs: [(TAB, PassangerFormController)] = []
    private func addTabItemAndController(_ placeholder: String, _ info: VisaRequestParams, index: Int) {
        let tabController = PassangerFormController()
        tabController.countryName = info.countryName
        tabController.countryId = info.country_id
        tabController.index = index

        let tabView = (placeholder.localized + " " + "\(index + 1)", { [weak self] in
            self?.selectTab(index, tabController)
        })

        tabController.successIndex.subscribe(onNext: { [unowned self] value in
            self.successInputIndexes.append(value)
            if !self.selectNextTab() {
                try! AppNavigator().push(.successVisaReqScreen(nil))
            }
        }, onError: nil, onCompleted: nil, onDisposed: nil).disposed(by: disposeBag)
        tabs.append((tabView, tabController))
    }

    private func setupTabbar(_ info: VisaRequestParams) {
        for index in 0 ..< Int(info.no_of_adult)! {
            addTabItemAndController("adult", info, index: index)
        }
        for index in 0 ..< Int(info.no_of_child)! {
            addTabItemAndController("child", info, index: index)
        }
        tabbar = TabBar(tabs: tabs.map { $0.0 })
        tabbar.tabsIcon.forEach { $0.image = #imageLiteral(resourceName: "rightGreen") }
        tabbarView.addSubview(tabbar)
//        tabbarWidthConstrain.constant = CGFloat(tabs.count * 100)

        tabbar.frame = tabbarView.bounds
        tabbar.snp.makeConstraints { make in
            make.top.trailing.bottom.equalToSuperview()
            make.width.equalTo(CGFloat(tabs.count * 100))
        }
        defaultTabSelection.startWith(0).subscribe(onNext: { [unowned self] value in
            self.selectTab(value, self.tabs[value].1)
        }, onError: nil, onCompleted: nil, onDisposed: nil).disposed(by: disposeBag)
    }

    private func selectNextTab() -> Bool {
        for tab in tabs {
            let index = (tab.1.index!)
            if successInputIndexes.contains(index) {
                tabbar.tabsIcon[index].image = #imageLiteral(resourceName: "path4")
            } else {
                selectTab(index, tab.1)
                return true
            }
        }
        return false
    }

    private func selectTab(_ index: Int, _ tab1VC: PassangerFormController) {
        if !containerView.subviews.contains(tab1VC.view) {
            addChild(tab1VC)
            containerView.addSubview(tab1VC.view)
            tab1VC.view.sameBoundsTo(parentView: containerView)
        }

        for (i, item) in tabs.enumerated() {
            item.1.view.isHidden = index == i ? false : true
        }
        tabbar.didSelectTab(index: index)
    }
}
