import SwiftUI

enum FFTypography {
    static let eyebrow = Font.system(.caption, design: .rounded, weight: .semibold)
    static let heroTitle = Font.system(.largeTitle, design: .serif, weight: .bold)
    static let displayMetric = Font.system(size: 62, weight: .bold, design: .rounded)
    static let sectionTitle = Font.system(.title3, design: .rounded, weight: .semibold)
    static let cardTitle = Font.system(.headline, design: .rounded, weight: .semibold)
    static let body = Font.system(.body, design: .rounded)
    static let detail = Font.system(.footnote, design: .rounded)
    static let micro = Font.system(.caption2, design: .rounded)
    static let code = Font.system(.headline, design: .monospaced, weight: .semibold)
}
