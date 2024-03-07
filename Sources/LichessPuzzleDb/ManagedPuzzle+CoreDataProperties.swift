//
// ManagedPuzzle+CoreDataProperties.swift
//
// Created by Imre Mihaly on 2024.
//
// All rights reserved.
//

//

import Foundation
import CoreData


extension ManagedPuzzle {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ManagedPuzzle> {
        return NSFetchRequest<ManagedPuzzle>(entityName: "Puzzle")
    }

    @NSManaged public var fen: String?
    @NSManaged public var id: String?
    @NSManaged public var moves: String?
    @NSManaged public var popularity: Int32
    @NSManaged public var rating: Int32
    @NSManaged public var ratingDeviation: Int32
    @NSManaged public var themes: NSSet?

}

// MARK: Generated accessors for themes
extension ManagedPuzzle {

    @objc(addThemesObject:)
    @NSManaged public func addToThemes(_ value: ManagedTheme)

    @objc(removeThemesObject:)
    @NSManaged public func removeFromThemes(_ value: ManagedTheme)

    @objc(addThemes:)
    @NSManaged public func addToThemes(_ values: NSSet)

    @objc(removeThemes:)
    @NSManaged public func removeFromThemes(_ values: NSSet)

}
