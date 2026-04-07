//
//  WatchOSSessionManager.swift
//  Twinte
//
//  Created by Takayuki Ueno on 2025/05/22.
//  Copyright © 2025 tako. All rights reserved.
//

import WatchConnectivity

struct WatchAppDto: Codable {
    let description: String
    let today: String
    let module: String
    // [月, 火, 水, 木, 金, 土]
    let timetable: [[Lecture]]
    
    let specials: [Lecture]
}

struct Lecture: Codable {
    let name: String
    let room: String
    let methods: [Int]
    let period: Int32
}

class WatchOSSessionManager: NSObject, WCSessionDelegate, ObservableObject {
    static let shared = WatchOSSessionManager()
    
    @Published var activationState: WCSessionActivationState = .notActivated
    @Published var isReachable: Bool = false
    @Published var receivedData: [String: Any] = [:]
    
    private var session: WCSession?
    
    private override init() {
        super.init()
        
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
            
            print("watchOS: WCSession activated")
        } else {
            print("watchOS: WCSession not supported")
        }
    }
    
    func session(_ session: WCSession,
                         activationDidCompleteWith activationState: WCSessionActivationState,
                         error: (any Error)?) {
        
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
            print("watchOS: Reachability is now \(session.isReachable)")
        }
    }
    
    func requestDataFromApp() {
        guard let validSession = session, validSession.activationState == .activated && validSession.isReachable else {
            print("WCSession not active or not reachable")
            return
        }
        
        let message = ["request": "fetchTimetable"]
        
        validSession.sendMessage(message, replyHandler: {replyMessage in
            print("reply: \(replyMessage)")
            do {            let decoder = JSONDecoder()
                if let encoded = replyMessage["data"] as? Data {
                    let data = try decoder.decode(WatchAppDto.self, from: encoded)
                    print("decoded: \(data)")
                }
                
                DispatchQueue.main.async {
                    self.receivedData = replyMessage
                }
            } catch {
                print("Decode error!")
            }
        })
    }
}
