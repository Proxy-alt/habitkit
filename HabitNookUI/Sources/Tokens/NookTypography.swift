import SwiftUI

// MARK: - HabitNook Typography (migration notice)
//
// The canonical typography tokens have moved to ``NookFont``.
// Deprecated `Font` extension aliases (`nookLargeTitle`, `nookTitle`, etc.)
// are now defined in NookFont.swift alongside the ``NookFont`` enum.
//
// Update all call sites from:
//   `.font(.nookHeadline)`  →  `.font(NookFont.headline)`
//   `.font(.nookBody)`      →  `.font(NookFont.body)`
//   etc.
