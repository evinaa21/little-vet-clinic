import SwiftUI
import UniformTypeIdentifiers

/// The whole widget: frosted card, header, quick-add, list, and the collapsed
/// "done today" drawer. Sized to a fixed width; height follows the content.
struct PanelView: View {
    @EnvironmentObject private var store: TaskStore
    @EnvironmentObject private var settings: AppSettings

    let onOpenSettings: () -> Void

    @State private var draft = ""
    @FocusState private var fieldFocused: Bool
    @State private var celebrating = false
    @State private var showDone = false
    @State private var draggingID: UUID?

    private var theme: Theme { settings.theme }

    private var mascotState: MascotState {
        if celebrating { return .happy }
        return store.isEmpty ? .sleepy : .idle
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            quickAdd
            content
            footer
        }
        .frame(width: Metrics.cardWidth)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Metrics.panelRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Metrics.panelRadius, style: .continuous)
                .strokeBorder(Color.white.opacity(0.55), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.22), radius: 20, x: 0, y: 8)
        .padding(Metrics.shadowGutter)   // transparent gutter for the shadow to land in
        .animation(.spring(response: 0.32, dampingFraction: 0.82), value: store.items)
    }

    // MARK: Background

    private var cardBackground: some View {
        ZStack {
            VisualEffectBlur(material: .hudWindow, blending: .behindWindow)
            // The pastel wash — enough to tint the frost without going opaque.
            LinearGradient(
                colors: [theme.wash.opacity(0.85), theme.wash.opacity(0.62)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .opacity(0.85)
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 8) {
            // Everything in here is draggable — this is the panel's handle.
            HStack(spacing: 10) {
                MascotView(mascot: settings.mascot, state: mascotState, theme: theme, size: 36)

                VStack(alignment: .leading, spacing: 0) {
                    Text(dayName)
                        .font(Font2.rounded(15, .bold))
                        .foregroundColor(theme.ink)
                    Text(dateLine)
                        .font(Font2.rounded(10.5, .semibold))
                        .foregroundColor(theme.ink.opacity(0.55))
                }

                Spacer(minLength: 4)
            }
            .contentShape(Rectangle())
            .background(WindowDragHandle())

            if settings.showStreak && store.streak > 0 {
                streakBadge
            }

            Button(action: onOpenSettings) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(theme.ink.opacity(0.5))
                    .frame(width: 22, height: 22)
                    .background(Circle().fill(Color.white.opacity(0.35)))
            }
            .buttonStyle(.plain)
            .help("Puff settings")
        }
        .padding(.horizontal, 14)
        .padding(.top, 13)
        .padding(.bottom, 10)
    }

    private var streakBadge: some View {
        HStack(spacing: 3) {
            Image(systemName: "flame.fill")
                .font(.system(size: 9.5, weight: .bold))
            Text("\(store.streak)")
                .font(Font2.rounded(11, .bold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(
            Capsule().fill(
                LinearGradient(colors: [Color(hex: 0xFFA85C), Color(hex: 0xFF7A9E)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            )
        )
        .help("\(store.streak)-day streak — clear every task to keep it alive")
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: Quick add

    private var quickAdd: some View {
        HStack(spacing: 8) {
            Image(systemName: "plus")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(theme.accent)

            ZStack(alignment: .leading) {
                if draft.isEmpty {
                    Text("add something…")
                        .font(Font2.rounded(13, .medium))
                        .foregroundColor(theme.ink.opacity(0.35))
                }
                TextField("", text: $draft)
                    .textFieldStyle(.plain)
                    .font(Font2.rounded(13, .medium))
                    .foregroundColor(theme.ink)
                    .focused($fieldFocused)
                    .onSubmit(commitDraft)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: Metrics.rowRadius, style: .continuous)
                .fill(Color.white.opacity(0.55))
                .overlay(
                    RoundedRectangle(cornerRadius: Metrics.rowRadius, style: .continuous)
                        .strokeBorder(fieldFocused ? theme.accent.opacity(0.7) : Color.white.opacity(0.6),
                                      lineWidth: fieldFocused ? 1.6 : 0.8)
                )
        )
        // While unfocused the panel may not be the active app, so one click both
        // brings Puff forward and drops the caret in the field.
        .overlay {
            if !fieldFocused {
                ClickToActivate { fieldFocused = true }
            }
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 10)
        .animation(.easeOut(duration: 0.15), value: fieldFocused)
    }

    private func commitDraft() {
        guard store.add(draft) else { return }
        draft = ""
        fieldFocused = true
    }

    // MARK: List

    @ViewBuilder
    private var content: some View {
        if store.isEmpty {
            EmptyStateView(mascot: settings.mascot, theme: theme)
                .padding(.horizontal, 14)
                .padding(.bottom, 6)
        } else {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 7) {
                    ForEach(store.openItems) { item in
                        row(for: item)
                    }

                    if !store.doneTodayItems.isEmpty {
                        doneSection
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 4)
            }
            .frame(maxHeight: Metrics.listMaxHeight)
        }
    }

    private func row(for item: TodoItem) -> some View {
        TaskRowView(
            item: item,
            theme: theme,
            onToggle: { toggle(item) },
            onDelete: { withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { store.delete(item.id) } }
        )
        .opacity(draggingID == item.id ? 0.35 : 1)
        // Drag the task's text to reorder; drag anywhere else on the row to swipe-delete.
        .onDrag {
            draggingID = item.id
            return NSItemProvider(object: item.id.uuidString as NSString)
        }
        .onDrop(
            of: [.text],
            delegate: ReorderDelegate(target: item, draggingID: $draggingID, store: store)
        )
    }

    private var doneSection: some View {
        VStack(spacing: 7) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { showDone.toggle() }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 8, weight: .bold))
                        .rotationEffect(.degrees(showDone ? 90 : 0))
                    Text("done today · \(store.doneTodayItems.count)")
                        .font(Font2.rounded(11, .bold))
                    Spacer()
                }
                .foregroundColor(theme.ink.opacity(0.5))
                .padding(.top, 6)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if showDone {
                ForEach(store.doneTodayItems) { item in
                    TaskRowView(
                        item: item,
                        theme: theme,
                        onToggle: { toggle(item) },
                        onDelete: { withAnimation { store.delete(item.id) } }
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }

    // MARK: Footer

    private var footer: some View {
        HStack(spacing: 4) {
            if store.allClear {
                Text("all done 🎉")
                    .font(Font2.rounded(10.5, .bold))
                    .foregroundColor(theme.accent)
            } else if !store.isEmpty {
                Text("\(store.openItems.count) left")
                    .font(Font2.rounded(10.5, .semibold))
                    .foregroundColor(theme.ink.opacity(0.45))
            }
            Spacer()
            Text(settings.hotKey.displayString)
                .font(Font2.rounded(10, .semibold))
                .foregroundColor(theme.ink.opacity(0.32))
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 12)
    }

    // MARK: Actions

    private func toggle(_ item: TodoItem) {
        let becameDone = store.toggle(item.id)
        guard becameDone else { return }

        if settings.soundEnabled { SoundPlayer.shared.playPop() }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { celebrating = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.easeOut(duration: 0.3)) { celebrating = false }
        }
    }

    // MARK: Dates

    private var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: Date()).lowercased()
    }

    private var dateLine: String {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMMd")
        return formatter.string(from: Date()).uppercased()
    }
}

// MARK: - Reordering

private struct ReorderDelegate: DropDelegate {
    let target: TodoItem
    @Binding var draggingID: UUID?
    let store: TaskStore

    func dropEntered(info: DropInfo) {
        guard let dragging = draggingID, dragging != target.id else { return }
        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
            store.move(id: dragging, before: target.id)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        draggingID = nil
        store.save()
        return true
    }
}