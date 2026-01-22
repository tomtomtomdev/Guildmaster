# Guild Master - MVP Roadmap & Development Priorities

## Reality Check: 12-Month Scope Analysis

### Full Vision Complexity Score: 10/10
**Estimated Development Time:** 24-36 months with a team of 3-5

### What You Originally Asked For:
- 8 races × 3 variants = 24 racial types
- 8 classes with unique ability trees
- Dynamic AI driven by INT stat
- Captain mechanics with CHA influence
- Satisfaction system with desertion
- 7 factions with reputation
- Rival guild AI (3-5 guilds)
- Turn-based tactical combat
- World events system
- 3+ story branches with multiple endings
- Roguelike elements
- All original art and UI

**Honest Assessment:** This is a AA-studio, 2-year game scope.

---

## The 12-Month MVP: What's Actually Achievable

### Core Philosophy
**"Nail one thing perfectly rather than do ten things poorly."**

Focus: **Turn-based tactical RPG with intelligent party AI**

Everything else is secondary or cut.

---

## MVP Scope (12 Months, Solo + Claude Code)

### ✅ KEEP - Core Features

#### 1. Character System (Simplified)
- **4 Races:** Human, Elf, Dwarf, Orc (no variants)
- **4 Classes:** Warrior, Rogue, Mage, Cleric
- **6 Stats:** STR, DEX, CON, INT, WIS, CHA
- **INT-driven AI:** 3 tiers (Low, Medium, High)
- **Captain Mechanics:** Basic version (INT+CHA score)
- **Satisfaction:** Simplified (0-100, basic factors only)

**Why:** This is your core innovation. The AI party members are what makes your game unique.

#### 2. Combat System
- **Turn-based grid combat** (hex, 10×12 grid)
- **4-6 abilities per class** (not full trees)
- **Basic positioning:** Cover, flanking, line of sight
- **Enemy AI:** 3 complexity tiers
- **5 combat encounters** per quest

**Why:** This is where players spend 70% of their time. It must feel great.

#### 3. Guild Management (Bare Bones)
- **Recruit adventurers** from a pool of 10
- **1 Guild facility:** Barracks (upgrade for capacity)
- **Quest board:** 3-5 available quests at a time
- **Simple economy:** Gold in, gold out

**Why:** Just enough to feel like management without overwhelming.

#### 4. Quest System
- **3 Quest Types:** Extermination, Rescue, Escort
- **Linear structure:** Travel → 3 encounters → Boss → Return
- **10 Total Quests** in campaign (including story quests)

**Why:** Quality over quantity. Each quest hand-crafted.

#### 5. Story (Minimal)
- **Single linear story** with 2 possible endings (based on final choice)
- **5 Story beats:** Introduction, Rising Action, Midpoint, Climax, Resolution
- **No faction system** (for MVP)

**Why:** Story is expensive. Save branching for post-launch.

#### 6. Content
- **15 Enemy Types** (5 per tier: basic, advanced, boss)
- **30 Items** (10 weapons, 10 armor, 10 consumables)
- **20 Abilities** (5 per class)

**Why:** Enough variety without drowning in content creation.

---

### ❌ CUT - Post-Launch Features

#### Save for Version 1.1-1.5:
- Rival guilds → **CUT** (complex AI, not core gameplay)
- 7 Factions → **CUT** (reduce to 0-1 for MVP)
- World events → **CUT** (dynamic systems are time sinks)
- Multiple story branches → **CUT** (1 linear story, 2 endings max)
- Racial variants → **CUT** (24 types → 4 types)
- Background system → **CUT** (complexity without payoff)
- 8 classes → **CUT** (reduce to 4)
- Complex guild facilities → **CUT** (1 facility: Barracks)
- Random encounters → **CUT** (fixed quest structure)
- Roguelike elements → **CUT** (save for post-launch mode)

#### Why Cut These?
Each of these is a 2-4 week feature. Cutting them gives you:
- 10-20 weeks of development time saved
- Simpler codebase = fewer bugs
- Ability to polish core gameplay

**Post-launch roadmap:**
- Update 1.1: Add Ranger class + 2 more races
- Update 1.2: Faction system (1 faction)
- Update 1.3: Rival guild mechanics
- Update 1.4: Second story branch
- Update 2.0: Roguelike mode, procedural dungeons

---

## 12-Month Development Timeline

### Month 1-2: Foundation & Prototyping

**Goals:**
- Set up Unity/Godot project
- Implement hex grid system
- Character stat system
- Basic turn order
- Simple AI decision tree (just 1 tier for now)

**Deliverable:** 
Playable prototype with 2 characters fighting 2 enemies on a grid.

**Milestones:**
- Week 1-2: Project setup, grid rendering
- Week 3-4: Character movement, basic attacks
- Week 5-6: Turn system, simple AI
- Week 7-8: First playable combat encounter

**Risk:** Grid-based pathfinding can be tricky. Use A* library.

---

### Month 3-4: Combat System Deep Dive

**Goals:**
- Implement all 4 classes with basic abilities
- INT-based AI (all 3 tiers)
- Captain mechanics
- Combat UI/UX
- Line of sight, cover, flanking

**Deliverable:** 
Full combat system with all classes playable.

**Milestones:**
- Week 9-10: Class abilities implementation
- Week 11-12: AI complexity tiers
- Week 13-14: Captain influence system
- Week 15-16: Combat UI polish, positioning mechanics

**Risk:** AI balancing will take iteration. Plan for Week 15-16 buffer.

---

### Month 5-6: Content Creation

**Goals:**
- Create 15 enemy types
- Design 10 quests (structure, encounters, rewards)
- Item database (30 items)
- Quest generation system

**Deliverable:** 
Playable campaign (first 5 quests).

**Milestones:**
- Week 17-18: Enemy designs + implementations
- Week 19-20: Quest framework + first 3 quests
- Week 21-22: Items, equipment system
- Week 23-24: Quests 4-10 creation

**Risk:** Content creation is slow. Consider procedural enemy stat generation.

---

### Month 7-8: Guild Management & Meta Systems

**Goals:**
- Recruitment system
- Satisfaction mechanics
- Basic economy
- Quest board UI
- Save/load system

**Deliverable:** 
Full game loop (recruit → quest → manage → repeat).

**Milestones:**
- Week 25-26: Recruitment + adventurer pool
- Week 27-28: Satisfaction system
- Week 29-30: Economy, quest rewards
- Week 31-32: Save/load, guild hall UI

**Risk:** Satisfaction system balance. Needs playtesting ASAP.

---

### Month 9: Story & Integration

**Goals:**
- Write and implement story
- Integrate story quests into campaign
- Create story UI (dialogue, cutscenes)
- First full playthrough

**Deliverable:** 
Complete story campaign, beginning to end.

**Milestones:**
- Week 33-34: Story writing + dialogue system
- Week 35-36: Story quest integration + endings

**Risk:** Story often expands scope. Stay disciplined.

---

### Month 10-11: Polish & Playtesting

**Goals:**
- UI/UX polish (minimalist fantasy theme)
- Sound effects + music (royalty-free or contract composer)
- Balance tuning based on playtests
- Bug fixing

**Deliverable:** 
Game ready for closed beta.

**Milestones:**
- Week 37-38: UI visual polish, fonts, colors
- Week 39-40: Audio implementation
- Week 41-42: Balance pass (enemy HP, damage, rewards)
- Week 43-44: Beta test with 10-20 players

**Risk:** Playtesting reveals major issues. Build 2-week buffer for rework.

---

### Month 12: iOS Optimization & Launch Prep

**Goals:**
- iOS optimization (performance, battery, touch controls)
- App Store assets (icon, screenshots, trailer)
- Final bug fixes
- Submission to App Store

**Deliverable:** 
Game live on App Store.

**Milestones:**
- Week 45-46: iOS build optimization
- Week 47: App Store page + marketing materials
- Week 48: Final QA, submission

**Risk:** App Store approval can take 1-2 weeks. Submit early.

---

## Technical Stack Recommendations

### Engine: **Unity** (Best for iOS)

**Why Unity?**
- Excellent iOS deployment
- Large asset store for time-saving
- Good 2D support (for your minimalist UI)
- Claude Code works well with C#
- Pathfinding/AI plugins available

**Alternative:** Godot (if you prefer open-source, but iOS export is trickier)

### Key Unity Assets/Plugins (Save Time)
- **A* Pathfinding Project** ($100) - Grid pathfinding
- **DOTween** (Free) - UI animations
- **TextMesh Pro** (Built-in) - Typography for your minimalist UI
- **Odin Inspector** ($60) - Better editor tools

**Total Asset Cost: ~$200**

### Art Style for MVP
**Solution:** Minimalist sprites + UI-heavy design

- **Characters:** Simple 2D sprites, token-style (like board game pieces)
- **Grid:** Clean hex lines with terrain color coding
- **UI:** Your strength - papyrus aesthetic, beautiful typography
- **Effects:** Particle systems for abilities (Unity built-in)

**Why:** You're solo. Focus on UI beauty, not complex animations.

---

## Content Creation Efficiency Tips

### 1. Procedural Enemy Variations
Don't create 15 entirely unique enemies. Create 5 enemy "archetypes":

- **Brute:** High HP, STR, low INT
- **Striker:** High DEX, damage
- **Caster:** High INT, spells
- **Support:** Buffs allies
- **Tank:** High AC, low damage

Then create variations by swapping sprites and stat distributions:
- Goblin Brute = Orc Warrior with -20% stats
- Skeleton Archer = Bandit Archer with undead traits

**Time Saved:** 60-70% on enemy creation

### 2. Item Tiers, Not Unique Items
Create 5 weapon base types:
- Sword, Axe, Bow, Staff, Dagger

Then create 3 tiers per type:
- Basic: Iron Sword
- Advanced: Steel Sword +1
- Elite: Flaming Sword +2

Use the same sprite with color shifts.

**Time Saved:** 50% on item art

### 3. Quest Templates
Create 3 quest templates with variable slots:

**Template: Extermination**
```
[Faction NPC] needs you to clear [Location] of [Enemy Type].
Rewards: [Gold], [Item from loot table], [Reputation +10]
Encounters: [3× Enemy Type] + [1× Elite variant]
```

Generate 10 quests by filling in variables.

**Time Saved:** 80% on quest writing

---

## Critical Success Factors

### 1. Nail the AI (This is Your Hook)
Players MUST notice the INT difference:
- Low INT ally walking into fire = funny/frustrating
- High INT ally saving low-HP teammate = emotional

**Test Early:** Month 3, do blind playtests. "Can you tell which character is smart?"

### 2. Captain Feels Impactful
When a high-CHA captain overrides a bad decision, player should feel:
"Thank god I have a good leader."

**Implementation:** 
- Visual feedback: Captain portrait glows, command speech bubble
- Sound: Authority voice line
- Effect: Immediately visible (ally changes target)

### 3. Combat Pacing
Turn-based can feel slow. Target:
- 5-7 minute combat encounters
- Max 10 turns per fight
- Fast animations (0.5s per action)

### 4. Progression Satisfaction
Every quest should give:
- 1 level up OR 1 new item OR 1 new recruit

Never let player feel "I gained nothing."

---

## Monetization Strategy

### Option 1: Premium ($9.99)
- One-time purchase
- No ads, no IAP
- Full game included

**Pros:** Simple, respects players
**Cons:** Lower revenue ceiling

### Option 2: Free + IAP
- Free: First 3 quests
- $4.99: Unlock full campaign
- $2.99: Cosmetic pack (character skins)

**Pros:** Higher player acquisition
**Cons:** Needs more UI work for store

### Recommendation: **Premium Model**
Your game is deep and niche. Target core strategy gamers who pay upfront.

**Pricing:**
- Launch: $7.99 (sale price)
- Regular: $9.99
- Future expansions: $3.99 each

---

## Post-Launch Content Roadmap (Months 13-24)

### Update 1.1 (Month 13-14) - "Expanded Roster"
- +2 Races (Halfling, Tiefling)
- +1 Class (Ranger)
- +5 Quests
- Quality of life improvements

**Goal:** Re-engage players, drive reviews.

### Update 1.2 (Month 15-16) - "Faction Wars"
- Add 1 faction system (Crown)
- +10 Faction quests
- Reputation rewards
- Faction-specific recruits

**Goal:** Add depth, extend playtime.

### Update 1.3 (Month 17-19) - "Rival Guilds"
- 2 rival guild AI
- Contract competition
- Ambush mechanics
- PvP-style guild combat

**Goal:** Dynamic replayability.

### Update 1.4 (Month 20-21) - "Dark Path"
- Second story branch (evil route)
- +5 Story quests
- New ending

**Goal:** New playthrough incentive.

### Update 2.0 (Month 22-24) - "Endless Mode"
- Roguelike mode
- Procedural dungeons
- Meta-progression
- Leaderboards

**Goal:** Infinite replayability, community.

---

## Risk Mitigation Strategies

### Risk 1: Scope Creep
**Mitigation:**
- Freeze features after Month 2
- Use Trello/Notion with strict "MVP" vs "Post-Launch" columns
- Every new idea goes to "Version 1.1+" list

### Risk 2: AI Doesn't Feel Different
**Mitigation:**
- Prototype AI first (Month 2)
- Weekly playtests focused on "can you tell?"
- Exaggerate differences if needed (low INT = comedically bad)

### Risk 3: Solo Burnout
**Mitigation:**
- Work in sprints: 6 days on, 1 day off
- Outsource music/art if needed (budget $500-1000)
- Join gamedev community (Discord, Reddit) for motivation

### Risk 4: iOS Approval Rejection
**Mitigation:**
- Study App Store guidelines early
- No loot boxes, no predatory mechanics
- Submit Test Flight build in Month 11 for early feedback

---

## When to Pivot or Quit

### Red Flags (Months 1-6)
If by Month 6 you haven't achieved:
- Playable combat that feels fun
- Visible AI differences
- At least 3 complete quests

**Action:** Reassess if project is viable. Consider pausing to refactor or pivot.

### Success Indicators (Month 9)
- Full campaign playthrough in <8 hours
- Testers say "I want to play again with different party"
- Core loop is addictive

**Action:** Full steam ahead to launch.

---

## Budget Estimate (Solo Developer)

### Essential Costs
- Unity Pro (if needed): $0-$2000/year
- Assets/Plugins: $200
- Music/SFX (royalty-free + 1-2 commissioned tracks): $300
- App Store Developer Account: $99/year
- Marketing (App Store ads, website hosting): $500

**Total: ~$1500-3000**

### Optional Costs
- Contract artist for key art: $500-1000
- Professional trailer editing: $300-500
- PR/Marketing consultant: $1000-2000

**With Optional: $3000-6500**

---

## Final Recommendations

### Do This:
1. **Build vertical slice first** (Month 1-3): One full quest, playable start to finish
2. **Playtest obsessively** starting Month 4
3. **Cut ruthlessly** - if a feature doesn't directly make combat or management better, cut it
4. **Ship something** rather than polish forever

### Don't Do This:
1. Don't add "just one more feature" after Month 6
2. Don't build your own engine/tools
3. Don't try to compete with AAA production values
4. Don't skip iOS optimization (it's 20% of your timeline)

### Your Competitive Edge:
Not graphics. Not content volume. Not brand.

**Your edge: AI party members that feel alive.**

If you nail that, you have a unique, memorable game.

---

## Measuring Success

### Launch Metrics (Month 12)
- **Target Downloads:** 1000 in first month
- **Revenue:** $5000-8000 (at $7.99 price point)
- **App Store Rating:** 4.0+ stars
- **Retention:** 40% Day 7 retention

### Year 1 Metrics (Month 24)
- **Total Downloads:** 10,000+
- **Revenue:** $50,000-80,000 (including updates)
- **Community:** Active Discord with 500+ members
- **Reviews:** 200+ with 4.2+ average

If you hit these numbers, you have a sustainable indie game that can fund future projects.

---

## The Brutal Truth

You're attempting a 2-3 year project in 12 months. **This is extremely risky.**

But with:
- Aggressive scope cuts
- Obsessive focus on the core hook (AI party members)
- Claude Code assistance
- Community feedback early and often

You can ship something **good enough to succeed** and iterate from there.

**Version 1.0 doesn't have to be perfect. It has to be fun and unique.**

Nail the AI. Ship the MVP. Build from there.

Good luck. You'll need it. But also, you can do this.

---

## Next Steps: What to Do Right Now

1. **Save these documents** ✅ (You're here)
2. **Set up project** (Unity + Git + GitHub)
3. **Build hex grid prototype** (Week 1-2 goal)
4. **Read "Scope Creep is Your Enemy" daily**
5. **Find 3-5 playtesters** who can give honest feedback
6. **Block out your calendar** for 12-month sprint

Start tomorrow. Don't wait for perfect. Start with a hex grid and two stick figures punching each other.

Everything else comes after.