//
//  V4APIClient.swift
//  Twinte
//
//  Created by Arata on 2025/04/05.
//  Copyright © 2025 Arata. All rights reserved.
//

internal import Connect
import Foundation

public final class V4APIClient {
    public static let shared = V4APIClient()

    private let client: ProtocolClient

    public private(set) lazy var timetableClient = Timetable_V1_TimetableServiceClient(client: client)
    public private(set) lazy var schoolcalendarClient = Schoolcalendar_V1_SchoolCalendarServiceClient(client: client)
    public private(set) lazy var unifiedClient = Unified_V1_UnifiedServiceClient(client: client)

    private init() {
        self.client = ProtocolClient(
            httpClient: URLSessionHTTPClient(),
            config: ProtocolClientConfig(
                host: "https://app.twinte.net/api/v4",
                networkProtocol: .connect,
                codec: ProtoCodec(),
                interceptors: [.init { AuthInterceptor(config: $0) }],
            ),
        )
    }
}

private final class AuthInterceptor: UnaryInterceptor {
    init(config: ProtocolClientConfig) {}

    @Sendable
    func handleUnaryRequest<Message>(
        _ request: HTTPRequest<Message>,
        proceed: @escaping @Sendable (Result<HTTPRequest<Message>, ConnectError>) -> Void
    ) {
        guard request.url.host == "app.twinte.net" else {
            proceed(.success(request))
            return
        }

        if let userDefaults = UserDefaults(suiteName: "group.net.twinte.app"),
           let stringCookie = userDefaults.string(forKey: "stringCookie") {
            var headers = request.headers
            headers["Cookie"] = [stringCookie]
            proceed(.success(HTTPRequest(
                url: request.url,
                headers: headers,
                message: request.message,
                method: request.method,
                trailers: request.trailers,
                idempotencyLevel: request.idempotencyLevel,
            )))
        } else {
            proceed(.failure(ConnectError(
                code: .unauthenticated,
                message: "Cookie not found",
                exception: nil,
                details: [],
                metadata: [:],
            )))
        }
    }
}
