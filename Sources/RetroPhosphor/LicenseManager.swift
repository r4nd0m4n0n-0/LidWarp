import Foundation
import Security

@MainActor
final class LicenseManager: ObservableObject {

    // MARK: - Published State

    @Published private(set) var isLicensed = false
    @Published private(set) var isChecking = false
    @Published private(set) var statusMessage = "License required"
    @Published private(set) var licenseKey = ""

    // MARK: - Configuration

    private let serverURL =
        "https://lidwarp-license.xchan2180.workers.dev"

    private let licenseKeyService =
        "com.lidwarp.license-key"

    private let deviceIDService =
        "com.lidwarp.device-id"

    private let licenseKeyAccount =
        "license-key"

    private let deviceIDAccount =
        "device-id"

    // MARK: - Initialization

    init() {
        licenseKey = loadLicenseKey() ?? ""
    }

    // MARK: - Public API

    /// Attempts to activate the entered license on this device.
    func activate(key: String) async {
        let normalizedKey = key
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()

        guard !normalizedKey.isEmpty else {
            isLicensed = false
            statusMessage = "Enter a license key"
            return
        }

        isChecking = true
        statusMessage = "Activating license..."

        defer {
            isChecking = false
        }

        let deviceID = getOrCreateDeviceID()

        do {
            let response = try await sendRequest(
                endpoint: "/activate",
                licenseKey: normalizedKey,
                deviceID: deviceID
            )

            if response.success {
                saveLicenseKey(normalizedKey)

                licenseKey = normalizedKey
                isLicensed = true
                statusMessage = "License activated"
            } else {
                isLicensed = false
                statusMessage = response.error ??
                    "License activation failed"
            }

        } catch {
            isLicensed = false
            statusMessage = userFriendlyError(error)
        }
    }

    /// Validates the currently stored license against this device.
    func validate() async {
        guard !licenseKey.isEmpty else {
            isLicensed = false
            statusMessage = "License required"
            return
        }

        isChecking = true
        statusMessage = "Checking license..."

        defer {
            isChecking = false
        }

        let deviceID = getOrCreateDeviceID()

        do {
            let response = try await sendRequest(
                endpoint: "/validate",
                licenseKey: licenseKey,
                deviceID: deviceID
            )

            if response.success && response.valid == true {
                isLicensed = true
                statusMessage = "License valid"
            } else {
                isLicensed = false
                statusMessage = response.error ??
                    "License is not valid"
            }

        } catch {
            isLicensed = false
            statusMessage = userFriendlyError(error)
        }
    }

    /// Deactivates this device from the current license.
    func deactivate() async {
        guard !licenseKey.isEmpty else {
            isLicensed = false
            statusMessage = "No license to deactivate"
            return
        }

        isChecking = true
        statusMessage = "Deactivating license..."

        defer {
            isChecking = false
        }

        let deviceID = getOrCreateDeviceID()

        do {
            let response = try await sendRequest(
                endpoint: "/deactivate",
                licenseKey: licenseKey,
                deviceID: deviceID
            )

            if response.success {
                deleteLicenseKey()

                licenseKey = ""
                isLicensed = false
                statusMessage = "License deactivated"
            } else {
                statusMessage = response.error ??
                    "Could not deactivate license"
            }

        } catch {
            statusMessage = userFriendlyError(error)
        }
    }

    /// Clears the locally stored license without contacting the server.
    func clearLocalLicense() {
        deleteLicenseKey()

        licenseKey = ""
        isLicensed = false
        statusMessage = "License required"
    }

    // MARK: - Device ID

    /// Returns the existing device ID or creates a new random UUID.
    ///
    /// The device ID is intentionally not based on hardware serial numbers.
    /// This avoids collecting unnecessary hardware information.
    private func getOrCreateDeviceID() -> String {
        if let existingID = loadDeviceID(),
           !existingID.isEmpty {
            return existingID
        }

        let newID = UUID().uuidString

        saveDeviceID(newID)

        return newID
    }

    // MARK: - Network

    private struct LicenseRequest: Encodable {
        let licenseKey: String
        let deviceId: String
    }

    private struct LicenseResponse: Decodable {
        let success: Bool
        let activated: Bool?
        let existingDevice: Bool?
        let valid: Bool?
        let deactivated: Bool?
        let licenseKey: String?
        let maxDevices: Int?
        let devicesUsed: Int?
        let message: String?
        let error: String?
    }

    private func sendRequest(
        endpoint: String,
        licenseKey: String,
        deviceID: String
    ) async throws -> LicenseResponse {

        guard let url = URL(
            string: serverURL + endpoint
        ) else {
            throw LicenseError.invalidServerURL
        }

        var request = URLRequest(url: url)

        request.httpMethod = "POST"

        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )

        request.setValue(
            "application/json",
            forHTTPHeaderField: "Accept"
        )

        let body = LicenseRequest(
            licenseKey: licenseKey,
            deviceId: deviceID
        )

        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(
            for: request
        )

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LicenseError.invalidResponse
        }

        let decoder = JSONDecoder()

        let decodedResponse: LicenseResponse

        do {
            decodedResponse = try decoder.decode(
                LicenseResponse.self,
                from: data
            )
        } catch {
            throw LicenseError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            return decodedResponse

        case 400:
            throw LicenseError.serverError(
                decodedResponse.error ??
                "Invalid license request"
            )

        case 401:
            throw LicenseError.serverError(
                decodedResponse.error ??
                "Invalid license"
            )

        case 403:
            throw LicenseError.serverError(
                decodedResponse.error ??
                "License is not active"
            )

        case 409:
            throw LicenseError.serverError(
                decodedResponse.error ??
                "Device limit reached"
            )

        default:
            throw LicenseError.serverError(
                decodedResponse.error ??
                "License server error"
            )
        }
    }

    // MARK: - Keychain

    private func saveLicenseKey(_ key: String) {
        saveKeychainValue(
            key,
            service: licenseKeyService,
            account: licenseKeyAccount
        )
    }

    private func loadLicenseKey() -> String? {
        loadKeychainValue(
            service: licenseKeyService,
            account: licenseKeyAccount
        )
    }

    private func deleteLicenseKey() {
        deleteKeychainValue(
            service: licenseKeyService,
            account: licenseKeyAccount
        )
    }

    private func saveDeviceID(_ id: String) {
        saveKeychainValue(
            id,
            service: deviceIDService,
            account: deviceIDAccount
        )
    }

    private func loadDeviceID() -> String? {
        loadKeychainValue(
            service: deviceIDService,
            account: deviceIDAccount
        )
    }

    private func saveKeychainValue(
        _ value: String,
        service: String,
        account: String
    ) {
        guard let data = value.data(using: .utf8) else {
            return
        }

        let query: [String: Any] = [
            kSecClass as String:
                kSecClassGenericPassword,

            kSecAttrService as String:
                service,

            kSecAttrAccount as String:
                account
        ]

        let attributes: [String: Any] = [
            kSecValueData as String:
                data
        ]

        let updateStatus = SecItemUpdate(
            query as CFDictionary,
            attributes as CFDictionary
        )

        if updateStatus == errSecItemNotFound {
            var item = query

            item[kSecValueData as String] = data

            SecItemAdd(
                item as CFDictionary,
                nil
            )
        }
    }

    private func loadKeychainValue(
        service: String,
        account: String
    ) -> String? {

        let query: [String: Any] = [
            kSecClass as String:
                kSecClassGenericPassword,

            kSecAttrService as String:
                service,

            kSecAttrAccount as String:
                account,

            kSecReturnData as String:
                true,

            kSecMatchLimit as String:
                kSecMatchLimitOne
        ]

        var result: AnyObject?

        let status = SecItemCopyMatching(
            query as CFDictionary,
            &result
        )

        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(
                  data: data,
                  encoding: .utf8
              ) else {
            return nil
        }

        return value
    }

    private func deleteKeychainValue(
        service: String,
        account: String
    ) {
        let query: [String: Any] = [
            kSecClass as String:
                kSecClassGenericPassword,

            kSecAttrService as String:
                service,

            kSecAttrAccount as String:
                account
        ]

        SecItemDelete(
            query as CFDictionary
        )
    }

    // MARK: - Errors

    private enum LicenseError: LocalizedError {
        case invalidServerURL
        case invalidResponse
        case serverError(String)

        var errorDescription: String? {
            switch self {
            case .invalidServerURL:
                return "Invalid license server URL"

            case .invalidResponse:
                return "Invalid response from license server"

            case .serverError(let message):
                return message
            }
        }
    }

    private func userFriendlyError(
        _ error: Error
    ) -> String {

        if let licenseError = error as? LicenseError {
            return licenseError.localizedDescription
        }

        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                return "No internet connection"

            case .timedOut:
                return "License server timed out"

            case .cannotFindHost,
                 .cannotConnectToHost:
                return "Could not reach license server"

            default:
                return "Network error"
            }
        }

        return "License check failed"
    }
}
