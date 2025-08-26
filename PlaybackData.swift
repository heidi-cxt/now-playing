//
//  PlaybackData.swift
//  lyrics
//
//  Created by heidi *⊹🥛◌◞🐈‍⬛𓂂𓏸  on 12/08/2025.
//

import Foundation
import SwiftUI

class SongInfo: ObservableObject {
    @Published var artwork: NSImage?
    @Published var songTitle: String = "No Song Playing"
    @Published var artist: String = ""
    @Published var playbackPosition: Double = 0.0
    
    // Add these properties to store the time in seconds
    @Published var currentTime: Double = 0.0
    @Published var totalTime: Double = 0.0
    
    @Published var isPlaying: Bool = false
}
