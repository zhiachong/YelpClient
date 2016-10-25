//
//  FiltersViewController.swift
//  Yelp
//
//  Created by Zhia Chong on 10/23/16.
//  Copyright © 2016 Timothy Lee. All rights reserved.
//

import UIKit

@objc protocol FiltersViewControllerDelegate {
    @objc optional func filtersViewController(filtersViewController: FiltersViewController, didUpdateFilters filters: [String: AnyObject])
}

enum PrefRowIdentifier : String{
    case Deals = "Deals"
    case Distance = "Distance"
    case SortedBy = "Sorted By"
    case Category = "Category"
}

class FiltersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, SwitchCellTableViewCellDelegate {

    @IBOutlet var tableView: UITableView!
    weak var delegate: FiltersViewControllerDelegate?
    
    let tableStructure: [[PrefRowIdentifier]] = [ [.Deals],
                                                  [.Distance],
                                                  [.SortedBy],
                                                  [.Category]
                                                ]
    
    var categories : [Int: Bool] = [:]
    var sortedBy : [Int: Bool] = [:]
    var distance : [Int: Bool] = [:]
    var deals : [Int: Bool] = [:]
    
    var isExpanded: [Bool] = []
    var hasPrefs: [Bool] = []
    var prefs: [[AnyObject]] = [[]]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self
        
        isExpanded = [false, false, false, false]
        hasPrefs = [false, false, false, false]
        prefs = [[], [], [], []]
        
        self.navigationController?.navigationBar.barTintColor = UIColor(colorLiteralRed: 1.96, green: 0.18, blue: 0, alpha: 1.0)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func onCancelTapped(_ sender: AnyObject) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func onSaveTapped(_ sender: AnyObject) {
        var filters = [String: AnyObject]()
        
        filters["deals"] = getDealsPref() as AnyObject?
        filters["distance"] = getDistancePref() as AnyObject?
        filters["sorted"] = getSortedByPref() as AnyObject?
        filters["categories"] = getCategoriesPref() as AnyObject?

        print ("Filters to use!")
        print (filters)
        
        delegate?.filtersViewController!(filtersViewController: self, didUpdateFilters: filters)
        dismiss(animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (false == isExpanded[section]) {
            return 1
        }
        
        return getAllPrefsToUseForSection(section).count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return tableStructure.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return tableStructure[section][0].rawValue
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var shouldUpdate = false
        if (indexPath.section < 3) {
            isExpanded[indexPath.section] = !isExpanded[indexPath.section]
            shouldUpdate = true
        } else {
            shouldUpdate = !isExpanded[indexPath.section]
            isExpanded[indexPath.section] = true
        }
        
        if (shouldUpdate) {
            tableView.reloadSections(NSIndexSet(index: indexPath.section) as IndexSet, with: .automatic)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCellTableViewCell", for: indexPath) as! SwitchCellTableViewCell
        let prefToUse = getAllPrefsToUseForSection(indexPath.section)
        var groupToUse = getGroupToUse(indexPath.section)
        
        cell.delegate = self
        cell.selectionStyle = .none
        
        var text = prefToUse[indexPath.row]["name"]
        var isOn = groupToUse[indexPath.row] ?? false

        if (indexPath.section < 3 && true == hasPrefs[indexPath.section] && !isExpanded[indexPath.section]) {
            text = prefs[indexPath.section][0] as? String
            isOn = prefs[indexPath.section][1] as! Bool
        }
        
        cell.switchLabel.text = text
        cell.onSwitch.isOn = isOn
        
        return cell
    }
    
    func switchCellTableViewCell(switchCellTableViewCell: SwitchCellTableViewCell, didChangeValue value: Bool) {
        let indexPath = tableView.indexPath(for: switchCellTableViewCell)!
        setGroupValue(indexPath:indexPath, value:value)
        
        if (indexPath.section < 3) {
            prefs[indexPath.section] = [switchCellTableViewCell.switchLabel.text as AnyObject, switchCellTableViewCell.onSwitch.isOn as AnyObject]
            hasPrefs[indexPath.section] = value
            
            if (isExpanded[indexPath.section]) {
                isExpanded[indexPath.section] = !isExpanded[indexPath.section]
                tableView.reloadSections(NSIndexSet(index: indexPath.section) as IndexSet, with: .automatic)
            }
        }
    }

    
    func getDistancePref() -> Float? {
        for (index, isSelected) in distance {
            if isSelected {
                return Float(Preferences.yelpDistances()[index]["code"]!)!
            }
        }
        
        return nil
    }
    
    func getDealsPref() -> Bool {
        return deals[0] ?? false
    }
    
    func getSortedByPref() -> YelpSortMode? {
        for (index, isSelected) in sortedBy {
            if (isSelected) {
                return YelpSortMode(rawValue: index)
            }
        }
        
        return nil
    }
    
    func getCategoriesPref() -> [String]? {
        var categoriesToUse:[String] = []
        
        for (index, isSelected) in categories {
            if (isSelected) {
                categoriesToUse.append(Preferences.yelpCategories()[index]["code"]!)
            }
        }
        
        return categoriesToUse.count > 0 ? categoriesToUse : nil
    }
    
    func getGroupToUse(_ section: Int) -> [Int: Bool] {
        switch section {
            case 0:
                return deals
            case 1:
                return distance
            case 2:
                return sortedBy
            case 3:
                return categories
            default:
                return categories
        }
    }
    
    func setGroupValue(indexPath: IndexPath, value: Bool) {
        let section = indexPath.section
        var indexPathsToUpdate:[IndexPath] = []
        switch section {
            case 0:
                deals[indexPath.row] = value
            case 1:
                distance[indexPath.row] = value
                for (i,_) in distance {
                    if (i != indexPath.row) {
                        distance[i] = false
                        if (isExpanded[indexPath.section]) {
                            let indexPathToUpdate = IndexPath(row: i, section: indexPath.section)
                            indexPathsToUpdate += [indexPathToUpdate]
                        }
                    }
            }
            case 2:
                sortedBy[indexPath.row] = value
                for (i,_) in sortedBy {
                    if (i != indexPath.row) {
                        sortedBy[i] = false
                        if (isExpanded[indexPath.section]) {
                            let indexPathToUpdate = IndexPath(row: i, section: indexPath.section)
                            indexPathsToUpdate += [indexPathToUpdate]
                        }
                    }
            }
            case 3:
                categories[indexPath.row] = value
            default:
                break
        }
        
        if (indexPathsToUpdate.count > 0) {
            tableView.reloadRows(at: indexPathsToUpdate, with: .none)
        }
    }
    
    func getAllPrefsToUseForSection(_ section: Int) -> [[String:String]] {
        switch section {
        case 0:
            return Preferences.yelpDeals()
        case 1:
            return Preferences.yelpDistances()
        case 2:
            return Preferences.yelpSort()
        case 3:
            return Preferences.yelpCategories()
        default:
            return Preferences.yelpCategories()
        }
    }
        
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
}
