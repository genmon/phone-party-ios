import SwiftUI

struct ColorUtils {
    static func colorToString(_ color: Color) -> String {
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return "\(red),\(green),\(blue),\(alpha)"
    }

    static func stringToColor(_ colorString: String) -> Color? {
        let components = colorString.split(separator: ",").compactMap { Double($0) }
        guard components.count == 4 else { return nil }
        return Color(red: components[0], green: components[1], blue: components[2], opacity: components[3])
    }
}
