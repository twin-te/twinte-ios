// Code generated by protoc-gen-connect-swift. DO NOT EDIT.
//
// Source: schoolcalendar/v1/service.proto
//

import Connect
import Foundation
import SwiftProtobuf

/// The following error codes are not stated explicitly in the each rpc, but may be returned.
///   - shared.InvalidArgument
///   - shared.Unauthenticated
///   - shared.Unauthorized
public protocol Schoolcalendar_V1_SchoolCalendarServiceClientInterface: Sendable {
    @discardableResult
    func listEventsByDate(request: Schoolcalendar_V1_ListEventsByDateRequest, headers: Connect.Headers, completion: @escaping @Sendable (ResponseMessage<Schoolcalendar_V1_ListEventsByDateResponse>) -> Void) -> Connect.Cancelable

    @available(iOS 13, *)
    func listEventsByDate(request: Schoolcalendar_V1_ListEventsByDateRequest, headers: Connect.Headers) async -> ResponseMessage<Schoolcalendar_V1_ListEventsByDateResponse>

    @discardableResult
    func getModuleByDate(request: Schoolcalendar_V1_GetModuleByDateRequest, headers: Connect.Headers, completion: @escaping @Sendable (ResponseMessage<Schoolcalendar_V1_GetModuleByDateResponse>) -> Void) -> Connect.Cancelable

    @available(iOS 13, *)
    func getModuleByDate(request: Schoolcalendar_V1_GetModuleByDateRequest, headers: Connect.Headers) async -> ResponseMessage<Schoolcalendar_V1_GetModuleByDateResponse>
}

/// Concrete implementation of `Schoolcalendar_V1_SchoolCalendarServiceClientInterface`.
public final class Schoolcalendar_V1_SchoolCalendarServiceClient: Schoolcalendar_V1_SchoolCalendarServiceClientInterface, Sendable {
    private let client: Connect.ProtocolClientInterface

    public init(client: Connect.ProtocolClientInterface) {
        self.client = client
    }

    @discardableResult
    public func listEventsByDate(request: Schoolcalendar_V1_ListEventsByDateRequest, headers: Connect.Headers = [:], completion: @escaping @Sendable (ResponseMessage<Schoolcalendar_V1_ListEventsByDateResponse>) -> Void) -> Connect.Cancelable {
        return self.client.unary(path: "/schoolcalendar.v1.SchoolCalendarService/ListEventsByDate", idempotencyLevel: .noSideEffects, request: request, headers: headers, completion: completion)
    }

    @available(iOS 13, *)
    public func listEventsByDate(request: Schoolcalendar_V1_ListEventsByDateRequest, headers: Connect.Headers = [:]) async -> ResponseMessage<Schoolcalendar_V1_ListEventsByDateResponse> {
        return await self.client.unary(path: "/schoolcalendar.v1.SchoolCalendarService/ListEventsByDate", idempotencyLevel: .noSideEffects, request: request, headers: headers)
    }

    @discardableResult
    public func getModuleByDate(request: Schoolcalendar_V1_GetModuleByDateRequest, headers: Connect.Headers = [:], completion: @escaping @Sendable (ResponseMessage<Schoolcalendar_V1_GetModuleByDateResponse>) -> Void) -> Connect.Cancelable {
        return self.client.unary(path: "/schoolcalendar.v1.SchoolCalendarService/GetModuleByDate", idempotencyLevel: .noSideEffects, request: request, headers: headers, completion: completion)
    }

    @available(iOS 13, *)
    public func getModuleByDate(request: Schoolcalendar_V1_GetModuleByDateRequest, headers: Connect.Headers = [:]) async -> ResponseMessage<Schoolcalendar_V1_GetModuleByDateResponse> {
        return await self.client.unary(path: "/schoolcalendar.v1.SchoolCalendarService/GetModuleByDate", idempotencyLevel: .noSideEffects, request: request, headers: headers)
    }

    public enum Metadata {
        public enum Methods {
            public static let listEventsByDate = Connect.MethodSpec(name: "ListEventsByDate", service: "schoolcalendar.v1.SchoolCalendarService", type: .unary)
            public static let getModuleByDate = Connect.MethodSpec(name: "GetModuleByDate", service: "schoolcalendar.v1.SchoolCalendarService", type: .unary)
        }
    }
}
