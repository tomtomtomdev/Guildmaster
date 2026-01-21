//
//  NameGenerator.swift
//  Guildmaster
//
//  Random name generation for characters by race
//

import Foundation

/// Generates random names based on race
struct NameGenerator {

    /// Generate a random name for a race
    static func generate(for race: Race, gender: Gender? = nil) -> String {
        let selectedGender = gender ?? Gender.allCases.randomElement()!

        let firstName = firstNames[race]?[selectedGender]?.randomElement() ?? "Unknown"
        let surname = surnames[race]?.randomElement() ?? "Unknown"

        return "\(firstName) \(surname)"
    }

    /// Gender for name generation
    enum Gender: CaseIterable {
        case male
        case female
    }

    // MARK: - Name Database

    private static let firstNames: [Race: [Gender: [String]]] = [
        .human: [
            .male: [
                "Aldric", "Bram", "Cedric", "Dorian", "Edmund", "Felix", "Garrett", "Harold",
                "Ivan", "Jasper", "Karl", "Leon", "Marcus", "Nolan", "Oliver", "Pierce",
                "Quinn", "Roland", "Stefan", "Thomas", "Victor", "Warren", "Xavier"
            ],
            .female: [
                "Alara", "Brianna", "Celeste", "Diana", "Elena", "Fiona", "Gwendolyn", "Helena",
                "Iris", "Julia", "Katherine", "Lydia", "Miranda", "Natalia", "Ophelia", "Petra",
                "Rosa", "Selena", "Thalia", "Ursula", "Vera", "Willa", "Yvonne"
            ]
        ],
        .elf: [
            .male: [
                "Aelindor", "Caelum", "Eryndor", "Faelar", "Galadrim", "Lorien", "Thalion", "Vaeril",
                "Arannis", "Berethon", "Celeborn", "Daeris", "Erevan", "Finrod", "Gildor", "Haldir",
                "Ithilion", "Legolas", "Maeglin", "Nieriel", "Orophin", "Peredhil"
            ],
            .female: [
                "Aelindra", "Caelia", "Elowen", "Faelara", "Galadriel", "Lirael", "Thalindra", "Vaelora",
                "Aranel", "Beruthiel", "Celebrian", "Daelynn", "Elenwë", "Finduilas", "Galawen", "Haleth",
                "Idril", "Lúthien", "Miriel", "Nimrodel", "Aredhel", "Silmariën"
            ]
        ],
        .dwarf: [
            .male: [
                "Balin", "Dain", "Gimli", "Thorin", "Brokk", "Durin", "Morgrim", "Thrain",
                "Borin", "Farin", "Groin", "Kili", "Nain", "Oin", "Fundin", "Gloin",
                "Dwalin", "Bifur", "Bofur", "Bombur", "Dori", "Nori", "Ori"
            ],
            .female: [
                "Brynhild", "Dagny", "Freya", "Hilda", "Ingrid", "Sigrid", "Thora", "Vigdis",
                "Astrid", "Brunhilde", "Disa", "Eira", "Gudrun", "Helga", "Kira", "Marta",
                "Nora", "Runa", "Solveig", "Thyra", "Una", "Ylva"
            ]
        ],
        .orc: [
            .male: [
                "Grokk", "Thrak", "Urgak", "Mogul", "Nazgrim", "Ragnar", "Skullcrusher", "Gorath",
                "Azog", "Bolg", "Durgash", "Grommash", "Kargath", "Lugdush", "Muzgash", "Narzug",
                "Shagrat", "Uglúk", "Gorbag", "Grishnákh", "Lurtz", "Mauhúr"
            ],
            .female: [
                "Grukka", "Shara", "Ursa", "Mogra", "Nazra", "Ragnara", "Goratha", "Kargasha",
                "Azoga", "Draka", "Garona", "Griselda", "Hurla", "Krenna", "Murgha", "Orgha",
                "Shelka", "Thura", "Ugla", "Varka", "Wratha", "Zumra"
            ]
        ]
    ]

    private static let surnames: [Race: [String]] = [
        .human: [
            "Blackwood", "Ironforge", "Stormwind", "Silverhand", "Oakenshield", "Ravencrest",
            "Brightblade", "Darkmore", "Goldwyn", "Hawthorne", "Kingsley", "Lionheart",
            "Nightingale", "Proudfoot", "Redmane", "Shadowmere", "Thornwood", "Whitmore",
            "Ashford", "Blackstone", "Coldwell", "Duskwalker", "Evergreen", "Frostborn"
        ],
        .elf: [
            "Moonwhisper", "Starweaver", "Leafshadow", "Dawnstrider", "Nightbloom", "Silvervine",
            "Brightwind", "Darkhollow", "Everlight", "Forestsong", "Gladerunner", "Higharrow",
            "Iceshard", "Jadeleaf", "Kindlebright", "Lorekeep", "Mistwalker", "Naturewarden",
            "Oakenheart", "Pinefall", "Quicksilver", "Ravenwood", "Skyreach", "Thunderbow"
        ],
        .dwarf: [
            "Ironbeard", "Stonefist", "Deepdelve", "Goldvein", "Hammerfall", "Anvilthorn",
            "Battleborn", "Coppervein", "Darkmine", "Earthshaker", "Fireforge", "Gemcutter",
            "Granitehelm", "Hardpick", "Ironbrow", "Jewelwright", "Keenaxe", "Longbeard",
            "Mithrilborn", "Noblehelm", "Oreseeker", "Proudhammer", "Quarrytooth", "Runecarver"
        ],
        .orc: [
            "Bloodfang", "Ironhide", "Skullsplitter", "Bonecrusher", "Ashhand", "Doomhammer",
            "Blackblood", "Deathbringer", "Firemaw", "Goreclaw", "Hellscream", "Irontusk",
            "Jawbreaker", "Killfist", "Lifetaker", "Maneater", "Nightraid", "Orcslayer",
            "Painbringer", "Ragefist", "Soulrender", "Thundermaw", "Warmachine", "Warsong"
        ]
    ]
}

// MARK: - Guild Name Generator

extension NameGenerator {

    /// Generate a random guild name
    static func generateGuildName() -> String {
        let prefixes = [
            "The Iron", "The Golden", "The Silver", "The Crimson", "The Azure",
            "The Shadow", "The Storm", "The Dawn", "The Dusk", "The Emerald",
            "The Obsidian", "The Crystal", "The Flame", "The Frost", "The Thunder"
        ]

        let suffixes = [
            "Wolves", "Lions", "Eagles", "Dragons", "Griffins",
            "Hawks", "Bears", "Serpents", "Ravens", "Falcons",
            "Guard", "Company", "Legion", "Brotherhood", "Order",
            "Blades", "Shields", "Hammers", "Axes", "Swords"
        ]

        let prefix = prefixes.randomElement()!
        let suffix = suffixes.randomElement()!

        return "\(prefix) \(suffix)"
    }
}

// MARK: - Quest Title Generator

extension NameGenerator {

    /// Generate a random quest title based on type
    static func generateQuestTitle(type: String, enemy: String? = nil, location: String? = nil) -> String {
        let templates: [String: [String]] = [
            "extermination": [
                "Clear the \(location ?? "Dungeon") of \(enemy ?? "Monsters")",
                "The \(enemy ?? "Monster") Menace",
                "\(enemy ?? "Monster") Infestation",
                "Hunt the \(enemy ?? "Beasts")"
            ],
            "rescue": [
                "Save the Captives",
                "Rescue Mission: \(location ?? "Unknown")",
                "The Missing Merchant",
                "Prisoners of \(enemy ?? "the Enemy")"
            ],
            "escort": [
                "Escort to \(location ?? "Safety")",
                "Guard the Caravan",
                "Safe Passage",
                "The Merchant's Journey"
            ]
        ]

        return templates[type]?.randomElement() ?? "A New Quest"
    }

    /// List of random locations
    static let locations = [
        "Old Mine", "Darkwood Forest", "Abandoned Keep", "Merchant Road", "Swamp Ruins",
        "Ancient Temple", "Goblin Warren", "Bandit Camp", "Haunted Crypt", "Dragon's Lair",
        "Orc Stronghold", "Wizard's Tower", "Sunken Cave", "Mountain Pass", "Cursed Village"
    ]

    /// List of random enemies
    static let enemies = [
        "Goblin", "Bandit", "Orc", "Undead", "Troll",
        "Skeleton", "Wolf", "Spider", "Cultist", "Ogre"
    ]
}
