//
//  LBCollection.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 04.10.26.
//

import Foundation
import SwiftData

@Model
public final class LBCollection {
    @Attribute(.unique) public var id: String
    public var userId: String?
    public var name: String
    public var colorHex: String
    public var iconName: String
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: String = UUID().uuidString,
        userId: String? = nil,
        name: String,
        colorHex: String = "#F59E0B",
        iconName: String = "folder.fill",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.colorHex = colorHex
        self.iconName = iconName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
