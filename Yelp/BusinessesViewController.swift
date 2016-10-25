//
//  BusinessesViewController.swift
//  Yelp
//
//  Created by Timothy Lee on 4/23/15.
//  Copyright (c) 2015 Timothy Lee. All rights reserved.
//

import UIKit
import ALLoadingView

class BusinessesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating, UISearchBarDelegate, UIScrollViewDelegate, FiltersViewControllerDelegate {
    @IBOutlet var tableView: UITableView!
    
    var myBusinesses: [Business]!
    var searchController: UISearchController!
    private var isMoreDataLoading = false
    private var shouldLoadMoreData = true
    private var dataPage = 1
    private var filteredData = [Business]()
    private var preferences : Preferences = Preferences() {
        didSet {
            updateData()
        }
    }
    
    
    override func viewDidLoad() {
        print ("View did load")
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 100
        
        setupView()
        
        ALLoadingView.manager.showLoadingView(ofType: .basic)
        ALLoadingView.manager.blurredBackground = true
        Business.searchWithTerm(term: "Restaurants", offset: 0, completion: { (businesses: [Business]?, error: Error?) -> Void in
            if let businesses = businesses {
                for business in businesses {
                    print(business.name!)
                    print(business.address!)
                }
                self.myBusinesses = businesses
                self.filteredData = businesses
                self.tableView.reloadData()
                ALLoadingView.manager.hideLoadingView()
            }
            
            }
        )
        
        /* Example of Yelp search with more search options specified
         Business.searchWithTerm("Restaurants", sort: .Distance, categories: ["asianfusion", "burgers"], deals: true) { (businesses: [Business]!, error: NSError!) -> Void in
         self.businesses = businesses
         
         for business in businesses {
         print(business.name!)
         print(business.address!)
         }
         }
         */
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
     // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let navigationController = segue.destination as! UINavigationController
        let filtersViewController = navigationController.topViewController as! FiltersViewController
        filtersViewController.delegate = self
    }
    
    func updateData() {
        ALLoadingView.manager.showLoadingView(ofType: .basic)
        ALLoadingView.manager.blurredBackground = true
        Business.searchWithTerm(term: "Restaurants", sort: preferences.sortedBy, categories: preferences.categories, radius: preferences.distance, deals: preferences.deals, offset: 0) { (businesses: [Business]?, error: Error?) in
            if (error == nil) {
                self.myBusinesses = businesses
                self.filteredData = self.myBusinesses
                self.tableView.reloadData()
                ALLoadingView.manager.hideLoadingView()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BusinessTableViewCell", for: indexPath) as! BusinessTableViewCell
        cell.business = filteredData[indexPath.row]
        cell.selectionStyle = .none
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredData.count
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        print("Search clicked!")
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        print("Cancel button clicked!")
        self.shouldLoadMoreData = true
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        // When user has entered text into the search box
        // Use the filter method to iterate over all items in the data array
        // For each item, return true if the item should be included and false if the
        // item should NOT be included
        let searchText = searchController.searchBar.text
        filteredData = (searchText?.isEmpty)! ? myBusinesses : myBusinesses.filter({(business: Business) -> Bool in
            // If dataItem matches the searchText, return true to include it
            return business.name?.range(of: searchText!, options: .caseInsensitive) != nil
        })
        
        self.tableView.reloadData()
        self.shouldLoadMoreData = (searchText?.isEmpty)!
        print ("updating ssearch!")
    }
    
    func filterButtonClicked(_ filterButton: UIBarButtonItem) {
        let vc = FiltersViewController()
        self.present(vc, animated: true, completion: nil)
        print ("Filter button clicked")
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (!isMoreDataLoading && shouldLoadMoreData) {
            // Calculate the position of one screen length before the bottom of the results
            let scrollViewContentHeight = tableView.contentSize.height
            let scrollOffsetThreshold = scrollViewContentHeight - tableView.bounds.size.height
            
            // When the user has scrolled past the threshold, start requesting
            if(scrollView.contentOffset.y > scrollOffsetThreshold && tableView.isDragging) {
                
                isMoreDataLoading = true
                
                // Code to load more results
                loadMoreData()
            }
        }
    }
    
    
    func filtersViewController(filtersViewController: FiltersViewController, didUpdateFilters filters: [String : AnyObject]) {
        preferences.categories = filters["categories"] as! [String]?
        preferences.sortedBy = filters["sorted"] as! YelpSortMode?
        preferences.distance = filters["distance"] as! Float?
        preferences.deals = filters["deals"] as! Bool?
        
        dataPage = 0
        self.myBusinesses = []
        self.filteredData = []
        loadMoreData()
    }
    
    func loadMoreData() {
        ALLoadingView.manager.showLoadingView(ofType: .basic)
        ALLoadingView.manager.blurredBackground = false
        Business.searchWithTerm(term: "Restaurant", sort: preferences.sortedBy, categories: preferences.categories, radius: preferences.distance, deals: preferences.deals, offset: dataPage, completion: { (businesses: [Business]?, error: Error?) -> Void in
            
            if let newBusinesses = businesses {
                self.myBusinesses.append(contentsOf: newBusinesses)
                self.filteredData = self.myBusinesses
                self.tableView.reloadData()
                self.isMoreDataLoading = false
                ALLoadingView.manager.hideLoadingView()
            }
            
        }
        )
        
        dataPage += 1
    }

    
    func setupView() {
        self.navigationController?.navigationBar.barTintColor = UIColor(colorLiteralRed: 1.96, green: 0.18, blue: 0, alpha: 1.0)
        
        // Initializing with searchResultsController set to nil means that
        // searchController will use this view controller to display the search results
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        // If we are using this same view controller to present the results
        // dimming it out wouldn't make sense. Should probably only set
        // this to yes if using another controller to display the search results.
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.sizeToFit()
        // Sets this view controller as presenting view controller for the search interface
        definesPresentationContext = true
        searchController.searchBar.sizeToFit()
        navigationItem.titleView = searchController.searchBar
        searchController.hidesNavigationBarDuringPresentation = false
    }
}
