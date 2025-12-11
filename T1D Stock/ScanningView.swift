import SwiftUI
import Combine

struct ScanningView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var storage: SensorStorage
    
    @State private var scannedCode: String = ""
    @State private var parsedData: ParsedGS1Data?
    @State private var tempSensors: [TempSensor] = []
    @State private var showSavedConfirmation = false
    @State private var showDuplicateWarning = false
    @State private var ignoreScanUntil: Date = Date()
    @State private var lastScanReceived: Date = Date()
    
    var body: some View {
        VStack(spacing: 0) {
            // Top bar with Done button
            HStack {
                Button("Done") {
                    saveSensors()
                    dismiss()
                }
                .font(.headline)
                .foregroundColor(.blue)
                .padding()
                
                Spacer()
                
                Text("Scanned: \(tempSensors.count)")
                    .font(.headline)
                    .padding()
            }
            .background(Color(.systemBackground))
            
            Divider()
            
            // Camera view
            ZStack {
                BarcodeScannerView(scannedCode: $scannedCode)
                    .onChange(of: scannedCode) { oldValue, newValue in
                        if !newValue.isEmpty {
                            lastScanReceived = Date()
                        }
                        
                        if Date() < ignoreScanUntil {
                            return
                        }
                        
                        if !newValue.isEmpty {
                            parsedData = GS1Parser.parse(newValue)
                        } else {
                            parsedData = nil
                        }
                    }
                    .onReceive(Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()) { _ in
                        checkScanTimeout()
                    }
                
                // Scan overlay
                VStack {
                    Spacer()
                    
                    if showDuplicateWarning {
                        VStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.orange)
                            Text("Already Scanned!")
                                .font(.headline)
                                .foregroundColor(.orange)
                        }
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(12)
                        .padding()
                    } else if showSavedConfirmation {
                        VStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.green)
                            Text("Sensor Added!")
                                .font(.headline)
                                .foregroundColor(.green)
                        }
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(12)
                        .padding()
                    } else if let data = parsedData {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Scanned Data")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            HStack {
                                Text("Serial:")
                                    .foregroundColor(.gray)
                                Text(data.serialNumber)
                                    .foregroundColor(.white)
                            }
                            .font(.subheadline)
                            
                            HStack {
                                Text("Expiry:")
                                    .foregroundColor(.gray)
                                Text(data.expiryDate.formatted(date: .abbreviated, time: .omitted))
                                    .foregroundColor(.white)
                            }
                            .font(.subheadline)
                            
                            Button(action: {
                                addSensor(data)
                            }) {
                                Text("ADD SENSOR")
                                    .font(.headline)
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .cornerRadius(8)
                            }
                        }
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(12)
                        .padding()
                    }
                }
            }
            .frame(maxHeight: .infinity)
            
            // List of scanned sensors
            if !tempSensors.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Scanned Sensors")
                        .font(.headline)
                        .padding()
                    
                    Divider()
                    
                    List {
                        ForEach(tempSensors) { sensor in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(sensor.serialNumber)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Text("Exp: \(sensor.expiryDate.formatted(date: .abbreviated, time: .omitted))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .frame(height: 200)
                }
                .background(Color(.systemBackground))
            }
        }
    }
    
    private func checkScanTimeout() {
        if Date() < ignoreScanUntil {
            return
        }
        
        if Date().timeIntervalSince(lastScanReceived) > 1.5 {
            if parsedData != nil {
                parsedData = nil
                scannedCode = ""
            }
        }
    }
    
    private func addSensor(_ data: ParsedGS1Data) {
        // Check if already in temp list or storage
        let isDuplicateInTemp = tempSensors.contains(where: { $0.serialNumber == data.serialNumber })
        let isDuplicateInStorage = storage.sensors.contains(where: { $0.serialNumber == data.serialNumber })
        
        parsedData = nil
        
        if isDuplicateInTemp || isDuplicateInStorage {
            showDuplicateWarning = true
            ignoreScanUntil = Date().addingTimeInterval(2.0)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showDuplicateWarning = false
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.1) {
                if !scannedCode.isEmpty && parsedData == nil {
                    parsedData = GS1Parser.parse(scannedCode)
                }
            }
        } else {
            tempSensors.append(TempSensor(
                serialNumber: data.serialNumber,
                expiryDate: data.expiryDate,
                productID: data.productID
            ))
            
            showSavedConfirmation = true
            ignoreScanUntil = Date().addingTimeInterval(2.0)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                showSavedConfirmation = false
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.1) {
                if !scannedCode.isEmpty && parsedData == nil {
                    parsedData = GS1Parser.parse(scannedCode)
                }
            }
        }
    }
    
    private func saveSensors() {
        for sensor in tempSensors {
            _ = storage.addSensor(
                productID: sensor.productID,
                serialNumber: sensor.serialNumber,
                expiryDate: sensor.expiryDate
            )
        }
    }
}

struct TempSensor: Identifiable {
    let id = UUID()
    let serialNumber: String
    let expiryDate: Date
    let productID: String
}
