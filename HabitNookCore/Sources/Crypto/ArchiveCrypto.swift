import CryptoKit
import Foundation
import Security

// MARK: - ArchiveCrypto

/// Provides AES-GCM encryption and decryption for `.habitarchive` exports (§8.23).
///
/// When the user enables encryption in Export settings, the archive payload is
/// encrypted with a key derived via HKDF from a Secure Enclave P-256 key. The
/// Secure Enclave key never leaves the device; the encrypted archive can only
/// be decrypted on the same device.
public enum ArchiveCrypto {

    // MARK: - Key management

    /// The label used to retrieve the Secure Enclave key from the Keychain.
    private static let seKeyLabel = "com.habitkit.archive.sekey"

    /// Returns (or generates) the Secure Enclave P-256 signing key for archive encryption.
    ///
    /// - Returns: A `SecureEnclave.P256.KeyAgreement.PrivateKey` stored in the Keychain.
    /// - Throws: Keychain or Secure Enclave errors.
    public static func archiveKey() throws -> SecureEnclave.P256.KeyAgreement.PrivateKey {
        // Attempt to load existing key.
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationLabel as String: seKeyLabel,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecReturnRef as String: true,
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        if status == errSecSuccess, let keyRef = item {
            let secKey = keyRef as! SecKey
            if let data = SecKeyCopyExternalRepresentation(secKey, nil) as Data? {
                if let key = try? SecureEnclave.P256.KeyAgreement.PrivateKey(
                    dataRepresentation: data
                ) {
                    return key
                }
            }
        }

        // Generate a new Secure Enclave key.
        let newKey = try SecureEnclave.P256.KeyAgreement.PrivateKey(
            compactRepresentable: false
        )
        let keyData = newKey.dataRepresentation
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationLabel as String: seKeyLabel,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]
        SecItemAdd(addQuery as CFDictionary, nil)
        return newKey
    }

    // MARK: - Encryption

    /// Encrypts archive data using AES-GCM with a key derived from the Secure Enclave.
    ///
    /// - Parameter plaintext: The raw archive payload data to encrypt.
    /// - Returns: `EncryptedArchive` containing the sealed box and public key data.
    /// - Throws: `ArchiveCryptoError` or CryptoKit errors.
    public static func encrypt(_ plaintext: Data) throws -> EncryptedArchive {
        let privateKey = try archiveKey()
        let publicKey = privateKey.publicKey

        // Derive a symmetric key via HKDF.
        let sharedSecret = try privateKey.sharedSecretFromKeyAgreement(
            with: publicKey
        )
        let symmetricKey = sharedSecret.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: "habitkit.archive.v1".data(using: .utf8) ?? Data(),
            sharedInfo: Data(),
            outputByteCount: 32
        )

        let sealedBox = try AES.GCM.seal(plaintext, using: symmetricKey)
        guard let combined = sealedBox.combined else {
            throw ArchiveCryptoError.sealFailed
        }

        return EncryptedArchive(
            encryptedData: combined,
            publicKeyData: publicKey.compressedRepresentation
        )
    }

    // MARK: - Decryption

    /// Decrypts an `EncryptedArchive` using the Secure Enclave key.
    ///
    /// - Parameter archive: The previously encrypted archive.
    /// - Returns: The decrypted plaintext data.
    /// - Throws: `ArchiveCryptoError` or CryptoKit errors.
    public static func decrypt(_ archive: EncryptedArchive) throws -> Data {
        let privateKey = try archiveKey()
        let publicKey = privateKey.publicKey

        let sharedSecret = try privateKey.sharedSecretFromKeyAgreement(
            with: publicKey
        )
        let symmetricKey = sharedSecret.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: "habitkit.archive.v1".data(using: .utf8) ?? Data(),
            sharedInfo: Data(),
            outputByteCount: 32
        )

        let sealedBox = try AES.GCM.SealedBox(combined: archive.encryptedData)
        return try AES.GCM.open(sealedBox, using: symmetricKey)
    }
}

// MARK: - EncryptedArchive

/// The output of `ArchiveCrypto.encrypt(_:)`.
public struct EncryptedArchive: Sendable {
    /// The AES-GCM sealed box (nonce + ciphertext + tag).
    public var encryptedData: Data
    /// Compressed representation of the Secure Enclave public key.
    public var publicKeyData: Data

    public init(encryptedData: Data, publicKeyData: Data) {
        self.encryptedData = encryptedData
        self.publicKeyData = publicKeyData
    }
}

// MARK: - ArchiveCryptoError

/// Errors thrown by `ArchiveCrypto`.
public enum ArchiveCryptoError: Error, Sendable {
    case sealFailed
    case keyNotFound
    case decryptionFailed
}
