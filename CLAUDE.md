# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Building and Running
- Open `DodgeGame.xcodeproj` in Xcode
- Build: `Cmd+B` in Xcode
- Run: `Cmd+R` in Xcode (use iOS Simulator or physical device)
- The app requires iOS 15.0+ and Swift 5.5+

### Project Structure
This is a native iOS SwiftUI project with no external dependencies. All development happens through Xcode - there are no build scripts, package managers, or command-line build tools.

## High-Level Architecture

### Core Architecture Pattern
The codebase follows a **hybrid MVVM/MVC pattern** with a single source of truth:

```
DodgeGameApp (Entry)
  └── ContentView (Root View Controller)
        └── @StateObject GameEngine (Observable Game State)
              ├── 60 FPS game loop (Timer-based)
              ├── All @Published game state
              └── Persistence via UserDefaults

        ├── Modular UI Components (in Views/)
        │   └── Receive GameEngine via @ObservedObject
        │
        └── Inline Game Views (nested in ContentView)
            ├── PlayerView, ObstacleView, PowerupView
            └── Particle rendering
```

**Key Architectural Decisions:**
- `GameEngine` is the **single source of truth** for all game state
- `ContentView.swift` (~1130 lines) is the root view controller that owns GameEngine
- `GameEngine.swift` (~1350 lines) contains all game logic, state, and the 60 FPS update loop
- Modular views in `Views/` folder are reusable settings/UI components
- Game rendering views (player, obstacles, powerups) are defined inline in ContentView

### State Management
All game state flows unidirectionally: `GameEngine` → `ContentView` → Child Views

GameEngine manages:
- Game state machine: `.ready`, `.playing`, `.paused`, `.gameOver`
- Entity arrays: `obstacles[]`, `powerups[]`, `particles[]`, `trailParticles[]`
- Player state: position, lives, shields, active powerups
- Powerup timers: shield, slowMo, magnet, speedBoost, freeze
- Score, combo system, difficulty level
- Persistence (via UserDefaults)

### Game Loop Architecture
The game uses a **fixed 60 FPS timer-based loop**:

```swift
Timer.scheduledTimer(withTimeInterval: 1.0/60) {
    self.tick()  // Calculate delta time
      └── update(dt: dt)  // Single update method
}
```

**Update Order in `update(dt:)`:**
1. Time tracking & time attack win condition
2. Score accumulation (10 points/second)
3. Combo system decay (2-second window)
4. Difficulty scaling (every 5 seconds)
5. Powerup timer countdown
6. Obstacle spawning & movement
7. Powerup spawning & magnet attraction
8. Particle system updates
9. Trail particle updates
10. Collision detection

### Entity Architecture
Entities are **value types (structs)** stored in arrays, not class hierarchies:

- `Player` - Fixed vertical position, horizontal drag control only
- `Obstacle: Identifiable` - Falling circles with varying speed/size
- `Powerup: Identifiable` - 7 types with weighted spawn probabilities
- `Particle: Identifiable` - Explosion/trail/aura effects with object pooling
- `TrailParticle: Identifiable` - Speed boost visual trail

All entities have position (x, y), radius, and are updated via direct array mutation.

### Performance Optimizations
- **Particle pooling**: `particlePool` maintains up to 100 pre-allocated particles to prevent GC pauses
- **Max particle cap**: 150 particles maximum to maintain 60 FPS
- **Off-screen cleanup**: Entities removed when off-screen
- **Efficient collision**: Simple distance-based circle collision (no spatial partitioning needed at this scale)

### Constants Architecture
All gameplay values are centralized in `GameEngine.GameConstants`:
- Entity sizes (player/obstacle/powerup radii)
- Physics (speeds, spawn intervals, magnet radius)
- Difficulty scaling (speed increases per level, spawn rate multipliers)
- Scoring (points per event, combo bonuses)
- Particle limits

**When balancing gameplay, modify GameConstants, not magic numbers scattered in code.**

### Powerup System
7 powerup types with weighted spawn (total 100%):
- Coin (55%): +25 points, combo fuel
- Shield (12%): Blocks 1 hit OR restores 1 life (5s)
- SlowMo (12%): 40% obstacle speed (4s)
- Magnet (8%): Auto-attracts coins in 150px radius (6s)
- SpeedBoost (5%): 1.5x player movement (5s)
- Freeze (4%): Stops all obstacles (3s)
- Bomb (4%): Destroys all obstacles (instant)

Powerups modify global state (e.g., `hasShield`, `hasMagnet`) and use timer properties (e.g., `shieldTimer`) that count down in the game loop.

### Theme System (`ThemeManager.swift`)
Modular cosmetic system with unlocking:
- **4 theme categories**: ObstacleTheme, BackgroundTheme, ParticleEffectPack, TrailEffect
- **Unlock requirements**: `.none` (default), `.totalCoins(Int)`, `.achievement(Achievement)`
- `ThemeManager` is separate from `GameEngine` to isolate cosmetic concerns
- Generic `ThemeSection<T>` component in Views handles all theme types

### Persistence Strategy
All data persisted to `UserDefaults` with strategic save timing:
- Game over: `saveBestScore()`, `saveStatistics()`
- Settings change: `themeManager.saveSettings()`
- Color unlock: `saveSettings()`

**Keys follow pattern**: `"DodgeGame_<PropertyName>"` (e.g., `DodgeGame_BestScore`)

### Collision & Interaction
- **Obstacle collision**: Circle-to-circle distance check (`dist² <= (r1 + r2)²`)
- **Powerup collection**: Same with +5px forgiveness for better feel
- **Shield blocks**: On collision with shield active, play effects and decrement shield
- **Lives system**: 3 lives in Endless/Time Attack, 1 in Hardcore

### Difficulty Scaling
Progressive difficulty every 5 seconds:
- Obstacle speed: `+25 units/second` per level (capped at 600)
- Spawn interval: `×0.97` (faster spawning, minimum 0.2s)
- Powerup spawn: `×0.95` (slight increase to help player)

Hardcore mode: 1.5x difficulty multiplier applied to speed increases.

## Code Organization

### File Breakdown
- **DodgeGameApp.swift** - App entry point, minimal code
- **ContentView.swift** - Root view with game rendering, menu, settings, game over screen
- **GameEngine.swift** - All game logic, state management, update loop
- **ThemeManager.swift** - Theme/cosmetic system, separate from core game logic
- **Views/** - Modular, reusable UI components for settings and menus:
  - `GameModeSelector.swift` - Game mode selection (Endless/Time Attack/Hardcore)
  - `ThemeSelector.swift` - Generic theme selection/unlocking UI
  - `PlayerColorGrid.swift` - Player color customization
  - `PowerupsLegend.swift` - Informational powerup guide
  - `GlassBackgroundStyle.swift` - Reusable glass morphism ViewModifier
  - `HapticToggle.swift`, `TimeAttackDurationSelector.swift`, etc.

### When Adding New Features
- **New powerup type**:
  1. Add case to `PowerupType` enum in GameEngine
  2. Add handling in `collectPowerup()` method
  3. Add timer property if duration-based
  4. Update timer countdown in `update(dt:)`
  5. Add icon to `PowerupsLegend.swift`

- **New game mode**:
  1. Add case to `GameMode` enum in GameEngine
  2. Update `startGame()` to initialize mode-specific state
  3. Add win/loss conditions in `update(dt:)`
  4. Update `GameModeSelector.swift` UI

- **New theme category**:
  1. Define enum in `ThemeManager.swift` conforming to `GameTheme` protocol
  2. Add unlock requirements
  3. Add @Published property and persistence
  4. Use generic `ThemeSection<T>` in `ThemeSelector.swift`

- **Balancing changes**: Modify `GameConstants` enum values, not hardcoded numbers

### Important Patterns
- **State updates happen in GameEngine only** - Views never mutate state directly
- **Haptic feedback** - Use `playHaptic()` method that respects user settings
- **Score events** - Always go through `addScore(_ points: Int, reason: String)` for consistency
- **Particle spawning** - Use `spawnParticles()` method which respects pooling and caps
- **Milestone notifications** - Check `reachedMilestones` set to avoid duplicate toasts

### Common Pitfalls
- Don't add game logic to ContentView - it belongs in GameEngine
- Don't bypass GameConstants - centralize all tuning values
- Don't create particles without respecting the pool - use `spawnParticles()`
- Don't modify obstacle/powerup arrays during iteration - use indices or removeAll with predicate
- Shield powerup has dual behavior: restores life if not at max, otherwise provides hit protection

## Game Modes

### Endless Mode (Default)
- 3 lives, no time limit
- Standard difficulty progression
- Goal: Survive as long as possible

### Time Attack Mode
- 3 lives, survive for set duration (60/90/120 seconds)
- Win by reaching time limit
- Countdown timer displays in top bar

### Hardcore Mode
- 1 life only
- 1.5x difficulty scaling multiplier
- Shield powerups disabled (won't spawn)
- For experienced players

## Testing & Debugging

### Manual Testing Checklist
- Test all 3 game modes (Endless, Time Attack, Hardcore)
- Verify all 7 powerup types work correctly
- Check collision detection at screen edges
- Test theme unlocking with various coin amounts
- Verify persistence (close app, reopen, check scores/unlocks)
- Test achievement unlocking
- Verify haptic feedback toggle works
- Test pause/resume functionality

### Performance Testing
- Monitor particle count doesn't exceed 150
- Check frame rate stays at 60 FPS on older devices
- Verify no memory leaks after extended gameplay
- Test with all particle effects enabled simultaneously

### Known Constraints
- Player movement is horizontal only (y-position is fixed)
- Obstacles spawn at top, move downward only (no diagonal/random movement)
- No networking or multiplayer functionality
- All data stored locally (UserDefaults)
