//
//  AdventurerDetailView.swift
//  Guildmaster
//
//  Comprehensive view for character details including personality, traits, and skills
//

import SwiftUI

/// Full-featured adventurer detail view
struct AdventurerDetailView: View {
    let character: Character
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: DetailTab = .overview

    enum DetailTab: String, CaseIterable {
        case overview = "Overview"
        case personality = "Personality"
        case skills = "Skills"
        case traits = "Traits"
        case relationships = "Relations"
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.12, green: 0.1, blue: 0.08)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header with portrait
                    adventurerHeader

                    // Tab selector
                    tabSelector

                    // Content based on tab
                    ScrollView {
                        switch selectedTab {
                        case .overview:
                            overviewContent
                        case .personality:
                            personalityContent
                        case .skills:
                            skillsContent
                        case .traits:
                            traitsContent
                        case .relationships:
                            relationshipsContent
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Header

    private var adventurerHeader: some View {
        HStack(spacing: 16) {
            // Portrait
            CharacterPortrait(character: character, size: 70)

            VStack(alignment: .leading, spacing: 4) {
                Text(character.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("\(character.race.rawValue) \(character.characterClass.rawValue)")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                HStack(spacing: 12) {
                    Label("Lv.\(character.level)", systemImage: "star.fill")
                        .font(.caption)
                        .foregroundColor(.blue)

                    Label("\(character.satisfaction)%", systemImage: satisfactionIcon)
                        .font(.caption)
                        .foregroundColor(satisfactionColor)
                }
            }

            Spacer()

            // AI Tier badge
            aiTierBadge
        }
        .padding()
        .background(Color.black.opacity(0.3))
    }

    private var aiTierBadge: some View {
        VStack(spacing: 2) {
            Text(aiTierName)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text("INT")
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(aiTierColor.opacity(0.3))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(aiTierColor, lineWidth: 1)
        )
    }

    private var aiTierName: String {
        if character.stats.int <= 8 { return "LOW" }
        if character.stats.int <= 14 { return "MED" }
        return "HIGH"
    }

    private var aiTierColor: Color {
        if character.stats.int <= 8 { return .red }
        if character.stats.int <= 14 { return .yellow }
        return .green
    }

    private var satisfactionIcon: String {
        if character.satisfaction >= 70 { return "face.smiling" }
        if character.satisfaction >= 40 { return "face.dashed" }
        return "face.dashed.fill"
    }

    private var satisfactionColor: Color {
        if character.satisfaction >= 70 { return .green }
        if character.satisfaction >= 40 { return .yellow }
        return .red
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(DetailTab.allCases, id: \.self) { tab in
                    Button(action: { selectedTab = tab }) {
                        Text(tab.rawValue)
                            .font(.caption)
                            .fontWeight(selectedTab == tab ? .bold : .regular)
                            .foregroundColor(selectedTab == tab ? .white : .gray)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedTab == tab ? Color.blue.opacity(0.3) : Color.clear)
                            .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.2))
    }

    // MARK: - Overview Content

    private var overviewContent: some View {
        VStack(spacing: 16) {
            // Stats Grid
            statsGrid

            // Combat Stats
            combatStatsSection

            // Resources
            resourcesSection

            // History
            historySection
        }
        .padding()
    }

    private var statsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Attributes")

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatDisplay(name: "STR", value: character.stats.str)
                StatDisplay(name: "DEX", value: character.stats.dex)
                StatDisplay(name: "CON", value: character.stats.con)
                StatDisplay(name: "INT", value: character.stats.int)
                StatDisplay(name: "WIS", value: character.stats.wis)
                StatDisplay(name: "CHA", value: character.stats.cha)
            }
        }
        .sectionStyle()
    }

    private var combatStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Combat")

            HStack(spacing: 0) {
                combatStatItem("HP", "\(character.secondaryStats.hp)/\(character.secondaryStats.maxHP)", .red)
                Divider().frame(height: 40)
                combatStatItem("AC", "\(character.secondaryStats.armorClass)", .blue)
                Divider().frame(height: 40)
                combatStatItem("Init", "+\(character.secondaryStats.initiative)", .green)
                Divider().frame(height: 40)
                combatStatItem("Speed", "\(character.secondaryStats.movementSpeed)", .orange)
            }
        }
        .sectionStyle()
    }

    private func combatStatItem(_ name: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .foregroundColor(color)
            Text(name)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }

    private var resourcesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Resources")

            ResourceBar(
                label: "Health",
                current: character.secondaryStats.hp,
                max: character.secondaryStats.maxHP,
                color: .red
            )

            if character.characterClass == .mage || character.characterClass == .cleric {
                ResourceBar(
                    label: "Mana",
                    current: character.secondaryStats.mana,
                    max: character.secondaryStats.maxMana,
                    color: .blue
                )
            }

            ResourceBar(
                label: "Stamina",
                current: character.secondaryStats.stamina,
                max: character.secondaryStats.maxStamina,
                color: .yellow
            )

            // Stress bar
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("Stress")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Spacer()
                    Text("\(character.stress)/100")
                        .font(.caption2)
                        .foregroundColor(stressColor)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.gray.opacity(0.3))

                        RoundedRectangle(cornerRadius: 2)
                            .fill(stressColor)
                            .frame(width: geometry.size.width * CGFloat(character.stress) / 100)
                    }
                }
                .frame(height: 4)
            }
        }
        .sectionStyle()
    }

    private var stressColor: Color {
        if character.stress >= 70 { return .red }
        if character.stress >= 40 { return .orange }
        return .green
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("History")

            HStack {
                historyItem("\(character.questsCompleted)", "Quests", .green)
                historyItem("\(character.questsFailed)", "Failed", .red)
                historyItem("\(character.totalKills)", "Kills", .orange)
                historyItem("\(character.daysSinceRest)", "Days Rested", .blue)
            }
        }
        .sectionStyle()
    }

    private func historyItem(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Personality Content

    private var personalityContent: some View {
        VStack(spacing: 16) {
            // Personality dimensions
            personalityDimensionsSection

            // Combat behavior
            combatBehaviorSection
        }
        .padding()
    }

    private var personalityDimensionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Personality Traits")

            PersonalityBar(trait: "Greedy", value: character.personality.greedy,
                          lowLabel: "Generous", highLabel: "Greedy", color: .yellow)
            PersonalityBar(trait: "Loyal", value: character.personality.loyal,
                          lowLabel: "Fickle", highLabel: "Devoted", color: .blue)
            PersonalityBar(trait: "Brave", value: character.personality.brave,
                          lowLabel: "Cautious", highLabel: "Fearless", color: .red)
            PersonalityBar(trait: "Cautious", value: character.personality.cautious,
                          lowLabel: "Reckless", highLabel: "Careful", color: .green)
        }
        .sectionStyle()
    }

    private var combatBehaviorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Combat Behavior")

            let behavior = character.personality.combatBehavior

            HStack(spacing: 16) {
                behaviorItem("Aggression", Int(behavior.aggressionModifier * 10), behavior.aggressionModifier > 0.5)
                behaviorItem("Self-Preservation", Int(behavior.selfPreservation * 10), behavior.selfPreservation > 0.5)
                behaviorItem("Ally Priority", Int(behavior.allyProtection * 10), behavior.allyProtection > 0.5)
            }

            if behavior.riskTolerance < 0.3 {
                HStack {
                    Image(systemName: "scope")
                    Text("Prefers ranged combat")
                }
                .font(.caption)
                .foregroundColor(.blue)
                .padding(.top, 4)
            }

            if behavior.fleeThreshold > 0.3 {
                HStack {
                    Image(systemName: "figure.run")
                    Text("May flee when HP below \(Int(behavior.fleeThreshold * 100))%")
                }
                .font(.caption)
                .foregroundColor(.orange)
            }
        }
        .sectionStyle()
    }

    private func behaviorItem(_ label: String, _ value: Int, _ isPositive: Bool) -> some View {
        VStack(spacing: 4) {
            Text(isPositive ? "+\(value)" : "\(value)")
                .font(.headline)
                .foregroundColor(isPositive ? .green : .gray)
            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Skills Content

    private var skillsContent: some View {
        VStack(spacing: 16) {
            sectionHeader("Utility Skills")

            ForEach(SkillType.allCases, id: \.self) { skill in
                SkillRow(
                    skill: skill,
                    modifier: character.skillModifier(for: skill),
                    isClassSkill: SkillManager.shared.isClassSkill(skill, for: character.characterClass)
                )
            }
        }
        .padding()
        .sectionStyle()
    }

    // MARK: - Traits Content

    private var traitsContent: some View {
        VStack(spacing: 16) {
            // Racial traits
            racialTraitsSection

            // Class traits
            classTraitsSection

            // Acquired traits
            acquiredTraitsSection
        }
        .padding()
    }

    private var racialTraitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Racial Trait")

            TraitDetailRow(
                name: character.racialTrait.rawValue,
                description: character.racialTrait.description,
                type: .racial
            )
        }
        .sectionStyle()
    }

    private var classTraitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Class Trait")

            TraitDetailRow(
                name: character.classTrait.rawValue,
                description: character.classTrait.description,
                type: .class_
            )
        }
        .sectionStyle()
    }

    private var acquiredTraitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Acquired Traits")

            if character.acquiredTraits.isEmpty {
                Text("No acquired traits yet")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .italic()
            } else {
                ForEach(character.acquiredTraits, id: \.self) { traitName in
                    if let trait = AcquiredTrait(rawValue: traitName) {
                        AcquiredTraitRow(trait: trait)
                    }
                }
            }
        }
        .sectionStyle()
    }

    // MARK: - Relationships Content

    private var relationshipsContent: some View {
        VStack(spacing: 16) {
            sectionHeader("Guild Relationships")

            let roster = GuildManager.shared.roster.filter { $0.id != character.id }

            if roster.isEmpty {
                Text("No other guild members")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .italic()
            } else {
                ForEach(roster) { other in
                    RelationshipRow(
                        character: character,
                        other: other
                    )
                }
            }
        }
        .padding()
        .sectionStyle()
    }

    // MARK: - Helper Views

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.white)
    }
}

// MARK: - Personality Bar

struct PersonalityBar: View {
    let trait: String
    let value: Int
    let lowLabel: String
    let highLabel: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(lowLabel)
                    .font(.caption2)
                    .foregroundColor(value < 5 ? color : .gray)
                Spacer()
                Text("\(value)/10")
                    .font(.caption)
                    .foregroundColor(.white)
                Spacer()
                Text(highLabel)
                    .font(.caption2)
                    .foregroundColor(value >= 5 ? color : .gray)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(value) / 10)
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Skill Row

struct SkillRow: View {
    let skill: SkillType
    let modifier: Int
    let isClassSkill: Bool

    var body: some View {
        HStack {
            Image(systemName: skill.icon)
                .foregroundColor(isClassSkill ? .blue : .gray)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(skill.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.white)

                    if isClassSkill {
                        Text("CLASS")
                            .font(.caption2)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(4)
                    }
                }

                Text(skill.description)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }

            Spacer()

            Text(modifier >= 0 ? "+\(modifier)" : "\(modifier)")
                .font(.headline)
                .foregroundColor(modifierColor)
        }
        .padding(.vertical, 4)
    }

    private var modifierColor: Color {
        if modifier >= 5 { return .green }
        if modifier >= 2 { return .blue }
        if modifier >= 0 { return .white }
        return .red
    }
}

// MARK: - Trait Row

enum TraitType {
    case racial, class_
}

struct TraitRow: View {
    let name: String
    let type: TraitType

    var body: some View {
        HStack {
            Image(systemName: type == .racial ? "person.fill" : "shield.fill")
                .foregroundColor(type == .racial ? .green : .blue)
                .frame(width: 24)

            Text(name)
                .font(.subheadline)
                .foregroundColor(.white)

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Trait Detail Row

struct TraitDetailRow: View {
    let name: String
    let description: String
    let type: TraitType

    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: type == .racial ? "person.fill" : "shield.fill")
                .foregroundColor(type == .racial ? .green : .blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Acquired Trait Row

struct AcquiredTraitRow: View {
    let trait: AcquiredTrait

    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: trait.isPositive ? "plus.circle.fill" : "minus.circle.fill")
                .foregroundColor(trait.isPositive ? .green : .red)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(trait.displayName)
                    .font(.subheadline)
                    .foregroundColor(.white)

                Text(trait.description)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Relationship Row

struct RelationshipRow: View {
    let character: Character
    let other: Character

    var body: some View {
        let relationship = RelationshipManager.shared.getRelationship(between: character.id, and: other.id)
        let tier = RelationshipManager.shared.getTier(between: character.id, and: other.id)

        HStack {
            CharacterPortrait(character: other, size: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(other.name)
                    .font(.subheadline)
                    .foregroundColor(.white)

                Text(tier.rawValue)
                    .font(.caption)
                    .foregroundColor(tierColor(tier))
            }

            Spacer()

            // Relationship value
            Text("\(relationship)")
                .font(.headline)
                .foregroundColor(relationship >= 0 ? .green : .red)
        }
        .padding(.vertical, 4)
    }

    private func tierColor(_ tier: RelationshipTier) -> Color {
        switch tier {
        case .hostile: return .red
        case .unfriendly: return .orange
        case .neutral: return .gray
        case .friendly: return .blue
        case .trusted: return .cyan
        case .bonded: return .green
        }
    }
}

// MARK: - Section Style Modifier

extension View {
    func sectionStyle() -> some View {
        self
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
    }
}

#Preview {
    AdventurerDetailView(character: Character.generateRandom(forClass: .warrior))
}
