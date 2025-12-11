import SwiftUI

struct DexcomSensorsView: View {
    @StateObject private var storage = SensorStorage()
    @State private var showScanner = false
    @State private var isEditMode = false
    @State private var selectedSensor: Sensor?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if storage.sensors.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "sensor.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.gray)
                        
                        Text("No Sensors Yet")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Tap the button below to scan your first sensor")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        // Available sensors section
                        if !storage.availableSensors.isEmpty {
                            Section {
                                ForEach(storage.availableSensors) { sensor in
                                    HStack(spacing: 12) {
                                        if isEditMode {
                                            Button(action: {
                                                selectedSensor = sensor
                                            }) {
                                                Image(systemName: "minus.circle.fill")
                                                    .foregroundColor(.red)
                                                    .font(.system(size: 22))
                                            }
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 8) {
                                            HStack {
                                                Text(sensor.productType)
                                                    .font(.headline)
                                                Spacer()
                                                Text("Exp: \(sensor.expiryDate.formatted(date: .abbreviated, time: .omitted))")
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                            }
                                            
                                            Text("Serial: \(sensor.serialNumber)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                        
                        // To notify supplier section
                        if !storage.notifySensors.isEmpty {
                            Section(header: Text("To Notify Supplier")) {
                                ForEach(storage.notifySensors) { sensor in
                                    HStack(spacing: 12) {
                                        if isEditMode {
                                            Button(action: {
                                                selectedSensor = sensor
                                            }) {
                                                Image(systemName: "minus.circle.fill")
                                                    .foregroundColor(.red)
                                                    .font(.system(size: 22))
                                            }
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 8) {
                                            HStack {
                                                Text(sensor.productType)
                                                    .font(.headline)
                                                    .foregroundColor(.gray)
                                                Spacer()
                                                Text("Exp: \(sensor.expiryDate.formatted(date: .abbreviated, time: .omitted))")
                                                    .font(.subheadline)
                                                    .foregroundColor(.gray)
                                            }
                                            
                                            HStack {
                                                Text("Serial: \(sensor.serialNumber)")
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                                
                                                Spacer()
                                                
                                                Text(sensor.status.rawValue)
                                                    .font(.caption)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.orange)
                                            }
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
                
                // Scan button at bottom
                Button(action: {
                    showScanner = true
                }) {
                    HStack {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.title2)
                        Text("SCAN SENSORS")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Dexcom Sensors")
            .toolbar {
                if !storage.sensors.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(isEditMode ? "Done" : "Edit") {
                            isEditMode.toggle()
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $showScanner) {
                ScanningView(storage: storage)
            }
            .sheet(item: $selectedSensor) { sensor in
                SensorActionSheet(
                    sensor: sensor,
                    onUsed: {
                        storage.markAsUsed(sensor)
                        selectedSensor = nil
                    },
                    onLost: {
                        storage.updateStatus(sensor, to: .lost)
                        selectedSensor = nil
                    },
                    onBroken: {
                        storage.updateStatus(sensor, to: .broken)
                        selectedSensor = nil
                    },
                    onCancel: {
                        selectedSensor = nil
                    }
                )
                .presentationDetents([.height(320)])
                .presentationDragIndicator(.visible)
            }
        }
    }
}

struct SensorActionSheet: View {
    let sensor: Sensor
    let onUsed: () -> Void
    let onLost: () -> Void
    let onBroken: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("Serial: \(sensor.serialNumber)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 20)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 20)
            
            Divider()
            
            // Options
            VStack(spacing: 0) {
                Button(action: onUsed) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                        Text("Used")
                            .font(.body)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                
                Divider()
                    .padding(.leading, 56)
                
                Button(action: onLost) {
                    HStack {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.orange)
                        Text("Lost/Stolen")
                            .font(.body)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                
                Divider()
                    .padding(.leading, 56)
                
                Button(action: onBroken) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                        Text("Broken/Defective")
                            .font(.body)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
            }
            
            Divider()
            
            // Cancel button
            Button(action: onCancel) {
                Text("Cancel")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                    .padding()
                    .frame(maxWidth: .infinity)
            }
            
            Spacer()
        }
        .background(Color(.systemBackground))
    }
}
