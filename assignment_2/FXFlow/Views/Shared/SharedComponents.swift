import SwiftUI

// MARK: - Shared Components
struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

struct DetailRowWithDate: View {
    let title: String
    let value: Any
    var isDate: Bool = false
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.gray)
            Spacer()
            if isDate, let date = value as? Date {
                Text(date, style: .date)
            } else {
                Text("\(value)")
            }
        }
    }
} 