//
//  ContentView.swift
//  Brainiak
//
//  Created by miguel corachea on 20/07/2025.
//

import SwiftUI

struct Game: Identifiable {
    let id = UUID()
    let name: String
    let icon: String // SF Symbol or asset name
    let rules: String
    let view: AnyView
}

// Placeholder views for each game
struct SudokuGameView: View {
    let onExit: () -> Void
    @State private var board: [[Int?]] = Array(repeating: Array(repeating: nil, count: 9), count: 9)
    @State private var selectedRow: Int? = nil
    @State private var selectedCol: Int? = nil
    @State private var showInvalidMove: Bool = false
    @State private var initialBoard: [[Int?]] = Array(repeating: Array(repeating: nil, count: 9), count: 9)
    
    func isEditable(row: Int, col: Int) -> Bool {
        initialBoard[row][col] == nil
    }
    
    func isValidMove(row: Int, col: Int, value: Int) -> Bool {
        for c in 0..<9 {
            if board[row][c] == value {
                return false
            }
        }
        for r in 0..<9 {
            if board[r][col] == value {
                return false
            }
        }
        let boxRow = (row / 3) * 3
        let boxCol = (col / 3) * 3
        for r in boxRow..<(boxRow+3) {
            for c in boxCol..<(boxCol+3) {
                if board[r][c] == value {
                    return false
                }
            }
        }
        return true
    }
    
    func generateRandomSudoku() -> [[Int?]] {
        // Simple random puzzle generator: shuffle a solved board and remove random cells
        var solved = solveSudoku()
        // Remove random cells for puzzle
        var puzzle = solved
        let cellsToRemove = Int.random(in: 40...55)
        var removed = 0
        while removed < cellsToRemove {
            let r = Int.random(in: 0..<9)
            let c = Int.random(in: 0..<9)
            if puzzle[r][c] != nil {
                puzzle[r][c] = nil
                removed += 1
            }
        }
        return puzzle
    }
    
    func solveSudoku() -> [[Int?]] {
        // Simple backtracking Sudoku solver to generate a full board
        var board = Array(repeating: Array(repeating: 0, count: 9), count: 9)
        func isSafe(_ row: Int, _ col: Int, _ num: Int) -> Bool {
            for x in 0..<9 { if board[row][x] == num || board[x][col] == num { return false } }
            let startRow = row / 3 * 3, startCol = col / 3 * 3
            for r in startRow..<(startRow+3) { for c in startCol..<(startCol+3) { if board[r][c] == num { return false } } }
            return true
        }
        func fill(_ row: Int, _ col: Int) -> Bool {
            if row == 9 { return true }
            let nextRow = col == 8 ? row + 1 : row
            let nextCol = col == 8 ? 0 : col + 1
            var nums = Array(1...9).shuffled()
            for num in nums {
                if isSafe(row, col, num) {
                    board[row][col] = num
                    if fill(nextRow, nextCol) { return true }
                    board[row][col] = 0
                }
            }
            return false
        }
        _ = fill(0, 0)
        return board.map { $0.map { $0 == 0 ? nil : $0 } }
    }
    
    func resetBoard() {
        let newPuzzle = generateRandomSudoku()
        initialBoard = newPuzzle
        board = newPuzzle
        selectedRow = nil
        selectedCol = nil
    }
    
    func isBoardComplete() -> Bool {
        for row in 0..<9 {
            for col in 0..<9 {
                if board[row][col] == nil {
                    return false
                }
            }
        }
        return true
    }
    
    func calculateDifficulty() -> String {
        var emptyCells = 0
        for row in 0..<9 {
            for col in 0..<9 {
                if initialBoard[row][col] == nil {
                    emptyCells += 1
                }
            }
        }
        
        if emptyCells >= 50 { return "Hard" }
        if emptyCells >= 40 { return "Medium" }
        return "Easy"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button(action: onExit) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
            Text("Sudoku")
                .font(.largeTitle.bold())
                .padding(.bottom, 8)
            Text("Tap a cell, then select a number to fill it.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom, 8)
            Spacer(minLength: 8)
            VStack(spacing: 2) {
                ForEach(0..<9, id: \ .self) { row in
                    HStack(spacing: 2) {
                        ForEach(0..<9, id: \ .self) { col in
                            let value = board[row][col]
                            ZStack {
                                Rectangle()
                                    .fill(selectedRow == row && selectedCol == col ? Color.accentColor.opacity(0.2) : Color.white)
                                    .border(Color.accentColor, width: (row % 3 == 2 && row != 8 ? 2 : 0.5) + (col % 3 == 2 && col != 8 ? 2 : 0.5))
                                Text(value != nil ? "\(value!)" : "")
                                    .font(.title2)
                                    .foregroundColor(isEditable(row: row, col: col) ? .primary : .gray)
                            }
                            .frame(width: 36, height: 36)
                            .onTapGesture {
                                if isEditable(row: row, col: col) {
                                    selectedRow = row
                                    selectedCol = col
                                }
                            }
                        }
                    }
                }
            }
            .background(Color.gray.opacity(0.2))
            .cornerRadius(12)
            .padding(.vertical, 12)
            Spacer(minLength: 8)
            if let row = selectedRow, let col = selectedCol, isEditable(row: row, col: col) {
                HStack(spacing: 8) {
                    ForEach(1...9, id: \ .self) { num in
                        Button(action: {
                            if isValidMove(row: row, col: col, value: num) {
                                board[row][col] = num
                                showInvalidMove = false
                                
                                // Check if puzzle is complete
                                if isBoardComplete() {
                                    let finalScore = GameScore(
                                        game: "Sudoku",
                                        score: 1000 - (calculateDifficulty() == "Hard" ? 0 : (calculateDifficulty() == "Medium" ? 200 : 400)),
                                        difficulty: calculateDifficulty()
                                    )
                                    ScoreManager.shared.addScore(finalScore)
                                }
                            } else {
                                showInvalidMove = true
                            }
                        }) {
                            Text("\(num)")
                                .font(.title3.bold())
                                .frame(width: 36, height: 36)
                                .background(Color.accentColor.opacity(0.15))
                                .foregroundColor(.accentColor)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.bottom, 8)
            }
            if showInvalidMove {
                Text("Invalid move!")
                    .foregroundColor(.red)
                    .font(.subheadline.bold())
                    .padding(.bottom, 4)
            }
            Button(action: resetBoard) {
                Text("New Game")
                    .font(.body.bold())
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.15))
                    .foregroundColor(.red)
                    .cornerRadius(10)
            }
            .padding(.top, 8)
            Spacer()
        }
        .padding()
        .onAppear {
            resetBoard()
        }
    }
}

struct Game2048View: View {
    let onExit: () -> Void
    @State private var board: [[Int]] = Array(repeating: Array(repeating: 0, count: 4), count: 4)
    @State private var score: Int = 0
    @State private var gameOver: Bool = false
    
    func emptyPositions() -> [(Int, Int)] {
        var positions: [(Int, Int)] = []
        for r in 0..<4 {
            for c in 0..<4 {
                if board[r][c] == 0 {
                    positions.append((r, c))
                }
            }
        }
        return positions
    }
    
    func addRandomTile() {
        let positions = emptyPositions()
        guard !positions.isEmpty else { return }
        let (r, c) = positions.randomElement()!
        board[r][c] = Int.random(in: 0..<10) == 0 ? 4 : 2
    }
    
    func resetGame() {
        board = Array(repeating: Array(repeating: 0, count: 4), count: 4)
        score = 0
        gameOver = false
        addRandomTile()
        addRandomTile()
    }
    
    func canMove() -> Bool {
        for r in 0..<4 {
            for c in 0..<4 {
                if board[r][c] == 0 { return true }
                if r < 3 && board[r][c] == board[r+1][c] { return true }
                if c < 3 && board[r][c] == board[r][c+1] { return true }
            }
        }
        return false
    }
    
    func move(_ direction: Direction) {
        var moved = false
        var merged = Array(repeating: Array(repeating: false, count: 4), count: 4)
        func slide(_ r: Int, _ c: Int, _ dr: Int, _ dc: Int) {
            guard board[r][c] != 0 else { return }
            var nr = r, nc = c
            while true {
                let tr = nr + dr, tc = nc + dc
                if tr < 0 || tr >= 4 || tc < 0 || tc >= 4 { break }
                if board[tr][tc] == 0 {
                    board[tr][tc] = board[nr][nc]
                    board[nr][nc] = 0
                    nr = tr; nc = tc
                    moved = true
                } else if board[tr][tc] == board[nr][nc] && !merged[tr][tc] && !merged[nr][nc] {
                    board[tr][tc] *= 2
                    score += board[tr][tc]
                    board[nr][nc] = 0
                    merged[tr][tc] = true
                    moved = true
                    break
                } else {
                    break
                }
            }
        }
        switch direction {
        case .up:
            for c in 0..<4 {
                for r in 1..<4 {
                    slide(r, c, -1, 0)
                }
            }
        case .down:
            for c in 0..<4 {
                for r in (0..<3).reversed() {
                    slide(r, c, 1, 0)
                }
            }
        case .left:
            for r in 0..<4 {
                for c in 1..<4 {
                    slide(r, c, 0, -1)
                }
            }
        case .right:
            for r in 0..<4 {
                for c in (0..<3).reversed() {
                    slide(r, c, 0, 1)
                }
            }
        }
        if moved {
            addRandomTile()
            if !canMove() {
                gameOver = true
                
                // Save the score
                let finalScore = GameScore(
                    game: "2048",
                    score: score,
                    difficulty: score >= 2048 ? "Hard" : (score >= 1024 ? "Medium" : "Easy")
                )
                ScoreManager.shared.addScore(finalScore)
            }
        }
    }
    
    enum Direction { case up, down, left, right }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button(action: onExit) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
            Text("2048")
                .font(.largeTitle.bold())
                .padding(.bottom, 8)
            Text("Swipe to move tiles. Merge to reach 2048!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom, 8)
            HStack {
                Text("Score: \(score)")
                    .font(.headline)
                    .padding(.horizontal)
                Spacer()
                Button(action: resetGame) {
                    Text("New Game")
                        .font(.body.bold())
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color.accentColor.opacity(0.15))
                        .foregroundColor(.accentColor)
                        .cornerRadius(8)
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 8)
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.2))
                VStack(spacing: 8) {
                    ForEach(0..<4, id: \ .self) { r in
                        HStack(spacing: 8) {
                            ForEach(0..<4, id: \ .self) { c in
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(tileColor(board[r][c]))
                                    if board[r][c] != 0 {
                                        Text("\(board[r][c])")
                                            .font(.title2.bold())
                                            .foregroundColor(board[r][c] <= 4 ? .primary : .white)
                                    }
                                }
                                .frame(width: 60, height: 60)
                            }
                        }
                    }
                }
                .padding(12)
            }
            .frame(width: 280, height: 280)
            .gesture(DragGesture(minimumDistance: 24)
                .onEnded { value in
                    let horizontal = value.translation.width
                    let vertical = value.translation.height
                    if abs(horizontal) > abs(vertical) {
                        if horizontal > 0 { move(.right) } else { move(.left) }
                    } else {
                        if vertical > 0 { move(.down) } else { move(.up) }
                    }
                }
            )
            if gameOver {
                Text("Game Over!")
                    .font(.title2.bold())
                    .foregroundColor(.red)
                    .padding(.top, 12)
            }
            Spacer()
        }
        .padding()
        .onAppear {
            resetGame()
        }
    }
    
    func tileColor(_ value: Int) -> Color {
        switch value {
        case 0: return Color.gray.opacity(0.3)
        case 2: return Color(red: 0.93, green: 0.89, blue: 0.85)
        case 4: return Color(red: 0.93, green: 0.87, blue: 0.78)
        case 8: return Color(red: 0.95, green: 0.69, blue: 0.47)
        case 16: return Color(red: 0.96, green: 0.58, blue: 0.39)
        case 32: return Color(red: 0.96, green: 0.48, blue: 0.37)
        case 64: return Color(red: 0.96, green: 0.36, blue: 0.23)
        case 128: return Color(red: 0.93, green: 0.81, blue: 0.45)
        case 256: return Color(red: 0.93, green: 0.80, blue: 0.38)
        case 512: return Color(red: 0.93, green: 0.78, blue: 0.31)
        case 1024: return Color(red: 0.93, green: 0.76, blue: 0.25)
        case 2048: return Color(red: 0.93, green: 0.75, blue: 0.19)
        default: return Color(.systemGray)
        }
    }
}

struct KakuroGameView: View {
    let onExit: () -> Void
    // 0 = black cell, nil = input cell, (across, down) = clue cell
    typealias KakuroCell = (across: Int?, down: Int?)?
    let grid: [[KakuroCell]] = [
        [nil, (nil, nil), (nil, 16), (nil, 24), nil],
        [(23, nil), nil, nil, nil, (17, nil)],
        [(30, nil), nil, nil, nil, (27, nil)],
        [nil, (12, nil), nil, nil, nil],
        [nil, nil, (nil, nil), (nil, nil), nil]
    ]
    @State private var values: [[Int?]] = Array(repeating: Array(repeating: nil, count: 5), count: 5)
    @State private var selected: SelectedCell? = nil
    @State private var showResult: Bool = false
    @State private var isCorrect: Bool = false
    
    func isInputCell(row: Int, col: Int) -> Bool {
        grid[row][col] == nil
    }
    func isClueCell(row: Int, col: Int) -> Bool {
        grid[row][col] != nil && (grid[row][col]?.across != nil || grid[row][col]?.down != nil)
    }
    func clueText(_ cell: KakuroCell) -> String {
        var text = ""
        if let across = cell?.across { text += "→\(across) " }
        if let down = cell?.down { text += "↓\(down)" }
        return text.trimmingCharacters(in: .whitespaces)
    }
    func checkSolution() -> Bool {
        // Check across clues
        for row in 0..<5 {
            var col = 0
            while col < 5 {
                if let clue = grid[row][col], let across = clue.across {
                    var sum = 0
                    var nums: [Int] = []
                    var c = col + 1
                    while c < 5 && isInputCell(row: row, col: c) {
                        if let v = values[row][c] { sum += v; nums.append(v) } else { return false }
                        c += 1
                    }
                    if sum != across || Set(nums).count != nums.count { return false }
                }
                col += 1
            }
        }
        // Check down clues
        for col in 0..<5 {
            var row = 0
            while row < 5 {
                if let clue = grid[row][col], let down = clue.down {
                    var sum = 0
                    var nums: [Int] = []
                    var r = row + 1
                    while r < 5 && isInputCell(row: r, col: col) {
                        if let v = values[r][col] { sum += v; nums.append(v) } else { return false }
                        r += 1
                    }
                    if sum != down || Set(nums).count != nums.count { return false }
                }
                row += 1
            }
        }
        return true
    }
    func clearBoard() {
        values = Array(repeating: Array(repeating: nil, count: 5), count: 5)
        selected = nil
        showResult = false
    }
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button(action: onExit) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
            Text("Kakuro")
                .font(.largeTitle.bold())
                .padding(.bottom, 8)
            Text("Fill the white cells so each group adds up to the clue. No repeats in a group.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom, 8)
            Spacer(minLength: 8)
            VStack(spacing: 2) {
                ForEach(0..<5, id: \ .self) { row in
                    HStack(spacing: 2) {
                        ForEach(0..<5, id: \ .self) { col in
                            ZStack {
                                if isInputCell(row: row, col: col) {
                                    Rectangle()
                                        .fill(selected?.row == row && selected?.col == col ? Color.accentColor.opacity(0.2) : Color.white)
                                        .border(Color.accentColor, width: 1)
                                    Text(values[row][col] != nil ? "\(values[row][col]!)" : "")
                                        .font(.title2)
                                        .foregroundColor(.primary)
                                } else if isClueCell(row: row, col: col) {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .border(Color.accentColor, width: 1)
                                    Text(clueText(grid[row][col]))
                                        .font(.caption2)
                                        .foregroundColor(.accentColor)
                                        .multilineTextAlignment(.center)
                                        .padding(2)
                                } else {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .border(Color.gray.opacity(0.3), width: 1)
                                }
                            }
                            .frame(width: 44, height: 44)
                            .onTapGesture {
                                if isInputCell(row: row, col: col) {
                                    selected = SelectedCell(row: row, col: col)
                                }
                            }
                        }
                    }
                }
            }
            .cornerRadius(10)
            .padding(.vertical, 12)
            Spacer(minLength: 8)
            if let sel = selected, isInputCell(row: sel.row, col: sel.col) {
                HStack(spacing: 8) {
                    ForEach(1...9, id: \ .self) { num in
                        Button(action: {
                            values[sel.row][sel.col] = num
                        }) {
                            Text("\(num)")
                                .font(.title3.bold())
                                .frame(width: 36, height: 36)
                                .background(Color.accentColor.opacity(0.15))
                                .foregroundColor(.accentColor)
                                .cornerRadius(8)
                        }
                    }
                    Button(action: { values[sel.row][sel.col] = nil }) {
                        Image(systemName: "delete.left")
                            .font(.title3)
                            .frame(width: 36, height: 36)
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.red)
                            .cornerRadius(8)
                    }
                }
                .padding(.bottom, 8)
            }
            HStack(spacing: 16) {
                Button(action: {
                    isCorrect = checkSolution()
                    showResult = true
                }) {
                    Text("Check")
                        .font(.body.bold())
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                        .background(Color.accentColor.opacity(0.15))
                        .foregroundColor(.accentColor)
                        .cornerRadius(10)
                }
                Button(action: clearBoard) {
                    Text("New Puzzle")
                        .font(.body.bold())
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.15))
                        .foregroundColor(.red)
                        .cornerRadius(10)
                }
            }
            .padding(.top, 8)
            if showResult {
                Text(isCorrect ? "Correct!" : "Not solved yet.")
                    .foregroundColor(isCorrect ? .green : .red)
                    .font(.headline)
                    .padding(.top, 4)
            }
            Spacer()
        }
        .padding()
        .onAppear {
            clearBoard()
        }
    }
}

struct KenKenGameView: View {
    let onExit: () -> Void
    // Cage structure: (cells: [(row, col)], operation: String, target: Int)
    typealias Cage = (cells: [(Int, Int)], operation: String, target: Int)
    @State private var cages: [Cage] = []
    @State private var board: [[Int?]] = Array(repeating: Array(repeating: nil, count: 4), count: 4)
    @State private var selected: SelectedCell? = nil
    @State private var showResult: Bool = false
    @State private var isCorrect: Bool = false
    
    func generateRandomPuzzle() -> [Cage] {
        var newCages: [Cage] = []
        var usedCells: Set<CellCoordinate> = []
        
        // Generate random cage configurations
        let cageConfigs = [
            [(0, 0), (0, 1)], [(0, 2)], [(0, 3)],
            [(1, 0)], [(1, 1), (1, 2)], [(1, 3)],
            [(2, 0), (3, 0)], [(2, 1), (2, 2), (2, 3)], [(3, 1)], [(3, 2), (3, 3)]
        ].shuffled()
        
        for config in cageConfigs {
            // Check if any cell in this config is already used
            let configSet = Set(config.map { CellCoordinate(row: $0.0, col: $0.1) })
            if configSet.isDisjoint(with: usedCells) {
                let operation = ["+", "×", "−", "÷"].randomElement() ?? "+"
                let target = generateTarget(for: config, operation: operation)
                newCages.append((cells: config, operation: operation, target: target))
                usedCells.formUnion(configSet)
            }
        }
        
        return newCages
    }
    
    func generateTarget(for cells: [(Int, Int)], operation: String) -> Int {
        switch operation {
        case "+":
            return Int.random(in: 3...10)
        case "×":
            return Int.random(in: 2...12)
        case "−":
            return Int.random(in: 1...3)
        case "÷":
            return Int.random(in: 2...4)
        default:
            return Int.random(in: 1...4)
        }
    }
    
    func getCage(for row: Int, col: Int) -> Cage? {
        return cages.first { cage in
            cage.cells.contains { $0.0 == row && $0.1 == col }
        }
    }
    
    func cageText(for row: Int, col: Int) -> String {
        guard let cage = getCage(for: row, col: col) else { return "" }
        // Only show operation and target for the first cell in the cage
        if cage.cells.first?.0 == row && cage.cells.first?.1 == col {
            return "\(cage.target)\(cage.operation)"
        }
        return ""
    }
    
    func checkSolution() -> Bool {
        // Check rows and columns for duplicates
        for row in 0..<4 {
            var rowNums: [Int] = []
            var colNums: [Int] = []
            for col in 0..<4 {
                if let val = board[row][col] { rowNums.append(val) }
                if let val = board[col][row] { colNums.append(val) }
            }
            if Set(rowNums).count != rowNums.count || Set(colNums).count != colNums.count {
                return false
            }
        }
        
        // Check cages
        for cage in cages {
            var cageValues: [Int] = []
            for (row, col) in cage.cells {
                if let val = board[row][col] {
                    cageValues.append(val)
                } else {
                    return false // Incomplete cage
                }
            }
            
            if !checkCage(cageValues, operation: cage.operation, target: cage.target) {
                return false
            }
        }
        return true
    }
    
    func checkCage(_ values: [Int], operation: String, target: Int) -> Bool {
        switch operation {
        case "+":
            return values.reduce(0, +) == target
        case "×":
            return values.reduce(1, *) == target
        case "−":
            return values.count == 2 && abs(values[0] - values[1]) == target
        case "÷":
            return values.count == 2 && (values[0] / values[1] == target || values[1] / values[0] == target)
        default:
            return values.count == 1 && values[0] == target
        }
    }
    
    func clearBoard() {
        cages = generateRandomPuzzle()
        board = Array(repeating: Array(repeating: nil, count: 4), count: 4)
        selected = nil
        showResult = false
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button(action: onExit) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
            Text("KenKen")
                .font(.largeTitle.bold())
                .padding(.bottom, 8)
            Text("Fill each cage so the numbers combine with the operation to reach the target.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom, 8)
            Spacer(minLength: 8)
            VStack(spacing: 2) {
                ForEach(0..<4, id: \ .self) { row in
                    HStack(spacing: 2) {
                        ForEach(0..<4, id: \ .self) { col in
                            ZStack {
                                Rectangle()
                                    .fill(selected?.row == row && selected?.col == col ? Color.accentColor.opacity(0.2) : Color.white)
                                    .border(Color.accentColor, width: 1)
                                VStack(spacing: 2) {
                                    Text(cageText(for: row, col: col))
                                        .font(.caption2)
                                        .foregroundColor(.accentColor)
                                    Text(board[row][col] != nil ? "\(board[row][col]!)" : "")
                                        .font(.title2)
                                        .foregroundColor(.primary)
                                }
                            }
                            .frame(width: 60, height: 60)
                            .onTapGesture {
                                selected = SelectedCell(row: row, col: col)
                            }
                        }
                    }
                }
            }
            .cornerRadius(10)
            .padding(.vertical, 12)
            Spacer(minLength: 8)
            if let sel = selected {
                HStack(spacing: 8) {
                    ForEach(1...4, id: \ .self) { num in
                        Button(action: {
                            board[sel.row][sel.col] = num
                        }) {
                            Text("\(num)")
                                .font(.title3.bold())
                                .frame(width: 36, height: 36)
                                .background(Color.accentColor.opacity(0.15))
                                .foregroundColor(.accentColor)
                                .cornerRadius(8)
                        }
                    }
                    Button(action: { board[sel.row][sel.col] = nil }) {
                        Image(systemName: "delete.left")
                            .font(.title3)
                            .frame(width: 36, height: 36)
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.red)
                            .cornerRadius(8)
                    }
                }
                .padding(.bottom, 8)
            }
            HStack(spacing: 16) {
                Button(action: {
                    isCorrect = checkSolution()
                    showResult = true
                }) {
                    Text("Check")
                        .font(.body.bold())
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                        .background(Color.accentColor.opacity(0.15))
                        .foregroundColor(.accentColor)
                        .cornerRadius(10)
                }
                Button(action: clearBoard) {
                    Text("New Puzzle")
                        .font(.body.bold())
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.15))
                        .foregroundColor(.red)
                        .cornerRadius(10)
                }
            }
            .padding(.top, 8)
            if showResult {
                Text(isCorrect ? "Correct!" : "Not solved yet.")
                    .foregroundColor(isCorrect ? .green : .red)
                    .font(.headline)
                    .padding(.top, 4)
            }
            Spacer()
        }
        .padding()
        .onAppear {
            clearBoard()
        }
    }
}

struct CalcudokuGameView: View {
    let onExit: () -> Void
    // Cage structure: (cells: [(row, col)], operation: String, target: Int)
    typealias Cage = (cells: [(Int, Int)], operation: String, target: Int)
    @State private var cages: [Cage] = []
    @State private var board: [[Int?]] = Array(repeating: Array(repeating: nil, count: 4), count: 4)
    @State private var selected: SelectedCell? = nil
    @State private var showResult: Bool = false
    @State private var isCorrect: Bool = false
    
    func generateRandomPuzzle() -> [Cage] {
        var newCages: [Cage] = []
        var usedCells: Set<CellCoordinate> = []
        
        // Generate random cage configurations
        let cageConfigs = [
            [(0, 0), (0, 1)], [(0, 2)], [(0, 3)],
            [(1, 0)], [(1, 1), (1, 2)], [(1, 3)],
            [(2, 0), (3, 0)], [(2, 1), (2, 2), (2, 3)], [(3, 1)], [(3, 2), (3, 3)]
        ].shuffled()
        
        for config in cageConfigs {
            // Check if any cell in this config is already used
            let configSet = Set(config.map { CellCoordinate(row: $0.0, col: $0.1) })
            if configSet.isDisjoint(with: usedCells) {
                let operation = ["+", "×", "−", "÷"].randomElement() ?? "+"
                let target = generateTarget(for: config, operation: operation)
                newCages.append((cells: config, operation: operation, target: target))
                usedCells.formUnion(configSet)
            }
        }
        
        return newCages
    }
    
    func generateTarget(for cells: [(Int, Int)], operation: String) -> Int {
        switch operation {
        case "+":
            return Int.random(in: 3...10)
        case "×":
            return Int.random(in: 2...12)
        case "−":
            return Int.random(in: 1...3)
        case "÷":
            return Int.random(in: 2...4)
        default:
            return Int.random(in: 1...4)
        }
    }
    
    func getCage(for row: Int, col: Int) -> Cage? {
        return cages.first { cage in
            cage.cells.contains { $0.0 == row && $0.1 == col }
        }
    }
    
    func cageText(for row: Int, col: Int) -> String {
        guard let cage = getCage(for: row, col: col) else { return "" }
        // Only show operation and target for the first cell in the cage
        if cage.cells.first?.0 == row && cage.cells.first?.1 == col {
            return "\(cage.target)\(cage.operation)"
        }
        return ""
    }
    
    func checkSolution() -> Bool {
        // Check rows and columns for duplicates
        for row in 0..<4 {
            var rowNums: [Int] = []
            var colNums: [Int] = []
            for col in 0..<4 {
                if let val = board[row][col] { rowNums.append(val) }
                if let val = board[col][row] { colNums.append(val) }
            }
            if Set(rowNums).count != rowNums.count || Set(colNums).count != colNums.count {
                return false
            }
        }
        
        // Check cages
        for cage in cages {
            var cageValues: [Int] = []
            for (row, col) in cage.cells {
                if let val = board[row][col] {
                    cageValues.append(val)
                } else {
                    return false // Incomplete cage
                }
            }
            
            if !checkCage(cageValues, operation: cage.operation, target: cage.target) {
                return false
            }
        }
        return true
    }
    
    func checkCage(_ values: [Int], operation: String, target: Int) -> Bool {
        switch operation {
        case "+":
            return values.reduce(0, +) == target
        case "×":
            return values.reduce(1, *) == target
        case "−":
            return values.count == 2 && abs(values[0] - values[1]) == target
        case "÷":
            return values.count == 2 && (values[0] / values[1] == target || values[1] / values[0] == target)
        default:
            return values.count == 1 && values[0] == target
        }
    }
    
    func clearBoard() {
        cages = generateRandomPuzzle()
        board = Array(repeating: Array(repeating: nil, count: 4), count: 4)
        selected = nil
        showResult = false
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button(action: onExit) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
            Text("Calcudoku")
                .font(.largeTitle.bold())
                .padding(.bottom, 8)
            Text("Fill each cage so the numbers combine with the operation to reach the target.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom, 8)
            Spacer(minLength: 8)
            VStack(spacing: 2) {
                ForEach(0..<4, id: \.self) { row in
                    HStack(spacing: 2) {
                        ForEach(0..<4, id: \.self) { col in
                            ZStack {
                                Rectangle()
                                    .fill(selected?.row == row && selected?.col == col ? Color.accentColor.opacity(0.2) : Color.white)
                                    .border(Color.accentColor, width: 1)
                                VStack(spacing: 2) {
                                    Text(cageText(for: row, col: col))
                                        .font(.caption2)
                                        .foregroundColor(.accentColor)
                                    Text(board[row][col] != nil ? "\(board[row][col]!)" : "")
                                        .font(.title2)
                                        .foregroundColor(.primary)
                                }
                            }
                            .frame(width: 60, height: 60)
                            .onTapGesture {
                                selected = SelectedCell(row: row, col: col)
                            }
                        }
                    }
                }
            }
            .cornerRadius(10)
            .padding(.vertical, 12)
            Spacer(minLength: 8)
            if let sel = selected {
                HStack(spacing: 8) {
                    ForEach(1...4, id: \.self) { num in
                        Button(action: {
                            board[sel.row][sel.col] = num
                        }) {
                            Text("\(num)")
                                .font(.title3.bold())
                                .frame(width: 36, height: 36)
                                .background(Color.accentColor.opacity(0.15))
                                .foregroundColor(.accentColor)
                                .cornerRadius(8)
                        }
                    }
                    Button(action: { board[sel.row][sel.col] = nil }) {
                        Image(systemName: "delete.left")
                            .font(.title3)
                            .frame(width: 36, height: 36)
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.red)
                            .cornerRadius(8)
                    }
                }
                .padding(.bottom, 8)
            }
            HStack(spacing: 16) {
                Button(action: {
                    isCorrect = checkSolution()
                    showResult = true
                }) {
                    Text("Check")
                        .font(.body.bold())
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                        .background(Color.accentColor.opacity(0.15))
                        .foregroundColor(.accentColor)
                        .cornerRadius(10)
                }
                Button(action: clearBoard) {
                    Text("New Puzzle")
                        .font(.body.bold())
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.15))
                        .foregroundColor(.red)
                        .cornerRadius(10)
                }
            }
            .padding(.top, 8)
            if showResult {
                Text(isCorrect ? "Correct!" : "Not solved yet.")
                    .foregroundColor(isCorrect ? .green : .red)
                    .font(.headline)
                    .padding(.top, 4)
            }
            Spacer()
        }
        .padding()
        .onAppear {
            clearBoard()
        }
    }
}

struct ColorMatchGameView: View {
    let onExit: () -> Void
    @State private var board: [[Int]] = []
    @State private var score: Int = 0
    @State private var moves: Int = 0
    @State private var gameOver: Bool = false
    @State private var selectedTile: TileCoordinate? = nil
    
    struct TileCoordinate: Hashable {
        let row: Int
        let col: Int
    }
    @State private var showWinMessage: Bool = false
    
    let gridSize = 6
    let colors = [1, 2, 3, 4, 5, 6] // Different colors represented by numbers
    
    func generateBoard() {
        board = Array(repeating: Array(repeating: 0, count: gridSize), count: gridSize)
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                board[row][col] = colors.randomElement() ?? 1
            }
        }
    }
    
    func getColor(_ value: Int) -> Color {
        switch value {
        case 1: return .red
        case 2: return .blue
        case 3: return .green
        case 4: return .yellow
        case 5: return .purple
        case 6: return .orange
        default: return .gray
        }
    }
    
    func selectTile(row: Int, col: Int) {
        if selectedTile == nil {
            selectedTile = TileCoordinate(row: row, col: col)
        } else {
            let firstTile = selectedTile!
            let secondTile = TileCoordinate(row: row, col: col)
            
            // Check if tiles are adjacent
            let rowDiff = abs(firstTile.row - secondTile.row)
            let colDiff = abs(firstTile.col - secondTile.col)
            
            if (rowDiff == 1 && colDiff == 0) || (rowDiff == 0 && colDiff == 1) {
                // Swap tiles
                let temp = board[firstTile.row][firstTile.col]
                board[firstTile.row][firstTile.col] = board[secondTile.row][secondTile.col]
                board[secondTile.row][secondTile.col] = temp
                
                moves += 1
                
                // Check for matches
                let matches = checkMatches()
                if matches > 0 {
                    score += matches * 10
                    removeMatches()
                    fillBoard()
                }
                
                // Check if board is solved (all same color)
                if isBoardSolved() {
                    gameOver = true
                    showWinMessage = true
                    
                    // Save the score
                    let finalScore = GameScore(
                        game: "Color Match",
                        score: score,
                        difficulty: moves <= 20 ? "Easy" : (moves <= 40 ? "Medium" : "Hard")
                    )
                    ScoreManager.shared.addScore(finalScore)
                }
            }
            
            selectedTile = nil
        }
    }
    
    func checkMatches() -> Int {
        var matchCount = 0
        
        // Check rows
        for row in 0..<gridSize {
            for col in 0..<(gridSize-2) {
                if board[row][col] == board[row][col+1] && board[row][col] == board[row][col+2] {
                    matchCount += 1
                }
            }
        }
        
        // Check columns
        for row in 0..<(gridSize-2) {
            for col in 0..<gridSize {
                if board[row][col] == board[row+1][col] && board[row][col] == board[row+2][col] {
                    matchCount += 1
                }
            }
        }
        
        return matchCount
    }
    
    func removeMatches() {
        // Mark matched tiles for removal
        var toRemove: Set<TileCoordinate> = []
        
        // Check rows
        for row in 0..<gridSize {
            for col in 0..<(gridSize-2) {
                if board[row][col] == board[row][col+1] && board[row][col] == board[row][col+2] {
                    toRemove.insert(TileCoordinate(row: row, col: col))
                    toRemove.insert(TileCoordinate(row: row, col: col+1))
                    toRemove.insert(TileCoordinate(row: row, col: col+2))
                }
            }
        }
        
        // Check columns
        for row in 0..<(gridSize-2) {
            for col in 0..<gridSize {
                if board[row][col] == board[row+1][col] && board[row][col] == board[row+2][col] {
                    toRemove.insert(TileCoordinate(row: row, col: col))
                    toRemove.insert(TileCoordinate(row: row+1, col: col))
                    toRemove.insert(TileCoordinate(row: row+2, col: col))
                }
            }
        }
        
        // Remove matched tiles
        for tile in toRemove {
            board[tile.row][tile.col] = 0
        }
    }
    
    func fillBoard() {
        // Fill empty spaces with new colors
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                if board[row][col] == 0 {
                    board[row][col] = colors.randomElement() ?? 1
                }
            }
        }
    }
    
    func isBoardSolved() -> Bool {
        let firstColor = board[0][0]
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                if board[row][col] != firstColor {
                    return false
                }
            }
        }
        return true
    }
    
    func resetGame() {
        score = 0
        moves = 0
        gameOver = false
        showWinMessage = false
        selectedTile = nil
        generateBoard()
    }
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Spacer()
                Button(action: onExit) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
            
            Text("Color Match")
                .font(.largeTitle.bold())
                .padding(.bottom, 8)
            
            Text("Match 3 or more same colors to clear them!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom, 8)
            
            HStack(spacing: 30) {
                VStack {
                    Text("Score")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(score)")
                        .font(.title2.bold())
                }
                
                VStack {
                    Text("Moves")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(moves)")
                        .font(.title2.bold())
                }
            }
            .padding(.bottom, 20)
            
            if gameOver {
                VStack(spacing: 16) {
                    if showWinMessage {
                        Text("🎉 Congratulations! 🎉")
                            .font(.title2.bold())
                            .foregroundColor(.green)
                        Text("You solved the puzzle!")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Final Score: \(score)")
                            .font(.title3)
                            .foregroundColor(.primary)
                    } else {
                        Text("Game Over!")
                            .font(.title2.bold())
                            .foregroundColor(.red)
                    }
                    
                    Button(action: resetGame) {
                        Text("Play Again")
                            .font(.body.bold())
                            .padding(.horizontal, 24)
                            .padding(.vertical, 8)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            } else {
                VStack(spacing: 8) {
                    ForEach(0..<gridSize, id: \.self) { row in
                        HStack(spacing: 8) {
                            ForEach(0..<gridSize, id: \.self) { col in
                                                let isSelected = selectedTile?.row == row && selectedTile?.col == col
                let isAdjacent = selectedTile != nil && 
                    ((abs(selectedTile!.row - row) == 1 && selectedTile!.col == col) ||
                     (abs(selectedTile!.col - col) == 1 && selectedTile!.row == row))
                                
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(getColor(board[row][col]))
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(isSelected ? Color.white : (isAdjacent ? Color.yellow : Color.clear), lineWidth: 3)
                                    )
                                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                                    .onTapGesture {
                                        selectTile(row: row, col: col)
                                    }
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .padding()
        .onAppear {
            if board.isEmpty {
                generateBoard()
            }
        }
    }
}

struct FutoshikiGameView: View {
    let onExit: () -> Void
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: onExit) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
            Spacer()
            Text("Futoshiki Game Coming Soon!")
                .font(.title)
                .padding()
            Spacer()
        }
    }
}

struct NumbrixGameView: View {
    let onExit: () -> Void
    @State private var board: [[Int?]] = Array(repeating: Array(repeating: nil, count: 5), count: 5)
    @State private var selected: SelectedCell? = nil
    @State private var showResult: Bool = false
    @State private var isCorrect: Bool = false
    
    func generatePuzzle() -> [[Int?]] {
        // Generate random puzzle templates
        let puzzleTemplates: [[[Int?]]] = [
            // Template 1: Original
            [
                [1, 2, 3, 4, 5],
                [nil, nil, nil, nil, 6],
                [nil, nil, nil, nil, 7],
                [nil, nil, nil, nil, 8],
                [25, 24, 23, 22, 9]
            ],
            // Template 2: Spiral pattern
            [
                [1, 2, 3, 4, 5],
                [16, nil, nil, nil, 6],
                [15, nil, nil, nil, 7],
                [14, nil, nil, nil, 8],
                [13, 12, 11, 10, 9]
            ],
            // Template 3: Corner pattern
            [
                [1, nil, nil, nil, 5],
                [nil, 2, nil, 4, nil],
                [nil, nil, 3, nil, nil],
                [nil, 22, nil, 24, nil],
                [21, nil, nil, nil, 25]
            ],
            // Template 4: Cross pattern
            [
                [1, 2, 3, 4, 5],
                [10, nil, nil, nil, 6],
                [9, nil, nil, nil, 7],
                [8, nil, nil, nil, 8],
                [25, 24, 23, 22, 9]
            ],
            // Template 5: Diagonal pattern
            [
                [1, nil, nil, nil, 5],
                [nil, 2, nil, 4, nil],
                [nil, nil, 3, nil, nil],
                [nil, 22, nil, 24, nil],
                [21, nil, nil, nil, 25]
            ]
        ]
        
        // Randomly select a template
        let randomTemplate = puzzleTemplates.randomElement() ?? puzzleTemplates[0]
        
        // Optionally add some randomization to the template
        var puzzle = randomTemplate
        let randomizeChance = 0.3 // 30% chance to randomize some cells
        
        for row in 0..<5 {
            for col in 0..<5 {
                if puzzle[row][col] != nil && Double.random(in: 0...1) < randomizeChance {
                    // 50% chance to clear this cell
                    if Double.random(in: 0...1) < 0.5 {
                        puzzle[row][col] = nil
                    }
                }
            }
        }
        
        return puzzle
    }
    
    func isValidMove(row: Int, col: Int, value: Int) -> Bool {
        // Check if the value is within range
        if value < 1 || value > 25 { return false }
        
        // Check if the value is already used
        for r in 0..<5 {
            for c in 0..<5 {
                if board[r][c] == value && (r != row || c != col) {
                    return false
                }
            }
        }
        
        // Check if the value is adjacent to the previous or next number
        let prevValue = value - 1
        let nextValue = value + 1
        
        var hasAdjacentPrev = false
        var hasAdjacentNext = false
        
        let directions = [(0, 1), (1, 0), (0, -1), (-1, 0)]
        for (dr, dc) in directions {
            let nr = row + dr
            let nc = col + dc
            if nr >= 0 && nr < 5 && nc >= 0 && nc < 5 {
                if let cellValue = board[nr][nc] {
                    if cellValue == prevValue {
                        hasAdjacentPrev = true
                    }
                    if cellValue == nextValue {
                        hasAdjacentNext = true
                    }
                }
            }
        }
        
        // Must be adjacent to either previous or next number (or both)
        return hasAdjacentPrev || hasAdjacentNext
    }
    
    func checkSolution() -> Bool {
        // Check if all cells are filled
        for row in 0..<5 {
            for col in 0..<5 {
                if board[row][col] == nil {
                    return false
                }
            }
        }
        
        // Check if numbers form a connected path from 1 to 25
        for value in 1..<25 {
            var found = false
            var nextFound = false
            
            // Find current value
            var currentRow = 0, currentCol = 0
            for row in 0..<5 {
                for col in 0..<5 {
                    if board[row][col] == value {
                        currentRow = row
                        currentCol = col
                        found = true
                        break
                    }
                }
                if found { break }
            }
            
            if !found { return false }
            
            // Check if next value is adjacent
            let directions = [(0, 1), (1, 0), (0, -1), (-1, 0)]
            for (dr, dc) in directions {
                let nr = currentRow + dr
                let nc = currentCol + dc
                if nr >= 0 && nr < 5 && nc >= 0 && nc < 5 {
                    if board[nr][nc] == value + 1 {
                        nextFound = true
                        break
                    }
                }
            }
            
            if !nextFound { return false }
        }
        
        return true
    }
    
    func clearBoard() {
        board = generatePuzzle()
        selected = nil
        showResult = false
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button(action: onExit) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
            Text("Numbrix")
                .font(.largeTitle.bold())
                .padding(.bottom, 8)
            Text("Fill the grid with numbers 1-25 so consecutive numbers are adjacent.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom, 8)
            Spacer(minLength: 8)
            VStack(spacing: 2) {
                ForEach(0..<5, id: \.self) { row in
                    HStack(spacing: 2) {
                        ForEach(0..<5, id: \.self) { col in
                            ZStack {
                                Rectangle()
                                    .fill(selected?.row == row && selected?.col == col ? Color.accentColor.opacity(0.2) : Color.white)
                                    .border(Color.accentColor, width: 1)
                                Text(board[row][col] != nil ? "\(board[row][col]!)" : "")
                                    .font(.title3)
                                    .foregroundColor(.primary)
                            }
                            .frame(width: 50, height: 50)
                            .onTapGesture {
                                selected = SelectedCell(row: row, col: col)
                            }
                        }
                    }
                }
            }
            .cornerRadius(10)
            .padding(.vertical, 12)
            Spacer(minLength: 8)
            if let sel = selected {
                HStack(spacing: 8) {
                    ForEach(1...25, id: \.self) { num in
                        Button(action: {
                            if isValidMove(row: sel.row, col: sel.col, value: num) {
                                board[sel.row][sel.col] = num
                            }
                        }) {
                            Text("\(num)")
                                .font(.caption.bold())
                                .frame(width: 28, height: 28)
                                .background(isValidMove(row: sel.row, col: sel.col, value: num) ? Color.accentColor.opacity(0.15) : Color.gray.opacity(0.1))
                                .foregroundColor(isValidMove(row: sel.row, col: sel.col, value: num) ? .accentColor : .gray)
                                .cornerRadius(6)
                        }
                    }
                }
                .padding(.bottom, 8)
                
                Button(action: { board[sel.row][sel.col] = nil }) {
                    Text("Clear")
                        .font(.body.bold())
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color.red.opacity(0.15))
                        .foregroundColor(.red)
                        .cornerRadius(8)
                }
                .padding(.bottom, 8)
            }
            HStack(spacing: 16) {
                Button(action: {
                    isCorrect = checkSolution()
                    showResult = true
                }) {
                    Text("Check")
                        .font(.body.bold())
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                        .background(Color.accentColor.opacity(0.15))
                        .foregroundColor(.accentColor)
                        .cornerRadius(10)
                }
                Button(action: clearBoard) {
                    Text("New Puzzle")
                        .font(.body.bold())
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.15))
                        .foregroundColor(.red)
                        .cornerRadius(10)
                }
            }
            .padding(.top, 8)
            if showResult {
                Text(isCorrect ? "Correct!" : "Not solved yet.")
                    .foregroundColor(isCorrect ? .green : .red)
                    .font(.headline)
                    .padding(.top, 4)
            }
            Spacer()
        }
        .padding()
        .onAppear {
            clearBoard()
        }
    }
}

struct ThreesGameView: View {
    let onExit: () -> Void
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: onExit) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
            Spacer()
            Text("Threes Game Coming Soon!")
                .font(.title)
                .padding()
            Spacer()
        }
    }
}

struct BinaryPuzzleGameView: View {
    let onExit: () -> Void
    @State private var board: [[Int?]] = Array(repeating: Array(repeating: nil, count: 6), count: 6)
    @State private var selected: SelectedCell? = nil
    @State private var showResult: Bool = false
    @State private var isCorrect: Bool = false
    
    func generatePuzzle() -> [[Int?]] {
        // Generate a simple puzzle with some pre-filled numbers
        let puzzle: [[Int?]] = [
            [1, 0, nil, nil, 0, 1],
            [0, 1, nil, nil, 1, 0],
            [nil, nil, 1, 0, nil, nil],
            [nil, nil, 0, 1, nil, nil],
            [1, 0, nil, nil, 0, 1],
            [0, 1, nil, nil, 1, 0]
        ]
        return puzzle
    }
    
    func cycleValue(row: Int, col: Int) {
        if board[row][col] == nil {
            board[row][col] = 0
        } else if board[row][col] == 0 {
            board[row][col] = 1
        } else {
            board[row][col] = nil
        }
    }
    
    func checkSolution() -> Bool {
        // Check each row and column
        for i in 0..<6 {
            if !checkRow(i) || !checkColumn(i) {
                return false
            }
        }
        
        // Check that all rows are unique
        var rows: [[Int]] = []
        for row in 0..<6 {
            var rowValues: [Int] = []
            for col in 0..<6 {
                if let val = board[row][col] {
                    rowValues.append(val)
                } else {
                    return false // Incomplete
                }
            }
            rows.append(rowValues)
        }
        
        if Set(rows).count != rows.count {
            return false
        }
        
        // Check that all columns are unique
        var columns: [[Int]] = []
        for col in 0..<6 {
            var colValues: [Int] = []
            for row in 0..<6 {
                if let val = board[row][col] {
                    colValues.append(val)
                } else {
                    return false // Incomplete
                }
            }
            columns.append(colValues)
        }
        
        if Set(columns).count != columns.count {
            return false
        }
        
        return true
    }
    
    func checkRow(_ row: Int) -> Bool {
        var zeros = 0
        var ones = 0
        var consecutive = 0
        var lastValue: Int? = nil
        
        for col in 0..<6 {
            if let value = board[row][col] {
                if value == 0 {
                    zeros += 1
                } else {
                    ones += 1
                }
                
                if value == lastValue {
                    consecutive += 1
                    if consecutive > 2 {
                        return false // More than 2 consecutive
                    }
                } else {
                    consecutive = 1
                }
                lastValue = value
            } else {
                return false // Incomplete
            }
        }
        
        return zeros == 3 && ones == 3
    }
    
    func checkColumn(_ col: Int) -> Bool {
        var zeros = 0
        var ones = 0
        var consecutive = 0
        var lastValue: Int? = nil
        
        for row in 0..<6 {
            if let value = board[row][col] {
                if value == 0 {
                    zeros += 1
                } else {
                    ones += 1
                }
                
                if value == lastValue {
                    consecutive += 1
                    if consecutive > 2 {
                        return false // More than 2 consecutive
                    }
                } else {
                    consecutive = 1
                }
                lastValue = value
            } else {
                return false // Incomplete
            }
        }
        
        return zeros == 3 && ones == 3
    }
    
    func clearBoard() {
        board = generatePuzzle()
        selected = nil
        showResult = false
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button(action: onExit) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
            Text("Binary Puzzle")
                .font(.largeTitle.bold())
                .padding(.bottom, 8)
            Text("Fill the grid with 0s and 1s. No more than two of the same number next to each other in any row or column. Each row and column must have an equal number of 0s and 1s, and all rows and columns must be unique.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom, 8)
            Spacer(minLength: 8)
            VStack(spacing: 2) {
                ForEach(0..<6, id: \.self) { row in
                    HStack(spacing: 2) {
                        ForEach(0..<6, id: \.self) { col in
                            ZStack {
                                Rectangle()
                                    .fill(selected?.row == row && selected?.col == col ? Color.accentColor.opacity(0.2) : Color.white)
                                    .border(Color.accentColor, width: 1)
                                Text(board[row][col] != nil ? "\(board[row][col]!)" : "")
                                    .font(.title2.bold())
                                    .foregroundColor(board[row][col] == 0 ? .blue : .red)
                            }
                            .frame(width: 45, height: 45)
                            .onTapGesture {
                                selected = SelectedCell(row: row, col: col)
                                cycleValue(row: row, col: col)
                            }
                        }
                    }
                }
            }
            .cornerRadius(10)
            .padding(.vertical, 12)
            
            Spacer(minLength: 8)
            HStack(spacing: 16) {
                Button(action: {
                    isCorrect = checkSolution()
                    showResult = true
                }) {
                    Text("Check")
                        .font(.body.bold())
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                        .background(Color.accentColor.opacity(0.15))
                        .foregroundColor(.accentColor)
                        .cornerRadius(10)
                }
                Button(action: clearBoard) {
                    Text("New Puzzle")
                        .font(.body.bold())
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.15))
                        .foregroundColor(.red)
                        .cornerRadius(10)
                }
            }
            .padding(.top, 8)
            if showResult {
                Text(isCorrect ? "Correct!" : "Not solved yet.")
                    .foregroundColor(isCorrect ? .green : .red)
                    .font(.headline)
                    .padding(.top, 4)
            }
            Spacer()
        }
        .padding()
        .onAppear {
            clearBoard()
        }
    }
}

struct MemoryMatchGameView: View {
    let onExit: () -> Void
    @State private var cards: [Card] = []
    @State private var flippedIndices: [Int] = []
    @State private var matchedPairs: Int = 0
    @State private var score: Int = 0
    @State private var gameOver: Bool = false
    @State private var timer: Timer?
    @State private var timeRemaining: Int = 60
    
    let gridSize = 4
    let cardPairs = 8 // Number of pairs
    
    struct Card: Identifiable, Hashable {
        let id = UUID()
        var value: Int
        var isFlipped: Bool = false
        var isMatched: Bool = false
    }
    
    func generateCards() {
        var values: [Int] = []
        for i in 0..<cardPairs {
            values.append(i)
            values.append(i)
        }
        values.shuffle()
        
        cards.removeAll()
        for i in 0..<(gridSize * gridSize) {
            cards.append(Card(value: values[i]))
        }
    }
    
    func flipCard(at index: Int) {
        guard index < cards.count && !cards[index].isMatched && !cards[index].isFlipped else { return }
        
        cards[index].isFlipped = true
        flippedIndices.append(index)
        
        if flippedIndices.count == 2 {
            let firstIndex = flippedIndices[0]
            let secondIndex = flippedIndices[1]
            
            if cards[firstIndex].value == cards[secondIndex].value {
                // Match found
                cards[firstIndex].isMatched = true
                cards[secondIndex].isMatched = true
                matchedPairs += 1
                score += 10
                
                // Check if all pairs have been matched
                if matchedPairs == cardPairs {
                    gameOver = true
                    timer?.invalidate()
                    
                    // Save the score
                    let finalScore = GameScore(
                        game: "Memory Match",
                        score: score,
                        difficulty: timeRemaining > 30 ? "Easy" : (timeRemaining > 15 ? "Medium" : "Hard")
                    )
                    ScoreManager.shared.addScore(finalScore)
                }
            } else {
                // No match - flip cards back after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    cards[firstIndex].isFlipped = false
                    cards[secondIndex].isFlipped = false
                }
                score -= 5
            }
            flippedIndices.removeAll()
        }
    }
    
    func startGame() {
        matchedPairs = 0
        score = 0
        timeRemaining = 60
        gameOver = false
        flippedIndices.removeAll()
        generateCards()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            timeRemaining -= 1
            if timeRemaining == 0 {
                gameOver = true
                timer?.invalidate()
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Spacer()
                Button(action: onExit) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
            Text("Memory Match")
                .font(.largeTitle.bold())
                .padding(.bottom, 8)
            Text("Find matching pairs of cards to earn points!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom, 8)
            
            Text("Time: \(timeRemaining)")
                .font(.title2)
                .foregroundColor(.primary)
                .padding(.bottom, 8)
            
            Text("Score: \(score)")
                .font(.title2)
                .foregroundColor(.primary)
                .padding(.bottom, 8)
            
            if gameOver {
                VStack(spacing: 12) {
                    if matchedPairs == cardPairs {
                        Text("Congratulations!")
                            .font(.title2.bold())
                            .foregroundColor(.green)
                        Text("You matched all the cards!")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Final Score: \(score)")
                            .font(.title3)
                            .foregroundColor(.primary)
                    } else {
                        Text("Game Over!")
                            .font(.title2.bold())
                            .foregroundColor(.red)
                        Text("Time's up!")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Final Score: \(score)")
                            .font(.title3)
                            .foregroundColor(.primary)
                    }
                    
                    Button(action: startGame) {
                        Text("Play Again")
                            .font(.body.bold())
                            .padding(.horizontal, 24)
                            .padding(.vertical, 8)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.top, 8)
                }
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                    ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                        CardView(card: card, onFlip: {
                            flipCard(at: index)
                        })
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .onAppear {
            startGame()
        }
    }
}

struct CardView: View {
    let card: MemoryMatchGameView.Card
    let onFlip: () -> Void
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(card.isFlipped || card.isMatched ? Color.accentColor : Color.gray.opacity(0.2))
                .shadow(color: Color.black.opacity(0.07), radius: 6, x: 0, y: 3)
            
            if card.isFlipped || card.isMatched {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white)
                    .overlay(
                        Text("\(card.value)")
                            .font(.title2)
                            .foregroundColor(.black)
                    )
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white)
                    .overlay(
                        Image(systemName: "questionmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    )
            }
        }
        .frame(width: 70, height: 90)
        .onTapGesture {
            onFlip()
        }
    }
}

struct SelectedCell {
    let row: Int
    let col: Int
}

struct CellCoordinate: Hashable {
    let row: Int
    let col: Int
}

enum SheetContent: Identifiable {
    case rules(Game)
    case game(Game)
    
    var id: UUID {
        switch self {
        case .rules(let game):
            return game.id
        case .game(let game):
            return game.id
        }
    }
}

struct ContentView: View {
    @State private var currentView: AppView = .home
    @State private var sheetContent: SheetContent? = nil
    
    enum AppView {
        case home, games, scores, settings
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color.gray.opacity(0.1), Color.gray.opacity(0.2)]), startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                switch currentView {
                case .home:
                    HomeView(onNavigate: { view in
                        currentView = view
                    })
                case .games:
                    GamesView(sheetContent: $sheetContent, onBack: {
                        currentView = .home
                    })
                case .scores:
                    ScoresView(onBack: {
                        currentView = .home
                    })
                case .settings:
                    SettingsView(onBack: {
                        currentView = .home
                    })
                }
            }
        }
        .sheet(item: $sheetContent) { content in
            switch content {
            case .rules(let game):
                RulesView(game: game, onStart: {
                    sheetContent = .game(game)
                })
            case .game(let game):
                switch game.name {
                case "Sudoku":
                    SudokuGameView(onExit: { sheetContent = nil })
                case "2048":
                    Game2048View(onExit: { sheetContent = nil })
                case "Kakuro":
                    KakuroGameView(onExit: { sheetContent = nil })
                case "KenKen":
                    KenKenGameView(onExit: { sheetContent = nil })
                case "Calcudoku":
                    CalcudokuGameView(onExit: { sheetContent = nil })
                case "Color Match":
                    ColorMatchGameView(onExit: { sheetContent = nil })
                case "Futoshiki":
                    FutoshikiGameView(onExit: { sheetContent = nil })
                case "Numbrix":
                    NumbrixGameView(onExit: { sheetContent = nil })
                case "Threes":
                    ThreesGameView(onExit: { sheetContent = nil })
                case "Binary Puzzle":
                    BinaryPuzzleGameView(onExit: { sheetContent = nil })
                case "Memory Match":
                    MemoryMatchGameView(onExit: { sheetContent = nil })
                default:
                    Text("Game Coming Soon!")
                }
            }
        }
    }
}

struct HomeView: View {
    let onNavigate: (ContentView.AppView) -> Void
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // App Title and Headline
            VStack(spacing: 16) {
                Text("Brainiak")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.accentColor)
                
                Text("Train your brain with logic and number games")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            Spacer()
            
            // Navigation Buttons
            VStack(spacing: 20) {
                NavigationButton(
                    title: "Game Modes",
                    subtitle: "Choose from 12 brain-training games",
                    icon: "gamecontroller.fill",
                    color: .blue
                ) {
                    onNavigate(.games)
                }
                
                NavigationButton(
                    title: "Scores",
                    subtitle: "View your achievements and high scores",
                    icon: "trophy.fill",
                    color: .orange
                ) {
                    onNavigate(.scores)
                }
                
                NavigationButton(
                    title: "Settings",
                    subtitle: "Customize your gaming experience",
                    icon: "gearshape.fill",
                    color: .purple
                ) {
                    onNavigate(.settings)
                }
            }
            .padding(.horizontal, 30)
            
            Spacer()
        }
        .padding()
    }
}

struct NavigationButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(color)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title3.bold())
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct GamesView: View {
    @Binding var sheetContent: SheetContent?
    let onBack: () -> Void
    
    let games: [Game] = [
        Game(
            name: "Sudoku",
            icon: "square.grid.3x3.fill",
            rules: "Fill the grid so that every row, column, and 3x3 box contains the digits 1 to 9 without repeating.",
            view: AnyView(SudokuGameView(onExit: {}))
        ),
        Game(
            name: "2048",
            icon: "number.square.fill",
            rules: "Swipe to combine tiles with the same number. Reach 2048 to win!",
            view: AnyView(Game2048View(onExit: {}))
        ),
        Game(
            name: "Kakuro",
            icon: "plus.slash.minus",
            rules: "• Fill white cells with digits 1-9\n• Each group of consecutive cells must add up to the clue number\n• No digit can be repeated within the same group\n• Clues show the sum for the group starting from that cell\n• Start with small sums (3-7) - they have fewer combinations\n• Use the 'Check' button to verify your solution",
            view: AnyView(KakuroGameView(onExit: {}))
        ),
        Game(
            name: "KenKen",
            icon: "function",
            rules: "• Fill each row and column with numbers 1-4 (no repeats)\n• Each cage (group of cells) has a target number and math operation\n• The numbers in a cage must combine using the operation to equal the target\n• Operations: + (add), × (multiply), − (subtract), ÷ (divide)\n• For subtraction/division, the larger number goes first\n• Use the 'Check' button to verify your solution",
            view: AnyView(KenKenGameView(onExit: {}))
        ),
        Game(
            name: "Calcudoku",
            icon: "divide.square.fill",
            rules: "A math-based version of Sudoku with arithmetic cage rules. Fill the grid so no number repeats in any row or column, and each cage's numbers combine to the target using the specified operation.",
            view: AnyView(CalcudokuGameView(onExit: {}))
        ),
        Game(
            name: "Color Match",
            icon: "paintpalette.fill",
            rules: "• Swap adjacent colored tiles to create matches of 3 or more\n• Match tiles horizontally or vertically to clear them\n• New tiles will fill empty spaces\n• Try to make the entire board the same color\n• Plan your moves carefully to create chain reactions\n• Score points for each match you create",
            view: AnyView(ColorMatchGameView(onExit: {}))
        ),
        Game(
            name: "Futoshiki",
            icon: "chevron.left.slash.chevron.right",
            rules: "Fill the grid with numbers so no repeats in any row or column. Inequality signs (>, <) between some squares must be respected.",
            view: AnyView(FutoshikiGameView(onExit: {}))
        ),
        Game(
            name: "Numbrix",
            icon: "number.circle.fill",
            rules: "• Fill the grid with numbers 1-25\n• Consecutive numbers must be adjacent (horizontally or vertically)\n• Create a continuous path from 1 to 25\n• Numbers cannot be repeated\n• Use the number pad to enter values\n• Valid moves are highlighted in the keypad",
            view: AnyView(NumbrixGameView(onExit: {}))
        ),
        Game(
            name: "Threes",
            icon: "3.circle.fill",
            rules: "Slide tiles to combine 1 and 2 into 3, then combine like numbers (multiples of 3). Try to get the highest score!",
            view: AnyView(ThreesGameView(onExit: {}))
        ),
        Game(
            name: "Binary Puzzle",
            icon: "circle.grid.2x2.fill",
            rules: "• Fill the grid with 0s and 1s\n• No more than 2 consecutive same numbers in any row or column\n• Each row and column must have exactly 3 zeros and 3 ones\n• All rows must be unique (no duplicate rows)\n• All columns must be unique (no duplicate columns)\n• Tap cells to cycle: empty → 0 → 1 → empty",
            view: AnyView(BinaryPuzzleGameView(onExit: {}))
        ),
        Game(
            name: "Memory Match",
            icon: "brain.head.profile",
            rules: "• Find matching pairs of cards\n• Tap cards to reveal them\n• Remember card positions\n• Match all pairs to win\n• Try to complete in fewest moves\n• Cards flip back if no match",
            view: AnyView(MemoryMatchGameView(onExit: {}))
        ),
    ]
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with back button
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                        Text("Back")
                            .font(.title3)
                    }
                    .foregroundColor(.accentColor)
                }
                
                Spacer()
                
                Text("Game Modes")
                    .font(.title.bold())
                
                Spacer()
                
                // Invisible element for balance
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .opacity(0)
                    Text("Back")
                        .font(.title3)
                        .opacity(0)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(games) { game in
                        Button(action: {
                            sheetContent = .rules(game)
                        }) {
                            VStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .fill(Color.accentColor.opacity(0.12))
                                        .shadow(color: Color.black.opacity(0.07), radius: 6, x: 0, y: 3)
                                    VStack(spacing: 8) {
                                        Image(systemName: game.icon)
                                            .font(.system(size: 40, weight: .bold))
                                            .foregroundColor(.accentColor)
                                        Text(game.name)
                                            .font(.title3.bold())
                                            .foregroundColor(.primary)
                                            .multilineTextAlignment(.center)
                                    }
                                    .padding(.vertical, 24)
                                    .padding(.horizontal, 8)
                                }
                            }
                            .frame(height: 140)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal, 4)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
        }
    }
}

struct ScoresView: View {
    let onBack: () -> Void
    @State private var selectedGame: String? = nil
    @State private var showAllScores = true
    @StateObject private var scoreManager = ScoreManager.shared
    
    let gameIcons: [String: String] = [
        "Sudoku": "square.grid.3x3.fill",
        "2048": "number.square.fill",
        "Color Match": "paintpalette.fill",
        "Memory Match": "brain.head.profile",
        "Threes": "3.circle.fill",
        "Kakuro": "plus.slash.minus",
        "KenKen": "function",
        "Calcudoku": "divide.square.fill",
        "Futoshiki": "chevron.left.slash.chevron.right",
        "Numbrix": "number.circle.fill",
        "Binary Puzzle": "circle.grid.2x2.fill"
    ]
    
    var allScores: [GameScore] {
        scoreManager.getScores().sorted { $0.score > $1.score }
    }
    
    var gamesWithScores: [String] {
        Array(Set(scoreManager.getScores().map { $0.game })).sorted()
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with back button
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                        Text("Back")
                            .font(.title3)
                    }
                    .foregroundColor(.accentColor)
                }
                
                Spacer()
                
                Text("Scores")
                    .font(.title.bold())
                
                Spacer()
                
                // Invisible element for balance
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .opacity(0)
                    Text("Back")
                        .font(.title3)
                        .opacity(0)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            // Toggle between All Scores and Game-specific scores
            HStack(spacing: 0) {
                Button(action: {
                    showAllScores = true
                    selectedGame = nil
                }) {
                    Text("All Scores")
                        .font(.headline)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(showAllScores ? Color.accentColor : Color.gray.opacity(0.2))
                        .foregroundColor(showAllScores ? .white : .primary)
                        .cornerRadius(8)
                }
                
                Button(action: {
                    showAllScores = false
                }) {
                    Text("By Game")
                        .font(.headline)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(!showAllScores ? Color.accentColor : Color.gray.opacity(0.2))
                        .foregroundColor(!showAllScores ? .white : .primary)
                        .cornerRadius(8)
                }
                
                Spacer()
                
                Button(action: {
                    scoreManager.clearScores()
                }) {
                    Text("Clear")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.red.opacity(0.2))
                        .foregroundColor(.red)
                        .cornerRadius(6)
                }
            }
            .padding(.horizontal)
            
            if showAllScores {
                // All Scores View
                if allScores.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.yellow)
                        
                        Text("No Scores Yet!")
                            .font(.title2.bold())
                            .foregroundColor(.primary)
                        
                        Text("Play some games to see your scores here.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(allScores.prefix(20), id: \.id) { score in
                                ScoreRowView(score: score, showGame: true)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            } else {
                // Game-specific scores
                if gamesWithScores.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.yellow)
                        
                        Text("No Scores Yet!")
                            .font(.title2.bold())
                            .foregroundColor(.primary)
                        
                        Text("Play some games to see your scores here.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(gamesWithScores, id: \.self) { gameName in
                                GameScoreSection(
                                    gameName: gameName,
                                    scores: scoreManager.getScores(for: gameName),
                                    icon: gameIcons[gameName] ?? "gamecontroller.fill",
                                    isExpanded: selectedGame == gameName,
                                    onToggle: {
                                        selectedGame = selectedGame == gameName ? nil : gameName
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
    }
}

struct GameScore: Identifiable, Codable {
    let id = UUID()
    let game: String
    let score: Int
    let date: Date
    let difficulty: String
    
    init(game: String, score: Int, date: Date = Date(), difficulty: String) {
        self.game = game
        self.score = score
        self.date = date
        self.difficulty = difficulty
    }
}

class ScoreManager: ObservableObject {
    static let shared = ScoreManager()
    
    @Published var scores: [GameScore] = []
    
    private let userDefaults = UserDefaults.standard
    private let scoresKey = "BrainiakGameScores"
    
    init() {
        loadScores()
    }
    
    func addScore(_ score: GameScore) {
        scores.append(score)
        scores.sort { $0.score > $1.score }
        saveScores()
    }
    
    func getScores(for game: String? = nil) -> [GameScore] {
        if let game = game {
            return scores.filter { $0.game == game }
        }
        return scores
    }
    
    func getHighScore(for game: String) -> GameScore? {
        return scores.filter { $0.game == game }.max { $0.score < $1.score }
    }
    
    private func saveScores() {
        if let encoded = try? JSONEncoder().encode(scores) {
            userDefaults.set(encoded, forKey: scoresKey)
        }
    }
    
    private func loadScores() {
        if let data = userDefaults.data(forKey: scoresKey),
           let decoded = try? JSONDecoder().decode([GameScore].self, from: data) {
            scores = decoded
        }
    }
    
    func clearScores() {
        scores.removeAll()
        userDefaults.removeObject(forKey: scoresKey)
    }
}

struct ScoreRowView: View {
    let score: GameScore
    let showGame: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Score rank/medal
            ZStack {
                Circle()
                    .fill(scoreColor)
                    .frame(width: 40, height: 40)
                
                if score.score >= 1000 {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.white)
                        .font(.title3)
                } else if score.score >= 500 {
                    Image(systemName: "star.fill")
                        .foregroundColor(.white)
                        .font(.title3)
                } else {
                    Text("\(score.score)")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    if showGame {
                        Text(score.game)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    Text("\(score.score)")
                        .font(.title2.bold())
                        .foregroundColor(.accentColor)
                }
                
                HStack {
                    Text(score.difficulty)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(difficultyColor.opacity(0.2))
                        .foregroundColor(difficultyColor)
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    Text(score.date, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    var scoreColor: Color {
        if score.score >= 1000 { return .orange }
        if score.score >= 500 { return .blue }
        return .green
    }
    
    var difficultyColor: Color {
        switch score.difficulty {
        case "Hard": return .red
        case "Medium": return .orange
        case "Easy": return .green
        default: return .gray
        }
    }
}

struct GameScoreSection: View {
    let gameName: String
    let scores: [GameScore]
    let icon: String
    let isExpanded: Bool
    let onToggle: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: onToggle) {
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(.accentColor)
                        .frame(width: 30)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(gameName)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("\(scores.count) scores")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if let bestScore = scores.max(by: { $0.score < $1.score }) {
                        Text("\(bestScore.score)")
                            .font(.title3.bold())
                            .foregroundColor(.accentColor)
                    }
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(scores.sorted { $0.score > $1.score }, id: \.id) { score in
                        ScoreRowView(score: score, showGame: false)
                    }
                }
                .padding(.top, 8)
            }
        }
    }
}

struct SettingsView: View {
    let onBack: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with back button
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                        Text("Back")
                            .font(.title3)
                    }
                    .foregroundColor(.accentColor)
                }
                
                Spacer()
                
                Text("Settings")
                    .font(.title.bold())
                
                Spacer()
                
                // Invisible element for balance
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .opacity(0)
                    Text("Back")
                        .font(.title3)
                        .opacity(0)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            Spacer()
            
            VStack(spacing: 20) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                
                Text("Coming Soon!")
                    .font(.title2.bold())
                    .foregroundColor(.primary)
                
                Text("Settings and customization options will be available in a future update.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
    }
}

struct RulesView: View {
    let game: Game
    let onStart: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: game.icon)
                .font(.system(size: 48))
                .foregroundColor(.accentColor)
            Text(game.name)
                .font(.largeTitle)
                .bold()
            ScrollView {
                Text(game.rules)
                    .font(.body)
                    .padding()
            }
            Spacer()
            Button(action: onStart) {
                Text("Start Game")
                    .font(.title2)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

