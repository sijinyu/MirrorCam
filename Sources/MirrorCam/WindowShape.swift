import Foundation

public enum WindowShape: String, Equatable {
    case circle
    case roundedRectangle
}

public enum MirrorEffect: String, Equatable, CaseIterable {
    case flat = "Flat Mirror"
    case convex = "Convex Mirror"
    case concave = "Concave Mirror"
}

public enum ColorFilter: String, Equatable, CaseIterable {
    case none = "None"
    case grayscale = "Grayscale"
    case sepia = "Sepia"
}
