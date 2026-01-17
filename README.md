# 🎮 Dodge Game

A fast-paced SwiftUI-based iOS game where you dodge obstacles, collect powerups, and survive as long as possible!

## 🌟 Features

### Core Gameplay
- **Intuitive Controls**: Drag to move your player left and right
- **Dynamic Difficulty**: Progressive difficulty scaling - the game gets harder every 5 seconds with faster obstacles and increased spawn rates
- **High Score Tracking**: Your best score is automatically saved and displayed
- **Multiple Lives System**: Start with 3 lives instead of instant game over (1 life in Hardcore mode)

### Game Modes
- **🎮 Endless Mode**: Classic survival - play until you run out of lives
- **⏱️ Time Attack**: Survive for a set duration (60, 90, or 120 seconds) to win
- **💀 Hardcore Mode**: 1 life only, no shields, faster difficulty progression

### Powerup System
Collect various powerups to enhance your gameplay:
- **⭐ Coins**: Collect for bonus points (55% spawn rate)
- **🛡️ Shield/Life**: Restores a life if not at max, otherwise provides hit protection (12% spawn rate, lasts 5 seconds)
- **🕐 Slow-Mo**: Slows down all obstacles by 60% (12% spawn rate, lasts 4 seconds)
- **🧲 Magnet**: Automatically attracts nearby coins (8% spawn rate, lasts 6 seconds)
- **⚡ Speed Boost**: Increases player movement speed (5% spawn rate, lasts 5 seconds)
- **❄️ Freeze**: Temporarily stops all obstacles (4% spawn rate, lasts 3 seconds, 10s cooldown after collection)
- **💥 Bomb**: Destroys all obstacles on screen instantly (4% spawn rate, 8s cooldown after collection)

Note: Cooldowns prevent collecting the same powerup type immediately after use, adding strategic depth to gameplay.

### Powerup Combinations 🌟 NEW!
Activate multiple powerups simultaneously for powerful combo effects:
- **🧲⏰ Super Magnet** (Magnet + Slow-Mo): +50% attraction radius for coin collection
- **🛡️⚡ Invincible Dash** (Shield + Speed Boost): Destroy obstacles on contact for 5 seconds!
- **❄️💥 Ice Blast** (Freeze + Bomb): Clear screen + extended freeze duration

### Powerup Upgrades 🆙 NEW!
Spend coins to permanently upgrade your powerups:
- **Shield Duration**: +1 second per level (max level 3)
- **Magnet Radius**: +20 range per level (max level 3)
- **Slow-Mo Duration**: +1 second per level (max level 3)
- **Freeze Duration**: +1 second per level (max level 3)
- **Cost**: 150 coins per upgrade

### Obstacle System 🎯 NEW!
Diverse obstacles with unique behaviors:

**Shapes** (different point values):
- **⚫ Circle**: Standard obstacle (1.0x points)
- **🔺 Triangle**: Sharp and dangerous (1.2x points)
- **⬛ Square**: Solid block (1.1x points)
- **⭐ Star**: Rare and valuable (1.5x points)

**Movement Patterns**:
- **Straight**: Classic downward fall
- **🌊 Snake**: Sinusoidal side-to-side motion
- **🎯 Tracking**: Slowly follows player position
- **⬅️➡️ Bouncing**: Bounces off screen edges

**Special Characteristics**:
- **🟠 Destructible**: Tap to destroy for bonus points!
- **💜 Splitting**: Splits into 2-3 smaller obstacles when hit
- **🔴 Explosive**: Creates chain reaction, damaging nearby obstacles
- **Normal**: Standard obstacle behavior

### Customization
- **Player Colors**: 6 unlockable player colors (White, Cyan, Green, Pink, Orange, Purple)
- **Unlock with Coins**: Spend your collected coins to unlock new colors
- **Persistent Progress**: All unlocks and preferences are saved

### Settings
- **Haptic Feedback Toggle**: Enable/disable vibration feedback
- **Time Attack Duration**: Choose 60, 90, or 120 seconds for Time Attack mode
- **Player Color Selection**: Choose your unlocked player color
- **Powerup Upgrades**: Spend coins to enhance your powerup effectiveness
- **Cooldown Indicators**: Visual feedback for powerup cooldowns

### Combo System
- Chain powerup collections to earn **combo bonuses**
- Combo multiplier increases with consecutive pickups within 2 seconds
- Extra points awarded for higher combos!

### Visual Effects
- **Particle System**: Explosive visual effects on collisions and powerup collection (optimized for performance)
- **Animated Background**: Beautiful gradient backdrop with star field
- **Smooth Animations**: Fluid gameplay with 60 FPS performance
- **Haptic Feedback**: Tactile responses for key game events (can be toggled)
- **Score Popups**: Animated floating text showing points earned
- **Milestone Notifications**: Celebratory alerts for achievements
- **Freeze Effect**: Obstacles turn blue when frozen
- **Speed Boost Trail**: Visual trail effect when speed boost is active

### Statistics & Progression
- **Lives Indicator**: Heart icons showing remaining lives
- **Difficulty Level Indicator**: See your current difficulty level during gameplay with visual flash on increases
- **Visual Feedback**: Screen element pulses and changes color when difficulty increases
- **Lifetime Statistics**: Track total games played and coins collected across all sessions
- **Level Achievement**: Shows maximum difficulty level reached each game
- **Milestone System**: Achievements for reaching coin milestones (10, 25, 50, 100, 250, 500) and score milestones (100, 250, 500, 1000, 2500, 5000, 10000)
- **Animated Feedback**: Score increases shown with floating text animations

## 🎯 How to Play

1. **Start**: Tap the START button from the main menu
2. **Select Mode**: Choose Endless, Time Attack, or Hardcore mode
3. **Move**: Drag your finger left or right to control the player
4. **Avoid**: Dodge obstacles with various shapes and movement patterns
5. **Tap**: Destroy orange destructible obstacles by tapping them
6. **Collect**: Grab powerups to gain advantages
7. **Combo**: Activate multiple powerups together for powerful combo effects
8. **Upgrade**: Spend coins in settings to upgrade your powerup effectiveness
9. **Survive**: Last as long as possible to achieve a high score!

## 📊 Scoring System

- **Time Survived**: Earn 10 points per second
- **Dodged Obstacles**: +2 points for each obstacle that passes (multiplied by shape bonus)
- **Destroyed Obstacles**: +6 points × shape multiplier for tapping destructible obstacles
- **Coin Powerups**: +25 points (plus combo bonus)
- **Other Powerups**: +10 points (plus combo bonus)
- **Shield Block**: +15 points when shield absorbs a hit
- **Invincible Dash**: +30 points when destroying obstacle with combo
- **Bomb Bonus**: +5 points per obstacle destroyed
- **Combo Bonus**: Additional points for chaining powerups (5 points × combo multiplier)
- **Shape Multipliers**: Circle (1.0x), Triangle (1.2x), Square (1.1x), Star (1.5x)

## 🎨 Game Mechanics

### Difficulty Scaling
- **Progressive System**: Difficulty increases every 5 seconds
- **Speed Increase**: +25 speed per difficulty level
- **Spawn Rate**: Obstacles spawn 0.03s faster per level (minimum 0.2s)
- **Balanced Challenge**: Powerup spawn rates also increase slightly to help players
- **Speed Cap**: Maximum obstacle speed capped at 600 to maintain playability

### Collision Detection
- Precise circular collision detection
- Shield provides one-hit protection with visual feedback
- Explosion effects on collision

### Powerup Effects
- **Shield**: Protects from one obstacle collision with cyan glow effect
- **Slow-Mo**: Reduces obstacle and powerup speed to 40% with yellow indicator
- **Magnet**: Attracts coins within 150-unit radius with purple field visualization
- **Timers**: Active powerup durations displayed in the top bar

## 🛠️ Technical Details

### Built With
- **SwiftUI**: Modern declarative UI framework
- **Combine**: Reactive programming for state management
- **UserDefaults**: Persistent storage for scores and statistics
- **UIKit**: Haptic feedback integration

### Architecture
- **MVVM Pattern**: Clean separation of game logic and UI
- **60 FPS Game Loop**: Smooth gameplay with Timer-based updates
- **State Management**: Observable game engine with published properties
- **Modular Design**: Separate components for player, obstacles, powerups, and particles

### Performance Optimizations
- Efficient particle system with automatic cleanup and particle count limiting (max 150)
- Off-screen object removal to maintain performance
- Optimized collision detection
- Smooth animations with SwiftUI's animation system
- 60 FPS consistent frame rate

## 🎲 Game Balance

The game is carefully balanced to provide an engaging difficulty curve:
- **Early Game (0-15s)**: Learn the controls, slower obstacles
- **Mid Game (15-45s)**: Increasing challenge, strategic powerup use important
- **Late Game (45s+)**: High difficulty, requires excellent reflexes and powerup timing
- **Maximum Difficulty**: Reaches peak challenge around level 15-20

## 📱 Requirements

- iOS 15.0+
- Xcode 13.0+
- Swift 5.5+

## 🚀 Getting Started

1. Clone the repository
2. Open `DodgeGame.xcodeproj` in Xcode
3. Build and run on your iOS device or simulator
4. Start dodging!

## 🏆 Tips for High Scores

1. **Stay Centered**: Position yourself in the middle to have maximum movement range
2. **Prioritize Shields**: Shield powerups restore lives when not at max
3. **Chain Combos**: Collect powerups in quick succession for bonus points
4. **Powerup Combos**: Combine Shield + Speed Boost for invincible dash, or Magnet + Slow-Mo for super collection
5. **Tap Destructibles**: Watch for orange obstacles and tap them for easy points
6. **Use Freeze Wisely**: Freeze powerup stops all obstacles - perfect for dense patterns (10s cooldown)
7. **Bomb Strategy**: Bomb powerup clears the screen - save for emergencies (8s cooldown)
8. **Speed Boost**: Use speed boost to make quick escapes and navigate tracking obstacles
9. **Magnet Strategy**: Activate magnets when multiple coins are on screen
10. **Upgrade Early**: Invest coins in powerup upgrades to enhance their effectiveness
11. **Watch the Level**: Pay attention to difficulty increases and adjust your strategy
12. **Learn Patterns**: Recognize snake, tracking, and bouncing obstacles and plan accordingly
13. **Chase Stars**: Star-shaped obstacles give 1.5x points - worth the risk!
14. **Avoid Explosive**: Red glowing obstacles can cause chain reactions
15. **Try Different Modes**: Time Attack for structured challenge, Hardcore for intense gameplay

## 📝 Version History

### Latest Version - Enhanced Edition v4 🆕
- 🎯 **Advanced Obstacle System**: 4 shapes (circle, triangle, square, star) with unique point values
- 🌊 **Dynamic Movement Patterns**: Snake, tracking, and bouncing obstacles
- 💥 **Special Characteristics**: Destructible (tap to destroy), splitting, and explosive obstacles
- ⭐ **Powerup Combinations**: Super Magnet, Invincible Dash, and Ice Blast combos
- ⏱️ **Cooldown System**: Freeze (10s) and Bomb (8s) cooldowns for balance
- 🔧 **Powerup Upgrades**: Permanent upgrades for Shield, Magnet, Slow-Mo, and Freeze
- 🎨 **Visual Enhancements**: Shape-specific rendering with custom icons
- 📊 **Enhanced Scoring**: Shape multipliers and characteristic bonuses
- 🎮 **Interactive Gameplay**: Tap destructible obstacles for bonus points
- 💫 **Combo UI**: Visual indicators for active combos and cooldowns

### Latest Version - Enhanced Edition v3
- ❤️ **Multiple Lives System**: Start with 3 lives instead of instant game over
- 🎮 **Game Modes**: Added Endless, Time Attack, and Hardcore modes
- ⚡ **Speed Boost Powerup**: Increases player movement speed
- ❄️ **Freeze Powerup**: Temporarily stops all obstacles
- 💥 **Bomb Powerup**: Destroys all obstacles on screen
- ⚙️ **Settings Menu**: Toggle haptics, select game mode, customize player
- 🎨 **Player Customization**: 6 unlockable player colors
- 🏪 **Unlock System**: Spend coins to unlock new colors
- ⏱️ **Time Attack Timer**: Visual countdown for Time Attack mode
- 💀 **Hardcore Mode**: 1 life, no shields, faster difficulty
- 🔧 **Code Quality**: Extracted magic numbers to constants
- 📖 **Updated Documentation**: Comprehensive README updates

### Previous - Enhanced Edition v2
- 🎯 Added milestone achievement system with visual notifications
- ✨ Implemented animated score popups for instant feedback
- 🎨 Enhanced visual effects and animations
- 🚀 Optimized particle system (max 150 particles for performance)
- 📊 Score milestone tracking (100, 250, 500, 1k, 2.5k, 5k, 10k)
- 🏅 Coin milestone achievements (10, 25, 50, 100, 250, 500)
- 💫 Added haptic feedback for milestone achievements
- 🔧 Performance improvements and code optimization

### Previous - Enhanced Edition v1
- ✨ Added difficulty level indicator with visual feedback
- 📊 Implemented lifetime statistics tracking
- 🎯 Enhanced game over screen with more detailed stats
- 💫 Improved visual feedback for difficulty increases
- 📈 Better game balance and progression
- 🎨 Polished UI with consistent design language

### Initial Release
- Initial release with core gameplay
- Powerup system implementation
- Combo mechanics
- Particle effects

## 🤝 Contributing

Feel free to submit issues and enhancement requests!

## 📄 License

This project is available for personal and educational use.

## 🎉 Enjoy!

Challenge yourself and your friends to beat the high score! How long can you survive?

---

Made with ❤️ using SwiftUI
