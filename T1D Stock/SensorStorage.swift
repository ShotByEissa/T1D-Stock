import Foundation
import Combine

class SensorStorage: ObservableObject {
    @Published var sensors: [Sensor] = []
    
    private let storageKey = "saved_sensors"
    
    init() {
        loadSensors()
    }
    
    var availableSensors: [Sensor] {
        sensors.filter { $0.status == .available }
    }
    
    var notifySensors: [Sensor] {
        sensors.filter { $0.status == .lost || $0.status == .broken }
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
    
    func markAsUsed(_ sensor: Sensor) {
        sensors.removeAll { $0.id == sensor.id }
        saveSensors()
    }
    
    func updateStatus(_ sensor: Sensor, to status: SensorStatus) {
        if let index = sensors.firstIndex(where: { $0.id == sensor.id }) {
            sensors[index].status = status
            saveSensors()
        }
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
