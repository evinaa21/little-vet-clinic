import SwiftUI

/// The whole widget: a clipboard holding today's intake sheet.
///
/// Fixed width, height follows the content. The clip is fixed furniture at the
/// top; everything below it is paper, clipped to a torn-off shape so the bottom
/// edge of the window really is perforated.
///
/// Opening the panel feeds that paper out from under the clip. The reveal is a
/// mask, not a height change: the layout stays at full size throughout, so the
/// window doesn't resize sixty times a second while the sheet extends.
struct ClipboardView: View {
    @EnvironmentObject private var store: PatientStore
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var presentation: PanelPresentation

    @State private var draft = ""
    @FocusState private var fieldFocused: Bool

    /// The natural height of the row stack, measured from the rows themselves.
    ///
    /// The list needs a *determinate* height. The window is sized from the hosting
    /// controller's preferred content size, and a `ScrollView` has no height of its
    /// own — it takes whatever it is offered. Left with only a `maxHeight` the two
    /// negotiate forever: the scroll view resizes, the window resizes to match, the
    /// scroll view resizes again. That recursion overflows the stack and kills the
    /// app. Measuring the content and pinning the frame to it breaks the loop,
    /// because the measurement depends only on the (fixed) card width.
    @State private var listHeight: CGFloat = 0

    var body: some View {
        ZStack(alignment: .top) {
            sheet
                // Grows downward from the top, so the paper appears to extend out
                // of the clip's grip rather than expanding in both directions.
                .mask(UnrollMask(reveal: presentation.reveal))

            clipStrip
        }
        .frame(width: Metrics.cardWidth)
        .shadow(color: Color.black.opacity(0.20), radius: 16, x: 0, y: 7)
        .padding(Metrics.shadowGutter)   // transparent gutter for the shadow to land in
    }

    // MARK: The clip

    /// Fixed: it does not move while the paper feeds past it, and it is what the
    /// window is dragged by.
    ///
    /// The whole strip is the grab area, not just the drawn clip — a 104pt target
    /// is a fussy thing to hit, and there is nothing else up here to click. The
    /// handle goes on top as an overlay: behind the clip it never sees the
    /// mouse-down at all.
    private var clipStrip: some View {
        ZStack {
            Color.clear
            ClipGraphic(pinch: presentation.clipPinch)
        }
        .frame(maxWidth: .infinity)
        .frame(height: Metrics.clipStripHeight)
        .contentShape(Rectangle())
        .overlay(WindowDragHandle())
        .help("Drag to move the clinic")
    }

    // MARK: Sheet

    private var sheet: some View {
        VStack(spacing: 0) {
            header
            DashedRule().padding(.horizontal, 14)
            checkIn
            DashedRule().padding(.horizontal, 14)
            content
            footer
        }
        .background(Clinic.paper)
        .overlay(clipShadow, alignment: .top)
        .clipShape(TornSheet())
    }

    /// The clip sits on top of the paper, so the paper is a little darker just
    /// underneath it.
    private var clipShadow: some View {
        LinearGradient(
            colors: [Clinic.paperShade, Clinic.paper.opacity(0)],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: 14)
        .allowsHitTesting(false)
    }

    // MARK: Header

    private var header: some View {
        VStack(spacing: 2) {
            Text("TODAY'S PATIENTS")
                .font(ClinicFont.display(14.5, .bold))
                .kerning(1.4)
                .foregroundColor(Clinic.ink)

            Text(dateLine)
                .font(ClinicFont.printed(8.5, .medium))
                .kerning(1.2)
                .foregroundColor(Clinic.inkMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Metrics.clipStripHeight + 6)   // clear of the clip
        .padding(.bottom, 10)
    }

    // MARK: Check-in

    private var checkIn: some View {
        HStack(spacing: 7) {
            Text("+")
                .font(ClinicFont.printed(12, .bold))
                .foregroundColor(fieldFocused ? Clinic.ink.opacity(0.6) : Clinic.inkMuted)

            ZStack(alignment: .leading) {
                if draft.isEmpty {
                    Text("check in a new patient…")
                        .font(ClinicFont.printed(10.5, .regular))
                        .foregroundColor(Clinic.inkMuted.opacity(0.75))
                }
                TextField("", text: $draft)
                    .textFieldStyle(.plain)
                    .font(ClinicFont.printed(10.5, .medium))
                    .foregroundColor(Clinic.ink)
                    .focused($fieldFocused)
                    .onSubmit(commitDraft)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        // While unfocused the clinic may not be the active app, so one click needs
        // to both bring it forward and drop the caret in the field.
        .overlay {
            if !fieldFocused {
                ClickToActivate { fieldFocused = true }
            }
        }
    }

    /// Pins the list to what the rows actually need, so the scroll view never has
    /// to ask the window how tall it may be. Deferred by a turn because this is
    /// called from inside a layout pass. Height must never animate — the window
    /// is sized from the content, and animating that frame is what overflows the
    /// constraint engine.
    private func noteListHeight(_ measured: CGFloat) {
        guard measured > 0, abs(measured - listHeight) > 0.5 else { return }
        DispatchQueue.main.async {
            var snap = Transaction()
            snap.disablesAnimations = true
            withTransaction(snap) { listHeight = measured }
        }
    }

    private func commitDraft() {
        // Same rule as `see()` / `discharge()`: never wrap the store mutation in
        // `withAnimation`. Adding the first waiting patient after the clinic
        // closed card was showing changes panel height and animating that resize
        // overflowed AppKit's constraint engine and killed the app.
        guard store.checkIn(draft) else { return }
        draft = ""
        fieldFocused = true
    }

    // MARK: Patient list

    @ViewBuilder
    private var content: some View {
        VStack(spacing: 0) {
            if !store.patients.isEmpty {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 2) {
                        ForEach(Array(store.patients.enumerated()), id: \.element.id) { index, patient in
                            PatientRowView(
                                patient: patient,
                                // Cycled by position, so the pastel rhythm holds no
                                // matter which animals are on the board.
                                badge: Clinic.badge(for: index),
                                onToggle: { see(patient) },
                                onDischarge: { discharge(patient) }
                            )
                            .transition(.patientRow)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        // Reports straight back into `listHeight` rather than
                        // through a PreferenceKey: preferences don't reliably
                        // cross a ScrollView's hosting boundary, so the value
                        // never arrived and the list sat at its fallback height.
                        GeometryReader { proxy in
                            Color.clear
                                .onAppear { noteListHeight(proxy.size.height) }
                                .onChange(of: proxy.size.height) { noteListHeight($0) }
                        }
                    )
                }
                // Before the first measurement lands, stand the list at its full
                // allowance. Starting from zero would give the rows no height to
                // lay out in, so they'd never report one and the list would stay
                // empty forever.
                .frame(height: listHeight > 0
                       ? min(listHeight, Metrics.listMaxHeight)
                       : Metrics.listMaxHeight)
                .animation(nil, value: listHeight)

            }

            // Shown whenever the waiting room is empty — either nobody has been
            // checked in yet, or everyone on the board has been seen. Seen rows stay
            // above it so a mis-click is still one click away from being undone.
            if store.isClosed {
                ClinicClosedView()
                    .padding(.horizontal, 14)
                    // Deliberately *not* animated into place. This block is the one
                    // thing that changes the panel's overall height, and the window
                    // is sized from the content — so animating it in would resize
                    // the window on every frame of the spring. Each of those resizes
                    // makes AppKit regenerate the autoresizing constraints for every
                    // platform view SwiftUI owns (the scroll view, the text field),
                    // and checking a task on and off a few dozen times backs the
                    // constraint engine up until it recurses off the end of the
                    // stack and the app dies. Snapping the height costs nothing:
                    // ClinicClosedView plays its own entrance from `onAppear`.
                    .transaction { $0.animation = nil }
            }
        }
        .animation(nil, value: store.isClosed)
        .animation(nil, value: store.patients.isEmpty)
        .onChange(of: store.isClosed) { closed in
            guard !closed else { return }
            var snap = Transaction()
            snap.disablesAnimations = true
            withTransaction(snap) { listHeight = 0 }
        }
        .onChange(of: store.patients.isEmpty) { isEmpty in
            if isEmpty {
                var snap = Transaction()
                snap.disablesAnimations = true
                withTransaction(snap) { listHeight = 0 }
            }
        }
    }

    // MARK: Tally

    private var footer: some View {
        VStack(spacing: 5) {
            DoubleRule()

            VStack(spacing: 3) {
                TallyLine(icon: "pawprint.fill", label: "PATIENTS SEEN:",
                          count: store.seenCount, ink: Clinic.seenPillInk)
                TallyLine(icon: "hourglass", label: "STILL WAITING:",
                          count: store.waitingCount, ink: Clinic.ink.opacity(0.65))
            }

            KeyCapView(label: HotKeyManager.displayString)
                .padding(.top, 2)
        }
        .padding(.horizontal, 16)
        .padding(.top, 9)
        .padding(.bottom, 10 + Metrics.tearDepth)   // keep type out of the teeth
    }

    // MARK: Actions

    private func see(_ patient: Patient) {
        // No animation transaction here on purpose. Everything this needs to
        // animate — the two-beat stamp, the avatar's hop, the pill, the tally pop —
        // is driven by each view off its own state. Wrapping the mutation would
        // additionally animate the panel's *height* whenever this closes or reopens
        // the clinic, which is what used to crash the app on repeated toggling.
        let becameSeen = store.toggleSeen(patient.id)

        if becameSeen && settings.soundEnabled {
            SoundPlayer.shared.playStamp()
        }
    }

    private func discharge(_ patient: Patient) {
        // Same rule as `see()`: wrapping the mutation would animate panel height
        // when the list shrinks or the clinic-closed card appears.
        store.discharge(patient.id)
    }

    // MARK: Date

    /// The small printed line under the headline — the receipt's timestamp.
    private var dateLine: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE · d MMM yyyy"
        return formatter.string(from: Date()).uppercased()
    }
}
