import SwiftUI

// MARK: - HabitKit Typography (migration notice)
//
// The canonical typography tokens have moved to ``HKFont``.
// Deprecated `Font` extension aliases (`hkLargeTitle`, `hkTitle`, etc.)
// are now defined in HKFont.swift alongside the ``HKFont`` enum.
//
// Update all call sites from:
//   `.font(.hkHeadline)`  →  `.font(HKFont.headline)`
//   `.font(.hkBody)`      →  `.font(HKFont.body)`
//   etc.
