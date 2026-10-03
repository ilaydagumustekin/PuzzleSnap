import SwiftUI

/// Maps between grid positions and points for a board fitted into the available space.
struct BoardLayout {
    let rows: Int
    let cols: Int
    let boardSize: CGSize
    let tileSize: CGSize

    init(available: CGSize, rows: Int, cols: Int, aspect: CGFloat = PhotoLibrary.aspect) {
        self.rows = rows
        self.cols = cols
        let width = max(1, min(available.width, available.height * aspect))
        boardSize = CGSize(width: width, height: width / aspect)
        tileSize = CGSize(width: width / CGFloat(cols), height: boardSize.height / CGFloat(rows))
    }

    func center(of p: GridPos) -> CGPoint {
        CGPoint(x: (CGFloat(p.col) + 0.5) * tileSize.width, y: (CGFloat(p.row) + 0.5) * tileSize.height)
    }

    func gridPos(at point: CGPoint) -> GridPos {
        GridPos(row: Int(floor(point.y / tileSize.height)), col: Int(floor(point.x / tileSize.width)))
    }
}

struct BoardView: View {
    let game: GameViewModel
    /// Resets on its own when a drag ends *or* is cancelled; `onEnded` only fires for the former.
    @GestureState private var isDragging = false

    var body: some View {
        GeometryReader { geo in
            let layout = BoardLayout(available: geo.size, rows: game.board.rows, cols: game.board.cols)
            board(layout)
                .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private func board(_ layout: BoardLayout) -> some View {
        let board = game.board
        let positions = board.tilePositions
        return ZStack(alignment: .topLeading) {
            ForEach(0..<board.count, id: \.self) { tile in
                let pos = positions[tile]
                let lifted = game.draggingTiles.contains(tile)
                TileView(image: game.tileImages[tile],
                         edges: JoinedEdges(board: board, at: pos),
                         lifted: lifted,
                         flashing: game.flashingTiles.contains(tile))
                    .frame(width: layout.tileSize.width, height: layout.tileSize.height)
                    .position(layout.center(of: pos))
                    .offset(lifted ? game.dragOffset : .zero)
                    .zIndex(lifted ? 1 : 0)
            }
        }
        .frame(width: layout.boardSize.width, height: layout.boardSize.height)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 1, coordinateSpace: .local)
                .updating($isDragging) { _, state, _ in state = true }
                .onChanged { value in
                    if game.draggingTiles.isEmpty {
                        game.beginDrag(at: layout.gridPos(at: value.startLocation), tileSize: layout.tileSize)
                    }
                    game.updateDrag(value.translation)
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) { game.endDrag() }
                }
        )
        .onChange(of: isDragging) { _, dragging in
            if !dragging, !game.draggingTiles.isEmpty {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) { game.cancelDrag() }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: board.slots)
    }
}

/// Which sides of a tile touch a tile it is joined to.
struct JoinedEdges {
    var top = false, leading = false, bottom = false, trailing = false

    init(board: PuzzleBoard, at p: GridPos) {
        top = board.isJoined(p, p + GridPos(row: -1, col: 0))
        bottom = board.isJoined(p, p + GridPos(row: 1, col: 0))
        leading = board.isJoined(p, p + GridPos(row: 0, col: -1))
        trailing = board.isJoined(p, p + GridPos(row: 0, col: 1))
    }
}

struct TileView: View {
    let image: UIImage
    let edges: JoinedEdges
    let lifted: Bool
    let flashing: Bool

    private let radius: CGFloat = 7
    private let gap: CGFloat = 1.5

    var body: some View {
        let shape = UnevenRoundedRectangle(
            topLeadingRadius: edges.top || edges.leading ? 0 : radius,
            bottomLeadingRadius: edges.bottom || edges.leading ? 0 : radius,
            bottomTrailingRadius: edges.bottom || edges.trailing ? 0 : radius,
            topTrailingRadius: edges.top || edges.trailing ? 0 : radius
        )
        Image(uiImage: image)
            .resizable()
            .overlay(Color.white.opacity(flashing ? 0.45 : 0))
            .clipShape(shape)
            .padding(EdgeInsets(top: edges.top ? 0 : gap, leading: edges.leading ? 0 : gap,
                                bottom: edges.bottom ? 0 : gap, trailing: edges.trailing ? 0 : gap))
            .shadow(color: .black.opacity(lifted ? 0.35 : 0.15), radius: lifted ? 6 : 1, y: lifted ? 4 : 1)
            .animation(.easeOut(duration: 0.2), value: edges.top)
    }
}
