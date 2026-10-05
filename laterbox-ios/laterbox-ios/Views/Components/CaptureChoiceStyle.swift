import SwiftUI

struct CaptureChoiceStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.body.weight(.semibold)).foregroundStyle(.black)
            .padding(.horizontal, 16).padding(.vertical, 12)
            .background(AppTheme.accent.opacity(configuration.isPressed ? 0.7 : 1), in: RoundedRectangle(cornerRadius: 14))
    }
}
struct CaptureDateChoices: View {
    @Binding var date: Date
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Button { shift(.day, -1) } label: { Image(systemName: "chevron.left") }
                Text(date, format: .dateTime.day().month().year()).frame(maxWidth: .infinity)
                Button { shift(.day, 1) } label: { Image(systemName: "chevron.right") }
            }
            HStack {
                Button("−1 hour") { shift(.hour, -1) }
                Text(date, format: .dateTime.hour().minute())
                Button("+1 hour") { shift(.hour, 1) }
            }
        }.foregroundStyle(.black).padding(12).background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 16)).buttonStyle(CaptureChoiceStyle())
    }
    private func shift(_ component: Calendar.Component, _ value: Int) {
        if let next = Calendar.current.date(byAdding: component, value: value, to: date), next > Date() { date = next }
    }
}
