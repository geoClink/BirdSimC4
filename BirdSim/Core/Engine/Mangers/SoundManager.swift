//
//  SoundManager.swift
//  BirdSim
//
//  Created by George Clinkscales on 2/3/26.
//

import SwiftData
import AVFoundation

enum GameTrack: String {
    case mainMap = "awesomeness"
    case nestBuilding = "song18"
    case feedingUser = "DST-TowerDefenseTheme"
    case predator = "Invasion"
    case leaveMap = "one_0"
    case feedingBaby = "Cyberpunk Moonlight Sonata v2"
    
    var fileName: String { self.rawValue }
}

enum SoundEffect: String {
    // --- Custom Sounds (Your files in Assets) ---
    case pickUp = "grab_effect"
    case building = "hammer_tap"
    case feedSuccess = "feedSuccess"
    
    // --- Apple System Sounds (Built-in) ---
    case tap = "1104"           // Standard UI Tap
    case tink = "1057"          // Light metallic "tink"
    case bloom = "1025"         // Soft chime (good for UI appearing)
    case alert = "1050"         // Soft pulse
    case complete = "1301"      // "Task Finished" chime
    case error = "1053"         // Low-pitched negative alert
    case swoosh = "1322"        // Air sound (good for scene transitions)
    
    
}

class SoundManager {
    static let shared = SoundManager()
    
    // Background Music Players (Do not change)
    private var musicPlayerA: AVAudioPlayer?
    private var musicPlayerB: AVAudioPlayer?
    private var isUsingPlayerA = true
    
    private var effectPlayers: [String: AVAudioPlayer] = [:]
    private(set) var currentTrack: String?

    private var isMusicEnabled: Bool = true
    private var musicVolume: Float = 0.5

    private init() {
        // Changed to .ambient so the game doesn't stop user's podcasts/Spotify unless you play music
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
    }
    
    // MARK: - Background Music (Original Logic)
    
    func startBackgroundMusic(track: GameTrack, fadeDuration: TimeInterval = 1.5) {
        let filename = track.fileName
        guard currentTrack != filename else { return }
        guard isMusicEnabled else { return }

        let extensions = ["wav", "mp3", "m4a"]
        var foundURL: URL?
        for ext in extensions {
            if let url = Bundle.main.url(forResource: filename, withExtension: ext) {
                foundURL = url
                break
            }
        }
        guard let url = foundURL else { return }

        do {
            let oldPlayer = isUsingPlayerA ? musicPlayerA : musicPlayerB
            let freshlyLoadedPlayer = try AVAudioPlayer(contentsOf: url)
            freshlyLoadedPlayer.numberOfLoops = -1
            freshlyLoadedPlayer.volume = 0
            freshlyLoadedPlayer.prepareToPlay()
            freshlyLoadedPlayer.play()
            
            freshlyLoadedPlayer.setVolume(musicVolume, fadeDuration: fadeDuration)
            oldPlayer?.setVolume(0, fadeDuration: fadeDuration)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + fadeDuration) {
                oldPlayer?.stop()
            }
            
            if isUsingPlayerA { musicPlayerB = freshlyLoadedPlayer } else { musicPlayerA = freshlyLoadedPlayer }
            isUsingPlayerA.toggle()
            currentTrack = filename
            
        } catch {
            print("❌ Crossfade Error: \(error)")
        }
    }

    func stopMusic() {
        musicPlayerA?.stop()
        musicPlayerB?.stop()
        currentTrack = nil
    }
    
    func setMusicEnabled(_ enabled: Bool) {
        isMusicEnabled = enabled
        if !enabled { stopMusic() }
    }

    func setMusicVolume(_ volume: Float) {
        musicVolume = volume
        musicPlayerA?.volume = volume
        musicPlayerB?.volume = volume
    }
    
    // MARK: - Sound Effects Logic
    
    /// Plays an effect from the SoundEffect enum. Automatically handles System IDs vs Files.
    func playEffect(_ effect: SoundEffect) {
        guard isMusicEnabled else { return }

        // Check if the value is a numeric SystemSoundID
        if let systemID = UInt32(effect.rawValue), systemID >= 1000 {
            AudioServicesPlaySystemSound(systemID)
        } else {
            // Otherwise, treat as a custom filename
            playSoundEffect(named: effect.rawValue)
        }
    }
    
    /// Internal helper to manage AVAudioPlayers for custom effect files
    func playSoundEffect(named filename: String) {
        guard isMusicEnabled else { return }
        
        if let player = effectPlayers[filename] {
            player.currentTime = 0
            player.play()
        } else {
            // Support multiple extensions for effects too
            let extensions = ["mp3", "wav", "m4a", "caf"]
            var foundURL: URL?
            
            for ext in extensions {
                if let url = Bundle.main.url(forResource: filename, withExtension: ext) {
                    foundURL = url
                    break
                }
            }
            
            guard let url = foundURL else {
                print("⚠️ Sound effect file not found: \(filename)")
                return
            }
            
            do {
                let newPlayer = try AVAudioPlayer(contentsOf: url)
                newPlayer.prepareToPlay()
                effectPlayers[filename] = newPlayer
                newPlayer.play()
            } catch {
                print("❌ Effect error: \(error)")
            }
        }
    }
}


//// Apple's built-in "Tink" sound
//SoundManager.shared.playEffect(.tink)
//
//// Your custom "swallow" sound file
//SoundManager.shared.playEffect(.feedSuccess)
