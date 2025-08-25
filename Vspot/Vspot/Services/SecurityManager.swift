//
//  SecurityManager.swift
//  Vspot
//
//  Security and encryption management
//

import Foundation
import CryptoKit
import Security
import LocalAuthentication

class SecurityManager: ObservableObject {
    static let shared = SecurityManager()
    
    // MARK: - Properties
    
    private let keychain = KeychainWrapper.standard
    private let encryptionKeyIdentifier = "vspot.encryption.key"
    private let biometricAuthEnabledKey = "vspot.biometric.enabled"
    
    @Published var isBiometricAuthEnabled: Bool = false
    @Published var isEncryptionEnabled: Bool = true
    
    // MARK: - Initialization
    
    private init() {
        loadSecuritySettings()
    }
    
    // MARK: - Encryption Key Management
    
    private func getOrCreateEncryptionKey() throws -> SymmetricKey {
        if let existingKey = getExistingEncryptionKey() {
            return existingKey
        }
        
        // Generate new encryption key
        let key = SymmetricKey(size: .bits256)
        
        // Store in Keychain
        let keyData = key.withUnsafeBytes { Data($0) }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: encryptionKeyIdentifier,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status != errSecSuccess && status != errSecDuplicateItem {
            throw SecurityError.keychainError(status)
        }
        
        return key
    }
    
    private func getExistingEncryptionKey() -> SymmetricKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: encryptionKeyIdentifier,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let keyData = result as? Data else {
            return nil
        }
        
        return SymmetricKey(data: keyData)
    }
    
    // MARK: - Encryption/Decryption
    
    func encrypt(_ data: Data) throws -> Data {
        guard isEncryptionEnabled else { return data }
        
        let key = try getOrCreateEncryptionKey()
        let sealedBox = try AES.GCM.seal(data, using: key)
        
        guard let encryptedData = sealedBox.combined else {
            throw SecurityError.encryptionFailed
        }
        
        return encryptedData
    }
    
    func decrypt(_ data: Data) throws -> Data {
        guard isEncryptionEnabled else { return data }
        
        let key = try getOrCreateEncryptionKey()
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        
        return decryptedData
    }
    
    func encryptString(_ string: String) throws -> Data {
        guard let data = string.data(using: .utf8) else {
            throw SecurityError.invalidData
        }
        return try encrypt(data)
    }
    
    func decryptString(_ data: Data) throws -> String {
        let decryptedData = try decrypt(data)
        guard let string = String(data: decryptedData, encoding: .utf8) else {
            throw SecurityError.decryptionFailed
        }
        return string
    }
    
    // MARK: - Biometric Authentication
    
    func enableBiometricAuth() async throws {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw SecurityError.biometricNotAvailable(error?.localizedDescription)
        }
        
        // Test biometric authentication
        try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Enable biometric authentication for Vspot")
        
        isBiometricAuthEnabled = true
        UserDefaults.standard.set(true, forKey: biometricAuthEnabledKey)
    }
    
    func disableBiometricAuth() {
        isBiometricAuthEnabled = false
        UserDefaults.standard.set(false, forKey: biometricAuthEnabledKey)
    }
    
    func authenticateWithBiometrics() async throws -> Bool {
        guard isBiometricAuthEnabled else { return true }
        
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw SecurityError.biometricNotAvailable(error?.localizedDescription)
        }
        
        return try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Authenticate to access secure data")
    }
    
    // MARK: - Secure Data Storage
    
    func storeSecureData(_ data: Data, forKey key: String) throws {
        let encryptedData = try encrypt(data)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: encryptedData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecDuplicateItem {
            // Update existing item
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: key
            ]
            
            let updateAttributes: [String: Any] = [
                kSecValueData as String: encryptedData
            ]
            
            let updateStatus = SecItemUpdate(updateQuery as CFDictionary, updateAttributes as CFDictionary)
            
            if updateStatus != errSecSuccess {
                throw SecurityError.keychainError(updateStatus)
            }
        } else if status != errSecSuccess {
            throw SecurityError.keychainError(status)
        }
    }
    
    func retrieveSecureData(forKey key: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let encryptedData = result as? Data else {
            throw SecurityError.keychainError(status)
        }
        
        return try decrypt(encryptedData)
    }
    
    func deleteSecureData(forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status != errSecSuccess && status != errSecItemNotFound {
            throw SecurityError.keychainError(status)
        }
    }
    
    // MARK: - Secure Deletion
    
    func secureDelete(_ data: inout Data) {
        // Overwrite with random data multiple times
        for _ in 0..<3 {
            data = Data((0..<data.count).map { _ in UInt8.random(in: 0...255) })
        }
        
        // Clear the data
        data.removeAll()
    }
    
    func secureDeleteString(_ string: inout String) {
        // Overwrite with random characters
        for _ in 0..<3 {
            string = String((0..<string.count).map { _ in Character(UnicodeScalar(UInt8.random(in: 32...126))) })
        }
        
        // Clear the string
        string.removeAll()
    }
    
    // MARK: - Security Settings
    
    private func loadSecuritySettings() {
        isBiometricAuthEnabled = UserDefaults.standard.bool(forKey: biometricAuthEnabledKey)
    }
    
    func updateSecuritySettings(encryptionEnabled: Bool, biometricEnabled: Bool) {
        isEncryptionEnabled = encryptionEnabled
        
        if biometricEnabled && !isBiometricAuthEnabled {
            Task {
                do {
                    try await enableBiometricAuth()
                } catch {
                    print("Failed to enable biometric auth: \(error)")
                }
            }
        } else if !biometricEnabled && isBiometricAuthEnabled {
            disableBiometricAuth()
        }
    }
    
    // MARK: - Security Validation
    
    func validateSecurityIntegrity() -> Bool {
        // Check if encryption key exists
        guard getExistingEncryptionKey() != nil else {
            return false
        }
        
        // Check if biometric auth is properly configured
        if isBiometricAuthEnabled {
            let context = LAContext()
            var error: NSError?
            
            guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
                return false
            }
        }
        
        return true
    }
    
    // MARK: - Security Audit
    
    func generateSecurityAudit() -> SecurityAudit {
        let hasEncryptionKey = getExistingEncryptionKey() != nil
        let biometricAvailable = LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        
        return SecurityAudit(
            encryptionEnabled: isEncryptionEnabled,
            encryptionKeyExists: hasEncryptionKey,
            biometricEnabled: isBiometricAuthEnabled,
            biometricAvailable: biometricAvailable,
            lastAuditDate: Date()
        )
    }
}

// MARK: - Supporting Types

struct SecurityAudit {
    let encryptionEnabled: Bool
    let encryptionKeyExists: Bool
    let biometricEnabled: Bool
    let biometricAvailable: Bool
    let lastAuditDate: Date
    
    var isSecure: Bool {
        return encryptionEnabled && encryptionKeyExists
    }
    
    var recommendations: [String] {
        var recommendations: [String] = []
        
        if !encryptionEnabled {
            recommendations.append("Enable encryption for sensitive data")
        }
        
        if !encryptionKeyExists {
            recommendations.append("Generate encryption key")
        }
        
        if biometricAvailable && !biometricEnabled {
            recommendations.append("Consider enabling biometric authentication")
        }
        
        return recommendations
    }
}

enum SecurityError: Error, LocalizedError {
    case encryptionFailed
    case decryptionFailed
    case invalidData
    case keychainError(OSStatus)
    case biometricNotAvailable(String?)
    case authenticationFailed
    
    var errorDescription: String? {
        switch self {
        case .encryptionFailed:
            return "Failed to encrypt data"
        case .decryptionFailed:
            return "Failed to decrypt data"
        case .invalidData:
            return "Invalid data format"
        case .keychainError(let status):
            return "Keychain error: \(status)"
        case .biometricNotAvailable(let message):
            return "Biometric authentication not available: \(message ?? "Unknown error")"
        case .authenticationFailed:
            return "Authentication failed"
        }
    }
}

// MARK: - KeychainWrapper Extension

extension KeychainWrapper {
    static let standard = KeychainWrapper(serviceName: "com.vspot.app")
}
