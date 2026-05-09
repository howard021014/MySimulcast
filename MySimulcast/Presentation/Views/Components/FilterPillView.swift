import SwiftUI

struct FilterPillView: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(Typography.chip)
                .tracking(-0.1)
                .foregroundStyle(isSelected ? Color.white : Color.dsText)
                .padding(.horizontal, Spacing.chipH)
                .padding(.vertical, Spacing.chipV)
                .background {
                    Capsule()
                        .fill(isSelected ? Color.dsAccent : Color.dsChipIdleBg)
                }
                .overlay {
                    Capsule()
                        .strokeBorder(
                            isSelected ? Color.clear : Color.dsChipIdleBorder,
                            lineWidth: 1
                        )
                }
                .shadow(
                    color: isSelected ? Color.dsAccent.opacity(0.32) : .clear,
                    radius: 10,
                    x: 0,
                    y: 4
                )
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}
