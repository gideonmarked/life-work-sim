# Live, Laugh, Level Up

**An Idle Life Simulator Where Sleep Is The Final Boss**

A cozy idle game built in Godot 4.5 where you start with almost nothing, pick a career path, earn money, climb positions, upgrade living arrangements, buy items, manage hunger/rest/mood, and occasionally get hit with reality.

![Resolution: 1925x1035](https://img.shields.io/badge/Resolution-1925x1035-blue)
![Engine: Godot 4.5](https://img.shields.io/badge/Engine-Godot%204.5-purple)
![Genre: Idle/Life Sim](https://img.shields.io/badge/Genre-Idle%20Life%20Sim-green)

---

## Table of Contents

- [Getting Started](#getting-started)
- [Game Overview](#game-overview)
- [Project Structure](#project-structure)
- [Core Systems](#core-systems)
- [Action Queue System](#action-queue-system)
- [Character AI System](#character-ai-system)
- [Career System](#career-system)
- [Needs System](#needs-system)
- [Progression System](#progression-system)
- [Economy System](#economy-system)
- [Daily Summary System](#daily-summary-system)
- [Character Remarks](#character-remarks)
- [UI Systems](#ui-systems)
- [Balance Data Reference](#balance-data-reference)
- [Modding Guide](#modding-guide)

---

## Getting Started

### Requirements
- Godot 4.5 or later

### Running the Game
1. Open the project in Godot
2. Press F5 or click the Play button
3. The game starts at the Main Menu

### Controls
- **Mouse**: All interactions
- **Speed Controls**: 1x, 2x, 5x, Pause buttons in bottom bar
- **AI Toggle**: Click "AI: ON/OFF" to enable/disable autonomous decisions
- **Console**: Toggle with Console button to see event log
- **Action Queue**: Manually add actions (Work, Sleep, Rest, etc.) or let AI decide

---

## Game Overview

### Time Scale
- **15 real minutes = 24 in-game hours (1 day)**
- 1 in-game minute = 0.625 real seconds
- 1 in-game hour = 37.5 real seconds

> Configure in [`time_scale.json`](#time_scalejson)

### Save System
- **7 save slots** maximum
- **Auto-save** at end of each day
- Manual save with Save button
- **Saves to the same slot** you loaded from or started with

### Daily Cycle
1. **Day Start**: Morning quote displayed, royalties paid
2. **Day Progress**: Work, eat, rest, travel, etc.
3. **Day End**: Promotion check, daily summary, auto-save
4. **Daily Summary**: Shows stats, pauses game, auto-continues after 60s

---

## Project Structure

```
live-laugh-level/
├── data/
│   └── balance/                    # All game balance data (JSON)
│       ├── time_scale.json         # Time progression speed
│       ├── careers.json            # All career data (branches, positions, salaries, PP thresholds)
│       ├── living_arrangements.json     # Housing tiers & stats
│       ├── travel_times.json       # Travel durations by tier
│       ├── items.json              # All purchasable items (by category)
│       ├── schedules.json          # Store hours and time periods
│       ├── needs_rules.json        # Hunger/rest/mood mechanics
│       ├── quotes.json             # Daily morning quotes
│       ├── comments.json           # Context-aware comments
│       ├── character_remarks.json  # Random jokes & witty remarks
│       ├── chances.json            # All probability values
│       ├── console_settings.json   # Console log settings
│       ├── console_colors.json     # Console category colors
│       ├── ai_settings.json        # Character AI weights
│       ├── work_settings.json      # Work/salary/progression config
│       └── events.json             # Random events (NOT YET IMPLEMENTED)
├── scenes/
│   └── screens/                    # Main game screens
│       ├── MainMenu.tscn
│       ├── GameScreen.tscn
│       └── Settings.tscn
├── scripts/
│   ├── autoloads/                  # Global singletons
│   │   ├── Balance.gd              # Loads all balance data
│   │   ├── TimeManager.gd          # In-game time system
│   │   ├── GameState.gd            # Character state & progression
│   │   ├── ConsoleLog.gd           # Event logging
│   │   ├── SaveManager.gd          # Save/load system
│   │   ├── ActionQueue.gd          # FIFO action queue system
│   │   └── CharacterAI.gd          # Autonomous decision making
│   └── ui/                         # Screen controllers
│       ├── MainMenu.gd
│       ├── GameScreen.gd
│       ├── Settings.gd
│       └── FloatingWindow.gd       # Draggable window component
└── project.godot
```

---

## Core Systems

### Autoload Singletons

#### Balance.gd
Loads and provides access to all balance data from JSON files.

```gdscript
# Example usage
var quote = Balance.get_random_quote()
var position = Balance.get_position("Coder", 5)
var item = Balance.get_item("laptop_basic")
var living = Balance.get_living_arrangement(12)

# Career data (from careers.json)
Balance.get_branch_data("Coder")  # Full branch info
Balance.get_position_pay("Coder", 5)  # Hourly wage
Balance.get_promotion_threshold("Coder", 4)  # PP needed for level 5
Balance.can_branch_create_releases("Author")  # true
Balance.get_branch_release_type("Musician")  # "Album"
Balance.get_branches_in_category("Art")  # ["Author", "VisualArtist", "Musician"]

# Chances & Remarks
Balance.roll_chance("needs", "hunger_increase_chance")  # Returns true/false
Balance.get_random_remark("tired")  # Random witty remark

# Console colors
Balance.get_console_category_color("WORK")  # "#f5a623"
Balance.get_console_special_color("timestamp")  # "#666666"

# Work settings
Balance.get_work_setting("productivity", "base_ep", 10)
```

#### TimeManager.gd
Manages in-game time progression with signals.

```gdscript
# Signals
signal minute_passed(game_time: Dictionary)
signal hour_passed(game_time: Dictionary)
signal day_started(day: int)
signal day_ended(day: int)

# Methods
TimeManager.start()
TimeManager.pause()
TimeManager.resume()
TimeManager.set_time_scale(2.0)  # Speed multiplier
TimeManager.get_day_time_string()  # "Day 1 | 06:00"
```

#### GameState.gd
Manages all character state, progression, and game mechanics.

```gdscript
# Signals
signal money_changed(new_amount: int)
signal stats_changed()
signal needs_changed()
signal position_changed(branch, level, title)
signal living_changed(tier, name)
signal inventory_changed()
signal royalty_received(amount, source)

# Key Properties
GameState.character_name
GameState.branch          # "Coder", "Author", etc.
GameState.position_level  # 1-10
GameState.progress_points # PP toward next level
GameState.living_tier     # 1-25
GameState.money
GameState.hunger          # 0-100 (lower is better)
GameState.rest            # 0-100 (higher is better)
GameState.mood            # 0-100 (higher is better)
GameState.inventory       # Array of {item_id, quantity}
GameState.active_royalties # Array of royalty streams
```

#### ConsoleLog.gd
In-game event logging system with color-coded categories.

```gdscript
# Categories: SYSTEM, INPUT, STATS, WORK, TRAVEL, STORE, 
#             ITEM, QUOTE, COMMENT, PROMOTION, DEMOTION, ROYALTY

ConsoleLog.log_work("Earned 10 coins")
ConsoleLog.log_promotion("Promoted to Level 2")
ConsoleLog.log_comment('💭 "I need coffee..."')
ConsoleLog.get_recent(50)  # Last 50 entries
```

> Category colors configurable in [`console_colors.json`](#console_colorsjson)

#### SaveManager.gd
Handles save/load operations.

```gdscript
SaveManager.save_game(slot)      # 1-7
SaveManager.load_game(slot)
SaveManager.delete_slot(slot)
SaveManager.get_all_slots_info()
SaveManager.get_most_recent_slot()
```

#### ActionQueue.gd
Manages the 7-action FIFO queue system.

```gdscript
# Signals
signal action_started(action: Dictionary)
signal action_completed(action: Dictionary)
signal action_progress(action: Dictionary, remaining: float)
signal queue_changed()

# Action Types
enum ActionType {
    IDLE, WORK, SLEEP, EAT, 
    TRAVEL_GROCERY, TRAVEL_MALL, 
    SHOP, REST, CREATE_RELEASE
}

# Methods
ActionQueue.add_action(type, data)
ActionQueue.skip_current()
ActionQueue.get_queue()
ActionQueue.get_current_action()
ActionQueue.get_time_remaining_string()
```

#### CharacterAI.gd
Autonomous decision-making system.

```gdscript
# Signals
signal decision_made(action_type: int, reason: String)

# Methods
CharacterAI.set_enabled(enabled)
CharacterAI.is_enabled()
CharacterAI.force_decide()
```

> AI behavior configurable in [`ai_settings.json`](#ai_settingsjson)

---

## Action Queue System

The game uses a **FIFO (First In, First Out)** action queue where the character always has up to 7 actions planned.

### Queue Structure

```
┌─────────────────────────────────────┐
│  CURRENT ACTION (executing now)    │  ← Shows progress bar & time remaining
├─────────────────────────────────────┤
│  1. Next action                    │  ← Will execute when current completes
│  2. Queued action                  │
│  3. Queued action                  │
│  4. Queued action                  │
│  5. Queued action                  │
│  6. Queued action                  │  ← Last in queue (most faded)
└─────────────────────────────────────┘
```

### Action Types

| Type | Icon | Duration | Description |
|------|------|----------|-------------|
| **Idle** | ○ | 30 min | Do nothing, light rest |
| **Work** | ⚙ | 60 min | Earn money, gain PP |
| **Sleep** | ☾ | Until 6am | Fast-forward to 6am, restore rest |
| **Eat** | 🍴 | 15 min | Consume food |
| **Travel Grocery** | → | 10-70 min | Go to grocery store |
| **Travel Mall** | → | 10-85 min | Go to mall |
| **Rest** | ◇ | 30 min | Light rest, mood recovery |
| **Create Release** | ★ | 120 min | Create app/book/album |

### Queue Rules
- Max **2 consecutive rest actions** allowed
- AI avoids stacking more than 3 of same action type
- FIFO execution: first added = first executed
- **Sleep fast-forwards** to 6am, calculating rest based on hours slept

### Sleep System
When the character sleeps:
1. Time **fast-forwards to 6am** (next day if after 6am)
2. Rest is calculated: **10 rest per hour of sleep**
3. Bonus rest for **ideal sleep hours** (10pm-6am): +2 per ideal hour
4. Daily summary shown if day boundary crossed

---

## Character AI System

The AI evaluates all possible actions and scores them based on needs, inventory, and context.

### Priority Thresholds

| Condition | Effect |
|-----------|--------|
| Hunger ≥ 85 | MUST eat now (+100 score) |
| Hunger ≥ 70 | Should eat soon (+60 score) |
| Rest ≤ 15 | MUST sleep now (+100 score) |
| Rest ≤ 30 | Should sleep soon (+50 score) |
| Mood ≤ 25 | Needs break (+40 score) |
| 9pm-7am | Strong sleep preference (+60-90 score) |

### Smart Features
1. **Food Awareness**: Won't queue "Eat" if no food
2. **Store Planning**: Queues travel when hungry and no food
3. **Work Momentum**: Bonus for 1-3 consecutive work hours
4. **Burnout Prevention**: Forces breaks after 4+ work hours
5. **Night Sleep**: Much higher sleep priority at night (9pm-7am)
6. **Store Hours**: Checks if stores are open before traveling

> Configure thresholds and weights in [`ai_settings.json`](#ai_settingsjson)

---

## Career System

### Categories and Branches

| Category | Branches |
|----------|----------|
| **Business** | Corporate, Merchant, Investor |
| **Art** | Author, Visual Artist, Musician |
| **Innovation** | Coder, Scientist, Engineer |

### Promotion System
- **Promotion check happens at END OF DAY** (not immediately)
- When PP threshold reached during work, promotion is "pending"
- Actual promotion occurs when day ends
- Promotion shown in Daily Summary with 🎉 banner
- **First promotion takes ~5-10 days** of consistent work

> All career data in [`careers.json`](#careersjson)

### Royalty System (Level 4+)
Available for: Coder, Author, Visual Artist, Musician

| Setting | Formula |
|---------|---------|
| Cost | 50 + (level × 20) coins |
| Monthly Income | 10 + (level × 5) + reputation bonus |
| Duration | 3 to 24 months |

> Royalty settings in [`work_settings.json`](#work_settingsjson)

---

## Needs System

### Needs (0-100)

| Need | Description | Ideal |
|------|-------------|-------|
| **Hunger** | How hungry you are | Lower is better (0 = full) |
| **Rest** | How rested you are | Higher is better |
| **Mood** | How happy you are | Higher is better |

### Passive Changes

| Change | Chance | Source |
|--------|--------|--------|
| Hunger +1 | 33% per minute | `chances.json` → needs.hunger_increase_chance |
| Rest -1 | 20% per minute | `chances.json` → needs.rest_decrease_chance |
| Mood -1 | 10% when hungry/tired | `chances.json` → needs.mood_decrease_from_needs_chance |

### Console Warnings
- ⚠ **CRITICAL** when Hunger ≥ 90, Rest ≤ 10, Mood ≤ 20
- **Warning** when Hunger ≥ 70, Rest ≤ 30, Mood ≤ 35

> All chance values configurable in [`chances.json`](#chancesjson)

---

## Progression System

### Effective Productivity (EP) Formula

```
CM = clamp(floor(TotalComfort / 2), -5, +5)    # Comfort Modifier
MM = clamp(floor((Mood - 50) / 10), -3, +3)   # Mood Modifier
NP = hunger_penalty + rest_penalty             # Need Penalties

EP = max(0, BaseProductivity + CM + MM + NP)
```

### Progress Points (PP) Formula

```
PP_gain = EP × (1 + Reputation/20) × (1 + Stability/25)
```

> Formula divisors configurable in [`work_settings.json`](#work_settingsjson)

### Need Penalties

| Condition | Penalty |
|-----------|---------|
| Hunger ≥ 80 | -2 EP |
| Hunger ≥ 95 | -4 EP |
| Rest ≤ 20 | -2 EP |
| Rest ≤ 5 | -4 EP |
| Missing required items | -3 EP, -1 Mood |

---

## Daily Summary System

At the end of each day, the game:

1. **Pauses time** automatically
2. **Processes pending promotion** (if threshold was reached)
3. **Auto-saves** to most recent slot
4. **Displays Daily Summary overlay** showing:
   - Day completion banner
   - 🎉 **PROMOTED** banner (if applicable)
   - Money: total, earned, spent, change
   - Royalties income
   - Position and progress
   - Hours worked
   - End of day needs (Hunger, Rest, Mood)

5. **Continue button** with 60-second countdown
   - Click to continue immediately
   - Auto-continues after 60 seconds

All daily summary data is also logged to the console.

---

## Character Remarks

The character randomly says jokes, witty remarks, and context-aware comments.

### Remark Categories

| Category | Triggers When |
|----------|---------------|
| `general` | Any time |
| `tired` | Rest is low |
| `hungry` | Hunger is high |
| `happy` | Mood is high |
| `working` | Currently working |
| `promoted` | Just got promoted |
| `broke` | Low on money |
| `morning` | 5am-10am |
| `evening` | 5pm-10pm |
| `jokes` | Random (10% chance) |

### Trigger Chances

| Trigger | Chance | Source |
|---------|--------|--------|
| Random remark | 3% per minute | `chances.json` → character_remarks.random_remark_chance |
| After work | 8% | `chances.json` → character_remarks.remark_after_work_chance |
| After eating | 15% | `chances.json` → character_remarks.remark_after_eating_chance |
| When tired | 10% | `chances.json` → character_remarks.remark_when_tired_chance |
| On new day | 40% | `chances.json` → character_remarks.remark_on_new_day_chance |

> Add/edit remarks in [`character_remarks.json`](#character_remarksjson)

---

## UI Systems

### Console Log Colors

Each category has a distinct color for easy scanning:

| Category | Color | Hex Code |
|----------|-------|----------|
| SYSTEM | Muted purple-gray | `#6a6a7a` |
| INPUT | Bright blue | `#7aa3ff` |
| STATS | Teal/mint | `#4dd4a0` |
| WORK | Orange | `#f5a623` |
| TRAVEL | Sky blue | `#5eb3f7` |
| STORE | Coral | `#e8875a` |
| ITEM | Gold | `#c9a86c` |
| QUOTE | Bright yellow | `#f7e67a` |
| COMMENT | Light purple | `#b794f6` |
| PROMOTION | Bright green | `#50fa7b` |
| DEMOTION | Bright red | `#ff5555` |
| ROYALTY | Amber | `#ffb86c` |

> All colors configurable in [`console_colors.json`](#console_colorsjson)

### Floating Windows

Three floating windows (Console, Inventory, Housing, Career) can be:
- Toggled from bottom bar
- Dragged by title bar
- Closed with ✕ button

### Window Controls
- **✕** (Top-left): Close application
- **✥** (Top-right): Drag to move window

> Window dragging only works in standalone mode, not Godot editor.

---

## Balance Data Reference

All game balance is stored in JSON files in `data/balance/`.

### time_scale.json
Controls game speed.
```json
{
  "real_seconds_per_game_minute": 0.625
}
```
> 0.625 seconds per game minute = 15 real minutes per in-game day

### careers.json
**Complete career system data** - combines positions, salaries, and progression:

```json
{
  "categories": {
    "Business": { "branches": ["Corporate", "Merchant", "Investor"], "color": "#f5a623" },
    "Art": { "branches": ["Author", "VisualArtist", "Musician"], "has_royalties": true },
    "Innovation": { "branches": ["Coder", "Scientist", "Engineer"] }
  },
  "branches": {
    "Coder": {
      "display_name": "Coder",
      "category": "Innovation",
      "description": "Write code, ship apps...",
      "can_create_releases": true,
      "release_type": "App/Game",
      "positions": [
        { "level": 1, "title": "App Suggester", "base_pay_per_hour": 4, "requires": ["notebook"], "grants": ["pencil_basic"], "pp_to_next": 110 },
        { "level": 2, "title": "Feature List Farmer", "base_pay_per_hour": 5, ... },
        ...
      ]
    }
  },
  "progression_settings": {
    "max_level": 10,
    "promotion_check_timing": "end_of_day",
    "pp_reset_on_promotion": true
  }
}
```

Each position includes:
- `title`: Display name
- `base_pay_per_hour`: Hourly wage
- `requires`: Items needed to work efficiently
- `grants`: Items given on promotion
- `pp_to_next`: Progress Points needed for next level (null for max level)

### living_arrangements.json
25 housing tiers with stats:
- `comfort`, `productivity`, `reputation`, `stability`, `storage`
- `price`: Upgrade cost

### travel_times.json
Travel duration by living tier and destination.

### items.json
All purchasable items organized by category:
```json
{
  "categories": {
    "food": { "name": "Food", "store": "Grocery" },
    "drink": { "name": "Drinks", "store": "Grocery" },
    "snack": { "name": "Snacks", "store": "Grocery" },
    "clothing": { "name": "Clothing", "store": "Mall" },
    "furniture": { "name": "Furniture", "store": "Mall" },
    "gadget": { "name": "Gadgets", "store": "Mall" },
    "tool": { "name": "Tools", "store": "Mall" },
    "decor": { "name": "Decor", "store": "Mall" },
    "appliance": { "name": "Appliances", "store": "Mall" }
  },
  "items": [
    { "id": "rice_bowl", "category": "food", "store": "Grocery", "price": 12, ... }
  ]
}
```

**100+ items** across categories:
- **Food**: Rice bowl, sushi, steak, pasta, pizza, healthy options
- **Drinks**: Coffee, tea, energy drinks, smoothies
- **Snacks**: Chocolate, chips, protein bars, ice cream
- **Clothing**: T-shirts, hoodies, suits, shoes, accessories, watches
- **Furniture**: Beds, chairs, desks, shelves, couches
- **Gadgets**: Phones, laptops, monitors, tablets, gaming gear
- **Tools**: Notebooks, pens, toolkits, art supplies
- **Appliances**: TVs, AC, fridge, coffee maker, microwave
- **Decor**: Lamps, plants, posters, rugs

### schedules.json
**Store operating hours and time periods**:
```json
{
  "locations": {
    "Grocery": { "open_hour": 6, "close_hour": 22, "closed_message": "Grocery is closed (opens 6am - 10pm)" },
    "Mall": { "open_hour": 10, "close_hour": 21, "closed_message": "Mall is closed (opens 10am - 9pm)" },
    "Home": { "always_open": true },
    "Work": { "always_open": true }
  },
  "ideal_sleep_hours": { "start": 22, "end": 6 }
}
```

- **Grocery**: 6am - 10pm
- **Mall**: 10am - 9pm
- AI automatically checks store hours before traveling

### needs_rules.json
Hunger/rest/mood mechanics:
- Penalty thresholds
- Mood modifiers
- Demotion risk rules

### quotes.json
Daily morning quotes pool.

### comments.json
Context-aware character comments by category.

### character_remarks.json
Random jokes and witty remarks by situation:
```json
{
  "categories": {
    "tired": ["Zzzz... wait, I'm awake.", "Coffee. Need. Now.", ...],
    "jokes": ["Why do programmers prefer dark mode?", ...],
    ...
  }
}
```

### chances.json
**All probability values in one place:**
```json
{
  "needs": {
    "hunger_increase_chance": 33,
    "rest_decrease_chance": 20,
    "mood_decrease_from_needs_chance": 10,
    "comment_after_travel_chance": 25,
    "random_comment_chance": 5
  },
  "work": {
    "missing_items_log_chance": 10
  },
  "sleep": {
    "rest_recovery_chance": 50,
    "hunger_while_sleeping_chance": 10
  },
  "character_remarks": {
    "random_remark_chance": 3,
    "remark_after_work_chance": 8,
    ...
  }
}
```

### console_colors.json
**Console log colors:**
```json
{
  "category_colors": {
    "SYSTEM": "#6a6a7a",
    "WORK": "#f5a623",
    "PROMOTION": "#50fa7b",
    ...
  },
  "special_colors": {
    "timestamp": "#666666",
    "warning": "#ffcc00",
    "critical": "#ff4444"
  }
}
```

### ai_settings.json
Character AI decision weights:
```json
{
  "priority_thresholds": {
    "critical_hunger": 85,
    "high_hunger": 70,
    "critical_rest": 15,
    "high_tired": 30,
    "low_mood": 25
  },
  "base_action_weights": {
    "work": 50,
    "sleep": 20,
    "eat": 30,
    ...
  }
}
```

### work_settings.json
**Work, salary, and progression config:**
```json
{
  "productivity": {
    "base_ep": 10,
    "missing_items_penalty": 3
  },
  "salary": {
    "ep_divisor": 10
  },
  "progress_points": {
    "reputation_divisor": 20,
    "stability_divisor": 25
  },
  "promotion": {
    "check_timing": "end_of_day",
    "pp_reset_on_promotion": true
  },
  "royalties": {
    "eligible_branches": ["Coder", "Author", "VisualArtist", "Musician"],
    "min_level_required": 4,
    "base_creation_cost": 50,
    "cost_per_level": 20
  }
}
```

### events.json
**Random events system (NOT YET IMPLEMENTED)**

Prepared structure for future random events:
```json
{
  "event_settings": {
    "enabled": false,
    "check_frequency_minutes": 60,
    "max_events_per_day": 3
  },
  "events": [
    {
      "id": "bonus_day",
      "name": "Surprise Bonus!",
      "category": "work",
      "rarity": "uncommon",
      "conditions": { "min_position_level": 2 },
      "effects": { "money": 50, "mood": 10 }
    },
    ...
  ]
}
```

15 sample events prepared across categories:
- **Work**: Surprise Bonus, Coffee Catastrophe, Inspiration Strike
- **Financial**: Found Money, Unexpected Expense
- **Personal**: Restful Night, Nightmare
- **Social**: Kind Words, Rude Customer
- **Random**: Power Outage, Free Food, Lucky Break, Bad Day

---

## Modding Guide

### Adding New Items
Edit `data/balance/items.json`:
```json
{
  "id": "super_coffee",
  "name": "Super Coffee",
  "store": "Grocery",
  "price": 15,
  "effects": { "rest": -3, "productivity": 3 },
  "tags": ["drink", "boost"]
}
```

### Adding Character Remarks
Edit `data/balance/character_remarks.json`:
```json
{
  "categories": {
    "tired": [
      "Your new tired remark here",
      ...
    ]
  }
}
```

### Adjusting Chance Values
Edit `data/balance/chances.json`:
```json
{
  "needs": {
    "hunger_increase_chance": 25,  // Lower = slower hunger
    "random_comment_chance": 10    // Higher = more comments
  }
}
```

### Changing Console Colors
Edit `data/balance/console_colors.json`:
```json
{
  "category_colors": {
    "PROMOTION": "#00ff00",  // Brighter green
    "WORK": "#ff8800"        // More orange
  }
}
```

### Tuning AI Behavior
Edit `data/balance/ai_settings.json`:
```json
{
  "priority_thresholds": {
    "critical_hunger": 70  // Eats sooner
  },
  "base_action_weights": {
    "work": 80  // Works more often
  }
}
```

### Adjusting Work/Salary
Edit `data/balance/work_settings.json`:
```json
{
  "productivity": {
    "missing_items_penalty": 5  // Harsher penalty
  },
  "royalties": {
    "base_monthly_amount": 20  // Higher royalty income
  }
}
```

---

## File Quick Reference

| File | Purpose |
|------|---------|
| `time_scale.json` | Game speed (15min = 1 day) |
| `careers.json` | **All career data** (branches, positions, salaries, PP thresholds) |
| `living_arrangements.json` | Housing tiers |
| `travel_times.json` | Travel durations |
| `items.json` | **100+ items** by category |
| `schedules.json` | **Store hours** (Grocery 6am-10pm, Mall 10am-9pm) |
| `needs_rules.json` | Hunger/rest/mood rules |
| `quotes.json` | Morning quotes |
| `comments.json` | Character comments |
| `character_remarks.json` | Jokes & witty remarks |
| `chances.json` | **All probabilities** |
| `console_colors.json` | **Log colors** |
| `console_settings.json` | Console config |
| `ai_settings.json` | AI decision weights |
| `work_settings.json` | **Work/salary/progression** |
| `events.json` | Random events (future) |

---

## License

This game was created as a personal project. Feel free to modify and learn from the code.

---

*"Small steps count. Even tiny steps."*
