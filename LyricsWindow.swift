//
//  LyricsWindow.swift
//  lyrics
//
//  Created by heidi *⊹🥛◌◞🐈‍⬛𓂂𓏸  on 12/08/2025.
//

import SwiftUI

struct LyricsWindow: View {
    @ObservedObject var songInfo: SongInfo
    
    // Add these properties for the button callbacks
    var previousAction: () -> Void
    var playPauseAction: () -> Void
    var nextAction: () -> Void
    var scrubAction: (Double) -> Void // New action for scrubbing
    
    // Local state to manage slider interaction
    @State private var isEditing = false
    @State private var scrubValue: Double = 0.0
    
    // Helper function to format seconds into "mm:ss"
    private func formatTime(_ timeInSeconds: Double) -> String {
        let minutes = Int(timeInSeconds) / 60
        let seconds = Int(timeInSeconds) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var body: some View {
        VStack(spacing: 10) {
            // Artwork
            if let artwork = songInfo.artwork {
                Image(nsImage: artwork)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 170, height: 170)
                    .cornerRadius(10)
            } else {
                // Placeholder if no artwork is available
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray)
                    .frame(width: 170, height: 170)
                    .overlay(Text("No Artwork").foregroundColor(.white))
            }

            // Song Information
            VStack(spacing: 2) {
                Text(songInfo.songTitle)
                    .font(.headline)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                Text(songInfo.artist)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 0) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // The track
                        Capsule()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 5)

                        // The filled part of the track
                        Capsule()
                            .fill(Color.gray)
                            .frame(width: geometry.size.width * (CGFloat(scrubValue) / CGFloat(songInfo.totalTime)), height: 5)
                        
                        // The draggable thumb
                        Circle()
                            .fill(Color.white)
                            .frame(width: 8, height: 8)
                            .overlay(
                                Circle()
                                    .stroke(Color.pink, lineWidth: 0)
                            )
                            .shadow(radius: 2)
                            .offset(x: max(0, geometry.size.width * (CGFloat(scrubValue) / CGFloat(songInfo.totalTime)) - 7.5))
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        isEditing = true
                                        let newPosition = (value.location.x / geometry.size.width) * songInfo.totalTime
                                        scrubValue = min(songInfo.totalTime, max(0, newPosition))
                                    }
                                    .onEnded { value in
                                        isEditing = false
                                        scrubAction(self.scrubValue)
                                    }
                            )
                    }
                }
                .frame(height: 15)
                .padding(.horizontal)
                .onAppear {
                    scrubValue = songInfo.currentTime
                }
                .onChange(of: songInfo.currentTime) { newValue in
                    if !isEditing {
                        scrubValue = newValue
                    }
                }

                HStack {
                    Text(formatTime(isEditing ? scrubValue : songInfo.currentTime))
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formatTime(songInfo.totalTime))
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 20)
            }

            // Controls
            HStack(spacing: 15) {
                Button(action: previousAction) {
                    Image(systemName: "backward.end.fill")
                        .font(.title)
                }
                .buttonStyle(BorderlessButtonStyle())

                Button(action: playPauseAction) {
                    Image(systemName: songInfo.isPlaying ? "pause.fill" : "play.fill")
                        .font(.largeTitle)
                }
                .buttonStyle(BorderlessButtonStyle())
                
                Button(action: nextAction) {
                    Image(systemName: "forward.end.fill")
                        .font(.title)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
        }
        .padding()
        .frame(minWidth: 250, minHeight: 325)
    }
}


