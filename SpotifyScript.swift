// SpotifyScript.swift

import Foundation
import Cocoa

class SpotifyScript {

    // A callback to notify when the song information and artwork has changed.
    var onTrackChange: ((String, NSImage?) -> Void)?
    var onPlayerStateChange: ((String) -> Void)? // New callback for player state

    func fetchCurrentTrack() {
        let script = """
        if application "Spotify" is running then
            tell application "Spotify"
                if current track is not missing value then
                    set trackName to name of current track
                    set artistName to artist of current track
                    set artworkUrl to artwork url of current track
                    set playerState to player state as string
                    return trackName & " by " & artistName & " | " & artworkUrl & " | " & playerState
                end if
            end tell
        end if
        return " |  | paused"
        """ 

        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            let output = scriptObject.executeAndReturnError(&error)
            
            if error == nil {
                let result = output.stringValue ?? ""
                
                // Check for valid output before parsing
                if result.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !result.contains(" | ") {
                    DispatchQueue.main.async {
                        self.onTrackChange?("No song playing", nil)
                        self.onPlayerStateChange?("paused")
                    }
                    return
                }
                
                let components = result.components(separatedBy: " | ")
                let trackInfo = components.first ?? " "
                let artworkUrlString = components.count > 1 ? components[1] : nil
                let playerState = components.count > 2 ? components[2] : "paused"

                var albumArt: NSImage?
                if let urlString = artworkUrlString, let url = URL(string: urlString) {
                    // Download the image from the URL on a background thread
                    URLSession.shared.dataTask(with: url) { (data, response, error) in
                        if let data = data, let image = NSImage(data: data) {
                            albumArt = image
                        }
                        // Update UI on the main thread
                        DispatchQueue.main.async {
                            self.onTrackChange?(trackInfo, albumArt)
                            self.onPlayerStateChange?(playerState) // Trigger the new callback
                        }
                    }.resume()
                } else {
                    self.onTrackChange?(trackInfo, nil)
                }
            } else {
                print("❌ AppleScript execution failed with error: \(error?.description ?? "Unknown error")")
                self.onTrackChange?("Error", nil)
            }
        }
    }
    
    func getCurrentTrackInfo() -> (artist: String, title: String)? {
        let script = """
        tell application "Spotify"
            if player state is playing then
                set trackName to name of current track
                set trackArtist to artist of current track
                return trackName & "||" & trackArtist
            else
                return ""
            end if
        end tell
        """
        
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script),
           let output = scriptObject.executeAndReturnError(&error).stringValue {
            if output.contains("||") {
                let parts = output.components(separatedBy: "||")
                return (parts[1], parts[0]) // artist, title
            }
        }
        return nil
    }

    func fetchPlaybackPosition() -> Double {
        let script = """
            if application "Spotify" is running then
                tell application "Spotify"
                    if player state is playing then
                        set currentPosition to player position
                        set trackDuration to (duration of current track / 1000)
                        if trackDuration is greater than 0 then
                            return (currentPosition / trackDuration) * 100
                        end if
                    end if
                end tell
            end if
            return 0
        """
        
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            if let output = scriptObject.executeAndReturnError(&error).stringValue {
                return Double(output) ?? 0.0
            }
        }
        return 0.0
    }
    
    // Inside your SpotifyScript.swift file
    func fetchPlaybackTime() -> (currentPosition: Double, trackDuration: Double) {
        let script = """
            if application "Spotify" is running then
                tell application "Spotify"
                    set currentPosition to player position
                    set trackDuration to (duration of current track / 1000)
                    return (currentPosition as string) & "," & (trackDuration as string)
                end tell
            end if
            return "0,0"
        """
        
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            if let output = scriptObject.executeAndReturnError(&error).stringValue {
                let components = output.components(separatedBy: ",")
                if components.count == 2,
                   let currentPosition = Double(components[0]),
                   let trackDuration = Double(components[1]) {
                    return (currentPosition, trackDuration)
                }
            }
        }
        return (0.0, 0.0)
    }
    
    func fetchCurrentPlayerState() -> String {
        let script = """
            if application "Spotify" is running then
                tell application "Spotify"
                    return player state as string
                end tell
            end if
            return "stopped"
        """
        
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            if let output = scriptObject.executeAndReturnError(&error).stringValue {
                return output
            }
        }
        return "stopped"
    }
    
    func spotifySetPlaybackPosition(to time: Double) {
        let script = """
            if application "Spotify" is running then
                tell application "Spotify"
                    set player position to \(time)
                end tell
            end if
        """
        
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            scriptObject.executeAndReturnError(&error)
        }
    }
    
    func systemVolumeUp() {
        let script = """
            set volume output volume ((get volume settings)'s output volume + 10)
        """
        
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            scriptObject.executeAndReturnError(&error)
        }
    }

    func systemVolumeDown() {
        let script = """
            set volume output volume ((get volume settings)'s output volume - 10)
        """
        
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            scriptObject.executeAndReturnError(&error)
        }
    }
    
    func spotifyPreviousTrack() {
        let script = "tell application \"Spotify\" to previous track"
        runAppleScript(source: script)
    }

    func spotifyNextTrack() {
        let script = "tell application \"Spotify\" to next track"
        runAppleScript(source: script)
    }

    func spotifyTogglePlayPause() {
        let script = """
        tell application "Spotify"
            if player state is playing then
                pause
            else
                play
            end if
        end tell
        """
        runAppleScript(source: script)
    }

    func runAppleScript(source: String) {
        if let appleScript = NSAppleScript(source: source) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
            if let error = error {
                print("AppleScript error: \(error)")
            }
        }
    }

}
