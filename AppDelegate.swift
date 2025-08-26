//
//  AppDelegate.swift
//  lyrics
//
//  Created by heidi *⊹🥛◌◞🐈‍⬛𓂂𓏸  on 07/08/2025.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    private let spotifyScript = SpotifyScript()
    var statusItem: NSStatusItem!
    // Add these new properties
    var showNowPlayingWindow = true
    var showTouchBar = true
    var mainWindowController: NSWindowController?
    
    @objc func previousTapped() {
        spotifyScript.spotifyPreviousTrack()
    }
    
    @objc func playPauseTapped() {
        spotifyScript.spotifyTogglePlayPause()
    }

    @objc func nextTapped() {
        spotifyScript.spotifyNextTrack()
    }
    
    @objc func quitApp() {
        NSApp.terminate(nil)
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // 1. Create the status bar icon
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.title = "🎧ྀི"
            button.font = NSFont.systemFont(ofSize: 14)
            // Use a specific action to handle clicks and show the dynamic menu
            button.action = #selector(statusBarButtonClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        if let windowController = NSApplication.shared.windows.first?.windowController {
            self.mainWindowController = windowController
        }
        
        checkSpotifyPermissions()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleWindowClosed), name: NSWindow.willCloseNotification, object: nil)
    }
    
    func checkSpotifyPermissions() {
        let script = """
            tell application "Spotify"
                return "ok"
            end tell
        """
        
        var error: NSDictionary?
        let appleScript = NSAppleScript(source: script)
        
        let result = appleScript?.executeAndReturnError(&error)
        
        if result == nil {
            // Permission was denied or an error occurred
            let alert = NSAlert()
            alert.messageText = "Spotify Permissions Required"
            alert.informativeText = "Please allow this app to control Spotify in System Settings > Privacy & Security > Automation."
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }

    @objc func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        if let event = NSApp.currentEvent {
            if event.type == .leftMouseUp {
                // On right-click, show the dynamic menu
                statusItem.menu = createMenu()
                statusItem.button?.performClick(nil)
            } else if event.type == .rightMouseUp {
                // On left-click, toggle the main window
                if let window = NSApp.windows.first {
                    if window.isVisible {
                        window.orderOut(nil)
                        showNowPlayingWindow = false // Update state when hiding
                    } else {
                        window.makeKeyAndOrderFront(nil)
                        showNowPlayingWindow = true // Update state when showing
                    }
                }
            }
        }
    }
    
    @objc func handleWindowClosed(_ notification: Notification) {
        if let window = notification.object as? NSWindow, window == NSApp.windows.first {
            showNowPlayingWindow = false
        }
    }

    // This method creates the dynamic menu
    func createMenu() -> NSMenu {
        let menu = NSMenu()

        // Track controls
        menu.addItem(NSMenuItem(title: "Previous", action: #selector(previousTapped), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Play/Pause", action: #selector(playPauseTapped), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Next", action: #selector(nextTapped), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())

        // Option 2: Show/Hide Now Playing Window
        let windowItem = NSMenuItem(title: "Show \"Now Playing\" Window", action: #selector(toggleNowPlayingWindow(_:)), keyEquivalent: "")
        windowItem.target = self
        windowItem.state = showNowPlayingWindow ? .on : .off
        menu.addItem(windowItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit option
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        return menu
    }
    

    @objc func toggleTouchBar(_ sender: NSMenuItem) {
        showTouchBar.toggle()
        sender.state = showTouchBar ? .on : .off
        
        // Get the window controller from the first window
        if let windowController = NSApp.windows.first?.windowController {
            // Get the view controller from the window's contentViewController
            if let viewController = windowController.contentViewController as? ViewController {
                if showTouchBar {
                    // Correct: Set the touchBar property to a newly created Touch Bar
                    windowController.touchBar = viewController.makeTouchBar()
                } else {
                    // Hide the Touch Bar by setting the property to nil
                    windowController.touchBar = nil
                }
            }
        }
    }

    // Action method to toggle the Now Playing window
    @objc func toggleNowPlayingWindow(_ sender: NSMenuItem) {
        showNowPlayingWindow.toggle()
        sender.state = showNowPlayingWindow ? .on : .off
        
        if let window = NSApp.windows.first {
            if showNowPlayingWindow {
                // Set the window to a floating level to keep it on top
                window.level = .floating
                window.makeKeyAndOrderFront(nil)
            } else {
                // Set it back to normal when hidden
                window.level = .normal
                window.orderOut(nil)
            }
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}

// Custom Notification Names
extension Notification.Name {
    static let toggleTouchBarNotification = Notification.Name("toggleTouchBarNotification")
    static let toggleWindowNotification = Notification.Name("toggleWindowNotification")
    static let nowPlayingWindowDidClose = Notification.Name("nowPlayingWindowDidClose") // New notification
}
