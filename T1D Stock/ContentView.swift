import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var storage = SensorStorage()
    @State private var scannedCode: String = ""
    @State private var parsedData: ParsedGS1Data?
    @State private var showSavedConfirmation = false
    @State private var showDuplicateWarning = false
    @State private var ignoreScanUntil: Date = Date()
    @State private var lastScanReceived: Date = Date()
    
    var body: some View {
        VStack(spacing: 0) {
            // Top half - Camera
            ZStack {
                BarcodeScannerView(scannedCode: $scannedCode)
                    .onChange(of: scannedCode) { oldValue, newValue in
                        // Always update last scan time when scanner detects something
                        if !newValue.isEmpty {
                            lastScanReceived = Date()
                        }
                        
                        // Ignore scans during cooldown period
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
                
                VStack {
                    Spacer()
                        .frame(height: 60)
                    
                    HStack {
                        Spacer()
                        
                        Text("Sensors: \(storage.sensors.count)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(8)
                        
                        Spacer()
                            .frame(width: 16)
                    }
                    
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Bottom half - UI
            VStack {
                if showDuplicateWarning {
                    VStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                            .padding(.bottom, 10)
                        
                        Text("Already Scanned!")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.orange)
                        
                        Text("This sensor is already in your inventory")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if showSavedConfirmation {
                    VStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                            .padding(.bottom, 10)
                        
                        Text("Sensor Saved!")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.green)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    if let data = parsedData {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Scanned Data")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Divider()
                            
                            HStack {
                                Text("Product:")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(data.productID)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)
                            }
                            
                            HStack {
                                Text("Serial:")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(data.serialNumber)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)
                            }
                            
                            HStack {
                                Text("Expiry:")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(data.expiryDate.formatted(date: .abbreviated, time: .omitted))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)
                            }
                            
                            if let lot = data.lotNumber {
                                HStack {
                                    Text("Lot:")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(lot)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.primary)
                                }
                            }
                            
                            Button(action: {
                                captureSensor(data)
                            }) {
                                Text("CAPTURE SENSOR")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .cornerRadius(12)
                            }
                            .padding(.top, 10)
                        }
                        .padding()
                    } else {
                        VStack {
                            Image(systemName: "barcode.viewfinder")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                                .padding(.bottom, 10)
                            
                            Text("Point camera at barcode")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
        }
        .edgesIgnoringSafeArea(.top)
    }
    
    private func checkScanTimeout() {
        // Don't clear during cooldown period
        if Date() < ignoreScanUntil {
            return
        }
        
        // Clear if no scan received for 1.5 seconds
        if Date().timeIntervalSince(lastScanReceived) > 1.5 {
            if parsedData != nil {
                parsedData = nil
                scannedCode = ""
            }
        }
    }
    
    private func captureSensor(_ data: ParsedGS1Data) {
        // Try to add sensor - returns false if duplicate
        let success = storage.addSensor(
            productID: data.productID,
            serialNumber: data.serialNumber,
            expiryDate: data.expiryDate
        )
        
        // Clear parsed data immediately
        parsedData = nil
        
        if success {
            // Show success confirmation
            showSavedConfirmation = true
            
            // Ignore new scans for 2 seconds
            ignoreScanUntil = Date().addingTimeInterval(2.0)
            
            // Hide confirmation after 1 second
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                showSavedConfirmation = false
            }
            
            // After cooldown, check if there's a code that needs parsing
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.1) {
                if !scannedCode.isEmpty && parsedData == nil {
                    parsedData = GS1Parser.parse(scannedCode)
                }
            }
        } else {
            // Show duplicate warning
            showDuplicateWarning = true
            
            // Ignore new scans for 2 seconds
            ignoreScanUntil = Date().addingTimeInterval(2.0)
            
            // Hide warning after 1.5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showDuplicateWarning = false
            }
            
            // After cooldown, check if there's a code that needs parsing
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.1) {
                if !scannedCode.isEmpty && parsedData == nil {
                    parsedData = GS1Parser.parse(scannedCode)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
