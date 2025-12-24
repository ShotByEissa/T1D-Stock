import Foundation

struct GS1Parser {
    static func parse(_ rawCode: String) -> ParsedGS1Data? {
        // Validate minimum length
        guard rawCode.count >= 4 else { return nil }
        
        var productID: String?
        var expiryDate: Date?
        var serialNumber: String?
        var lotNumber: String?
        
        var index = rawCode.startIndex
        
        while index < rawCode.endIndex {
            // Need at least 2 characters for AI
            let remaining = rawCode.distance(from: index, to: rawCode.endIndex)
            guard remaining >= 2 else { break }
            
            let aiEnd = rawCode.index(index, offsetBy: 2)
            let ai = String(rawCode[index..<aiEnd])
            
            index = aiEnd
            
            switch ai {
            case "01": // Product ID (14 digits fixed)
                guard rawCode.distance(from: index, to: rawCode.endIndex) >= 14 else { break }
                let endIndex = rawCode.index(index, offsetBy: 14)
                productID = String(rawCode[index..<endIndex])
                index = endIndex
                
            case "11": // Production date (6 digits fixed)
                guard rawCode.distance(from: index, to: rawCode.endIndex) >= 6 else { break }
                let endIndex = rawCode.index(index, offsetBy: 6)
                index = endIndex
                
            case "17": // Expiry date (6 digits fixed)
                guard rawCode.distance(from: index, to: rawCode.endIndex) >= 6 else { break }
                let endIndex = rawCode.index(index, offsetBy: 6)
                let dateString = String(rawCode[index..<endIndex])
                expiryDate = parseDate(dateString)
                index = endIndex
                
            case "10": // Lot number (variable length)
                if let nextAI = findNextAI(in: rawCode, from: index) {
                    lotNumber = String(rawCode[index..<nextAI])
                    index = nextAI
                } else {
                    lotNumber = String(rawCode[index...])
                    index = rawCode.endIndex
                }
                
            case "21": // Serial number (12 digits fixed for Dexcom)
                guard rawCode.distance(from: index, to: rawCode.endIndex) >= 12 else { break }
                let endIndex = rawCode.index(index, offsetBy: 12)
                serialNumber = String(rawCode[index..<endIndex])
                index = endIndex
                
            default:
                // Unknown AI, try to skip it
                if let nextAI = findNextAI(in: rawCode, from: index) {
                    index = nextAI
                } else {
                    break
                }
            }
        }
        
        guard let product = productID,
              let expiry = expiryDate,
              let serial = serialNumber else {
            return nil
        }
        
        return ParsedGS1Data(
            productID: product,
            expiryDate: expiry,
            serialNumber: serial,
            lotNumber: lotNumber
        )
    }
    
    private static func findNextAI(in string: String, from index: String.Index) -> String.Index? {
        let knownAIs = ["01", "11", "17", "10", "21", "24", "30"]
        
        guard index < string.endIndex else { return nil }
        
        var searchIndex = string.index(after: index)
        
        while searchIndex < string.endIndex {
            let remaining = string.distance(from: searchIndex, to: string.endIndex)
            guard remaining >= 2 else { break }
            
            let checkEnd = string.index(searchIndex, offsetBy: 2)
            let nextTwoChars = String(string[searchIndex..<checkEnd])
            
            if knownAIs.contains(nextTwoChars) {
                return searchIndex
            }
            
            guard searchIndex < string.endIndex else { break }
            searchIndex = string.index(after: searchIndex)
        }
        
        return nil
    }
    
    private static func parseDate(_ dateString: String) -> Date? {
        // Format: YYMMDD
        guard dateString.count == 6 else { return nil }
        
        let yearStr = String(dateString.prefix(2))
        let monthStr = String(dateString.dropFirst(2).prefix(2))
        let dayStr = String(dateString.suffix(2))
        
        guard let year = Int(yearStr),
              let month = Int(monthStr),
              let day = Int(dayStr) else {
            return nil
        }
        
        // Assume 20xx for years
        let fullYear = 2000 + year
        
        var components = DateComponents()
        components.year = fullYear
        components.month = month
        components.day = day
        
        return Calendar.current.date(from: components)
    }
}

struct ParsedGS1Data {
    let productID: String
    let expiryDate: Date
    let serialNumber: String
    let lotNumber: String?
}
