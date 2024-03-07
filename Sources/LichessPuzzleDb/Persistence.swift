//
// Persistence.swift
//
// Created by Imre Mihaly on 2024.
//
// All rights reserved.
//


import Foundation
import CoreData
import ZIPFoundation

class PersistenceController {
    static let shared = PersistenceController()
    static let dbDirectory = "Lichess"
    static let dbName = "PuzzleDatabase"
    static let metadataName = "meta"
    
    enum MetadataKeys: String {
        case version
        case date
    }

    // MARK: - Core Data stack
    lazy var persistentContainer: NSPersistentContainer = {
        let bundle = Bundle.module
        if shouldInstall() {
            if !install() {
                logger.error("[PuzzleDb] Db installation failed.")
            }
        }
        
        guard let model = NSManagedObjectModel.mergedModel(from: [Bundle.module]) else {
            logger.error("[PuzzleDb] Cannot get the database model.")
            return NSPersistentContainer()
        }
        let container = NSPersistentContainer(name: Self.dbName, managedObjectModel: model)
        container.persistentStoreDescriptions.first!.url = getDatabaseURL()

        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                logger.error("[PuzzleDb] Could not read the database \(error), \(error.userInfo)")
            }

        })
        return container
    }()
    
    // MARK: - Data install/update
    
    /**
     Compares the version of the bundled data and the installed obe if any.
     */
    func shouldInstall() -> Bool {
        return getBundledVersion() != getInstalledVersion()
    }
    
    /**
     Installs the bundled database over the one installed, if any.
     */
    func install() -> Bool {
        guard let sourceUrl = Bundle.module.url(forResource: Self.dbName, withExtension: "zip") else {
            logger.error("[PuzzleDb] Failed to install: bundled db could not be found!")
            return false
        }
        let targetDirectory = getLichessDirectory()

        // remove all items from the target directory
        if FileManager.default.fileExists(atPath: targetDirectory.path) {
            do {
                try FileManager.default.removeItem(at: targetDirectory)
            } catch {
                logger.error("[PuzzleDb] Failed to install: could not remove the old version from: \(targetDirectory) with error: \(error)")
                return false
            }
        }
        
        // create the target directory
        do {
            try FileManager.default.createDirectory(at: targetDirectory, withIntermediateDirectories: true)
        } catch {
            logger.error("[PuzzleDb] Failed to install: could not create target directory: \(targetDirectory) with error: \(error)")
            return false
        }
        
        // unzip the database
        do {
            try FileManager.default.unzipItem(at: sourceUrl, to: targetDirectory)
        } catch {
            logger.error("[PuzzleDb] Failed to install: could not unzip the puzzle database with error: \(error).")
            return false
        }
        
        // copy version
        if let bundledMetadataUrl = Bundle.module.url(forResource: "\(Self.metadataName)", withExtension: "json") {
            do {
                try FileManager.default.copyItem(at: bundledMetadataUrl, to: getMetadataURL())
            } catch {
                logger.error("[PuzzleDb] Failed to install: could not copy bundled metadata with error:\(error).")
                return false
            }
        } else {
            logger.error("[PuzzleDb] Failed to install: could not locate bundled metadata.")
            return false
        }

        return true
    }
    
    // MARK: - helpers
    func getDocumentsDirectory()-> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }

    func getLichessDirectory() -> URL {
        return self.getDocumentsDirectory()
            .appendingPathComponent("\(Self.dbDirectory)")
    }
    
    func getDatabaseURL() -> URL {
        return getLichessDirectory()
            .appendingPathComponent("\(Self.dbName).sqlite")
    }
    
    func getMetadataURL() -> URL {
        return getLichessDirectory()
            .appendingPathComponent("\(Self.metadataName).json")
    }

    func getInstalledVersion() -> String? {
        guard let metadata = getInstalledMetadata() else {
            return nil
        }

        return metadata[MetadataKeys.version.rawValue]
    }
    
    func getBundledVersion() -> String? {
        guard let metadata = getBundledMetadata() else {
            return nil
        }
        
        return metadata[MetadataKeys.version.rawValue]
    }
    
    func getBundledMetadata() -> [String: String]? {
        guard let url = Bundle.module.url(forResource: "\(Self.metadataName)", withExtension: "json") else {
            
            logger.error("[PuzzleDb] Bundled data version is unrecoverable!")
            return nil
        }
        return getMetadata(from: url)
    }
    
    func getInstalledMetadata() -> [String: String]? {
        return getMetadata(from: getMetadataURL())
    }
    
    func getMetadata(from url: URL) -> [String: String]? {
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        
        guard let metadata = try? JSONDecoder().decode([String: String].self, from: data) else {
            return nil
        }
        
        return metadata
    }
}
