import SwiftUI

/// The selected day as a large title.
struct PageHeader: View {
    let day: Day
    let calendar: DayCalendar
    @ScaledMetric(relativeTo: .largeTitle) private var titleSize: CGFloat = 44

    var body: some View {
        Text(calendar.date(of: day), format: .dateTime.month(.wide).day())
            .font(Fonts.ui(titleSize, .medium, relativeTo: .largeTitle))
            .tracking(-1.3)
            .foregroundStyle(Theme.primaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
            .accessibilityIdentifier("page-title")
    }
}
