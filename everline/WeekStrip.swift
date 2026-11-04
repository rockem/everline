import SwiftUI

struct WeekStrip: View {
    let model: NotebookModel

    var body: some View {
        HStack(spacing: 0) {
            arrow("chevron.left", label: "Previous week", id: "previous-week", action: model.showPreviousWeek)
            ForEach(model.weekDays) { day in
                dayButton(day)
            }
            arrow("chevron.right", label: "Next week", id: "next-week", action: model.showNextWeek)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Theme.background)
        .overlay(alignment: .bottom) {
            Theme.divider.frame(height: 1)
        }
    }

    private func arrow(_ symbol: String, label: String, id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.weekdayLabel)
                .frame(width: 28, height: 52)
                .contentShape(Rectangle())
        }
        .accessibilityLabel(label)
        .accessibilityIdentifier(id)
    }

    private func dayButton(_ day: Day) -> some View {
        let date = model.calendar.date(of: day)
        let isSelected = day == model.selected
        let isToday = day == model.today
        return Button { model.select(day) } label: {
            VStack(spacing: 2) {
                Text(isToday ? "Today" : date.formatted(.dateTime.weekday(.abbreviated)))
                    .font(.system(size: 10, weight: .semibold))
                    .textCase(.uppercase)
                    .tracking(1.4)
                    .foregroundStyle(isToday ? Theme.accent : (isSelected ? Theme.onPill : Theme.weekdayLabel))
                Text(date, format: .dateTime.day())
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(isSelected ? Theme.onPill : Theme.dayNumber)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.pill)
                }
            }
            .contentShape(Rectangle())
        }
        .accessibilityLabel(date.formatted(.dateTime.weekday(.wide).day()) + (isToday ? ", today" : ""))
        .accessibilityIdentifier("day-\(day.id)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
