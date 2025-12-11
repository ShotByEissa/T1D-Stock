import Foundation
import Combine

class SensorStorage: ObservableObject {
    @Published var sensors: [Sensor] = []
    
    private let storageKey = "saved_sensors"
    
    init() {
        loadSensors()
    }
    
    func addSensor(productID: String, serialNumber: String, expiryDate: Date) -> Bool {
        // Check if serial number already exists
        if sensors.contains(where: { $0.serialNumber == serialNumber }) {
            return false // Duplicate found
        }
        
        let sensor = Sensor(
            productType: "Dexcom G7",
            serialNumber: serialNumber,
            expiryDate: expiryDate
        )
        sensors.append(sensor)
        saveSensors()
        return true // Successfully added
    }
    
    private func saveSensors() {
        if let encoded = try? JSONEncoder().encode(sensors) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
    
    private func loadSensors() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([Sensor].self, from: data) {
            sensors = decoded
        }
    }
}
