//
//  DefeatScreenView.swift
//  Guildmaster
//
//  Full defeat screen with fallen heroes, epitaphs, and consequences
//

import SwiftUI
import Combine

/// Types of defeat
enum DefeatType: String {
    case totalPartyKill = "Total Party Kill"
    case partialWipe = "Party Defeated"
    case objectiveFailed = "Objective Failed"
    case retreat = "Tactical Retreat"

    var description: String {
        switch self {
        case .totalPartyKill: return "None survived to tell the tale..."
        case .partialWipe: return "The survivors limp home..."
        case .objectiveFailed: return "The mission has failed..."
        case .retreat: return "Discretion is the better part of valor..."
        }
    }
}

/// Epitaph generator for fallen heroes
enum EpitaphGenerator {

    /// Generate an epitaph for a fallen character
    static func generate(for character: Character, killedBy: String? = nil) -> String {
        let templates = epitaphTemplates(for: character.characterClass)
        var epitaph = templates.randomElement() ?? "Fell in battle."

        // Replace placeholders
        epitaph = epitaph.replacing("{name}", with: character.name)
        epitaph = epitaph.replacing("{class}", with: character.characterClass.rawValue)
        epitaph = epitaph.replacing("{race}", with: character.race.rawValue)

        if let killer = killedBy {
            epitaph = epitaph.replacing("{killer}", with: killer)
        } else {
            epitaph = epitaph.replacing(" by {killer}", with: "")
            epitaph = epitaph.replacing("{killer}", with: "the enemy")
        }

        return epitaph
    }

    private static func epitaphTemplates(for characterClass: CharacterClass) -> [String] {
        switch characterClass {
        case .warrior:
            return [
                "{name} died as they lived - sword in hand.",
                "A warrior's death for {name}. May their blade rest.",
                "{name} fell defending their allies to the last.",
                "The battlefield claims another brave {race}.",
                "{name} never retreated, even at the end."
            ]
        case .rogue:
            return [
                "The shadows finally claimed {name}.",
                "{name}'s luck finally ran out.",
                "Even the quickest blade couldn't save {name}.",
                "{name} slipped away... this time forever.",
                "The {race} rogue met an end as quiet as their steps."
            ]
        case .mage:
            return [
                "{name}'s magic fades from this world.",
                "The arcane light of {name} has been extinguished.",
                "{name}'s final spell goes uncast.",
                "Knowledge dies with the fallen {race}.",
                "{name}'s staff falls silent."
            ]
        case .cleric:
            return [
                "{name}'s prayers went unanswered today.",
                "May {name}'s god welcome them home.",
                "{name} healed many, but couldn't save themselves.",
                "The light fades from {name}'s eyes.",
                "Even divine favor couldn't protect {name}."
            ]
        }
    }
}

/// Defeat quotes by situation
enum DefeatQuotes {
    static func quote(for defeatType: DefeatType, survivors: Int) -> String {
        switch defeatType {
        case .totalPartyKill:
            return [
                "Darkness falls...",
                "All is lost...",
                "The guild hall awaits news that will never come...",
                "Silence where once there was battle...",
                "Their sacrifice will not be forgotten."
            ].randomElement() ?? "Defeat."

        case .partialWipe:
            return [
                "The survivors carry heavy burdens home.",
                "Victory was not meant to be today.",
                "They will return... but not whole.",
                "Some stories end in tragedy.",
                "The price of failure weighs heavy."
            ].randomElement() ?? "Defeat."

        case .objectiveFailed:
            return [
                "The mission is lost.",
                "They fought, but could not prevail.",
                "Another contract unfulfilled.",
                "The guild's reputation suffers this day."
            ].randomElement() ?? "Defeat."

        case .retreat:
            return [
                "Live to fight another day.",
                "A tactical withdrawal.",
                "Sometimes retreat is wisdom.",
                "There is no shame in survival."
            ].randomElement() ?? "Retreat."
        }
    }
}

/// View model for defeat screen
class DefeatScreenViewModel: ObservableObject {
    let party: [Character]
    let quest: Quest
    let defeatType: DefeatType

    @Published var fallenHeroes: [FallenHero] = []
    @Published var survivors: [Character] = []
    @Published var consequences: [String] = []

    init(party: [Character], quest: Quest) {
        self.party = party
        self.quest = quest

        // Determine defeat type
        let dead = party.filter { $0.hp <= 0 }
        let alive = party.filter { $0.hp > 0 }

        if dead.count == party.count {
            self.defeatType = .totalPartyKill
        } else if !dead.isEmpty {
            self.defeatType = .partialWipe
        } else {
            self.defeatType = .objectiveFailed
        }

        self.survivors = alive

        // Generate epitaphs for fallen
        self.fallenHeroes = dead.map { character in
            FallenHero(
                character: character,
                epitaph: EpitaphGenerator.generate(for: character)
            )
        }

        // Generate consequences
        calculateConsequences()
    }

    private func calculateConsequences() {
        var result: [String] = []

        // Gold loss
        let goldLoss = quest.rewards.gold / 2
        if goldLoss > 0 {
            result.append("Lost equipment worth \(goldLoss) gold")
        }

        // Reputation loss
        result.append("Guild reputation decreased")

        // Survivor injuries
        for survivor in survivors {
            if survivor.hpPercentage < 0.5 {
                result.append("\(survivor.name) is seriously injured")
            }
        }

        // Stress increase
        if !survivors.isEmpty {
            result.append("Survivors are stressed and demoralized")
        }

        consequences = result
    }
}

/// Data for a fallen hero
struct FallenHero: Identifiable {
    let id = UUID()
    let character: Character
    let epitaph: String
}

/// Full defeat screen view
struct DefeatScreenView: View {
    @ObservedObject var viewModel: DefeatScreenViewModel
    let onContinue: () -> Void

    @State private var showConsequences = false

    var body: some View {
        ZStack {
            // Dark background
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.05, blue: 0.05),
                    Color(red: 0.15, green: 0.08, blue: 0.08)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Defeat Banner
                    defeatBanner

                    // Fallen Heroes
                    if !viewModel.fallenHeroes.isEmpty {
                        fallenHeroesCard
                    }

                    // Survivors
                    if !viewModel.survivors.isEmpty {
                        survivorsCard
                    }

                    // Consequences
                    if showConsequences {
                        consequencesCard
                    }

                    // Continue Button
                    Button("Return to Guild Hall") {
                        onContinue()
                    }
                    .buttonStyle(DefeatButtonStyle())
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
                .padding()
            }
        }
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - Defeat Banner

    private var defeatBanner: some View {
        VStack(spacing: 12) {
            // Skull icon
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red.opacity(0.8))

            Text(viewModel.defeatType.rawValue.uppercased())
                .font(.system(size: 32, weight: .bold, design: .serif))
                .foregroundColor(.red)

            Text(viewModel.quest.title)
                .font(.title3)
                .foregroundColor(.white.opacity(0.6))

            Text(DefeatQuotes.quote(for: viewModel.defeatType, survivors: viewModel.survivors.count))
                .font(.subheadline.italic())
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical, 20)
    }

    // MARK: - Fallen Heroes

    private var fallenHeroesCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "heart.slash.fill")
                    .foregroundColor(.red)
                Text("Fallen Heroes")
                    .font(.headline)
                    .foregroundColor(.red)
            }

            ForEach(viewModel.fallenHeroes) { fallen in
                fallenHeroRow(fallen)
            }
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(12)
    }

    private func fallenHeroRow(_ fallen: FallenHero) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                // Crossed out portrait
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 50, height: 50)

                    Text(String(fallen.character.characterClass.rawValue.prefix(1)))
                        .font(.title2)
                        .foregroundColor(.gray)

                    // X overlay
                    Image(systemName: "xmark")
                        .font(.title)
                        .foregroundColor(.red.opacity(0.7))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(fallen.character.name)
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                        .strikethrough(color: .red)

                    Text("\(fallen.character.race.rawValue) \(fallen.character.characterClass.rawValue)")
                        .font(.caption)
                        .foregroundColor(.gray)

                    Text("Level \(fallen.character.level)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()
            }

            // Epitaph
            Text("\"\(fallen.epitaph)\"")
                .font(.caption.italic())
                .foregroundColor(.white.opacity(0.5))
                .padding(.leading, 62)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Survivors

    private var survivorsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.fill.checkmark")
                    .foregroundColor(.orange)
                Text("Survivors")
                    .font(.headline)
                    .foregroundColor(.orange)
            }

            ForEach(viewModel.survivors, id: \.id) { survivor in
                survivorRow(survivor)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }

    private func survivorRow(_ character: Character) -> some View {
        HStack(spacing: 12) {
            // Portrait
            ZStack {
                Circle()
                    .fill(classColor(character.characterClass))
                    .frame(width: 40, height: 40)

                Text(String(character.characterClass.rawValue.prefix(1)))
                    .font(.headline)
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(character.name)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)

                // HP bar
                HStack(spacing: 4) {
                    ProgressView(value: character.hpPercentage)
                        .progressViewStyle(LinearProgressViewStyle(tint: hpColor(character.hpPercentage)))
                        .frame(width: 80)

                    Text("\(character.hp)/\(character.maxHP)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            // Status
            if character.hpPercentage < 0.3 {
                Text("Critical")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.red.opacity(0.2))
                    .cornerRadius(4)
            } else if character.hpPercentage < 0.6 {
                Text("Injured")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(4)
            }
        }
    }

    // MARK: - Consequences

    private var consequencesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.yellow)
                Text("Consequences")
                    .font(.headline)
                    .foregroundColor(.yellow)
            }

            ForEach(viewModel.consequences, id: \.self) { consequence in
                HStack(spacing: 8) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.red.opacity(0.7))
                        .font(.caption)
                    Text(consequence)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .padding()
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(12)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    // MARK: - Helpers

    private func classColor(_ characterClass: CharacterClass) -> Color {
        switch characterClass {
        case .warrior: return .red.opacity(0.6)
        case .rogue: return .purple.opacity(0.6)
        case .mage: return .blue.opacity(0.6)
        case .cleric: return .yellow.opacity(0.6)
        }
    }

    private func hpColor(_ percentage: Double) -> Color {
        if percentage < 0.3 { return .red }
        if percentage < 0.6 { return .orange }
        return .green
    }

    private func startAnimations() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.5)) {
                showConsequences = true
            }
        }
    }
}

/// Button style for defeat screen
struct DefeatButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(.horizontal, 40)
            .padding(.vertical, 14)
            .background(Color.gray.opacity(0.3))
            .foregroundColor(.white.opacity(0.8))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}

// MARK: - Preview

#Preview {
    let party = [
        Character(name: "Grimjaw", race: .orc, characterClass: .warrior),
        Character(name: "Elara", race: .elf, characterClass: .mage)
    ]

    // Simulate deaths
    party[0].hp = 0
    party[1].hp = 15

    let quest = Quest.goblinCamp()

    let viewModel = DefeatScreenViewModel(party: party, quest: quest)

    return DefeatScreenView(viewModel: viewModel) {
        print("Continue")
    }
}
