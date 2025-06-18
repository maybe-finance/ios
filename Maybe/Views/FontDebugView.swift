import SwiftUI

struct FontDebugView: View {
    @State private var bundleContents: [String] = []
    @State private var fontURLs: [String] = []
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Font Debug Info")
                    .font(.largeTitle)
                    .padding(.bottom)
                
                // Check bundle contents
                VStack(alignment: .leading, spacing: 10) {
                    Text("Font files in bundle:")
                        .font(.headline)
                    
                    if fontURLs.isEmpty {
                        Text("No .otf files found in bundle!")
                            .foregroundColor(.red)
                    } else {
                        ForEach(fontURLs, id: \.self) { url in
                            Text(url)
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                
                // Check registered fonts
                VStack(alignment: .leading, spacing: 10) {
                    Text("Registered font families:")
                        .font(.headline)
                    
                    let geistFamilies = UIFont.familyNames.filter { $0.contains("Geist") }
                    
                    if geistFamilies.isEmpty {
                        Text("No Geist fonts registered!")
                            .foregroundColor(.red)
                    } else {
                        ForEach(geistFamilies.sorted(), id: \.self) { family in
                            VStack(alignment: .leading) {
                                Text(family)
                                    .font(.subheadline)
                                    .bold()
                                ForEach(UIFont.fontNames(forFamilyName: family).sorted(), id: \.self) { font in
                                    Text("  → \(font)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                
                // Manual font registration attempt
                VStack(alignment: .leading, spacing: 10) {
                    Text("Manual registration test:")
                        .font(.headline)
                    
                    Button("Try to Register Fonts Manually") {
                        registerFontsManually()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            .padding()
        }
        .onAppear {
            checkBundleContents()
        }
    }
    
    private func checkBundleContents() {
        if let resourcePath = Bundle.main.resourcePath {
            do {
                let items = try FileManager.default.contentsOfDirectory(atPath: resourcePath)
                bundleContents = items.sorted()
                fontURLs = items.filter { $0.hasSuffix(".otf") }.sorted()
            } catch {
                print("Error reading bundle contents: \(error)")
            }
        }
    }
    
    private func registerFontsManually() {
        let fontNames = [
            "Geist-Black", "Geist-Bold", "Geist-ExtraBold", "Geist-ExtraLight",
            "Geist-Light", "Geist-Medium", "Geist-Regular", "Geist-SemiBold", "Geist-Thin"
        ]
        
        for fontName in fontNames {
            if let fontURL = Bundle.main.url(forResource: fontName, withExtension: "otf") {
                var error: Unmanaged<CFError>?
                if CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error) {
                    print("Successfully registered \(fontName)")
                } else {
                    if let error = error?.takeRetainedValue() {
                        print("Failed to register \(fontName): \(error)")
                    } else {
                        print("Failed to register \(fontName): Unknown error")
                    }
                }
            } else {
                print("Font file not found: \(fontName).otf")
            }
        }
        
        // Refresh the view
        checkBundleContents()
    }
}

#Preview {
    FontDebugView()
}
