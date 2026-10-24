import SwiftUI

/// Keyboard control for the arena operator, who sits beside the Mac and can't reach the
/// screen (docs/gtm/run-sheet.md). Works on a Mac running the app as Designed for iPad and on
/// an iPad with a keyboard. Apply to whatever view presents the arena.
///
///   →      advance (next reveal)          ⌘N   new demo battle
///   ⌘T     start the current turn         ⌘⇧N  new full battle
///   ⌘K     skip the current turn          ⌘R   rematch
///   1 2 3  pick a theme card (theme phase), wired when the theme cards land
struct ArenaOperatorShortcuts: ViewModifier {
    let battle: BattleClient
    var themeCards: [String] = []

    func body(content: Content) -> some View {
        content.background {
            // Zero-size buttons carry the shortcuts without taking space or focus.
            Group {
                Button("Advance") { battle.advance() }
                    .keyboardShortcut(.rightArrow, modifiers: [])
                Button("Start turn") { if let turn = battle.currentTurn { battle.startTurn(turn.id) } }
                    .keyboardShortcut("t", modifiers: .command)
                Button("Skip turn") { if let turn = battle.currentTurn { battle.skipTurn(turn.id) } }
                    .keyboardShortcut("k", modifiers: .command)
                Button("Rematch") { battle.rematch() }
                    .keyboardShortcut("r", modifiers: .command)
                Button("New demo battle") { battle.createRoom(.demoMode) }
                    .keyboardShortcut("n", modifiers: .command)
                Button("New battle") { battle.createRoom(.standard) }
                    .keyboardShortcut("n", modifiers: [.command, .shift])
                ForEach(Array(themeCards.prefix(3).enumerated()), id: \.offset) { index, theme in
                    Button("Theme \(index + 1)") { battle.chooseTheme(theme) }
                        .keyboardShortcut(KeyEquivalent(Character("\(index + 1)")), modifiers: [])
                }
            }
            .frame(width: 0, height: 0)
            .opacity(0)
            .accessibilityHidden(true)
        }
    }
}

extension View {
    func arenaOperatorShortcuts(_ battle: BattleClient, themeCards: [String] = []) -> some View {
        modifier(ArenaOperatorShortcuts(battle: battle, themeCards: themeCards))
    }
}
