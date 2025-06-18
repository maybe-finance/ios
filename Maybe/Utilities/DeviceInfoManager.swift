import Foundation
import UIKit

class DeviceInfoManager {
    static let shared = DeviceInfoManager()
    
    private let deviceIdKey = "MaybeApp.DeviceID"
    
    private init() {}
    
    // Get or create a persistent device ID
    var deviceId: String {
        // Check if we have a stored device ID
        if let storedId = UserDefaults.standard.string(forKey: deviceIdKey) {
            return storedId
        }
        
        // Generate a new device ID
        let newId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        UserDefaults.standard.set(newId, forKey: deviceIdKey)
        return newId
    }
    
    // Get the current device info
    var currentDeviceInfo: DeviceInfo {
        DeviceInfo(
            device_id: deviceId,
            device_name: deviceName,
            device_type: "ios",
            os_version: osVersion,
            app_version: appVersion
        )
    }
    
    // Get a user-friendly device name
    private var deviceName: String {
        // First try to get the user-assigned device name
        let deviceName = UIDevice.current.name
        
        // If it's generic, create a more specific name
        if deviceName.lowercased().contains("iphone") || deviceName.lowercased().contains("ipad") {
            return deviceName
        } else {
            // Include the device model for clarity
            let model = UIDevice.current.model
            return "\(deviceName)'s \(model)"
        }
    }
    
    // Get the iOS version
    private var osVersion: String {
        UIDevice.current.systemVersion
    }
    
    // Get the app version from Info.plist
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}