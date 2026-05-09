import SwiftUI

struct DsSearchField: View {
    @Binding var text: String
    var placeholder: String = "Search anime by title"
    var isActive: Bool = false
    var onSubmit: (() -> Void)? = nil

    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(isActive ? Color.dsAccent : Color.dsTextFaint)

            TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(Color.dsTextFaint))
                .font(Typography.rowTitle)
                .foregroundStyle(Color.dsText)
                .textInputAutocapitalization(.never)
                .submitLabel(.search)
                .focused($focused)
                .onSubmit { onSubmit?() }

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.dsTextFaint)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 38)
        .background(
            RoundedRectangle(cornerRadius: Radii.field, style: .continuous)
                .fill(Color.dsFieldBg)
        )
    }
}
