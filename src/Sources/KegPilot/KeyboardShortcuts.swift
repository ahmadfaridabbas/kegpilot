import SwiftUI
import AppKit

/// Phase 1 keyboard shortcuts: a single source of truth for the app's in-panel shortcuts.
///
/// These are *in-panel* shortcuts — they fire only while the menu-bar window is open and focused,
/// via SwiftUI's `.keyboardShortcut` on the backing buttons. This type is the canonical catalog so
/// the live shortcuts and the read-only reference window can never drift apart: `KegPilotApp.swift`
/// attaches `.keyboardShortcut(entry.key, modifiers: entry.modifiers)` using the same entries the
/// reference window renders.
///
/// Customization (user-reassignable combos) is intentionally out of scope here; that is Phase 2 and
/// would move dispatch to an `NSEvent` monitor driven by a persisted mapping. Phase 1 keeps the
/// mapping hardcoded and simply documents it in a window.
enum ShortcutKey: Equatable {
    case character(Character)
    case backspace

    /// The SwiftUI key equivalent used by `.keyboardShortcut`.
    var keyEquivalent: KeyEquivalent {
        switch self {
        case .character(let c): return KeyEquivalent(c)
        case .backspace: return .delete
        }
    }
}

struct ShortcutEntry: Identifiable {
    let id: String
    let title: String
    let key: ShortcutKey
    let modifiers: EventModifiers
    /// The glyph string shown in the reference window, e.g. "⌘⇧U".
    let display: String
    /// Which section of the panel this shortcut applies to.
    let group: String
}

enum KeyboardShortcuts {
    /// The complete, agreed Phase 1 mapping. The `key`/`modifiers` here must match what the live
    /// buttons declare in `KegPilotApp.swift`, `UpdatesView.swift`, and the console controls.
    static let all: [ShortcutEntry] = [
        // Maintenance actions (brew commands)
        .init(id: "update",     title: "Update",             key: .character("u"), modifiers: .command,            display: "⌘U",  group: "Maintenance"),
        .init(id: "outdated",   title: "Outdated",           key: .character("o"), modifiers: .command,            display: "⌘O",  group: "Maintenance"),
        .init(id: "upgrade",    title: "Upgrade",            key: .character("u"), modifiers: [.command, .shift],  display: "⌘⇧U", group: "Maintenance"),
        .init(id: "cleanup",    title: "Cleanup",            key: .character("k"), modifiers: .command,            display: "⌘K",  group: "Maintenance"),
        .init(id: "autoremove", title: "Autoremove",         key: .character("a"), modifiers: [.command, .shift],  display: "⌘⇧A", group: "Maintenance"),
        .init(id: "doctor",     title: "Doctor",             key: .character("d"), modifiers: .command,            display: "⌘D",  group: "Maintenance"),

        // Section tabs
        .init(id: "tab1",       title: "Maintenance tab",    key: .character("1"), modifiers: .command,            display: "⌘1",  group: "Navigation"),
        .init(id: "tab2",       title: "Installed tab",      key: .character("2"), modifiers: .command,            display: "⌘2",  group: "Navigation"),
        .init(id: "tab3",       title: "Updates tab",        key: .character("3"), modifiers: .command,            display: "⌘3",  group: "Navigation"),

        // Updates tab
        .init(id: "check",      title: "Check (refresh list)", key: .character("r"), modifiers: .command,          display: "⌘R",  group: "Updates"),
        .init(id: "refreshdef", title: "Refresh definitions", key: .character("r"), modifiers: [.command, .shift], display: "⌘⇧R", group: "Updates"),

        // Brewfile
        .init(id: "export",     title: "Export Brewfile",    key: .character("e"), modifiers: .command,            display: "⌘E",  group: "Brewfile"),
        .init(id: "restore",    title: "Restore Brewfile",   key: .character("b"), modifiers: [.command, .shift],  display: "⌘⇧B", group: "Brewfile"),

        // Console
        .init(id: "copy",       title: "Copy output",        key: .character("c"), modifiers: [.command, .shift],  display: "⌘⇧C", group: "Console"),
        .init(id: "clear",      title: "Clear console",      key: .backspace,      modifiers: .command,            display: "⌘⌫",  group: "Console"),
        .init(id: "stop",       title: "Stop command",       key: .character("."), modifiers: .command,            display: "⌘.",  group: "Console"),

        // Panel
        .init(id: "close",      title: "Close panel",        key: .character("w"), modifiers: .command,            display: "⌘W",  group: "Panel"),
        .init(id: "quit",       title: "Quit KegPilot",      key: .character("q"), modifiers: .command,            display: "⌘Q",  group: "Panel"),
    ]

    /// Look up one entry by id so the live buttons can declare `.keyboardShortcut` from the catalog.
    static func entry(_ id: String) -> ShortcutEntry {
        guard let found = all.first(where: { $0.id == id }) else {
            fatalError("Unknown shortcut id: \(id)")
        }
        return found
    }

    /// Group order for the reference window.
    static let groupOrder = ["Navigation", "Maintenance", "Updates", "Brewfile", "Console", "Panel"]
}

/// Convenience: attach a catalog shortcut to any view by id.
extension View {
    func kegShortcut(_ id: String) -> some View {
        let e = KeyboardShortcuts.entry(id)
        return self.keyboardShortcut(e.key.keyEquivalent, modifiers: e.modifiers)
    }
}

// MARK: - Reference window (read-only, non-activating)

/// A single shared controller for the "Keyboard Shortcuts" reference window. It uses a
/// `.nonactivatingPanel` at `.floating` level so the window can appear *without* taking key focus
/// away from the menu-bar panel — which is what lets the main KegPilot panel stay open alongside it
/// (a `MenuBarExtra(.window)` panel dismisses itself the moment it loses focus, so an ordinary
/// activating window would close it).
final class ShortcutsWindowController {
    static let shared = ShortcutsWindowController()
    private var panel: NSPanel?

    func toggle(appearance: AppearanceMode, systemIsDark: Bool) {
        if let panel, panel.isVisible {
            panel.close()
            return
        }
        show(appearance: appearance, systemIsDark: systemIsDark)
    }

    func show(appearance: AppearanceMode, systemIsDark: Bool) {
        if panel == nil {
            let hosting = NSHostingController(
                rootView: ShortcutsReference(appearance: appearance, systemIsDark: systemIsDark)
            )
            let p = NSPanel(contentViewController: hosting)
            p.styleMask = [.titled, .closable, .nonactivatingPanel, .utilityWindow]
            p.title = "Keyboard Shortcuts"
            p.isFloatingPanel = true
            // The MenuBarExtra(.window) panel sits at the status-bar / pop-up level, which is above
            // `.floating`. To guarantee this reference window appears *in front of* the main panel,
            // we place it one step above the pop-up-menu level.
            p.level = NSWindow.Level(rawValue: NSWindow.Level.popUpMenu.rawValue + 1)
            p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            p.hidesOnDeactivate = false
            p.isReleasedWhenClosed = false
            p.standardWindowButton(.miniaturizeButton)?.isHidden = true
            p.standardWindowButton(.zoomButton)?.isHidden = true
            p.setContentSize(NSSize(width: 360, height: 460))
            positionNearMenuBar(p)
            panel = p
        } else {
            // Refresh the content so the window matches the current theme if re-shown.
            (panel?.contentViewController as? NSHostingController<ShortcutsReference>)?
                .rootView = ShortcutsReference(appearance: appearance, systemIsDark: systemIsDark)
        }
        // orderFrontRegardless shows the panel without activating the app, preserving the
        // menu-bar panel's key focus so it does not auto-dismiss. The elevated window level above
        // ensures it draws in front of the menu-bar panel rather than behind it. We deliberately do
        // NOT make it key: taking key focus would make the MenuBarExtra panel resign key and
        // auto-close, which contradicts "keep the main panel open."
        panel?.orderFrontRegardless()
    }

    /// Place the window just under the menu bar, toward the right where the status item lives, so
    /// it reads as belonging to the main panel. Falls back to centering if no screen is found.
    private func positionNearMenuBar(_ window: NSWindow) {
        guard let screen = NSScreen.main else { window.center(); return }
        let visible = screen.visibleFrame
        let size = window.frame.size
        let margin: CGFloat = 12
        let origin = NSPoint(
            x: visible.maxX - size.width - margin,
            y: visible.maxY - size.height - margin
        )
        window.setFrameOrigin(origin)
    }
}

/// The read-only shortcut list shown in the reference panel.
struct ShortcutsReference: View {
    let appearance: AppearanceMode
    let systemIsDark: Bool
    private var theme: Theme { Theme.resolve(appearance, systemIsDark: systemIsDark) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "keyboard").font(.system(size: 18)).foregroundStyle(theme.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Keyboard Shortcuts").font(.system(size: 15, weight: .semibold)).foregroundStyle(theme.text)
                    Text("Active while this panel is open.").font(.system(size: 10)).foregroundStyle(theme.secondaryText)
                }
                Spacer()
            }.padding(16)
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(KeyboardShortcuts.groupOrder, id: \.self) { group in
                        let entries = KeyboardShortcuts.all.filter { $0.group == group }
                        if !entries.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(group.uppercased())
                                    .font(.system(size: 10, weight: .bold)).foregroundStyle(theme.secondaryText)
                                ForEach(entries) { entry in
                                    HStack {
                                        Text(entry.title).font(.system(size: 12)).foregroundStyle(theme.text)
                                        Spacer()
                                        Text(entry.display)
                                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                                            .monospacedDigit()
                                            .padding(.horizontal, 8).padding(.vertical, 3)
                                            .background(theme.surface, in: RoundedRectangle(cornerRadius: 6))
                                            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(theme.surfaceBorder))
                                            .foregroundStyle(theme.text)
                                    }
                                }
                            }
                        }
                    }
                }.padding(16)
            }
        }
        .frame(width: 360, height: 460)
        .background(theme.usesMaterial ? AnyView(Rectangle().fill(.regularMaterial)) : AnyView(theme.background))
        .environment(\.theme, theme)
    }
}
