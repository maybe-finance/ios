import SwiftUI

struct FontTestView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Font Weight Test")
                    .font(.largeTitle)
                    .padding(.bottom)
                
                // Check if any custom font works at all
                HStack {
                    Text("Default:")
                        .font(.caption)
                    Text("Test Text")
                    Text("Custom:")
                        .font(.caption)
                    Text("Test Text")
                        .font(.custom("Geist-Regular", size: 17))
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                
                Group {
                    Text("System Font - UltraLight")
                        .font(.system(size: 24, weight: .ultraLight))
                    
                    Text("System Font - Light")
                        .font(.system(size: 24, weight: .light))
                    
                    Text("System Font - Regular")
                        .font(.system(size: 24, weight: .regular))
                    
                    Text("System Font - Medium")
                        .font(.system(size: 24, weight: .medium))
                    
                    Text("System Font - Semibold")
                        .font(.system(size: 24, weight: .semibold))
                    
                    Text("System Font - Bold")
                        .font(.system(size: 24, weight: .bold))
                    
                    Text("System Font - Heavy")
                        .font(.system(size: 24, weight: .heavy))
                    
                    Text("System Font - Black")
                        .font(.system(size: 24, weight: .black))
                }
                
                Divider()
                    .padding(.vertical)
                
                Group {
                    Text("Geist - UltraLight")
                        .font(.geist(size: 24, weight: .ultraLight))
                    
                    Text("Geist - Light")
                        .font(.geist(size: 24, weight: .light))
                    
                    Text("Geist - Regular")
                        .font(.geist(size: 24, weight: .regular))
                    
                    Text("Geist - Medium")
                        .font(.geist(size: 24, weight: .medium))
                    
                    Text("Geist - Semibold")
                        .font(.geist(size: 24, weight: .semibold))
                    
                    Text("Geist - Bold")
                        .font(.geist(size: 24, weight: .bold))
                    
                    Text("Geist - Heavy")
                        .font(.geist(size: 24, weight: .heavy))
                    
                    Text("Geist - Black")
                        .font(.geist(size: 24, weight: .black))
                }
                
                Divider()
                    .padding(.vertical)
                
                // Test with explicit font names
                Group {
                    Text("Geist-ExtraLight (direct)")
                        .font(.custom("Geist-ExtraLight", size: 24))
                    
                    Text("Geist-Light (direct)")
                        .font(.custom("Geist-Light", size: 24))
                    
                    Text("Geist-Regular (direct)")
                        .font(.custom("Geist-Regular", size: 24))
                    
                    Text("Geist-Medium (direct)")
                        .font(.custom("Geist-Medium", size: 24))
                    
                    Text("Geist-SemiBold (direct)")
                        .font(.custom("Geist-SemiBold", size: 24))
                    
                    Text("Geist-Bold (direct)")
                        .font(.custom("Geist-Bold", size: 24))
                    
                    Text("Geist-ExtraBold (direct)")
                        .font(.custom("Geist-ExtraBold", size: 24))
                    
                    Text("Geist-Black (direct)")
                        .font(.custom("Geist-Black", size: 24))
                }
                
                Divider()
                    .padding(.vertical)
                
                // Test alternative naming conventions
                Group {
                    Text("Geist ExtraLight (space)")
                        .font(.custom("Geist ExtraLight", size: 24))
                    
                    Text("Geist Light (space)")
                        .font(.custom("Geist Light", size: 24))
                    
                    Text("Geist Regular (space)")
                        .font(.custom("Geist Regular", size: 24))
                    
                    Text("Geist Medium (space)")
                        .font(.custom("Geist Medium", size: 24))
                    
                    Text("Geist SemiBold (space)")
                        .font(.custom("Geist SemiBold", size: 24))
                    
                    Text("Geist Bold (space)")
                        .font(.custom("Geist Bold", size: 24))
                    
                    Text("Geist Black (space)")
                        .font(.custom("Geist Black", size: 24))
                }
                
                Divider()
                    .padding(.vertical)
                
                // List all available fonts
                Text("Available Fonts:")
                    .font(.headline)
                    .padding(.top)
                
                // Show ALL font families to debug
                Text("All Font Families:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ForEach(UIFont.familyNames.sorted(), id: \.self) { family in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(family)
                            .font(.caption2)
                            .bold()
                        ForEach(UIFont.fontNames(forFamilyName: family).sorted(), id: \.self) { font in
                            Text("  → \(font)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding()
        }
    }
}

#Preview {
    FontTestView()
}