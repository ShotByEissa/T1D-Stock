import SwiftUI

struct ContentView: View {
    @State private var scannedCode: String = "Point camera at barcode..."
    @State private var parsedData: ParsedGS1Data?
    
    var body: some View {
        ZStack {
            BarcodeScannerView(scannedCode: $scannedCode)
                .edgesIgnoringSafeArea(.all)
                .onChange(of: scannedCode) { oldValue, newValue in
                    parsedData = GS1Parser.parse(newValue)
                }
            
            VStack {
                Spacer()
                
                VStack(spacing: 10) {
                    Text("Raw Code:")
                        .font(.caption)
                        .foregroundColor(.white)
                    
                    Text(scannedCode)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(10)
                    
                    if let data = parsedData {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Parsed Data:")
                                .font(.caption)
                                .foregroundColor(.white)
                            
                            Text("Product: \(data.productID)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.green)
                            
                            Text("Serial: \(data.serialNumber)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.green)
                            
                            Text("Expiry: \(data.expiryDate.formatted(date: .abbreviated, time: .omitted))")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.green)
                            
                            if let lot = data.lotNumber {
                                Text("Lot: \(lot)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.green)
                            }
                        }
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(10)
                    }
                }
                .padding(.bottom, 50)
            }
        }
    }
}

#Preview {
    ContentView()
}
