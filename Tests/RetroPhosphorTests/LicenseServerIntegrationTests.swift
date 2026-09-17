import Foundation
import XCTest

final class LicenseServerIntegrationTests: XCTestCase {

    private let serverURL =
        "https://lidwarp-license.xchan2180.workers.dev"

    private let testLicenseKey =
        "LIDWARP-TEST-001"

    private var testDeviceID: String!

    override func setUp() {
        super.setUp()

        testDeviceID =
            "github-actions-\(UUID().uuidString)"
    }

    // MARK: - Health

    func testLicenseServerHealth() async throws {

        let url = try XCTUnwrap(
            URL(string: serverURL + "/health")
        )

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response) =
            try await URLSession.shared.data(
                for: request
            )

        let httpResponse =
            try XCTUnwrap(
                response as? HTTPURLResponse
            )

        XCTAssertEqual(
            httpResponse.statusCode,
            200
        )

        let json =
            try XCTUnwrap(
                try JSONSerialization.jsonObject(
                    with: data
                ) as? [String: Any]
            )

        XCTAssertEqual(
            json["success"] as? Bool,
            true
        )
    }

    // MARK: - Activation

    func testLicenseActivation() async throws {

        let response =
            try await sendRequest(
                endpoint: "/activate",
                licenseKey: testLicenseKey,
                deviceID: testDeviceID
            )

        XCTAssertEqual(
            response.statusCode,
            200,
            "Activation should return HTTP 200"
        )

        XCTAssertEqual(
            response.json["success"] as? Bool,
            true
        )

        XCTAssertEqual(
            response.json["activated"] as? Bool,
            true
        )

        XCTAssertEqual(
            response.json["licenseKey"] as? String,
            testLicenseKey
        )
    }

    // MARK: - Validation

    func testActivatedLicenseValidation() async throws {

        let activation =
            try await sendRequest(
                endpoint: "/activate",
                licenseKey: testLicenseKey,
                deviceID: testDeviceID
            )

        XCTAssertEqual(
            activation.statusCode,
            200
        )

        let validation =
            try await sendRequest(
                endpoint: "/validate",
                licenseKey: testLicenseKey,
                deviceID: testDeviceID
            )

        XCTAssertEqual(
            validation.statusCode,
            200,
            "Validation should return HTTP 200"
        )

        XCTAssertEqual(
            validation.json["success"] as? Bool,
            true
        )

        XCTAssertEqual(
            validation.json["valid"] as? Bool,
            true
        )
    }

    // MARK: - Unactivated Device

    func testUnactivatedDeviceIsRejected() async throws {

        let unusedDeviceID =
            "github-actions-unused-\(UUID().uuidString)"

        let response =
            try await sendRequest(
                endpoint: "/validate",
                licenseKey: testLicenseKey,
                deviceID: unusedDeviceID
            )

        XCTAssertEqual(
            response.statusCode,
            401,
            "Unactivated device should return HTTP 401"
        )

        XCTAssertEqual(
            response.json["success"] as? Bool,
            false
        )

        XCTAssertEqual(
            response.json["valid"] as? Bool,
            false
        )
    }

    // MARK: - Invalid License

    func testInvalidLicenseIsRejected() async throws {

        let response =
            try await sendRequest(
                endpoint: "/validate",
                licenseKey: "LIDWARP-INVALID-DO-NOT-USE",
                deviceID: "github-actions-invalid-\(UUID().uuidString)"
            )

        XCTAssertEqual(
            response.statusCode,
            401,
            "Invalid license should return HTTP 401"
        )

        XCTAssertEqual(
            response.json["success"] as? Bool,
            false
        )

        XCTAssertEqual(
            response.json["valid"] as? Bool,
            false
        )
    }

    // MARK: - Deactivation

    func testLicenseDeactivation() async throws {

        let activation =
            try await sendRequest(
                endpoint: "/activate",
                licenseKey: testLicenseKey,
                deviceID: testDeviceID
            )

        XCTAssertEqual(
            activation.statusCode,
            200
        )

        let deactivation =
            try await sendRequest(
                endpoint: "/deactivate",
                licenseKey: testLicenseKey,
                deviceID: testDeviceID
            )

        XCTAssertEqual(
            deactivation.statusCode,
            200,
            "Deactivation should return HTTP 200"
        )

        XCTAssertEqual(
            deactivation.json["success"] as? Bool,
            true
        )

        XCTAssertEqual(
            deactivation.json["deactivated"] as? Bool,
            true
        )

        let validation =
            try await sendRequest(
                endpoint: "/validate",
                licenseKey: testLicenseKey,
                deviceID: testDeviceID
            )

        XCTAssertEqual(
            validation.statusCode,
            401,
            "Deactivated device should no longer validate"
        )

        XCTAssertEqual(
            validation.json["success"] as? Bool,
            false
        )

        XCTAssertEqual(
            validation.json["valid"] as? Bool,
            false
        )
    }

    // MARK: - Helpers

    private struct ServerResponse {
        let statusCode: Int
        let json: [String: Any]
    }

    private func sendRequest(
        endpoint: String,
        licenseKey: String,
        deviceID: String
    ) async throws -> ServerResponse {

        let url = try XCTUnwrap(
            URL(string: serverURL + endpoint)
        )

        var request =
            URLRequest(url: url)

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

        request.httpBody =
            try JSONSerialization.data(
                withJSONObject: body
            )

        let (data, response) =
            try await URLSession.shared.data(
                for: request
            )

        let httpResponse =
            try XCTUnwrap(
                response as? HTTPURLResponse
            )

        let json =
            try XCTUnwrap(
                try JSONSerialization.jsonObject(
                    with: data
                ) as? [String: Any]
            )

        return ServerResponse(
            statusCode: httpResponse.statusCode,
            json: json
        )
    }
}
