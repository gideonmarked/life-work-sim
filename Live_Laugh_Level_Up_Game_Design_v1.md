# Live, Laugh, Level Up: An Idle Life Simulator Where Sleep Is The Final Boss
## Game Design Notes (Living Document)
## Version 1

---

## 1) Core Setup
- **Engine:** Godot  
- **Genre:** Idle / Life Progression  
- **Resolution:** **700 x 420**  
- **Save Slots:** **Max 7 characters**  
- **Time Scale:** **10 in-game minutes = 5 seconds real time**
  - 1 real second = 2 in-game minutes  
  - 30 in-game minutes travel = 15 real seconds  
  - 1 in-game hour = 30 real seconds  
  - 1 in-game day (24h) = 12 real minutes  
- **Daily Morning Quote:** appears every morning for **7 seconds**

---

## 2) Game Summary
An idle life sim where your character starts with almost nothing, picks a career path, earns money, climbs positions, upgrades living arrangements, buys items, manages hunger/rest/mood, travels to stores, gets funny wholesome thoughts, and sometimes gets hit with reality (negative comfort, bad food, demotion risk).  
Some careers can produce “big releases” that pay monthly for **3 to 24 months**.

---

## 3) Major Categories and Branches

### 3.1 Categories
1. **Business**
2. **Art**
3. **Innovation**

### 3.2 Branches
**Business**
- Corporate
- Merchant
- Investor (Stocks)

**Art**
- Author
- Visual Artist
- Musician

**Innovation**
- Coder
- Scientist
- Engineer

---

## 4) Screens and Navigation (Version 1)

### 4.1 Major Screens (4)
1. **Main Menu**
2. **Game Screen**
3. **Settings Screen**
4. **Daily Statistics (Report) Screen**

### 4.2 Main Menu Flow
- **New Game**
  - If a slot is available → create new character and go to **Game Screen**
  - If all 7 slots are full → prompt to overwrite/delete
- **Continue**
  - Loads most recent slot (or opens slot list)
- **Settings**
  - Goes to Settings Screen

---

## 5) Daily Morning Quote System
- Trigger: Start of every in-game day (morning)
- Duration: **7 seconds**
- Quote chosen randomly from pool
- Optional later: allow skip (click/space)

### 5.1 Starter Quote Pool
- “Small steps count. Even tiny steps.”
- “Progress is still progress.”
- “You are allowed to start messy.”
- “Consistency beats motivation.”
- “Rest is part of the grind.”
- “Even legends buy groceries.”
- “Do the next right thing.”
- “A better routine beats a perfect plan.”
- “Today is a good day to upgrade something.”
- “One more task. Then water.”

---

## 6) Character Comment System
Short funny wholesome comments appear sometimes.

### 6.1 Trigger Examples
- After working
- After traveling
- After buying items
- On promotion/demotion
- When hunger/rest/mood changes
- Random low chance during idle ticks

### 6.2 Comment Pool (Starter)

**General**
- “Today I will be productive. After I blink for 40 minutes.”
- “My ambition is strong. My sleep is not.”
- “I deserve a snack for thinking about work.”
- “I am thriving in theory.”
- “This is fine. Everything is slightly on fire.”
- “My best is currently buffering.”
- “I worked hard. Now I will stare at a wall respectfully.”
- “I bought something. Mood temporarily restored.”
- “My comfort level is a personality trait now.”
- “I am not late. Time is early.”

**Hungry**
- “Food would solve at least 83% of my problems.”
- “My stomach is filing a complaint.”
- “If hunger was a quest, I am failing it.”
- “I should eat. I should also not eat mystery soup.”
- “I am running on dreams and crumbs.”

**Tired**
- “Sleep is the final boss and I am under-leveled.”
- “I need rest. Not the sit down kind. The hibernate kind.”
- “I will sleep after this task. Please laugh gently.”
- “My eyes are doing overtime.”

**Mood High**
- “Look at me, functioning like a responsible adult.”
- “Mood is up. Confidence is suspiciously up.”

**Mood Low**
- “My mood is in a loading screen.”
- “I regret everything, including this chair.”

**Business: Corporate**
- “I attended a meeting. I survived. That is the deliverable.”
- “I sent an email so polite it could heal nations.”
- “My calendar is a horror story.”
- “I scheduled a meeting to talk about scheduling meetings.”
- “I replied ‘Noted’ and felt powerful.”

**Business: Merchant**
- “Inventory is just money taking a nap.”
- “Restocking is my cardio.”
- “I sold a thing. I am now a CEO of vibes.”
- “If it has a barcode, I can love it.”

**Business: Investor**
- “I diversified my portfolio and my anxiety.”
- “I will not check prices. I will check prices.”
- “Long-term thinking. Short-term panic.”
- “I bought the dip. The dip became a pit.”

**Innovation: Coder**
- “I wrote an idea down. That counts as version 0.0.1.”
- “It works on my imagination.”
- “My notebook is basically a startup incubator.”
- “I debugged my life. Found too many warnings.”
- “One game sale and I will suddenly believe in myself.”

**Innovation: Scientist**
- “Hypothesis: I need a nap.”
- “This experiment is either genius or soup.”
- “I cleaned a beaker and gained +1 dignity.”

**Innovation: Engineer**
- “If it’s held together, it’s a prototype.”
- “I built something that works. Please do not touch it.”
- “I solved the problem by making it a different problem.”

**Art: Author**
- “I wrote one sentence. It is a brave sentence.”
- “My draft is messy. Like my sleep schedule.”
- “My characters are arguing with me.”

**Art: Visual Artist**
- “I made art. It is either genius or a potato.”
- “Color theory wants me to suffer.”
- “I finished a piece. I will now stare at it suspiciously.”

**Art: Musician**
- “My neighbors practiced patience.”
- “I recorded a demo. It is 40% music, 60% hope.”
- “I played one good note. Career secured.”

---

## 7) Stats

### 7.1 Career Stats (affect progression/events)
- **Comfort** (can be negative)
- **Productivity**
- **Reputation**
- **Stability**

### 7.2 Inventory Capacity
- **Storage (4–40)** is **not** a career stat.
- Storage only controls how many items you can hold at a time.
- Suggested rule: `MaxItems = BaseSlots + Storage`

### 7.3 Needs and Mood
- **Hunger** (0–100, higher = more hungry)
- **Rest/Sleep** (0–100, higher = more rested)
- **Mood** (0–100, higher = happier)

Rules (Version 1 intent):
- Good food lowers Hunger and can raise Mood.
- Bad food can lower Mood and can apply negative Comfort.
- Shopping can raise Mood (or lower it if item is junk/regret).
- High Hunger + low Rest lowers Mood and slows progression.

---

## 8) Stores and Travel (Version 1)

### 8.1 Stores (2 only)
1. **Grocery**
   - Food and drinks
2. **Mall**
   - Furniture
   - Gadgets/devices

### 8.2 Distance and Travel Time
- Each living arrangement has different distances to stores.
- Distance is represented by **travel time in in-game minutes**.
- Example: Grocery can be 30 minutes travel depending on where you live.

### 8.3 Travel Time Table (editable)
In-game minutes:

| Tier | Living Arrangement | Grocery | Mall |
|---:|---|---:|---:|
| 1 | Park Bench | 15 | 25 |
| 2 | Cardboard Shelter | 10 | 30 |
| 3 | Tent | 35 | 50 |
| 4 | Abandoned House | 55 | 70 |
| 5 | Squat Room (one usable room) | 30 | 45 |
| 6 | Storage Unit Corner | 40 | 35 |
| 7 | Shipping Container Home | 35 | 55 |
| 8 | Tiny House | 45 | 60 |
| 9 | Studio Apartment | 20 | 25 |
| 10 | Shared Apartment (roommates) | 25 | 30 |
| 11 | Basement Unit | 30 | 35 |
| 12 | 1-Bedroom Apartment | 20 | 20 |
| 13 | 2-Bedroom Apartment | 20 | 25 |
| 14 | Townhouse | 25 | 35 |
| 15 | Condo Unit | 15 | 20 |
| 16 | Small Suburban House | 35 | 45 |
| 17 | Modern House | 30 | 40 |
| 18 | Smart Home | 25 | 35 |
| 19 | Luxury Condo | 15 | 15 |
| 20 | Loft Penthouse | 10 | 10 |
| 21 | Beach House / Vacation Home | 60 | 75 |
| 22 | Private Villa | 45 | 60 |
| 23 | Estate Home | 50 | 65 |
| 24 | Mansion | 55 | 70 |
| 25 | Mega Mansion (Private Compound) | 70 | 85 |

---

## 9) Living Arrangements (Tier 1–25)

### 9.1 What living arrangements provide
- Comfort (can be negative)
- Productivity
- Reputation
- Storage (inventory only)
- Stability
- Store distances (travel time table above)

### 9.2 Living Arrangement Table
| Tier | Living Arrangement | Comfort | Productivity | Reputation | Storage | Stability |
|---:|---|---:|---:|---:|---:|---:|
| 1 | Park Bench | 1 | 1 | 1 | 4 | 1 |
| 2 | Cardboard Shelter | 1 | 1 | 1 | 4 | 1 |
| 3 | Tent | 2 | 1 | 1 | 6 | 2 |
| 4 | Abandoned House | -2 | 2 | 1 | 8 | 2 |
| 5 | Squat Room (one usable room) | 4 | 3 | 2 | 10 | 3 |
| 6 | Storage Unit Corner | 2 | 2 | 1 | 18 | 4 |
| 7 | Shipping Container Home | 5 | 4 | 2 | 20 | 5 |
| 8 | Tiny House | 7 | 5 | 3 | 16 | 6 |
| 9 | Studio Apartment | 6 | 6 | 4 | 14 | 7 |
| 10 | Shared Apartment (roommates) | 5 | 5 | 4 | 13 | 6 |
| 11 | Basement Unit | 6 | 5 | 3 | 18 | 6 |
| 12 | 1-Bedroom Apartment | 8 | 7 | 6 | 20 | 8 |
| 13 | 2-Bedroom Apartment | 9 | 7 | 7 | 23 | 8 |
| 14 | Townhouse | 9 | 8 | 7 | 24 | 9 |
| 15 | Condo Unit | 9 | 8 | 8 | 21 | 9 |
| 16 | Small Suburban House | 10 | 8 | 7 | 26 | 9 |
| 17 | Modern House | 10 | 9 | 8 | 28 | 9 |
| 18 | Smart Home | 10 | 10 | 8 | 29 | 10 |
| 19 | Luxury Condo | 10 | 9 | 9 | 25 | 10 |
| 20 | Loft Penthouse | 10 | 9 | 10 | 27 | 10 |
| 21 | Beach House / Vacation Home | 10 | 8 | 10 | 28 | 9 |
| 22 | Private Villa | 10 | 9 | 10 | 32 | 10 |
| 23 | Estate Home | 10 | 9 | 10 | 35 | 10 |
| 24 | Mansion | 10 | 10 | 10 | 37 | 10 |
| 25 | Mega Mansion (Private Compound) | 10 | 10 | 10 | 40 | 10 |

---

## 10) Money System

### 10.1 Base Pay Balance
- **Business**: easiest steady money
- **Innovation**: mid base pay (Coder can spike)
- **Art**: lowest base pay (can spike)

### 10.2 Royalties (3–24 months)
- **Coder** can release apps/games → monthly royalty for 3–24 months.
- **Art** can sell books/albums/paintings → monthly royalty for 3–24 months.

---

## 11) Positions and Salary (All branches, 10 positions each)

### 11.1 Business
**Corporate**
- Titles: Coffee Courier, Meeting Note Ninja, Email Polisher, Administrative Assistant, Operations Coordinator, Business Analyst, Project Manager, Department Manager, Director, Executive
- Base Pay (Coins/hr): **6, 7, 8, 12, 16, 22, 30, 40, 55, 75**

**Merchant**
- Titles: Street Vendor, Deal Hunter, Sticker Price Expert, Shopkeeper, Online Seller, Inventory Manager, Store Manager, Business Owner, Wholesale Supplier, Merchant Tycoon
- Base Pay (Coins/hr): **7, 8, 9, 14, 18, 24, 32, 45, 60, 85**

**Investor (Stocks)**
- Titles: Chart Watcher, Paper Trader, Rumor Collector, Retail Investor, Portfolio Manager (Personal), Active Trader, Value Investor, Risk Manager, Fund Manager, Investment Director
- Base Pay (Coins/hr): **6, 7, 8, 12, 18, 24, 30, 40, 55, 75**

### 11.2 Innovation
**Coder**
- Titles: App Suggester, Feature List Farmer, UI Sketcher, Junior Programmer, Frontend Developer, Backend Developer, Full-Stack Developer, Senior Software Engineer, Tech Lead, Software Architect
- Base Pay (Coins/hr): **4, 5, 6, 12, 16, 18, 24, 34, 45, 58**

**Scientist**
- Titles: Label Sticker Intern, Beaker Rinser, Notebook Observer, Lab Assistant, Research Assistant, Research Associate, Scientist, Senior Scientist, Research Lead, Principal Scientist
- Base Pay (Coins/hr): **4, 5, 6, 12, 15, 18, 22, 30, 40, 55**

**Engineer**
- Titles: Tape-and-Hope Builder, Parts Sorter, Blueprint Doodler, Junior Engineer, Design Engineer, Systems Engineer, Project Engineer, Senior Engineer, Lead Engineer, Chief Engineer
- Base Pay (Coins/hr): **4, 5, 6, 12, 16, 20, 24, 34, 45, 58**

### 11.3 Art
**Author**
- Titles: Idea Hoarder, Prompt Writer, Draft Sprinter, Copywriter, Content Writer, Freelance Author, Published Author, Best-Selling Author, Franchise Author, Legendary Author
- Base Pay (Coins/hr): **2, 3, 4, 6, 7, 9, 12, 16, 20, 24**

**Visual Artist**
- Titles: Doodle Miner, Sketch Grinder, Color Dabbler, Junior Illustrator, Commission Artist, Professional Illustrator, Concept Artist, Senior Artist, Art Director, Master Artist
- Base Pay (Coins/hr): **2, 3, 4, 6, 8, 10, 12, 16, 22, 26**

**Musician**
- Titles: Hum Recorder, Beat Tapper, Chord Collector, Session Musician, Recording Artist, Gig Performer, Producer/Composer, Touring Musician, Headline Performer, Music Icon
- Base Pay (Coins/hr): **2, 3, 4, 6, 7, 9, 12, 16, 20, 25**

---

## 12) Progression, Promotion, and Demotion

### 12.1 Key Rule
- **Productivity affects progression/promotions, not base pay.**
- **Storage does not affect promotions** (inventory only).

### 12.2 Comfort affects Productivity (can be negative)
Comfort can be negative. Negative comfort can slow progress and increase demotion risk.

Comfort modifier:
- `CM = clamp(floor(TotalComfort / 2), -5, +5)`

Mood modifier:
- `MM = clamp(floor((Mood - 50) / 10), -3, +3)`

Need penalties:
- Hunger ≥ 80 → -2, Hunger ≥ 95 → -4
- Rest ≤ 20 → -2, Rest ≤ 5 → -4
- `NP = NP_hunger + NP_rest`

Effective productivity:
- `EP = max(0, BP + CM + MM + NP)`

### 12.3 Progress Points (PP)
Progress per tick:
- `PP_gain = EP * (1 + Reputation/20) * (1 + Stability/25)`
- `PP = PP + PP_gain`

### 12.4 Promotion Requirements (branch-specific)
Format: **L1→L2, L2→L3, ... L9→L10**

**Business**
- Corporate: `120, 300, 650, 1100, 1800, 2700, 3900, 5600, 8000`
- Merchant: `100, 260, 520, 900, 1400, 2100, 3100, 4500, 6500`
- Investor: `140, 360, 750, 1300, 2100, 3200, 4700, 6700, 9500`

**Innovation**
- Coder: `110, 280, 600, 1050, 1700, 2600, 3800, 5400, 7600`
- Scientist: `120, 320, 700, 1200, 1900, 2850, 4100, 5900, 8300`
- Engineer: `115, 300, 650, 1150, 1850, 2800, 4050, 5800, 8200`

**Art**
- Author: `80, 200, 420, 750, 1150, 1650, 2350, 3300, 4700`
- Visual Artist: `85, 220, 460, 820, 1250, 1800, 2550, 3600, 5100`
- Musician: `90, 240, 500, 900, 1400, 2050, 2950, 4150, 5900`

### 12.5 Demotion (bad state can demote)
Demotion Risk Score (DRS):
- If TotalComfort < 0 → add abs(TotalComfort)
- Mood < 30 → +2
- Hunger ≥ 95 → +3
- Rest ≤ 5 → +3
- Stability ≤ 2 → +2

Rule:
- If DRS ≥ 8 for 1 in-game day:
  - `PP = PP - 50`
  - If `PP < -100`, demote 1 position and set PP to 0 (or small buffer).

---

## 13) Items System (Version 1)

### 13.1 Item Rules
- Items can affect: Comfort, Productivity, Reputation, Stability, Mood, Hunger, Rest.
- Negative effects are allowed (bad food, broken furniture, cringe items).
- Items consume inventory slots.
- Storage only affects how many items can be held.

### 13.2 Work Requirements and Free Item Grants (Final)
**Rule:** Some positions require items; some grant items automatically.  
Missing required item → either **Work Block** (EP=0 for that work action) or **Soft Penalty** (recommended): `EP -3` and `Mood -1` per work session.

#### Innovation → Coder
| Level | Position | Required Items | Granted Items |
|---:|---|---|---|
| 1 | App Suggester | Notebook | Pencil (basic) |
| 2 | Feature List Farmer | Notebook | Sticky Notes Pack |
| 3 | UI Sketcher | Notebook | **Toy Laptop** (Mood +2, Productivity +0) |
| 4 | Junior Programmer | **Basic Laptop** | **Basic Laptop** |
| 5 | Frontend Developer | Basic Laptop | Mouse (basic) |
| 6 | Backend Developer | Basic Laptop | USB Drive (basic) |
| 7 | Full-Stack Developer | **Work Laptop** *(or Basic Laptop + Upgrade Kit)* | Rubber Duck (Mood +1) |
| 8 | Senior Software Engineer | Work Laptop | External Monitor |
| 9 | Tech Lead | Work Laptop | Planner/Whiteboard |
| 10 | Software Architect | Work Laptop + Monitor | Noise-cancel Headphones |

#### Innovation → Scientist
| Level | Position | Required Items | Granted Items |
|---:|---|---|---|
| 1 | Label Sticker Intern | None | Lab Labels Pack |
| 2 | Beaker Rinser | None | Gloves (basic) |
| 3 | Notebook Observer | Notebook | Safety Goggles |
| 4 | Lab Assistant | Notebook | **Basic Lab Kit** |
| 5 | Research Assistant | Basic Lab Kit | Calculator |
| 6 | Research Associate | Basic Lab Kit | Data Folder |
| 7 | Scientist | Basic Lab Kit | Proper Lab Coat (Reputation +1) |
| 8 | Senior Scientist | Basic Lab Kit | Equipment Voucher (discount) |
| 9 | Research Lead | Basic Lab Kit | Clipboard of Authority (Mood +1) |
| 10 | Principal Scientist | Basic Lab Kit | Fancy Pen (Reputation +1, Mood +1) |

#### Innovation → Engineer
| Level | Position | Required Items | Granted Items |
|---:|---|---|---|
| 1 | Tape-and-Hope Builder | None | Duct Tape (basic) |
| 2 | Parts Sorter | None | Screw Pack |
| 3 | Blueprint Doodler | Notebook | Ruler (basic) |
| 4 | Junior Engineer | **Tool Kit (basic)** | **Tool Kit (basic)** |
| 5 | Design Engineer | Tool Kit | Measuring Tape |
| 6 | Systems Engineer | Tool Kit | Multimeter (Productivity +1) |
| 7 | Project Engineer | Tool Kit | Safety Helmet (Stability +1) |
| 8 | Senior Engineer | Tool Kit + Multimeter | Power Drill (Productivity +1) |
| 9 | Lead Engineer | Tool Kit | Walkie-Talkie |
| 10 | Chief Engineer | Tool Kit + Power Drill | Golden Wrench (Reputation +1) |

#### Business → Corporate
| Level | Position | Required Items | Granted Items |
|---:|---|---|---|
| 1 | Coffee Courier | None | Reusable Cup |
| 2 | Meeting Note Ninja | Notebook | Pen (basic) |
| 3 | Email Polisher | None | Polite Template Pack (fun) |
| 4 | Administrative Assistant | **Office Access Badge** | **Office Access Badge** |
| 5 | Operations Coordinator | Badge + Smartphone | Cheap Smartphone *(optional grant)* |
| 6 | Business Analyst | Badge + Laptop (basic) | Laptop (basic) *(optional grant)* |
| 7 | Project Manager | Badge + Laptop | Planner App License (Mood +1) |
| 8 | Department Manager | Badge + Laptop | Office Chair Voucher |
| 9 | Director | Badge + Laptop | Corner Desk (Comfort +1) |
| 10 | Executive | Badge + Laptop | Executive Mug (Mood +1) |

#### Business → Merchant
| Level | Position | Required Items | Granted Items |
|---:|---|---|---|
| 1 | Street Vendor | None | Small Pouch |
| 2 | Deal Hunter | None | Price Tag Roll |
| 3 | Sticker Price Expert | None | Marker (basic) |
| 4 | Shopkeeper | **Basic Shelf/Crate** | **Basic Shelf/Crate** |
| 5 | Online Seller | Smartphone | Shipping Tape |
| 6 | Inventory Manager | Shelf/Crate + Notebook | Barcode Stickers |
| 7 | Store Manager | Shelf/Crate | Basic POS Device (Productivity +1) |
| 8 | Business Owner | POS Device | Signboard (Reputation +1) |
| 9 | Wholesale Supplier | POS Device | Hand Truck (Stability +1) |
| 10 | Merchant Tycoon | POS Device | Golden Price Gun (Reputation +1, Mood +1) |

#### Business → Investor (Stocks)
| Level | Position | Required Items | Granted Items |
|---:|---|---|---|
| 1 | Chart Watcher | None | Newspaper (fun) |
| 2 | Paper Trader | None | Fake Portfolio Notebook |
| 3 | Rumor Collector | None | Hot Tip Coupon (Stability -1, Mood +1) |
| 4 | Retail Investor | **Smartphone** | **Cheap Smartphone** |
| 5 | Portfolio Manager (Personal) | Smartphone | Finance App Subscription (Productivity +1) |
| 6 | Active Trader | Smartphone | Power Bank |
| 7 | Value Investor | Smartphone | Long-Term Glasses (Mood +1) |
| 8 | Risk Manager | Smartphone | Risk Log Notebook |
| 9 | Fund Manager | Smartphone + Laptop | Laptop (basic) *(optional grant)* |
| 10 | Investment Director | Smartphone + Laptop | Dual Monitor Voucher (Productivity +1) |

#### Art → Author
| Level | Position | Required Items | Granted Items |
|---:|---|---|---|
| 1 | Idea Hoarder | Notebook | Pencil |
| 2 | Prompt Writer | Notebook | Coffee Coupon |
| 3 | Draft Sprinter | Notebook | Pen That Works Sometimes (fun) |
| 4 | Copywriter | Notebook or Basic Laptop | Basic Laptop *(optional grant)* |
| 5 | Content Writer | Laptop (or Notebook) | Desk Lamp (Comfort +1) |
| 6 | Freelance Author | Laptop | Basic Desk |
| 7 | Published Author | Laptop | Better Chair Voucher |
| 8 | Best-Selling Author | Laptop | Editor Contact (Reputation +1) |
| 9 | Franchise Author | Laptop | Bookshelf |
| 10 | Legendary Author | Laptop | Fountain Pen of Destiny (Mood +2) |

#### Art → Visual Artist
| Level | Position | Required Items | Granted Items |
|---:|---|---|---|
| 1 | Doodle Miner | Pencil | Sketchbook |
| 2 | Sketch Grinder | Sketchbook | Eraser |
| 3 | Color Dabbler | Basic Colors | Brush That Sheds (fun, Comfort -1) |
| 4 | Junior Illustrator | Art Supplies or Drawing Tablet | **Basic Art Supplies Kit** |
| 5 | Commission Artist | Supplies Kit | Better Brushes |
| 6 | Professional Illustrator | Drawing Tablet *(recommended)* | Basic Drawing Tablet *(optional grant)* |
| 7 | Concept Artist | Drawing Tablet | Reference Book (Productivity +1) |
| 8 | Senior Artist | Drawing Tablet | Pro Tablet Voucher |
| 9 | Art Director | Drawing Tablet | Gallery Card (Reputation +1) |
| 10 | Master Artist | Drawing Tablet | Signature Stamp (Reputation +1) |

#### Art → Musician
| Level | Position | Required Items | Granted Items |
|---:|---|---|---|
| 1 | Hum Recorder | None | Voice Memo App (fun) |
| 2 | Beat Tapper | None | Metronome App |
| 3 | Chord Collector | Basic Instrument *(optional)* | 3-String Guitar (fun, Productivity -1, Mood +1) |
| 4 | Session Musician | **Instrument or Budget Microphone** | **Budget Microphone** |
| 5 | Recording Artist | Mic + Headphones | Headphones (basic) |
| 6 | Gig Performer | Instrument/Mic | Gig Bag |
| 7 | Producer / Composer | Mic + **Audio Interface** | Audio Interface *(optional grant)* |
| 8 | Touring Musician | Audio Interface | Better Mic Voucher |
| 9 | Headline Performer | Audio Interface | Tour Jacket (Reputation +1) |
| 10 | Music Icon | Audio Interface | Golden Mic (Reputation +1, Mood +2) |

### 13.3 Store Inventory (starter)

#### Grocery: Food and Drinks (examples)
- Rice bowl (Hunger -20, Mood +1)
- Fruit pack (Hunger -10, Mood +2)
- Veggie meal (Hunger -18, Mood +2)
- Chicken meal (Hunger -25, Mood +1)
- Water (optional tiny Stability +1)
- Coffee (temporary boost, Rest -1)
- Energy drink (bigger temporary boost, Rest -2, later Mood -1)
- Instant noodles (Hunger -12, optional Comfort -1 if eaten often)
- Questionable hotdog (Hunger -20, Mood -3, Comfort -2)
- Expired sandwich (Hunger -10, Mood -5, Comfort -3)
- Mystery soup (random effect)

#### Mall: Furniture (examples)
- Basic bed (Comfort +2)
- Luxury bed (Comfort +5)
- Plastic chair (Comfort -1)
- Office chair (Comfort +2)
- Ergonomic chair (Comfort +4)
- Cheap desk (Comfort +1)
- Standing desk (Comfort +2, Productivity +1)
- Bookshelf (inventory utility later)

#### Mall: Gadgets/Devices (examples)
- Cheap smartphone (Investor requirement)
- Mid smartphone (Mood +2, Stability +1)
- Noise-cancel headphones (Comfort +2)
- Electric fan (Comfort +1)
- Air conditioner (Comfort +3)
- Basic laptop (Productivity +1)
- Work laptop (Productivity +2)
- High-end gaming laptop (Productivity +3, Mood +2)
- Desktop PC (Productivity +2)
- Dual monitors (Productivity +2)
- Drawing tablet (Artist requirement, Productivity +1)
- Pro drawing tablet (Productivity +3)
- Budget microphone (Musician requirement, Productivity +1)
- Audio interface (Productivity +2)
- Studio microphone (Productivity +3)

#### Funny Items (examples)
- **Toy Laptop** (Coder L3): Mood +2, Productivity +0
- “Motivational Poster: HUSTLE”: Mood +1, Comfort -1
- “Stock tips from a pigeon”: Mood +1, Stability -2
- Guitar with only 3 strings: Mood +1, Productivity -1
- Pen with 4 colors but none work: Mood -1

---

## 14) Console Viewer (Debug / Event Log Panel)

### 14.1 Purpose
A built-in **Console Viewer** shows what happens in the background:
- number changes (stats, EP breakdown, PP changes)
- events/actions
- character comments
- store purchases
- travel actions
- promotions/demotions
- daily quotes
- player inputs (New Game, chosen name, selected branch, etc.)

This is both:
- a developer/debug tool
- a fun “life log” for players (optional)

### 14.2 Placement (Game Screen)
- Recommended: small **Console** toggle button that opens/closes a panel.
- Panel is scrollable and fits the 700x420 layout.

### 14.3 Console Features (Version 1)
- Scrollable log (latest at bottom)
- Timestamps (in-game day + time)
- Category filters:
  - SYSTEM, INPUT, STATS, WORK, TRAVEL, STORE, ITEM, QUOTE, COMMENT, PROMOTION, DEMOTION, ROYALTY
- Optional later: search, copy button, clear (dev only)

### 14.4 Log Entry Format (recommended)
`[Day 3 | 08:10] [CATEGORY] Message... (optional key=value list)`

Examples:
- `[Day 1 | 06:00] [INPUT] Player clicked New Game`
- `[Day 1 | 06:00] [INPUT] Character name set: TestName`
- `[Day 1 | 06:01] [INPUT] Selected Category: Innovation | Branch: Coder`
- `[Day 1 | 06:05] [QUOTE] "Rest is part of the grind." (7s)`
- `[Day 1 | 06:10] [STATS] Hunger=60 Rest=40 Mood=48 Comfort=1 Prod=1 Rep=1 Stab=1`
- `[Day 1 | 06:10] [WORK] EP=3 (BP=2 CM=1 MM=0 NP=0) PP+2.1 TotalPP=2.1`
- `[Day 1 | 06:12] [COMMENT] Character said: "I wrote an idea down. That counts as version 0.0.1."`
- `[Day 1 | 06:20] [TRAVEL] From=Home To=Grocery TravelTime=30min`
- `[Day 1 | 06:50] [STORE] Grocery Purchase: Rice Bowl cost=12 Hunger-20 Mood+1`
- `[Day 2 | 09:00] [PROMOTION] Promoted to Level 2: Feature List Farmer (PP reset: 0)`
- `[Day 4 | 22:10] [DEMOTION] DRS=9 (Comfort=-3 Hunger=97 Rest=4) PP-50 -> -110 Demotion triggered`

### 14.5 What to log (minimum)
**Input:** new game, continue, settings, name/branch selection, purchases, travel  
**System:** load balance files, save/load, day start/end, quote shown  
**Stats:** before/after on work/eat/sleep/travel/buy, EP breakdown occasionally  
**Progression:** PP gains, thresholds, promotions; warnings and demotions  
**Items:** missing required items, granted items, inventory full, item effects  
**Royalties:** new release, payouts, remaining months, expiry

---

## 15) Save System (what to store)
Each of the 7 slots stores:
- Category + branch
- Position level + PP
- Living arrangement tier
- Career stats (Comfort, Productivity, Reputation, Stability)
- Storage + inventory items
- Needs (Hunger, Rest, Mood)
- Royalties (active products + months left + monthly amount)
- Last played timestamp
- Optional: last N console log lines (debug convenience)

---

## 16) Editable Balance Data (Godot files)
All numbers should be editable through data files.

Recommended folder:
- `res://data/balance/`

Suggested files:
- `time_scale.json`
- `positions.json` (titles, pay, requirements, grants)
- `promotion_requirements.json` (per branch)
- `living_arrangements.json` (stats)
- `travel_times.json` (store distances)
- `items.json` (store, price, effects, requirements)
- `needs_rules.json`
- `quotes.json`
- `comments.json`
- `console_settings.json`

Recommended loader:
- Autoload singleton `Balance.gd` that loads these files and exposes values.

