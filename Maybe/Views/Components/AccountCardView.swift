import SwiftUI

struct AccountCardView: View {
    let account: Account

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Account header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(account.name)
                        .font(.geist(size: 17, weight: .bold))

                    if let institution = account.institution {
                        Text(institution)
                            .font(.geist(size: 15, weight: .light))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(account.formattedBalance)
                        .font(.geist(size: 22, weight: .heavy))
                        .foregroundColor(.primary)

                    HStack(spacing: 8) {
                        Text(account.accountType.capitalized)
                            .font(.geist(size: 12, weight: .medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(4)

                        Text(account.classification.capitalized)
                            .font(.geist(size: 12, weight: .medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.1))
                            .foregroundColor(.secondary)
                            .cornerRadius(4)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    VStack {
        Text("Account Card Preview")
    }
    .padding()
}