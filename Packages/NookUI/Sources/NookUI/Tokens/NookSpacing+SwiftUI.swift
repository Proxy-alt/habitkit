import NookCore
import SwiftUI

public extension NookSpacing {

    /// The spacing in points.
    var value: CGFloat { CGFloat(points) }
}

public extension View {

    /// Pads all edges by a spacing token: `.padding(.md)`.
    func padding(_ spacing: NookSpacing) -> some View {
        padding(.all, spacing.value)
    }

    /// Pads the given edges by a spacing token: `.padding(.horizontal, .md)`.
    func padding(_ edges: Edge.Set, _ spacing: NookSpacing) -> some View {
        padding(edges, spacing.value)
    }
}
