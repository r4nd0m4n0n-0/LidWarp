import XCTest

final class LicenseServerIntegrationTests: XCTestCase {

    private let serverURL =
        "https://lidwarp-license.xchan2180.workers.dev"

    private let testLicense =
        "LIDWARP-TEST-001"

    private func request(
        endpoint: String,
        licenseKey: String,
        deviceID: String
    ) async throws -> (
        statusCode: Int,
        json: [String: Any]
    ) {
        guard let url = URL(
            string: serverURL + endpoint
        ) else {
            throw NSError(
                domain: "LicenseTests",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Invalid server URL"
                ]
            )
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

        let body: [String: String] = [
            "licenseKey": licenseKey,
            "deviceId": deviceID
        ]

        request.httpBody = try JSONSerialization.data(
            withJSONObject: body
        )

        let (data, response) =
            try await URLSession.shared.data(
                for: request
            )

        guard let httpResponse =
            response as? HTTPURLResponse else {
            throw NSError(
                domain: "LicenseTests",
                code: 2,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Invalid HTTP response"
                ]
            )
        }

        let json =
            try JSONSerialization.jsonObject(
                with: data
            ) as? [String: Any] ?? [:]

        return (
            httpResponse.statusCode,
            json
        )
    }

    func testLicenseServerHealth() async throws {
        let url = URL(
            string: serverURL + "/health"
        )!

        let (data, response) =
            try await URLSession.shared.data(
                from: url
            )

        let httpResponse =
            response as! HTTPURLResponse

        XCTAssertEqual(
            httpResponse.statusCode,
            200
        )

        let json =
            try JSONSerialization.jsonObject(
                with: data
            ) as! [String: Any]

        XCTAssertEqual(
            json["success"] as? Bool,
            true
        )

        XCTAssertEqual(
            json["status"] as? String,
            "online"
        )

        XCTAssertEqual(
            json["database"] as? String,
            "connected"
        )
    }

    func testOneDeviceLimit() async throws {
        let device1 =
            "TEST-DEVICE-ONE-\(UUID().uuidString)"

        let device2 =
            "TEST-DEVICE-TWO-\(UUID().uuidString)"

        // Clean up in case a previous run
        // left an activation behind.
        _ = try? await request(
            endpoint: "/deactivate",
            licenseKey: testLicense,
            deviceID: device1
        )

        _ = try? await request(
            endpoint: "/deactivate",
            licenseKey: testLicense,
            deviceID: device2
        )

        // Device 1 must activate successfully.
        let first =
            try await request(
                endpoint: "/activate",
                licenseKey: testLicense,
                deviceID: device1
            )

        XCTAssertEqual(
            first.statusCode,
            200
        )

        XCTAssertEqual(
            first.json["success"] as? Bool,
            true
        )

        XCTAssertEqual(
            first.json["activated"] as? Bool,
            true
        )

        // The license must report one-device capacity.
        XCTAssertEqual(
            first.json["maxDevices"] as? Int,
            1
        )

        // Activating the same device again
        // must succeed as an existing device.
        let existing =
            try await request(
                endpoint: "/activate",
                licenseKey: testLicense,
                deviceID: device1
            )

        XCTAssertEqual(
            existing.statusCode,
            200
        )

        XCTAssertEqual(
            existing.json["success"] as? Bool,
            true
        )

        XCTAssertEqual(
            existing.json["existingDevice"] as? Bool,
            true
        )

        // Device 2 must be rejected.
        let second =
            try await request(
                endpoint: "/activate",
                licenseKey: testLicense,
                deviceID: device2
            )

        XCTAssertEqual(
            second.statusCode,
            409
        )

        XCTAssertEqual(
            second.json["success"] as? Bool,
            false
        )

        XCTAssertEqual(
            second.json["error"] as? String,
            "Device limit reached"
        )

        XCTAssertEqual(
            second.json["maxDevices"] as? Int,
            1
        )

        XCTAssertEqual(
            second.json["devicesUsed"] as? Int,
            1
        )

        // Device 1 must validate successfully.
        let validation =
            try await request(
                endpoint: "/validate",
                licenseKey: testLicense,
                deviceID: device1
            )

        XCTAssertEqual(
            validation.statusCode,
            200
        )

        XCTAssertEqual(
            validation.json["success"] as? Bool,
            true
        )

        XCTAssertEqual(
            validation.json["valid"] as? Bool,
            true
        )

        // Deactivate device 1.
        let deactivation =
            try await request(
                endpoint: "/deactivate",
                licenseKey: testLicense,
                deviceID: device1
            )

        XCTAssertEqual(
            deactivation.statusCode,
            200
        )

        XCTAssertEqual(
            deactivation.json["success"] as? Bool,
            true
        )

        XCTAssertEqual(
            deactivation.json["deactivated"] as? Bool,
            true
        )

        // Device 2 must now be able to activate.
        let replacement =
            try await request(
                endpoint: "/activate",
                licenseKey: testLicense,
                deviceID: device2
            )

        XCTAssertEqual(
            replacement.statusCode,
            200
        )

        XCTAssertEqual(
            replacement.json["success"] as? Bool,
            true
        )

        XCTAssertEqual(
            replacement.json["activated"] as? Bool,
            true
        )

        XCTAssertEqual(
            replacement.json["maxDevices"] as? Int,
            1
        )

        // Cleanup.
        _ = try? await request(
            endpoint: "/deactivate",
            licenseKey: testLicense,
            deviceID: device2
        )
    }

    func testInvalidLicenseIsRejected() async throws {
        let deviceID =
            "INVALID-LICENSE-DEVICE-\(UUID().uuidString)"

        let response =
            try await request(
                endpoint: "/activate",
                licenseKey: "LIDWARP-INVALID-999",
                deviceID: deviceID
            )

        XCTAssertEqual(
            response.statusCode,
            401
        )

        XCTAssertEqual(
            response.json["success"] as? Bool,
            false
        )

        XCTAssertEqual(
            response.json["error"] as? String,
            "Invalid license key"
        )
    }

    func testUnactivatedDeviceIsRejected() async throws {
        let deviceID =
            "UNACTIVATED-\(UUID().uuidString)"

        let response =
            try await request(
                endpoint: "/validate",
                licenseKey: testLicense,
                deviceID: deviceID
            )

        XCTAssertEqual(
            response.statusCode,
            401
        )

        XCTAssertEqual(
            response.json["success"] as? Bool,
            false
        )

        XCTAssertEqual(
            response.json["valid"] as? Bool,
            false
        )

        XCTAssertEqual(
            response.json["error"] as? String,
            "License is not activated on this device"
        )
    }

    func testLicenseDeactivation() async throws {
        let deviceID =
            "DEACTIVATE-\(UUID().uuidString)"

        _ = try? await request(
            endpoint: "/deactivate",
            licenseKey: testLicense,
            deviceID: deviceID
        )

        let activation =
            try await request(
                endpoint: "/activate",
                licenseKey: testLicense,
                deviceID: deviceID
            )

        XCTAssertEqual(
            activation.statusCode,
            200
        )

        let deactivation =
            try await request(
                endpoint: "/deactivate",
                licenseKey: testLicense,
                deviceID: deviceID
            )

        XCTAssertEqual(
            deactivation.statusCode,
            200
        )

        XCTAssertEqual(
            deactivation.json["success"] as? Bool,
            true
        )

        let validation =
            try await request(
                endpoint: "/validate",
                licenseKey: testLicense,
                deviceID: deviceID
            )

        XCTAssertEqual(
            validation.statusCode,
            401
        )

        XCTAssertEqual(
            validation.json["valid"] as? Bool,
            false
        )
    }
}
