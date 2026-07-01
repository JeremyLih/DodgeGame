# 🎮 Dodge Game

A fast-paced SwiftUI iOS game: drag to dodge falling obstacles, grab powerups, and survive as long as you can. Pure native SwiftUI with **zero external dependencies**.

## ✨ Features

- **Three game modes** — Endless, Time Attack, and Hardcore
- **7 powerups** — shields, slow-mo, magnet, speed boost, freeze, bomb, and coins
- **Combo system** — chain pickups within 2 seconds for bonus points
- **Progressive difficulty** — obstacles get faster and denser every 5 seconds
- **Customization** — unlockable player colors and cosmetic themes, bought with coins
- **Progression** — lives system, lifetime stats, and coin/score milestone achievements
- **Polish** — 60 FPS gameplay, particle effects, haptics, and animated score popups

## 🕹️ Game Modes

| Mode | Lives | Goal |
|------|-------|------|
| **Endless** | 3 | Survive as long as possible |
| **Time Attack** | 3 | Last a set duration (60 / 90 / 120s) to win |
| **Hardcore** | 1 | 1.5× difficulty, no shields — for experts |

## ⚡ Powerups

| Powerup | Effect | Spawn | Duration |
|---------|--------|-------|----------|
| ⭐ Coin | +25 points, fuels combos | 55% | — |
| 🛡️ Shield | Restores a life, else blocks 1 hit | 12% | 5s |
| 🕐 Slow-Mo | Obstacles move at 40% speed | 12% | 4s |
| 🧲 Magnet | Auto-attracts nearby coins | 8% | 6s |
| ⚡ Speed Boost | 1.5× player movement | 5% | 5s |
| ❄️ Freeze | Stops all obstacles | 4% | 3s |
| 💥 Bomb | Destroys all obstacles instantly | 4% | — |

## 🎯 How to Play

1. Tap **START**, then pick a game mode.
2. **Drag** left/right to move your player.
3. **Dodge** the falling obstacles and **collect** powerups.
4. Survive as long as you can to set a high score.

Scoring rewards time survived (10 pts/sec), dodged obstacles, powerup pickups, and combo chains. Your best score and stats persist between sessions.

## 🛠️ Tech Stack

- **SwiftUI** for the UI, with a `GameEngine` `ObservableObject` as the single source of truth
- **Timer-based 60 FPS game loop** driving all entity updates and collision detection
- **UserDefaults** for persistence (scores, unlocks, settings)
- Pooled particle system capped at 150 for consistent performance

## 🚀 Getting Started

```bash
git clone https://github.com/JeremyLih/DodgeGame.git
cd DodgeGame
open DodgeGame.xcodeproj
```

Then in Xcode:

1. Under **Signing & Capabilities**, select your development team (the project ships with none set).
2. Build & run with `Cmd+R` on the simulator or a connected device.

No package managers or setup scripts required — just clone and open.

## 📱 Requirements

- iOS 15.0+
- Xcode 13.0+ / Swift 5.5+

## 📄 License

Licensed under the **MIT License** — see [LICENSE](LICENSE) for details.

---

Made with ❤️ using SwiftUI
