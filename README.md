# 🎮 Dodge Game

A fast-paced SwiftUI-based iOS game where you dodge obstacles, collect powerups, and survive as long as possible!

## 🌟 Features

### Core Gameplay
- **Intuitive Controls**: Drag to move your player left and right
- **Dynamic Difficulty**: Progressive difficulty scaling - the game gets harder every 5 seconds with faster obstacles and increased spawn rates
- **High Score Tracking**: Your best score is automatically saved and displayed

### Powerup System
Collect various powerups to enhance your gameplay:
- **⭐ Coins**: Collect for bonus points (60% spawn rate)
- **🛡️ Shield**: Survive one hit from an obstacle (15% spawn rate, lasts 5 seconds)
- **🕐 Slow-Mo**: Slows down all obstacles by 60% (15% spawn rate, lasts 4 seconds)
- **🧲 Magnet**: Automatically attracts nearby coins (10% spawn rate, lasts 6 seconds)

### Combo System
- Chain powerup collections to earn **combo bonuses**
- Combo multiplier increases with consecutive pickups within 2 seconds
- Extra points awarded for higher combos!

### Visual Effects
- **Particle System**: Explosive visual effects on collisions and powerup collection
- **Animated Background**: Beautiful gradient backdrop with star field
- **Smooth Animations**: Fluid gameplay with 60 FPS performance
- **Haptic Feedback**: Tactile responses for key game events

### Statistics & Progression
- **Difficulty Level Indicator**: See your current difficulty level during gameplay
- **Visual Feedback**: Screen flashes when difficulty increases
- **Lifetime Statistics**: Track total games played and coins collected across all sessions
- **Level Achievement**: Shows maximum difficulty level reached each game

## 🎯 How to Play

1. **Start**: Tap the START button from the main menu
2. **Move**: Drag your finger left or right to control the player
3. **Avoid**: Dodge the red obstacles falling from the top
4. **Collect**: Grab powerups to gain advantages
5. **Survive**: Last as long as possible to achieve a high score!

## 📊 Scoring System

- **Time Survived**: Earn 10 points per second
- **Dodged Obstacles**: +2 points for each obstacle that passes
- **Coin Powerups**: +25 points (plus combo bonus)
- **Other Powerups**: +10 points (plus combo bonus)
- **Shield Block**: +15 points when shield absorbs a hit
- **Combo Bonus**: Additional points for chaining powerups (5 points × combo multiplier)

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
- Efficient particle system with automatic cleanup
- Off-screen object removal
- Optimized collision detection
- Smooth animations with SwiftUI's animation system

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
2. **Prioritize Shields**: Shield powerups are your best friend at higher difficulties
3. **Chain Combos**: Collect powerups in quick succession for bonus points
4. **Use Slow-Mo Wisely**: Save slow-mo powerups for dense obstacle patterns
5. **Magnet Strategy**: Activate magnets when multiple coins are on screen
6. **Watch the Level**: Pay attention to difficulty increases and adjust your strategy
7. **Practice Patterns**: Learn to recognize dangerous obstacle formations

## 📝 Version History

### Latest Version - Enhanced Edition
- ✨ Added difficulty level indicator with visual feedback
- 📊 Implemented lifetime statistics tracking
- 🎯 Enhanced game over screen with more detailed stats
- 💫 Improved visual feedback for difficulty increases
- 📈 Better game balance and progression
- 🎨 Polished UI with consistent design language

### Previous
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
