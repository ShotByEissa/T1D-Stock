//
//  Sensor.swift
//  T1D Stock
//
//  Created by Eissa Ahmad on 2025-12-11.
//

import Foundation

struct Sensor: Identifiable, Codable {
    let id: UUID
    let productType: String
    let serialNumber: String
    let expiryDate: Date
    var status: SensorStatus
    let dateAdded: Date
    
    init(productType: String, serialNumber: String, expiryDate: Date) {
        self.id = UUID()
        self.productType = productType
        self.serialNumber = serialNumber
        self.expiryDate = expiryDate
        self.status = .available
        self.dateAdded = Date()
    }
}

enum SensorStatus: String, Codable, CaseIterable {
    case available = "Available"
    case lost = "Lost/Stolen"
    case broken = "Broken/Defective"
}
