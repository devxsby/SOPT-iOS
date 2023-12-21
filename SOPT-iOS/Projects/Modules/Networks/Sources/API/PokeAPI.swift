//
//  PokeAPI.swift
//  Networks
//
//  Created by sejin on 12/19/23.
//  Copyright © 2023 SOPT-iOS. All rights reserved.
//

import Foundation

import Alamofire
import Moya
import Core

public enum PokeAPI {
    case getWhoPokedToMe
    case getFriend
    case getFriendRandomUser
}

extension PokeAPI: BaseAPI {
    public static var apiType: APIType = .poke
    
    public var path: String {
        switch self {
        case .getWhoPokedToMe:
            return "/to/me"
        case .getFriend:
            return "/friend"
        case .getFriendRandomUser:
            return "/friend/random-user"
        }
    }
    
    public var method: Moya.Method {
        switch self {
        case .getWhoPokedToMe, .getFriend, .getFriendRandomUser:
            return .get
        }
    }
    
    public var task: Moya.Task {
        switch self {
        default:
            return .requestPlain
        }
    }
}
