//
//  FavoriteVC.swift
//  RecipeFlicker
//
//  Created by minami on 2018-10-16.
//  Copyright © 2018 Kenta Kodashima. All rights reserved.
//

import UIKit
import Firebase
import RealmSwift

class FavoriteVC: UIViewController {
  
  enum ViewType: Int {
    case list
    case grid
  }
  
  var ref: DatabaseReference!
  var selectedCollectionId: String!
  var selectedRecipeId: String?
  
  @IBOutlet weak var typeSegmentControll: UISegmentedControl!
  @IBOutlet weak var collectionView: UICollectionView!
  @IBOutlet weak var searchBar: UISearchBar!
  
  
  let gridLayout = GridFlowLayout()
  let listLayout = ListFlowLayout()
  
  let recipeFactory = ReplicaRecipeFactory()
  var favoriteRecipes = [Recipe]()
  var collections = [Collection]()
  
  
  fileprivate func getFavoriteRecipesFromFirebase(_ userID: String?) {
    ref.child("favorites").child(userID!).observe(.value) { (snapshot) in
      self.favoriteRecipes.removeAll()
      for child in snapshot.children {
        if let recipe = (child as! DataSnapshot).value as? [String: String],
          let id = recipe["firebaseId"],
          let url = recipe["originalRecipeUrl"],
          let title = recipe["title"],
          let image = recipe["image"],
          let isFavotiteLiteral = recipe["isFavorite"]
        {
          let whichCollectionToBelongList = List<String>()
          if let whichCollectionToBelong = recipe["whichCollectionToBelong"] as? [String:Any] {
            for collectionId in whichCollectionToBelong.keys {
              whichCollectionToBelongList.append(collectionId)
            }
          }
          let favoriteRecipe = Recipe(firebaseId: id, originalRecipeUrl: url, title: title, image: image, isFavorite: (isFavotiteLiteral == "true"), whichCollectionToBelong: whichCollectionToBelongList)
          self.favoriteRecipes.append(favoriteRecipe)
        }
      }
      if self.typeSegmentControll.selectedSegmentIndex == ViewType.list.rawValue
        && self.favoriteRecipes.count <= 0 {
        self.collectionView.setNoDataLabelForCollectionView()
      } else {
        self.collectionView.removeNoDataLabel()
      }
      self.collectionView.reloadData()
    }
  }
  
  fileprivate func getCollectionsFromFirebase(_ userID: String?) {
    ref.child("userCollections").child(userID!).observe(.value) { (snapshot) in
      self.collections.removeAll()
      for child in snapshot.children {
        if let collectionData = (child as! DataSnapshot).value as? [String: String],
        let id = collectionData["firebaseId"],
        let name = collectionData["name"]
        {
          let image = collectionData["image"]
          let collection = Collection(withId: id, andName: name, andImageUrl: image)
          self.collections.append(collection)
        }
      }
      if self.typeSegmentControll.selectedSegmentIndex == ViewType.grid.rawValue
        && self.collections.count <= 0 {
        self.collectionView.setNoDataLabelForCollectionView()
      } else {
        self.collectionView.removeNoDataLabel()
      }
      self.collectionView.reloadData()
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
//    searchBar.layer.borderWidth = 1
//    searchBar.layer.borderColor = #colorLiteral(red: 1, green: 0.9420082569, blue: 0.7361317277, alpha: 1)
    searchBar.setSearchBar()
    
    ref = Database.database().reference()
    let userID = Auth.auth().currentUser?.uid
    
    getFavoriteRecipesFromFirebase(userID)
    getCollectionsFromFirebase(userID)
    
    typeSegmentControll.tintColor = AppColors.accent.value
    collectionView.collectionViewLayout = listLayout
    collectionView.register(CollectionViewCellForList.self,
                            forCellWithReuseIdentifier: CollectionViewCellForList.reuseIdentifier)
    collectionView.register(CollectionViewCellForGrid.self, forCellWithReuseIdentifier: CollectionViewCellForGrid.reuseIdentifier)
  }
  
  @IBAction func onSegmentControlTapped(_ sender: UISegmentedControl) {
    switch sender.selectedSegmentIndex {
    case ViewType.list.rawValue:
      changeView(flowLayout: listLayout)
      if favoriteRecipes.count <= 0 {
        collectionView.setNoDataLabelForCollectionView()
      }
      break
    case ViewType.grid.rawValue:
      changeView(flowLayout: gridLayout)
      if collections.count <= 0 {
       collectionView.setNoDataLabelForCollectionView()
      }
      break
    default:
      break
    }
  }
  
  func changeView(flowLayout: UICollectionViewFlowLayout) {
    self.collectionView.removeNoDataLabel()
    self.collectionView.collectionViewLayout.invalidateLayout()
    self.collectionView.reloadData()
    self.collectionView.setCollectionViewLayout(flowLayout, animated: false)
  }
}

extension FavoriteVC: UICollectionViewDataSource, UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    if typeSegmentControll.selectedSegmentIndex == ViewType.list.rawValue {
      if favoriteRecipes.count > 0 {
        return favoriteRecipes.count
      } else {
        return 0
      }
    } else {
      if collections.count > 0 {
        return collections.count
      } else {
        return 0
      }
    }
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    if typeSegmentControll.selectedSegmentIndex == ViewType.list.rawValue {
      let recipe = favoriteRecipes[indexPath.row]
      let cell = collectionView.dequeueReusableCell(
        withReuseIdentifier: CollectionViewCellForList.reuseIdentifier,
        for: indexPath)
        as! CollectionViewCellForList
      cell.setupContents(withTitle: recipe.title, andImage: recipe.image)
      return cell
    } else {
      let collection = collections[indexPath.row]
      let cell = collectionView.dequeueReusableCell(
        withReuseIdentifier: CollectionViewCellForGrid.reuseIdentifier,
        for: indexPath)
        as! CollectionViewCellForGrid
      cell.setupContents(withTitle: collection.name, andImage: collection.image ?? "")
      return cell
    }
  }
  
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    if typeSegmentControll.selectedSegmentIndex == ViewType.list.rawValue {
      if !isEditing {
        let recipe = favoriteRecipes[indexPath.row]
        selectedRecipeId = recipe.firebaseId
        self.performSegue(withIdentifier: "goToDetail", sender: self.collectionView)
      } else {
        self.toolBar.isHidden = false
      }
    } else {
      let collection = collections[indexPath.row]
      selectedCollectionId = collection.firebaseId
      print(selectedCollectionId)
      self.performSegue(withIdentifier: "goToCollection", sender: self.collectionView)
    }
    
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "goToCollection" {
      let destVC = segue.destination as! CollectionVC
      destVC.collectionId = selectedCollectionId
      print("pass: \(destVC.collectionId)")
    } else if segue.identifier == "goToDetail" {
      let destVC = segue.destination as! DetailVC
      destVC.recipeId = selectedRecipeId
    }
  }
}



extension FavoriteVC: UISearchBarDelegate {
  
}
