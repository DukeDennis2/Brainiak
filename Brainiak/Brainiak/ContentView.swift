//
//  ContentView.swift
//  Brainiak
//
//  Created by miguel corachea on 20/07/2025.
//

import SwiftUI
import UIKit

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
            .background(Color(.systemGray5))
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
                    .fill(Color(.systemGray5))
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
        case 0: return Color(.systemGray4)
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
            Text("Kakuro Game Coming Soon!")
                .font(.title)
                .padding()
            Spacer()
        }
    }
}

struct KenKenGameView: View {
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
            Text("KenKen Game Coming Soon!")
                .font(.title)
                .padding()
            Spacer()
        }
    }
}

struct NonogramsGameView: View {
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
            Text("Nonograms Game Coming Soon!")
                .font(.title)
                .padding()
            Spacer()
        }
    }
}

struct HitoriGameView: View {
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
            Text("Hitori Game Coming Soon!")
                .font(.title)
                .padding()
            Spacer()
        }
    }
}

struct CalcudokuGameView: View {
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
            Text("Calcudoku Game Coming Soon!")
                .font(.title)
                .padding()
            Spacer()
        }
    }
}

struct NurikabeGameView: View {
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
            Text("Nurikabe Game Coming Soon!")
                .font(.title)
                .padding()
            Spacer()
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
            Text("Numbrix Game Coming Soon!")
                .font(.title)
                .padding()
            Spacer()
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
            Text("Binary Puzzle Game Coming Soon!")
                .font(.title)
                .padding()
            Spacer()
        }
    }
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
            rules: "Think 'crossword meets Sudoku.' Fill the grid so that the sums match the clues. Each number in a run must be unique.",
            view: AnyView(KakuroGameView(onExit: {}))
        ),
        Game(
            name: "KenKen",
            icon: "function",
            rules: "Like Sudoku but with math operations (add, subtract, multiply, divide) inside grid cages. Fill the grid so no number repeats in any row or column, and each cage's numbers combine to the target using the specified operation.",
            view: AnyView(KenKenGameView(onExit: {}))
        ),
        Game(
            name: "Nonograms",
            icon: "paintbrush.pointed.fill",
            rules: "Number clues guide which squares to fill to reveal a hidden picture. Each number tells you how many consecutive filled squares are in that row or column.",
            view: AnyView(NonogramsGameView(onExit: {}))
        ),
        Game(
            name: "Hitori",
            icon: "circle.lefthalf.filled",
            rules: "Remove repeating numbers in rows/columns by shading them. No two shaded cells can touch horizontally or vertically, and all unshaded cells must form a single group.",
            view: AnyView(HitoriGameView(onExit: {}))
        ),
        Game(
            name: "Calcudoku",
            icon: "divide.square.fill",
            rules: "A math-based version of Sudoku with arithmetic cage rules. Fill the grid so no number repeats in any row or column, and each cage's numbers combine to the target using the specified operation.",
            view: AnyView(CalcudokuGameView(onExit: {}))
        ),
        Game(
            name: "Nurikabe",
            icon: "square.split.2x2.fill",
            rules: "Fill squares to form islands with unique rules: each island contains one number, the number tells how many squares in the island, islands can't touch, and all water forms a single connected group.",
            view: AnyView(NurikabeGameView(onExit: {}))
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
            rules: "Fill in missing numbers in a grid from 1 to n so that they connect in order, horizontally or vertically.",
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
            rules: "Fill the grid with 0s and 1s. No more than two of the same number next to each other in any row or column. Each row and column must have an equal number of 0s and 1s, and all rows and columns must be unique.",
            view: AnyView(BinaryPuzzleGameView(onExit: {}))
        ),
    ]
    
    @State private var sheetContent: SheetContent? = nil
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color(UIColor.systemGray6), Color(UIColor.systemGray4)]), startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Brainiak")
                                .font(.system(size: 38, weight: .bold, design: .rounded))
                                .foregroundColor(.accentColor)
                            Text("Train your brain with logic and number games")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
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
                .padding(.top, 24)
            }
            .navigationBarHidden(true)
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
                    case "Nonograms":
                        NonogramsGameView(onExit: { sheetContent = nil })
                    case "Hitori":
                        HitoriGameView(onExit: { sheetContent = nil })
                    case "Calcudoku":
                        CalcudokuGameView(onExit: { sheetContent = nil })
                    case "Nurikabe":
                        NurikabeGameView(onExit: { sheetContent = nil })
                    case "Futoshiki":
                        FutoshikiGameView(onExit: { sheetContent = nil })
                    case "Numbrix":
                        NumbrixGameView(onExit: { sheetContent = nil })
                    case "Threes":
                        ThreesGameView(onExit: { sheetContent = nil })
                    case "Binary Puzzle":
                        BinaryPuzzleGameView(onExit: { sheetContent = nil })
                    default:
                        Text("Game Coming Soon!")
                    }
                }
            }
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
