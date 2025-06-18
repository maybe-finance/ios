import SwiftUI

extension Font {
    static func geist(size: CGFloat, weight: Font.Weight = .regular, italic: Bool = false) -> Font {
        let weightName: String
        switch weight {
        case .black:
            weightName = italic ? "Geist-BlackItalic" : "Geist-Black"
        case .heavy:
            weightName = italic ? "Geist-ExtraBoldItalic" : "Geist-ExtraBold"
        case .bold:
            weightName = italic ? "Geist-BoldItalic" : "Geist-Bold"
        case .semibold:
            weightName = italic ? "Geist-SemiBoldItalic" : "Geist-SemiBold"
        case .medium:
            weightName = italic ? "Geist-MediumItalic" : "Geist-Medium"
        case .regular:
            weightName = italic ? "Geist-RegularItalic" : "Geist-Regular"
        case .light:
            weightName = italic ? "Geist-LightItalic" : "Geist-Light"
        case .thin:
            weightName = italic ? "Geist-ThinItalic" : "Geist-Thin"
        case .ultraLight:
            weightName = italic ? "Geist-ExtraLightItalic" : "Geist-ExtraLight"
        default:
            weightName = italic ? "Geist-RegularItalic" : "Geist-Regular"
        }
        
        return Font.custom(weightName, size: size)
    }
    
    static func geistMono(size: CGFloat, weight: Font.Weight = .regular, italic: Bool = false) -> Font {
        let weightName: String
        switch weight {
        case .black:
            weightName = italic ? "GeistMono-BlackItalic" : "GeistMono-Black"
        case .heavy:
            weightName = italic ? "GeistMono-ExtraBoldItalic" : "GeistMono-ExtraBold"
        case .bold:
            weightName = italic ? "GeistMono-BoldItalic" : "GeistMono-Bold"
        case .semibold:
            weightName = italic ? "GeistMono-SemiBoldItalic" : "GeistMono-SemiBold"
        case .medium:
            weightName = italic ? "GeistMono-MediumItalic" : "GeistMono-Medium"
        case .regular:
            weightName = italic ? "GeistMono-Italic" : "GeistMono-Regular"
        case .light:
            weightName = italic ? "GeistMono-LightItalic" : "GeistMono-Light"
        case .thin:
            weightName = italic ? "GeistMono-ThinItalic" : "GeistMono-Thin"
        case .ultraLight:
            weightName = italic ? "GeistMono-ExtraLightItalic" : "GeistMono-ExtraLight"
        default:
            weightName = italic ? "GeistMono-Italic" : "GeistMono-Regular"
        }
        
        return Font.custom(weightName, size: size)
    }
    
    // Convenience methods for common text styles using Geist
    static var geistLargeTitle: Font {
        .geist(size: 34, weight: .regular)
    }
    
    static var geistTitle: Font {
        .geist(size: 28, weight: .regular)
    }
    
    static var geistTitle2: Font {
        .geist(size: 22, weight: .regular)
    }
    
    static var geistTitle3: Font {
        .geist(size: 20, weight: .regular)
    }
    
    static var geistHeadline: Font {
        .geist(size: 17, weight: .semibold)
    }
    
    static var geistBody: Font {
        .geist(size: 17, weight: .regular)
    }
    
    static var geistCallout: Font {
        .geist(size: 16, weight: .regular)
    }
    
    static var geistSubheadline: Font {
        .geist(size: 15, weight: .regular)
    }
    
    static var geistFootnote: Font {
        .geist(size: 13, weight: .regular)
    }
    
    static var geistCaption: Font {
        .geist(size: 12, weight: .regular)
    }
    
    static var geistCaption2: Font {
        .geist(size: 11, weight: .regular)
    }
    
    // Monospaced variants
    static var geistMonoBody: Font {
        .geistMono(size: 17, weight: .regular)
    }
    
    static var geistMonoCallout: Font {
        .geistMono(size: 16, weight: .regular)
    }
    
    static var geistMonoFootnote: Font {
        .geistMono(size: 13, weight: .regular)
    }
    
    static var geistMonoCaption: Font {
        .geistMono(size: 12, weight: .regular)
    }
}