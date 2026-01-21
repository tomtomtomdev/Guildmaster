//
//  SaveManager.swift
//  Guildmaster
//
//  Persistence layer for saving and loading game state
//

import Foundation
import Combine

/// Manages saving and loading game state
class SaveManager {

    // MARK: - Singleton

    static let shared = SaveManager()

    // MARK: - Constants

    private let saveKey = "GuildmasterSaveData"
    private let userDefaults = UserDefaults.standard

    // MARK: - Initialization

    private init() {
        setupNotificationObservers()
    }

    private var cancellables = Set<AnyCancellable>()

    private func setupNotificationObservers() {
        // Auto-save on quest completion
        NotificationCenter.default.publisher(for: .questCompleted)
            .sink { [weak self] _ in
                self?.save()
            }
            .store(in: &cancellables)
    }

    // MARK: - Save

    /// Save current game state to UserDefaults
    func save() {
        let saveData = GameSaveData(
            guild: GuildManager.shared.save(),
            items: ItemManager.shared.save(),
            quests: QuestManager.shared.save(),
            recruitment: RecruitmentManager.shared.save()
        )

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(saveData)
            userDefaults.set(data, forKey: saveKey)
            userDefaults.synchronize()
            print("[SaveManager] Game saved successfully")
        } catch {
            print("[SaveManager] Failed to save game: \(error)")
        }
    }

    // MARK: - Load

    /// Load game state from UserDefaults
    func load() -> Bool {
        guard let data = userDefaults.data(forKey: saveKey) else {
            print("[SaveManager] No save data found")
            return false
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let saveData = try decoder.decode(GameSaveData.self, from: data)

            // Restore all managers
            GuildManager.shared.load(from: saveData.guild)
            ItemManager.shared.load(from: saveData.items)
            QuestManager.shared.load(from: saveData.quests)
            RecruitmentManager.shared.load(from: saveData.recruitment)

            print("[SaveManager] Game loaded successfully")
            return true
        } catch {
            print("[SaveManager] Failed to load game: \(error)")
            return false
        }
    }

    // MARK: - Utility

    /// Check if save data exists
    func hasSaveData() -> Bool {
        return userDefaults.data(forKey: saveKey) != nil
    }

    /// Delete save data
    func deleteSave() {
        userDefaults.removeObject(forKey: saveKey)
        userDefaults.synchronize()
        print("[SaveManager] Save data deleted")
    }

    /// Get save file size (approximate)
    var saveDataSize: Int {
        return userDefaults.data(forKey: saveKey)?.count ?? 0
    }
}

// MARK: - Game Save Data

/// Combined save data from all managers
struct GameSaveData: Codable {
    let guild: GuildSaveData
    let items: ItemManagerSaveData
    let quests: QuestManagerSaveData
    let recruitment: RecruitmentSaveData
    let saveVersion: Int
    let saveDate: Date

    init(
        guild: GuildSaveData,
        items: ItemManagerSaveData,
        quests: QuestManagerSaveData,
        recruitment: RecruitmentSaveData
    ) {
        self.guild = guild
        self.items = items
        self.quests = quests
        self.recruitment = recruitment
        self.saveVersion = 1
        self.saveDate = Date()
    }
}
