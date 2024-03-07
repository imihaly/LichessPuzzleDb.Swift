//
// File.swift
//
// Created by Imre Mihaly on 2024.
//
// All rights reserved.
//


import Foundation

/**
 A structure representing a puzzle.
 */
public struct Puzzle: Hashable {
    /**
     Lichess puzzle id, maybe used to refere to a puzzle across database updates.
     */
    public let id: String
    
    /**
     The FEN of the starting position.
     */
    public let fen: String
    
    /**
     The moves in UCI format.
     The puzzle should be presented fro the user by making the first move.
     */
    public let moves: [String]
    
    /**
     The estimated rating of the puzzle.
     */
    public let rating: Int
    
    /**
     The theme collection to categorize the puzzle.
     */
    public let themes: Set<String>
}

extension Puzzle {
    init(from puzzle: ManagedPuzzle) {
        self.id = puzzle.id ?? ""
        self.fen = puzzle.fen ?? ""
        self.moves = (puzzle.moves ?? "").components(separatedBy: .whitespaces)
        self.rating = Int(puzzle.rating)
        
        if let themes = puzzle.themes as? Set<ManagedTheme> {
            self.themes = Set( themes.compactMap { $0.name } )
        } else {
            self.themes = .init()
        }
    }
}
