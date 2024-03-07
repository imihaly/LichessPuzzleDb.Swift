//
// ManagedTheme+CoreDataProperties.swift
//
// Created by Imre Mihaly on 2024.
//
// All rights reserved.
//

//

import Foundation
import CoreData


extension ManagedTheme {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ManagedTheme> {
        return NSFetchRequest<ManagedTheme>(entityName: "Theme")
    }

    @NSManaged public var name: String?
    @NSManaged public var puzzles: NSSet?

}

// MARK: Generated accessors for puzzles
extension ManagedTheme {

    @objc(addPuzzlesObject:)
    @NSManaged public func addToPuzzles(_ value: ManagedPuzzle)

    @objc(removePuzzlesObject:)
    @NSManaged public func removeFromPuzzles(_ value: ManagedPuzzle)

    @objc(addPuzzles:)
    @NSManaged public func addToPuzzles(_ values: NSSet)

    @objc(removePuzzles:)
    @NSManaged public func removeFromPuzzles(_ values: NSSet)

}
