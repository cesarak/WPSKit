//
//  ArrayDataSource.swift
//
// Created by Kirby Turner.
// Copyright 2016 White Peak Software. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to permit
// persons to whom the Software is furnished to do so, subject to the
// following conditions:
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
// CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

import UIKit

public class ArrayDataSource: NSObject, DataSource {
  
  public var array:[[AnyObject]] = [[]]
  
  public let defaultCellIdentifier: String?

  public let sectionHeaderTitles: [String]?
  
  public var configureCell: ((cell: AnyObject, indexPath: NSIndexPath, item: AnyObject) -> Void)!
  
  public var cellIdentifier: ((indexPath: NSIndexPath, item: AnyObject) -> String)!
  
  public var canEdit: ((indexPath: NSIndexPath) -> Bool)!
  
  public var commitEditingStyle: ((tableView: UITableView, editingStyle: UITableViewCellEditingStyle, indexPath: NSIndexPath) -> Void)!
  
  public var canMoveItem: ((indexPath: NSIndexPath) -> Bool)!
  
  public var moveItem: ((tableView: UITableView, sourceIndexPath: NSIndexPath, destinationIndexPath: NSIndexPath) -> Void)!
  
  public var configureSupplementaryView: ((view: AnyObject, kind: String, indexPath: NSIndexPath) -> Void)!
  
  public var reuseIdentifierForSupplementaryView: ((kind: String, indexPath: NSIndexPath) -> String)!

  public init(defaultCellIdentifier: String? = nil, sectionHeaderTitles: [String]? = nil) {
    self.defaultCellIdentifier = defaultCellIdentifier
    self.sectionHeaderTitles = sectionHeaderTitles
  }
}

// MARK: - DataSource Public

public extension ArrayDataSource {
  
  /**
   Returns the object found at the provided index path.
   
   - parameter indexPath: The index path to the object.
   
   - return Returns the object.
   */
  public func objectAtIndexPath(indexPath: NSIndexPath) -> AnyObject? {
    guard indexPath.section < array.count else {
      return nil
    }
    
    guard indexPath.row < array[indexPath.section].count else {
      return nil
    }
    
    return array[indexPath.section][indexPath.row]
  }
  
}

// MARK: - DataSource Private

private extension ArrayDataSource {
  
  private func numberOfSections() -> Int {
    return array.count
  }
  
  private func numberOfRowsInSection(section: Int) -> Int {
    guard section < array.count else {
      return 0
    }
    
    return array[section].count
  }

  private func cellIdentifierAtIndexPath(indexPath: NSIndexPath) -> String {
    var id = defaultCellIdentifier
    if let cellIdentifier = cellIdentifier {
      if let item = objectAtIndexPath(indexPath) {
        id = cellIdentifier(indexPath: indexPath, item: item)
      }
    }
    if id == nil {
      fatalError("You did not set the cell identifier!")
    }
    return id!
  }
  
  private func reuseIdentifierForSupplementaryViewAtIndexPath(indexPath: NSIndexPath, kind: String) -> String {
    return reuseIdentifierForSupplementaryView(kind: kind, indexPath: indexPath)
  }
  
}

// MARK: - UICollectionViewDataSource

extension ArrayDataSource {

  public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
    return numberOfSections()
  }
  
  public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return numberOfRowsInSection(section)
  }
  
  public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    let identifier = cellIdentifierAtIndexPath(indexPath)
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(identifier, forIndexPath: indexPath)
    if let configureCell = configureCell {
      let item = objectAtIndexPath(indexPath)
      configureCell(cell: cell, indexPath: indexPath, item: item!)
    }
    return cell
  }
  
  public func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
    let reuseIdentifier = reuseIdentifierForSupplementaryViewAtIndexPath(indexPath, kind: kind)
    let reusableView = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath)
    if let configureSupplementaryView = configureSupplementaryView {
      configureSupplementaryView(view: reusableView, kind: kind, indexPath: indexPath)
    }
    
    return reusableView
  }
}

// MARK: - UITableViewDataSource

extension ArrayDataSource {
  
  public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return numberOfSections()
  }
  
  public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return numberOfRowsInSection(section)
  }
  
  public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let identifier = cellIdentifierAtIndexPath(indexPath)
    let cell = tableView.dequeueReusableCellWithIdentifier(identifier, forIndexPath: indexPath)
    if let configureCell = configureCell {
      let item = objectAtIndexPath(indexPath)
      configureCell(cell: cell, indexPath: indexPath, item: item!)
    }
    return cell
  }
  
  public func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    guard let titles = sectionHeaderTitles else {
      return nil
    }
    
    guard section < titles.count else {
      return nil
    }
    
    return titles[section]
  }
  
  public func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    var edit = false
    if let canEdit = canEdit {
      edit = canEdit(indexPath: indexPath)
    }
    return edit
  }

  public func tableView(tableView: UITableView, editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    if let commitEditingStyle = commitEditingStyle {
      commitEditingStyle(tableView: tableView, editingStyle: editingStyle, indexPath: indexPath)
    }
  }
  
  public func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    var canMove = false
    if let canMoveItem = canMoveItem {
      canMove = canMoveItem(indexPath: indexPath)
    }
    return canMove
  }

  public func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
    if let moveItem = moveItem {
      moveItem(tableView: tableView, sourceIndexPath: sourceIndexPath, destinationIndexPath: destinationIndexPath)
    }
  }
}
