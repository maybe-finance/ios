import SwiftUI

struct TopHeaderView: View {
    @State private var currentDate = Date()

    var body: some View {
        HStack {
            // Left side - Clock icon
            Button(action: {
                // Action for clock/time functionality
            }) {
                Image(systemName: "clock")
                    .font(.system(size: 24))
                    .foregroundColor(.primary)
            }

            Spacer()

            // Center - Calendar widget
            VStack(spacing: 2) {
                Text(currentDate.formatted(.dateTime.weekday(.abbreviated).locale(Locale(identifier: "en_US"))))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.red)
                    .textCase(.uppercase)

                Text(currentDate.formatted(.dateTime.day()))
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.1))
            .cornerRadius(12)

            Spacer()

            // Right side - Menu dots
            Button(action: {
                // Action for menu
            }) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 24))
                    .foregroundColor(.primary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.clear)
        .onAppear {
            // Update time every minute
            Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
                currentDate = Date()
            }
        }
    }
}

#Preview {
    VStack {
        Text("Top Header Preview")
    }
    .padding()
}