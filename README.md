# LichessPuzzleDb

Lichess [puzzle database](https://database.lichess.org/#puzzles) available as a Swift package.

## How to use it:
```swift

// install or update the db
if LichessPuzzleDb.installDbIfNeeded() {
    fatalError("Lichess database could not be installed.")
}

// fetch themes
let puzzleThemes = await LichessPuzzleDb.shared.themes()

// fetch the first 100 puzzle
let puzzleSet1 = await LichessPuzzleDb.shared.puzzles()

// fetch the first 1000 puzzle
let puzzleSet2 = await LichessPuzzleDb.shared.puzzles(pageSize: 1000)

// fetch the second 1000 puzzle
let puzzleSet3 = await LichessPuzzleDb.shared.puzzles(pageSize: 1000, offset: 1000)

// fetch 200 puzzles with rating between 1000 and 2000
let puzzleSet4 = await LichessPuzzleDb.shared.puzzles(ratingRange: 1000...2000, pageSize: 200)

// fetch 200 puzzles with rating between 1000 and 2000, with theme "mateIn1" or "mateIn2"
let puzzleSet4 = await LichessPuzzleDb.shared.puzzles(ratingRange: 1000...2000,themeFilter: .any(themes: Set(["mateIn1", "mateIn2"])), pageSize: 200) 

// fetch 200 puzzles with rating between 1000 and 2000, with theme "mateIn1" and "endgame"
let puzzleSet4 = await LichessPuzzleDb.shared.puzzles(ratingRange: 1000...2000,themeFilter: .all(themes: Set(["mateIn1", "endgame"])), pageSize: 200) 

```
