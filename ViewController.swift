//
//  ViewController.swift
//  lyrics
//
//  Created by heidi *⊹🥛◌◞🐈‍⬛𓂂𓏸  on 07/08/2025.
//

import Cocoa
import Foundation
import SwiftUI
import SwiftSoup


extension NSTouchBarItem.Identifier {
    static let customTextItem = NSTouchBarItem.Identifier("com.yourapp.customTextItem")
    static let lyricsItem = NSTouchBarItem.Identifier("com.yourapp.lyricsItem") // New identifier
    static let controls = NSTouchBarItem.Identifier("com.yourapp.controls") // New identifier
    static let previousButton = NSTouchBarItem.Identifier("com.yourapp.previousButton")
    static let playPauseButton = NSTouchBarItem.Identifier("com.yourapp.playPauseButton")
    static let nextButton = NSTouchBarItem.Identifier("com.yourapp.nextButton")
    static let touchBarSystemVolumeGroup = NSTouchBarItem.Identifier("com.example.touchBarSystemVolumeGroup")
    static let touchBarVolumeUp = NSTouchBarItem.Identifier("com.example.touchBarVolumeUp") // New identifier
    static let touchBarVolumeDown = NSTouchBarItem.Identifier("com.example.touchBarVolumeDown") // New identifier
}


class ViewController: NSViewController, NSTouchBarDelegate, NSWindowDelegate {
    @IBOutlet var lyricsContainerView: NSView!
    
    private let spotifyScript = SpotifyScript()
    
    var songLabel: NSTextField!
    var artistLabel: NSTextField!
    var artworkImageView: NSImageView!
    var lyricsLabel: NSTextField!
    var playPauseButton: NSButton! // Add a reference to the button
    
    private var lyricsWindow: NSWindow? // Add this line
    @State private var currentPlaybackPosition: Double = 0.0 // Add this line
    
    // Declare these properties here so they're accessible throughout the class
    private var swiftUIView: LyricsWindow!
    
    // Create a single instance of your ObservableObject
    private var songInfo = SongInfo()
    private var lyricsView: NSHostingView<LyricsWindow>!
    
    private var isPlaying: Bool = false
    
    @objc func previousTapped() {
        spotifyScript.spotifyPreviousTrack()
    }

    @objc func playPauseTapped() {
        spotifyScript.spotifyTogglePlayPause()

        // Fetch the new player state after toggling
        let playerState = self.spotifyScript.fetchCurrentPlayerState()
        
        DispatchQueue.main.async {
            self.songInfo.isPlaying = (playerState == "playing")
            
            // You can also use this to update the Touch Bar button title if needed
            if playerState == "playing" {
                self.playPauseButton.title = "⏸"
                self.playPauseButton.font = NSFont.systemFont(ofSize: 20)
            } else {
                self.playPauseButton.title = "►"
                self.playPauseButton.font = NSFont.systemFont(ofSize: 14)
            }
        }
    }

    @objc func nextTapped() {
        spotifyScript.spotifyNextTrack()
    }
    
    @objc func quitApp() {
        NSApp.terminate(nil)
    }
    
    // New method to handle the Touch Bar toggle
    @objc private func handleTouchBarToggle(_ notification: Notification) {
        if let userInfo = notification.userInfo, let show = userInfo["showTouchBar"] as? Bool {
            if let windowController = self.view.window?.windowController {
                if show {
                    // Show the Touch Bar by recreating it
                    windowController.touchBar = windowController.makeTouchBar()
                } else {
                    // Hide the Touch Bar by setting it to nil
                    windowController.touchBar = nil
                }
            }
        }
    }

    // New method to handle the Now Playing window toggle
    @objc private func handleWindowToggle(_ notification: Notification) {
        if let userInfo = notification.userInfo, let show = userInfo["showWindow"] as? Bool {
            if show {
                self.view.window?.makeKeyAndOrderFront(nil)
            } else {
                self.view.window?.orderOut(nil)
            }
        }
    }
    
    @objc func volumeUpTapped() {
        spotifyScript.systemVolumeUp()
    }

    @objc func volumeDownTapped() {
        spotifyScript.systemVolumeDown()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.window?.delegate = self

        // Pass the ObservableObject instance to the SwiftUI view
        let swiftUIView = LyricsWindow(songInfo: self.songInfo,
                                               previousAction: { self.previousTapped() },
                                               playPauseAction: { self.playPauseTapped() },
                                               nextAction: { self.nextTapped() },
                                               scrubAction: { newTime in
                                                    // Call the new method to set the song position
                                                    self.spotifyScript.spotifySetPlaybackPosition(to: newTime)
                                               })
        
        // Create the NSHostingView with your SwiftUI view
        self.lyricsView = NSHostingView(rootView: swiftUIView)
        self.lyricsView.translatesAutoresizingMaskIntoConstraints = false
                
        self.lyricsContainerView.addSubview(self.lyricsView)
        NSLayoutConstraint.activate([
            self.lyricsView.topAnchor.constraint(equalTo: self.lyricsContainerView.topAnchor),
            self.lyricsView.bottomAnchor.constraint(equalTo: self.lyricsContainerView.bottomAnchor),
            self.lyricsView.leadingAnchor.constraint(equalTo: self.lyricsContainerView.leadingAnchor),
            self.lyricsView.trailingAnchor.constraint(equalTo: self.lyricsContainerView.trailingAnchor)
        ])
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleTouchBarToggle(_:)), name: .toggleTouchBarNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleWindowToggle(_:)), name: .toggleWindowNotification, object: nil)
    }
    
    func windowWillClose(_ notification: Notification) {
        // Post a notification for the AppDelegate to handle
        NotificationCenter.default.post(name: .nowPlayingWindowDidClose, object: nil)
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        print("✅ viewDidAppear called, setting first responder")
        
        self.view.window?.makeFirstResponder(self)
        
        // Set the callback BEFORE starting timer
        spotifyScript.onTrackChange = { (newInfo: String, albumArt: NSImage?) -> Void in
            DispatchQueue.main.async {
                let components = newInfo.components(separatedBy: " by ")
                let song = components.first ?? "Unknown Song"
                let artist = components.count > 1 ? components[1] : ""
                
                // Update the properties on the shared SongInfo object
                self.songInfo.artwork = albumArt
                self.songInfo.songTitle = song
                self.songInfo.artist = artist
                
                self.songLabel.stringValue = song
                self.artistLabel.stringValue = artist
                self.artworkImageView.image = albumArt
                
                self.spotifyScript.onPlayerStateChange = { playerState in
                    DispatchQueue.main.async {
                        self.songInfo.isPlaying = (playerState == "playing")
                        
                        // You can also use this to update the Touch Bar button title if needed
                        if playerState == "playing" {
                            self.playPauseButton.title = "⏸"
                            self.playPauseButton.font = NSFont.systemFont(ofSize: 20)
                        } else {
                            self.playPauseButton.title = "►"
                            self.playPauseButton.font = NSFont.systemFont(ofSize: 14)
                        }
                    }
                }
            }
        }

        
        // Start a timer to update the song every 1 second
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.spotifyScript.fetchCurrentTrack()

            // Add this to update the progress bar
            let (currentPosition, trackDuration) = self.spotifyScript.fetchPlaybackTime()
            DispatchQueue.main.async {
                // Update the properties on the shared SongInfo object
                self.songInfo.currentTime = currentPosition
                self.songInfo.totalTime = trackDuration
                
                // Calculate the playback position percentage
                if trackDuration > 0 {
                    self.songInfo.playbackPosition = (currentPosition / trackDuration) * 100
                } else {
                    self.songInfo.playbackPosition = 0
                }
            }
        }
    }

    override func makeTouchBar() -> NSTouchBar? {
        print("✅ makeTouchBar called")
        let touchBar = NSTouchBar()
        touchBar.delegate = self
        touchBar.defaultItemIdentifiers = [.customTextItem, .lyricsItem, .flexibleSpace, .touchBarSystemVolumeGroup, .controls]
        return touchBar
    }
    
    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        
        
        let previousButton = NSButton(title: "⏮", target: self, action: #selector(previousTapped))
        let playPauseButton = NSButton(title: "►", target: self, action: #selector(playPauseTapped))
        let nextButton = NSButton(title: "⏭", target: self, action: #selector(nextTapped))
        
        let previousItem = NSCustomTouchBarItem(identifier: .init("previous"))
        previousItem.view = previousButton
        
        let playPauseItem = NSCustomTouchBarItem(identifier: .init("playPause"))
        playPauseItem.view = playPauseButton
        
        let nextItem = NSCustomTouchBarItem(identifier: .init("next"))
        nextItem.view = nextButton
        
        let customViewItem = NSCustomTouchBarItem(identifier: identifier)
        
        switch identifier {
        case .customTextItem:
            print("✅ Making custom touch bar item")
            let item = NSCustomTouchBarItem(identifier: identifier)
            
            // Artwork image view
            let artworkView = NSImageView()
            artworkView.imageScaling = .scaleProportionallyUpOrDown
            artworkView.translatesAutoresizingMaskIntoConstraints = false
            artworkView.widthAnchor.constraint(equalToConstant: 31).isActive = true
            artworkView.heightAnchor.constraint(equalToConstant: 31).isActive = true
            artworkView.wantsLayer = true
            artworkView.layer?.cornerRadius = 4
            artworkView.layer?.masksToBounds = true
            
            // Song title label
            let titleLabel = NSTextField(labelWithString: "")
            titleLabel.font = NSFont.boldSystemFont(ofSize: 14)
            titleLabel.lineBreakMode = .byTruncatingTail
            titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
            
            // Artist label
            let artistLabel = NSTextField(labelWithString: "")
            artistLabel.font = NSFont.systemFont(ofSize: 12)
            artistLabel.textColor = .secondaryLabelColor
            artistLabel.lineBreakMode = .byTruncatingTail
            artistLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
            
            // Store references for later updates
            self.songLabel = titleLabel
            self.artistLabel = artistLabel
            self.artworkImageView = artworkView
            
            // Vertical stack for song + artist
            let textStack = NSStackView(views: [titleLabel, artistLabel])
            textStack.orientation = .vertical
            textStack.alignment = .leading
            textStack.spacing = 2
            
            // Horizontal stack for artwork + text
            let mainStack = NSStackView(views: [artworkView, textStack])
            mainStack.orientation = .horizontal
            mainStack.spacing = 8
            mainStack.alignment = .centerY
            
            item.view = mainStack
            return item
            
        case .touchBarSystemVolumeGroup:
            let item = NSCustomTouchBarItem(identifier: identifier)
            
            // Create the buttons
            let volumeDownImage = NSImage(named: "volumeDownIcon")!
            volumeDownImage.size = NSSize(width: 15, height: 15)
            let volumeDownButton = NSButton(image: volumeDownImage, target: self, action: #selector(volumeDownTapped))
            
            let volumeUpImage = NSImage(named: "volumeUpIcon")!
            volumeUpImage.size = NSSize(width: 15, height: 15)
            let volumeUpButton = NSButton(image: volumeUpImage, target: self, action: #selector(volumeUpTapped))

            // Put them in a horizontal stack with no spacing to stick them together
            let stack = NSStackView(views: [volumeDownButton, volumeUpButton])
            stack.orientation = .horizontal
            stack.spacing = -4
            stack.edgeInsets = NSEdgeInsetsZero

            item.view = stack
            return item

        case .controls:
            print("✅ Making controls touch bar item")

            let item = NSCustomTouchBarItem(identifier: identifier)

            // Create buttons
            let prevButton = NSButton(title: "⏮", target: self, action: #selector(previousTapped))
            prevButton.font = NSFont.systemFont(ofSize: 20)

            let playPauseButton = NSButton(title: "►", target: self, action: #selector(playPauseTapped))
            //playPauseButton.font = NSFont.systemFont(ofSize: 18) // smaller if you want different size
            self.playPauseButton = playPauseButton // store reference

            let nextButton = NSButton(title: "⏭", target: self, action: #selector(nextTapped))
            nextButton.font = NSFont.systemFont(ofSize: 20)

            // Put them in a horizontal stack with *no* spacing
            let stack = NSStackView(views: [prevButton, playPauseButton, nextButton])
            stack.orientation = .horizontal
            stack.spacing = -4
            stack.edgeInsets = NSEdgeInsetsZero

            // Assign stack to the item view
            item.view = stack

            return item
            
        default:
            return nil
        }
    }
}
