# Habit Grow

A calm, plant-themed habit tracker for iOS. Pure SwiftUI + SwiftData, data stays on device.

- Today / Week / Month views, per-habit detail with calendar and streaks
- Progress is measured inside each habit's own period (day → this week, week, month) with "N to go · D days left"
- A plant that grows with your progress (SVG assets in `Shared/Assets.xcassets`)
- Local reminders, 12 colors, drag-to-arrange
- Interactive widgets (single habit / multiple habits)
- Traditional Chinese / English, light / dark

> 「App 開發與上架入門」課程範例專案。作者：江承祐（阿班）· Threads @your.engineer.ben
> 這是一個真實在 App Store 上架流程中的 App，原始碼開放給學員學習：SwiftUI、SwiftData、Widget、StoreKit 2 一次購買、多語系、App Store 截圖自動化的實際寫法。

## 給學員：怎麼跑起來

1. 安裝 Xcode（Mac App Store）與 XcodeGen：`brew install xcodegen`
2. 在專案資料夾執行 `xcodegen generate`，打開 `HabitGrow.xcodeproj`
3. 在模擬器上直接按 ▶ 就能跑（不需要開發者帳號）
4. 要裝到自己的 iPhone：在 Signing & Capabilities 選你自己的 Team，並把 Bundle ID 與 App Group 改成你自己的
5. 用 Claude Code / Codex 打開這個資料夾，試著請 AI 幫你加一個小功能

## Build

Requires Xcode 26 and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
xcodegen generate
open HabitGrow.xcodeproj
```

Pick your own Team in Xcode for the App and Widget targets, and update the App Group
(`group.com.charonyuu.habitgrow`) if you change the bundle identifier.

## Pro (one-time purchase)

`com.charonyuu.habitgrow.pro`, non-consumable. Free: up to 5 habits, the sprout plant, single-habit widget.
Pro: unlimited habits, all plants + 3D crops, multi-habit widget, yearly heatmap, alternate app icons.

- Ownership comes from StoreKit entitlements; "Restore Purchase" brings it back on a new phone (same Apple ID).
- `HabitGrow.storekit` is attached to the shared scheme, so run from Xcode to test purchases locally.
  In Debug builds, launch argument `-forcePro` unlocks Pro for UI testing without StoreKit. Release builds ignore it.
- Set the real price in App Store Connect (local config uses NT$60).

## Privacy

`Shared/PrivacyInfo.xcprivacy` is embedded in both targets and declares local/App Group preferences with no tracking or app-operated data collection.

## License

For learning purposes. You may read, run and modify the code for your own study. Please don't republish it to the App Store as-is (Guideline 4.1 / 4.3).

## Town

The Town tab turns habits into a small 3D town (SceneKit, built entirely from code, no image assets).
Each habit is a house on its own lot; houses level up with lifetime check-ins (0 / 1 / 8 / 30 / 100),
extras (lamps, benches, wells...) appear as total check-ins grow, level-ups pop with sparkles.
Pan, pinch and rotate to look around. Themes are palettes: Cottage (free), Japanese, Forest, Snow, Island, Night (Pro).
A Town widget shows a rendered picture of the town.
