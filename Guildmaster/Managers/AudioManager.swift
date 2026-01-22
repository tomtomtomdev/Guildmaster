//
//  AudioManager.swift
//  Guildmaster
//
//  Manages sound effects and music playback
//

import Foundation
import AVFoundation
import Combine

// MARK: - Sound Types

/// Categories of sound effects
enum SoundCategory: String {
    case ui = "UI"
    case combat = "Combat"
    case ambient = "Ambient"
    case music = "Music"
}

/// Available sound effects
enum SoundEffect: String, CaseIterable {
    // UI Sounds
    case buttonTap = "button_tap"
    case menuOpen = "menu_open"
    case menuClose = "menu_close"
    case goldCoins = "gold_coins"
    case notification = "notification"
    case levelUp = "level_up"
    case questAccept = "quest_accept"
    case questComplete = "quest_complete"
    case error = "error"

    // Combat Sounds
    case swordSwing = "sword_swing"
    case swordHit = "sword_hit"
    case bowShot = "bow_shot"
    case arrowHit = "arrow_hit"
    case magicCast = "magic_cast"
    case fireball = "fireball"
    case heal = "heal"
    case shield = "shield"
    case criticalHit = "critical_hit"
    case miss = "miss"
    case block = "block"
    case death = "death"
    case victory = "victory"
    case defeat = "defeat"
    case turnStart = "turn_start"
    case combatStart = "combat_start"

    // Ambient
    case footsteps = "footsteps"
    case doorOpen = "door_open"
    case chestOpen = "chest_open"

    var category: SoundCategory {
        switch self {
        case .buttonTap, .menuOpen, .menuClose, .goldCoins, .notification, .levelUp,
             .questAccept, .questComplete, .error:
            return .ui
        case .swordSwing, .swordHit, .bowShot, .arrowHit, .magicCast, .fireball,
             .heal, .shield, .criticalHit, .miss, .block, .death, .victory,
             .defeat, .turnStart, .combatStart:
            return .combat
        case .footsteps, .doorOpen, .chestOpen:
            return .ambient
        }
    }

    var defaultVolume: Float {
        switch category {
        case .ui: return 0.6
        case .combat: return 0.8
        case .ambient: return 0.4
        case .music: return 0.5
        }
    }
}

/// Available music tracks
enum MusicTrack: String, CaseIterable {
    case mainMenu = "main_menu"
    case guildHall = "guild_hall"
    case combat = "combat"
    case combatIntense = "combat_intense"
    case victory = "victory_theme"
    case defeat = "defeat_theme"
    case exploration = "exploration"
    case tavern = "tavern"

    var shouldLoop: Bool {
        switch self {
        case .victory, .defeat:
            return false
        default:
            return true
        }
    }
}

// MARK: - Audio Manager

/// Singleton manager for all game audio
class AudioManager: ObservableObject {
    static let shared = AudioManager()

    // MARK: - Published Properties

    @Published var isMusicEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(isMusicEnabled, forKey: "musicEnabled")
            if !isMusicEnabled {
                stopMusic()
            }
        }
    }

    @Published var isSoundEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(isSoundEnabled, forKey: "soundEnabled")
        }
    }

    @Published var musicVolume: Float = 0.5 {
        didSet {
            UserDefaults.standard.set(musicVolume, forKey: "musicVolume")
            musicPlayer?.volume = musicVolume
        }
    }

    @Published var soundVolume: Float = 0.7 {
        didSet {
            UserDefaults.standard.set(soundVolume, forKey: "soundVolume")
        }
    }

    // MARK: - Private Properties

    private var musicPlayer: AVAudioPlayer?
    private var soundPlayers: [String: AVAudioPlayer] = [:]
    private var currentMusicTrack: MusicTrack?
    private var preloadedSounds: [String: AVAudioPlayer] = [:]

    // MARK: - Initialization

    private init() {
        loadSettings()
        setupAudioSession()
        preloadCommonSounds()
    }

    private func loadSettings() {
        isMusicEnabled = UserDefaults.standard.object(forKey: "musicEnabled") as? Bool ?? true
        isSoundEnabled = UserDefaults.standard.object(forKey: "soundEnabled") as? Bool ?? true
        musicVolume = UserDefaults.standard.object(forKey: "musicVolume") as? Float ?? 0.5
        soundVolume = UserDefaults.standard.object(forKey: "soundVolume") as? Float ?? 0.7
    }

    private func setupAudioSession() {
        #if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
        #endif
    }

    private func preloadCommonSounds() {
        // Preload frequently used sounds for instant playback
        let commonSounds: [SoundEffect] = [.buttonTap, .swordHit, .heal, .turnStart]
        for sound in commonSounds {
            if let player = createPlayer(for: sound.rawValue, type: "wav") {
                player.prepareToPlay()
                preloadedSounds[sound.rawValue] = player
            }
        }
    }

    // MARK: - Sound Effects

    /// Play a sound effect
    func playSound(_ effect: SoundEffect) {
        guard isSoundEnabled else { return }

        // Check preloaded sounds first
        if let player = preloadedSounds[effect.rawValue] {
            player.volume = effect.defaultVolume * soundVolume
            player.currentTime = 0
            player.play()
            return
        }

        // Create new player if not preloaded
        guard let player = createPlayer(for: effect.rawValue, type: "wav") else {
            // Sound file doesn't exist - this is expected during development
            return
        }

        player.volume = effect.defaultVolume * soundVolume
        player.play()

        // Store reference to prevent deallocation
        soundPlayers[effect.rawValue] = player
    }

    /// Play a sound effect with delay
    func playSound(_ effect: SoundEffect, delay: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.playSound(effect)
        }
    }

    /// Play combat sound based on action type
    func playCombatSound(for action: CombatSoundAction) {
        let sound: SoundEffect
        switch action {
        case .meleeAttack:
            sound = .swordSwing
        case .meleeHit:
            sound = .swordHit
        case .rangedAttack:
            sound = .bowShot
        case .rangedHit:
            sound = .arrowHit
        case .spellCast:
            sound = .magicCast
        case .heal:
            sound = .heal
        case .miss:
            sound = .miss
        case .critical:
            sound = .criticalHit
        case .block:
            sound = .block
        case .death:
            sound = .death
        }
        playSound(sound)
    }

    // MARK: - Music

    /// Play a music track
    func playMusic(_ track: MusicTrack, fadeIn: Bool = true) {
        guard isMusicEnabled else { return }

        // Don't restart the same track
        if currentMusicTrack == track && musicPlayer?.isPlaying == true {
            return
        }

        // Stop current music
        if fadeIn && musicPlayer?.isPlaying == true {
            fadeOutMusic { [weak self] in
                self?.startMusic(track)
            }
        } else {
            startMusic(track)
        }
    }

    private func startMusic(_ track: MusicTrack) {
        guard let player = createPlayer(for: track.rawValue, type: "mp3") else {
            // Music file doesn't exist - expected during development
            return
        }

        currentMusicTrack = track
        musicPlayer = player
        musicPlayer?.volume = 0
        musicPlayer?.numberOfLoops = track.shouldLoop ? -1 : 0
        musicPlayer?.play()

        // Fade in
        fadeInMusic()
    }

    /// Stop music playback
    func stopMusic(fadeOut: Bool = true) {
        if fadeOut {
            fadeOutMusic { [weak self] in
                self?.musicPlayer?.stop()
                self?.currentMusicTrack = nil
            }
        } else {
            musicPlayer?.stop()
            currentMusicTrack = nil
        }
    }

    /// Pause music
    func pauseMusic() {
        musicPlayer?.pause()
    }

    /// Resume music
    func resumeMusic() {
        guard isMusicEnabled else { return }
        musicPlayer?.play()
    }

    private func fadeInMusic(duration: TimeInterval = 1.0) {
        guard let player = musicPlayer else { return }

        let targetVolume = musicVolume
        let steps = 20
        let stepDuration = duration / Double(steps)
        let volumeStep = targetVolume / Float(steps)

        for i in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) {
                player.volume = volumeStep * Float(i)
            }
        }
    }

    private func fadeOutMusic(duration: TimeInterval = 0.5, completion: @escaping () -> Void) {
        guard let player = musicPlayer else {
            completion()
            return
        }

        let startVolume = player.volume
        let steps = 10
        let stepDuration = duration / Double(steps)
        let volumeStep = startVolume / Float(steps)

        for i in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) {
                player.volume = startVolume - (volumeStep * Float(i))
                if i == steps {
                    completion()
                }
            }
        }
    }

    // MARK: - Helpers

    private func createPlayer(for name: String, type: String) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: name, withExtension: type) else {
            return nil
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            return player
        } catch {
            print("Failed to create audio player for \(name): \(error)")
            return nil
        }
    }

    // MARK: - Scene-Based Music

    /// Play appropriate music for a game screen
    func playMusicForScreen(_ screen: GameScreen) {
        switch screen {
        case .mainMenu:
            playMusic(.mainMenu)
        case .guildHall, .barracks, .recruitment, .inventory, .ledger, .training, .settings:
            playMusic(.guildHall)
        case .questBoard, .partySelection:
            playMusic(.exploration)
        case .questFlow, .testCombat:
            playMusic(.combat)
        case .questResult:
            // Music will be set by quest result (victory/defeat)
            break
        }
    }

    /// Play victory or defeat music
    func playResultMusic(victory: Bool) {
        playMusic(victory ? .victory : .defeat)
    }
}

// MARK: - Combat Sound Action

enum CombatSoundAction {
    case meleeAttack
    case meleeHit
    case rangedAttack
    case rangedHit
    case spellCast
    case heal
    case miss
    case critical
    case block
    case death
}

// MARK: - Audio Extensions for Combat

extension AudioManager {
    /// Play sound for ability usage
    func playSoundForAbility(_ abilityType: AbilityType) {
        switch abilityType {
        case .powerAttack, .cleave, .shieldBash, .whirlwind:
            playSound(.swordSwing)
        case .sneakAttack, .backstab, .poisonBlade:
            playSound(.swordSwing)
        case .hide, .evasion:
            playSound(.footsteps)
        case .magicMissile, .fireball, .haste, .counterspell:
            playSound(.magicCast)
        case .shield:
            playSound(.shield)
        case .cureWounds, .massHealing:
            playSound(.heal)
        case .bless, .divineSmite:
            playSound(.magicCast)
        case .turnUndead:
            playSound(.magicCast)
        case .secondWind:
            playSound(.heal)
        case .basicAttack:
            playSound(.swordSwing)
        case .defend:
            playSound(.shield)
        case .move:
            playSound(.footsteps)
        }
    }

    /// Play hit sound based on damage type
    func playHitSound(isCritical: Bool, isRanged: Bool) {
        if isCritical {
            playSound(.criticalHit)
        } else if isRanged {
            playSound(.arrowHit)
        } else {
            playSound(.swordHit)
        }
    }
}
