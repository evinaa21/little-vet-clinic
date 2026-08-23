import SwiftUI

/// One task. Hover reveals a trash button; dragging the row left far enough
/// deletes it, with a soft-red track showing up behind as you go.
struct TaskRowView: View {
    let item: TodoItem
    let theme: Theme
    let onToggle: () -> Void
    let onDelete: () -> Void

    @State private var isHovering = false
    @State private var swipeOffset: CGFloat = 0

    /// How far left the row must travel before letting go deletes it.
    private let deleteThreshold: CGFloat = -76

    var body: some View {
        ZStack(alignment: .trailing) {
            // The track that peeks out from under a swiping row.
            RoundedRectangle(cornerRadius: Metrics.rowRadius, style: .continuous)
                .fill(Color(hex: 0xFF8FA8).opacity(min(1, abs(swipeOffset) / 70) * 0.55))
                .overlay(
                    Image(systemName: "trash.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                        .opacity(min(1, abs(swipeOffset) / 60))
                        .padding(.trailing, 14),
                    alignment: .trailing
                )

            HStack(spacing: 10) {
                CheckboxView(isDone: item.isDone, theme: theme, action: onToggle)

                Text(item.title)
                    .font(Font2.rounded(13, .medium))
                    .foregroundColor(item.isDone ? theme.ink.opacity(0.45) : theme.ink)
                    .strikethrough(item.isDone, color: theme.ink.opacity(0.35))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if isHovering {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 10.5, weight: .semibold))
                            .foregroundColor(theme.ink.opacity(0.55))
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                    .help("Delete task")
                }
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: Metrics.rowRadius, style: .continuous)
                    .fill(theme.rowFill.opacity(isHovering ? 0.62 : 0.42))
                    .overlay(
                        RoundedRectangle(cornerRadius: Metrics.rowRadius, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.5), lineWidth: 0.8)
                    )
            )
            .offset(x: swipeOffset)
            .gesture(
                DragGesture(minimumDistance: 8)
                    .onChanged { value in
                        // Left only — rightward drags are for reordering, not deleting.
                        guard value.translation.width < 0 else { return }
                        swipeOffset = max(value.translation.width, -110)
                    }
                    .onEnded { _ in
                        if swipeOffset <= deleteThreshold {
                            withAnimation(.easeIn(duration: 0.16)) { swipeOffset = -320 }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { onDelete() }
                        } else {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { swipeOffset = 0 }
                        }
                    }
            )
        }
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.14)) { isHovering = hovering }
        }
    }
}