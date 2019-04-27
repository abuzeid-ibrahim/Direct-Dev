//
//  HomeCollectionSectionWrapper.swift
//  Direct
//
//  Created by abuzeid on 4/27/19.
//  Copyright © 2019 abuzeid. All rights reserved.
//

import UIKit

class HomeCollectionSectionWrapper: UICollectionViewCell {
    static let cellId = "HomeCollectionSectionWrapper"
    @IBOutlet weak var collectionView: UICollectionView!

    var cellId:String!{
        didSet{
            self.collectionView.register(UINib(nibName: cellId, bundle: nil), forCellWithReuseIdentifier: cellId)
        }
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        collectionView.dataSource = self
        collectionView.delegate = self

    }

}
extension HomeCollectionSectionWrapper:UICollectionViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.bounds.width - 50, height: self.bounds.height - 4)
    }
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataList.count
    }
   
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath)
        
        return cell
    }
    
    
}
