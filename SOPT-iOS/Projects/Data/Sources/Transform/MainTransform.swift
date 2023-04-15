//
//  MainTransform.swift
//  MainFeature
//
//  Created by sejin on 2023/04/01.
//  Copyright © 2023 SOPT-iOS. All rights reserved.
//

import Foundation

import Domain
import Network

extension MainEntity {

    public func toDomain() -> MainModel? {
        guard let user = user, let operation = operation else { return nil }
        return MainModel.init(status: user.status, name: user.name, profileImage: user.profileImage, historyList: user.historyList, attendanceScore: operation.attendanceScore, announcement: operation.announcement)
    }
}
