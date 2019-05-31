//
//  NewDirectVisaViewModel.swift
//  Direct
//
//  Created by abuzeid on 5/26/19.
//  Copyright © 2019 abuzeid. All rights reserved.
//

import Foundation
import RxOptional
import RxSwift

class NewDirectVisaViewModel {
    var disposeBag = DisposeBag()
    var screenData = PublishSubject<[NewVisaService]>()
    var bioOptions: [BioOption] = []
    var relativesList: [Relative] = []
    var selectedDate = PublishSubject<Date?>()
    var showProgress = PublishSubject<Bool>()

    private var network: ApiClientFacade?
    var selectedCountry: NewVisaService?
    var selectedCountryName = PublishSubject<String?>()
    var passangersCount = PublishSubject<PassangerCount>()
    var selectedVisaType = PublishSubject<String?>()
    var selectedBio = PublishSubject<String?>()
    var selectedRelation = PublishSubject<String?>()
    var totalCost = BehaviorSubject<String>(value: "0".priced)
    var embassyLocations: [DTEmbassyLocation]?
    init(network: ApiClientFacade? = ApiClientFacade()) {
        self.network = network
    }

    func viewDidLoad() {
        guard let network = network else {
            return
        }
        showProgress.onNext(true)

        // get countries
        let countries = network.getCountries()
        countries.subscribe(onNext: { [weak self] countries in
            self?.screenData.onNext(countries)
        }, onError: { [weak self] err in
            self?.screenData.onError(err)
        }, onCompleted: nil, onDisposed: nil).disposed(by: disposeBag)
        // get biou
        let bios = network.getBiometricChoices()
        bios.subscribe(onNext: { [weak self] bios in
            self?.bioOptions.append(contentsOf: bios.bioOption)
        }, onError: { [weak self] _ in
//                self?.bioOptions.onError(err)
        }, onCompleted: nil, onDisposed: nil).disposed(by: disposeBag)

        // get relatives
        let rel = network.getRelationList()
        rel.subscribe(onNext: { [weak self] bios in
            self?.relativesList.append(contentsOf: bios.relatives)
        }, onError: nil, onCompleted: nil, onDisposed: nil).disposed(by: disposeBag)

        Observable.zip(
            countries, bios, rel,
            resultSelector: { _, _, _ in
                self.showProgress.onNext(false)
        }).observeOn(MainScheduler.instance)
            .subscribe()
            .disposed(by: disposeBag)
    }

    var params = VisaRequestParams()

    func submitVisaRequest() {
//        try! AppNavigator().push(.visaRequirement(country: self.selectedCountry!.countryID))
//
//        return
        if params.biometry_loc_id == nil {
            validate(msg: "all is well")
            return
        }

        params.no_of_passport = "0"

        showProgress.onNext(true)
        network?.sendVisaRequest(params: params).subscribe(onNext: {[unowned self] response in
            self.showProgress.onNext(false)
            try! AppNavigator().push(.visaRequirement(country: self.selectedCountry!.countryID))

        }, onError: { _ in
            self.showProgress.onNext(false)
        }, onCompleted: nil, onDisposed: nil).disposed(by: disposeBag)
    }

    func validate(msg: String) {}

    func showVisaTypes() {
        guard let data = selectedCountry?.visatypes else {
            validate(msg: "اختر الدولة اولاً")
            return
        }
        let str = data.map { $0.visaTypeName.rawValue }

        let dest = Destination.selectableSheet(data: str, titleText: "نوع التأشيرة", style: .textCenter)
        let vc = dest.controller() as! SelectableTableSheet
        vc.selectedItem.asObservable().subscribe { event in
            switch event.event {
            case .next(let value):

                let itms = data.filter { $0.visaTypeName.rawValue == value }
                if let id = itms.first?.visaTypeID {
                    self.params.visatype = id
                }
                self.selectedVisaType.onNext(value)
            default:
                break
            }

        }.disposed(by: disposeBag)
        try! AppNavigator().presentModally(vc)
    }

    func showBiometricSpinner() {
        guard let locations = embassyLocations else { return }
        let cities = locations.map { $0.cityName }
        let dest = Destination.selectableSheet(data: cities, titleText: "مكان البصمة", style: .textCenter)
        let vc = dest.controller() as! SelectableTableSheet
        vc.selectedItem.asObservable().subscribe { event in
            switch event.event {
            case .next(let value):
                let locations = locations.filter { $0.cityName == value }
                if let cityObj = locations.first {
                    self.params.biometry_loc_id = cityObj.cityID
                    self.selectedBio.onNext(value)
                }
            default:
                break
            }

        }.disposed(by: disposeBag)
        try! AppNavigator().presentModally(vc)
    }

    func showDatePickerDialog() {
        let dest = Destination.datePicker
        let vc = dest.controller() as! DatePickerController
        vc.selectedDate.asObservable().subscribe { event in
            switch event.event {
            case .next(let value):
                self.params.travel_date = value!.apiFormat
                print(value!.apiFormat)
                self.selectedDate.onNext(value)
            default:
                break
            }

        }.disposed(by: disposeBag)
        try! AppNavigator().presentModally(vc)
    }

    private let countriesController = Destination.searchCountries.controller() as! SearchViewController

    func showCountriesSpinner() {
        countriesController.selectedItem.asObservable().subscribe { event in
            switch event.event {
            case .next(let value):
                self.selectedCountry = value
                self.params.country_id = value.countryID
                self.selectedCountryName.onNext(value.countryName)
                let cities = self.network?.getCities(country: value.countryID)
                cities?.subscribe(onNext: { [weak self] cities in
                    self?.embassyLocations = cities.dtEmbassyLocations
                }, onError: nil, onCompleted: nil, onDisposed: nil).disposed(by: self.disposeBag)

            default:
                break
            }

        }.disposed(by: disposeBag)
        try! AppNavigator().presentModally(countriesController)
    }

    func showPasangersCountSpinner() {
        guard let country = self.selectedCountry else {
            validate(msg: "")
            return
        }
        var vc = Destination.passangersCount.controller() as! PassangersCountController

        vc.info = VisaPriceParams(cid: params.country_id, cityid: params.biometry_loc_id, no_of_adult: 0.stringValue, no_of_child: 0.stringValue, no_of_passport: 0.stringValue, promo_code: 0.stringValue, visatype: params.visatype)
        vc.result.asObservable().subscribe { event in
            switch event.event {
            case .next(let value):
                self.passangersCount.onNext(value)
                self.params.no_of_adult = "\(value.0)"
                self.params.no_of_child = "\(value.1)"
                self.totalCost.onNext(value.2.priced)
            default:
                break
            }

        }.disposed(by: disposeBag)
        try! AppNavigator().presentModally(vc)
    }

    func showRelationsSpinner() {
        let bios = relativesList.map { $0.name }
        let dest = Destination.selectableSheet(data: bios, titleText: "العلاقة بين المسافرين", style: .textCenter)
        let vc = dest.controller() as! SelectableTableSheet
        vc.selectedItem.asObservable().subscribe { event in
            switch event.event {
            case .next(let value):
                let bio = self.relativesList.filter { $0.name == value }
                if let bioObj = bio.first {
                    self.params.relation_with_travelers = bioObj.id
                }

                self.selectedRelation.onNext(value)

            default:
                break
            }

        }.disposed(by: disposeBag)
        try! AppNavigator().presentModally(vc)
    }
}
