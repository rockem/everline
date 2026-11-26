import SwiftUI

struct WeekStrip: View {
    let model: NoteRangeModel
    @ScaledMetric(relativeTo: .title3) private var rowHeight: CGFloat = 72
    @ScaledMetric(relativeTo: .caption2) private var labelSize: CGFloat = 11
    @ScaledMetric(relativeTo: .title3) private var numberSize: CGFloat = 20

    var body: some View {
        HStack(spacing: 0) {
            arrow("chevron.left", label: "Previous week", id: "previous-week", action: model.previousRange)
            ForEach(model.weekDays) { day in
                dayButton(day)
            }
            arrow("chevron.right", label: "Next week", id: "next-week", action: model.nextRange)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Theme.background)
        .overlay(alignment: .bottom) {
            Theme.divider.frame(height: 1)
        }
    }

    private func arrow(_ symbol: String, label: String, id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.secondaryText)
                .frame(minWidth: 44, minHeight: 44)
                .frame(height: rowHeight)
                .contentShape(Rectangle())
        }
        .accessibilityLabel(label)
        .accessibilityIdentifier(id)
    }

    private func dayButton(_ day: Day) -> some View {
        let date = model.calendar.date(of: day)
        let style = model.calendar.formatStyle()
        let isSelected = day == model.selected
        let isToday = day == model.today
        let color = textColor(isSelected: isSelected, isToday: isToday)
        return Button { model.select(day) } label: {
            VStack(spacing: 2) {
                Text(isToday ? "Today" : date.formatted(style.weekday(.abbreviated)))
                    .font(Fonts.ui(labelSize, .semibold))
                    .textCase(.uppercase)
                    .tracking(1.4)
                Text(date, format: style.day())
                    .font(Fonts.ui(numberSize, isToday || isSelected ? .semibold : .medium))
                noteDot(model.hasNote(on: day))
            }
            .foregroundStyle(color)
            .frame(maxWidth: .infinity, minHeight: 44)
            .frame(height: rowHeight)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.selectedPill)
                    RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Theme.selectedOutline)
                }
            }
            .contentShape(Rectangle())
        }
        .accessibilityLabel(date.formatted(style.weekday(.wide).day()) + (isToday ? ", today" : "")
            + (model.hasNote(on: day) ? ", has a note" : ""))
        .accessibilityIdentifier("day-\(day.id)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    /// Selected wins over today for the text color; today keeps its "Today" label either way.
    private func textColor(isSelected: Bool, isToday: Bool) -> Color {
        if isSelected { return Theme.selectedText }
        return isToday ? Theme.primaryText : Theme.secondaryText
    }

    /// A small dot under a day whose note has text; the space stays so rows keep their height.
    @ViewBuilder
    private func noteDot(_ hasNote: Bool) -> some View {
        if hasNote {
            Circle()
                .fill(Theme.noteDot)
                .frame(width: 4, height: 4)
                .accessibilityHidden(true)
                .accessibilityIdentifier("note-dot")
        } else {
            Color.clear.frame(width: 4, height: 4)
        }
    }
}
