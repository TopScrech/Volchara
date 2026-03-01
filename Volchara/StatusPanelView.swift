import SwiftUI

struct StatusPanelView: View {
    let statusText: String
    let lastSlapText: String
    let copyAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Status")
                    .font(.headline)
                Spacer(minLength: 0)
                Button("Copy Status", systemImage: "doc.on.doc", action: copyAction)
                    .buttonStyle(.bordered)
            }

            Text(statusText)
                .font(.body)

            Text(lastSlapText)
                .font(.callout.monospaced())
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.thinMaterial, in: .rect(cornerRadius: 12))
    }
}
