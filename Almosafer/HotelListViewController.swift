//
//  HotelListViewController.swift
//  Almosafer
//
//  Created by Fawzi Rifa'i on 10/03/2022.
//

import UIKit

enum SortBy {
    case Recommended, LowestPrice, StarRating, Distance
}

class HotelListViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    var hotels = [Hotel]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        customizeNavigationBarAppearance()
        setUpSearchBar()
        title = "Dubai, United Arab Emirates"
        if let url = URL(string: "https://sgerges.s3-eu-west-1.amazonaws.com/iostesttaskhotels.json") {
            URLSession.shared.dataTask(with: url) { (data, response, error) in
                if let data = data {
                    DispatchQueue.main.async {
                        if let jsonHotels = try? JSONDecoder().decode(Hotels.self, from: data) {
                            for (_, value) in jsonHotels.hotels {
                                self.hotels.append(value)
                            }
                            self.collectionView.reloadData()
                        }
                    }
                }
            }.resume()
        }
    }
    
    func downloadImage(for hotel: Hotel) {
        if let url = URL(string: hotel.thumbnailUrl) {
            URLSession.shared.dataTask(with: url) { (data, response, error) in
                if let data = data {
                    DispatchQueue.main.async {
                        hotel.imageData = data
                        hotel.downloaded = true
                        self.collectionView.reloadData()
                    }
                }
            }.resume()
        }
    }
    
    func customizeNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(named: "AccentColor")
        appearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = navigationController?.navigationBar.standardAppearance
        navigationController?.navigationBar.overrideUserInterfaceStyle = .dark
        navigationController?.navigationBar.tintColor = .white
    }
    
    @IBAction func showMap() {
        guard let mapViewController = storyboard?.instantiateViewController(withIdentifier: "Map") as? MapViewController else { return }
        mapViewController.hotels = hotels
        navigationController?.pushViewController(mapViewController, animated: true)
    }
    
    @IBAction func showSortOptions() {
        let alertController = UIAlertController(title: "Sort by…", message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Recommended", style: .default, handler: { action in
            self.sortHotels(by: .Recommended)
        }))
        alertController.addAction(UIAlertAction(title: "Lowest price", style: .default, handler: { action in
            self.sortHotels(by: .LowestPrice)
        }))
        alertController.addAction(UIAlertAction(title: "Star rating", style: .default, handler: { action in
            self.sortHotels(by: .StarRating)
        }))
        alertController.addAction(UIAlertAction(title: "Distance", style: .default, handler: { action in
            self.sortHotels(by: .Distance)
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alertController.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItem
        present(alertController, animated: true)
    }
    
    func sortHotels(by sortOption: SortBy) {
        switch sortOption {
        case .Recommended:
            hotels.sort(by: { $0.priorityScore > $1.priorityScore })
        case .LowestPrice:
            hotels.sort(by: {
                if let firstElementPrice = $0.price {
                    if let secondElementPrice = $1.price {
                        return firstElementPrice < secondElementPrice
                    } else {
                        return true
                    }
                } else {
                    return false
                }
            })
        case .StarRating:
            hotels.sort(by: { $0.starRating ?? 0 > $1.starRating ?? 0 })
        case .Distance:
            hotels.sort(by: { $0.distanceInMeters < $1.distanceInMeters })
        }
        collectionView.reloadData()
    }
    
}

extension HotelListViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return hotels.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Hotel Cell", for: indexPath as IndexPath) as! HotelCollectionViewCell
        cell.backgroundColor = UIColor.secondarySystemGroupedBackground
        cell.layer.cornerRadius = 8
        let hotel = hotels[indexPath.row]
        cell.title.attributedText = hotel.attributedName
        if hotel.downloaded == true {
            cell.imageView.image = UIImage(data: hotel.imageData!)
        } else {
            cell.imageView.image = UIImage()
            downloadImage(for: hotel)
        }
        cell.price.text = hotel.priceWithCurrency
        cell.address.text = hotel.address["en"] as? String
        if let hotelReview = hotel.review {
            if hotelReview.count == 0 {
                cell.reviewStack.isHidden = true
            } else {
                cell.reviewStack.isHidden = false
                cell.reviewScore.text = "\(hotelReview.score)"
                cell.reviewScoreDescription.text = hotelReview.scoreDescription["en"]
                cell.reviewCount.text = "\(hotelReview.count) reviews"
            }
            
        } else {
            cell.reviewStack.isHidden = true
        }
        cell.layoutIfNeeded()
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width - 20, height: 200)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
    }
    
}

extension HotelListViewController: UISearchControllerDelegate, UISearchBarDelegate {
    
    func setUpSearchBar() {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.delegate = self
        searchController.searchBar.delegate = self
        searchController.searchBar.tintColor = .white
        searchController.searchBar.placeholder = "Search hotels from this list"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
}
