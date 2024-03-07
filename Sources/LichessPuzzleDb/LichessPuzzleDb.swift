import CoreData

public class LichessPuzzleDb {
    public enum SortOption {
        case rating(ascending: Bool)
        case id(ascending: Bool)
    }
    
    public enum ThemeFilter {
        case any(themes: Set<String>)
        case all(themes: Set<String>)
    }
    
    public static let shared = LichessPuzzleDb()
    let managedObjectContext = PersistenceController.shared.persistentContainer.newBackgroundContext()
    
    /**
     Installs or updates the db.
     Update may happen when the host app is installed with a newer PuzzleDb package.
     */
    public static func installDbIfNeeded() -> Bool {
        if PersistenceController.shared.shouldInstall() {
            return PersistenceController.shared.install()
        }
        return true
    }

    /**
     Fetches all available themes from the database.
     */
    public func themes() -> [String] {
        let fetchRequest = ManagedTheme.fetchRequest()
        do {
            let themes = try managedObjectContext.fetch(fetchRequest)
            return themes.map { $0.name! }
        } catch {
            logger.error("[PuzzleDb] Error fetching themes: \(error)")
        }
        return []
    }
    
    /**
     Fetches puzzles from the database.
     
     - parameter ratingRange: a closed range to filter results by rating
     - parameter themeFilter: filter results by theme
     - parameter sort: sorting options
     - parameter pageSize: the maximum count of the returned items, defaults to 100
     - parameter offset: together with `pageSize` makes paging through the results available
     */
    public func puzzles(ratingRange: ClosedRange<Int>? = nil,
                        themeFilter: ThemeFilter? = nil,
                        sort: [SortOption]? = nil,
                        pageSize: Int? = 100,
                        offset: Int? = nil
    ) async -> [Puzzle]
    {
     
        let fetchRequest = buildRequest(ratingRange: ratingRange,
                                        offset: offset,
                                        pageSize: pageSize,
                                        themeFilter: themeFilter)
        
        if let sortOptions = sort {
            fetchRequest.sortDescriptors = sortOptions.map { option in
                switch option {
                case .rating(ascending: let ascending):
                    return NSSortDescriptor(keyPath: \ManagedPuzzle.rating, ascending: ascending)
                case .id(ascending: let ascending):
                    return NSSortDescriptor(keyPath: \ManagedPuzzle.id, ascending: ascending)
                }
            }
        }
        
        return managedObjectContext.performAndWait {
            do {
                return try managedObjectContext.fetch(fetchRequest).map {
                    Puzzle(from: $0)
                }
            } catch {
                logger.error("[PuzzleDb] Error fetching puzzles: \(error)")
                return []
            }
        }
    }
    
    /**
     Counts the puzzles in the database matching the filtering options.
     
     - parameter ratingRange: a closed range to filter results by rating
     - parameter themeFilter: filter results by theme
     */
    public func countPuzzles(ratingRange: ClosedRange<Int>? = nil,
                             themeFilter: ThemeFilter? = nil) async -> Int
    {
        
        let fetchRequest = buildRequest(ratingRange: ratingRange,
                                        themeFilter: themeFilter)
        
        return managedObjectContext.performAndWait {
            do {
                return try managedObjectContext.count(for: fetchRequest)
            } catch {
                logger.error("[PuzzleDb] Error counting puzzles: \(error)")
                return 0
            }
        }
    }

    private func buildRequest(ratingRange: ClosedRange<Int>? = nil,
                        offset: Int? = nil,
                        pageSize: Int? = nil,
                        themeFilter: ThemeFilter? = nil) -> NSFetchRequest<ManagedPuzzle> {

        let fetchRequest = ManagedPuzzle.fetchRequest()
        var predicateFormats: [String] = []
        var predicateVariables: [Any] = []
        
        if let ratingRange = ratingRange {
            predicateFormats += ["rating >= %d AND rating <= %d"]
            predicateVariables += [ratingRange.lowerBound, ratingRange.upperBound]
        }
        
        if let themeFilter = themeFilter {
            switch themeFilter {
            case .any(themes: let themes):
                let subQueryCondition = Array(themes).map { theme in
                    "$theme.name == '\(theme)'"
                }.joined(separator: " OR ")
                let subQuery = "SUBQUERY(themes, $theme, \(subQueryCondition)).@count > 0"
                predicateFormats += [subQuery]

            case .all(themes: let themes):
                for theme in themes {
                    let subQueryCondition = "$theme.name == '\(theme)'"
                    let subQuery = "SUBQUERY(themes, $theme, \(subQueryCondition)).@count > 0"
                    predicateFormats += [subQuery]
                }
            }
        }
        
        if predicateFormats.count > 0 {
            let predicateFormat = predicateFormats.joined(separator: " AND ")
            fetchRequest.predicate = NSPredicate(format: predicateFormat, argumentArray: predicateVariables)
        }
        
        if let offset = offset {
            fetchRequest.fetchOffset = offset
        }
        
        if let pageSize = pageSize {
            fetchRequest.fetchLimit = pageSize
        }

        return fetchRequest
    }
}
