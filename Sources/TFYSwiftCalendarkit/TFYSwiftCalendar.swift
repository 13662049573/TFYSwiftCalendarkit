import UIKit

@MainActor
open class TFYSwiftCalendar: UIView {
    public weak var dataSource: (any TFYSwiftCalendarDataSource)?
    public weak var delegate: (any TFYSwiftCalendarDelegate)?

    public let appearance = TFYSwiftCalendarAppearance()
    public let calendarHeaderView = TFYSwiftCalendarHeaderView()
    public let calendarWeekdayView = TFYSwiftCalendarWeekdayView()
    public let collectionViewLayout = TFYSwiftCalendarCollectionViewLayout()
    public let collectionView: UICollectionView
    public let scopeGestureRecognizer = UIPanGestureRecognizer()
    public let swipeToChooseGestureRecognizer = UILongPressGestureRecognizer()

    public var calendar: Calendar = {
        var value = Calendar(identifier: .gregorian)
        value.locale = .current
        value.timeZone = .current
        return value
    }() {
        didSet {
            guard !isApplyingCalendarConfiguration, calendar != oldValue else { return }
            isApplyingCalendarConfiguration = true
            locale = calendar.locale ?? locale
            timeZone = calendar.timeZone
            firstWeekday = Self.normalizedFirstWeekday(calendar.firstWeekday)
            isApplyingCalendarConfiguration = false
            calendarConfigurationDidChange()
        }
    }

    public var locale: Locale = .current {
        didSet {
            guard !isApplyingCalendarConfiguration, locale != oldValue else { return }
            updateCalendarConfiguration { $0.locale = locale }
        }
    }

    public var timeZone: TimeZone = .current {
        didSet {
            guard !isApplyingCalendarConfiguration, timeZone != oldValue else { return }
            updateCalendarConfiguration { $0.timeZone = timeZone }
        }
    }

    public var firstWeekday: Int = Calendar.current.firstWeekday {
        didSet {
            guard !isApplyingCalendarConfiguration else { return }
            let normalized = Self.normalizedFirstWeekday(firstWeekday)
            if firstWeekday != normalized {
                isApplyingCalendarConfiguration = true
                firstWeekday = normalized
                isApplyingCalendarConfiguration = false
            }
            guard normalized != oldValue else { return }
            updateCalendarConfiguration { $0.firstWeekday = normalized }
        }
    }

    public var today: Date? = Date() {
        didSet { reloadVisibleDates() }
    }

    public private(set) var currentPage = Date()
    public private(set) var scope: TFYSwiftCalendarScope = .month

    public var scrollDirection: TFYSwiftCalendarScrollDirection = .horizontal {
        didSet {
            collectionViewLayout.scrollDirection = scrollDirection
            collectionView.alwaysBounceHorizontal = scrollDirection == .horizontal
            collectionView.alwaysBounceVertical = scrollDirection == .vertical
            setCurrentPage(currentPage, animated: false)
        }
    }

    public var placeholderType: TFYSwiftCalendarPlaceholderType = .fillSixRows {
        didSet { reloadData() }
    }

    public var allowsSelection = true {
        didSet { collectionView.allowsSelection = allowsSelection }
    }

    public var allowsMultipleSelection = false {
        didSet {
            collectionView.allowsMultipleSelection = true
            if !allowsMultipleSelection, selectedDates.count > 1, let last = selectedDates.last {
                removeAllSelections(except: last, notifyDelegate: false)
            }
        }
    }

    /// Optional upper bound for multi-date selection. `nil` means unlimited.
    public var maximumSelectedDates: Int? {
        didSet {
            if let maximumSelectedDates, maximumSelectedDates < 1 {
                self.maximumSelectedDates = nil
                return
            }
            enforceMaximumSelectionCount()
        }
    }

    public var adjustsBoundingRectWhenChangingMonths = false

    public var pagingEnabled = true {
        didSet {
            collectionView.isPagingEnabled = pagingEnabled
            collectionViewLayout.invalidateDataSourceMetrics()
            setNeedsLayout()
        }
    }

    public var scrollEnabled = true {
        didSet { collectionView.isScrollEnabled = scrollEnabled }
    }

    public var headerHeight = TFYSwiftCalendarDefaults.headerHeight {
        didSet { invalidateCalendarLayout() }
    }

    public var weekdayHeight = TFYSwiftCalendarDefaults.weekdayHeight {
        didSet { invalidateCalendarLayout() }
    }

    public var rowHeight = TFYSwiftCalendarDefaults.rowHeight {
        didSet {
            collectionViewLayout.continuousRowHeight = rowHeight
            invalidateCalendarLayout()
        }
    }

    /// Height of the sticky month header used by vertical, non-paging calendars. Set to `0` to hide it.
    public var continuousSectionHeaderHeight: CGFloat = 0 {
        didSet {
            collectionViewLayout.continuousSectionHeaderHeight = max(0, continuousSectionHeaderHeight)
            collectionViewLayout.invalidateLayout()
        }
    }

    public var sectionInsets: UIEdgeInsets = .zero {
        didSet { collectionViewLayout.sectionInsets = sectionInsets }
    }

    public var configuredDateRange: ClosedRange<Date> {
        get { configuredMinimumDate...configuredMaximumDate }
        set {
            usesDefaultDateRange = false
            configuredMinimumDate = newValue.lowerBound
            configuredMaximumDate = newValue.upperBound
            reloadData()
        }
    }

    public private(set) var minimumDate = Date(timeIntervalSince1970: 0)
    public private(set) var maximumDate = Date(timeIntervalSince1970: 4_102_444_799)

    public var selectedDate: Date? { selectedDates.last }
    public var selectedDates: [Date] {
        selectedDateValues.values.sorted()
    }

    /// The earliest and latest selected days, or `nil` when no date is selected.
    public var selectedDateBounds: ClosedRange<Date>? {
        guard let first = selectedDates.first, let last = selectedDates.last else { return nil }
        return first...last
    }

    /// Unique dates represented by cells that are currently on screen.
    public var visibleDates: [Date] {
        var values: [TFYSwiftCalendarDayKey: Date] = [:]
        for indexPath in collectionView.indexPathsForVisibleItems {
            guard let date = item(at: indexPath)?.date else { continue }
            values[dayKey(for: date)] = math.startOfDay(for: date)
        }
        return values.values.sorted()
    }

    public var visibleDateRange: ClosedRange<Date>? {
        let dates = visibleDates
        guard let first = dates.first, let last = dates.last else { return nil }
        return first...last
    }

    public var visibleCells: [TFYSwiftCalendarCell] {
        collectionView.visibleCells.compactMap { $0 as? TFYSwiftCalendarCell }
    }

    public var preferredHeight: CGFloat {
        headerHeight + weekdayHeight + CGFloat(rowsOnCurrentPage) * rowHeight
    }

    private static let defaultCellIdentifier = "TFYSwiftCalendarCell"
    private static let blankCellIdentifier = "TFYSwiftCalendarBlankCell"
    private static let maximumCachedPageCount = 48

    private var configuredMinimumDate = Date(timeIntervalSince1970: 0)
    private var configuredMaximumDate = Date(timeIntervalSince1970: 4_102_444_799)
    private var usesDefaultDateRange = true
    private var selectedDateValues: [TFYSwiftCalendarDayKey: Date] = [:]
    private var pageCache: [Int: [TFYSwiftCalendarGridItem]] = [:]
    internal var cachedPageCount: Int { pageCache.count }
    private var lastLaidOutSize = CGSize.zero
    private var isApplyingCalendarConfiguration = false
    private var isCalendarReady = false
    private var lastSwipeSelectedKey: TFYSwiftCalendarDayKey?
    private var requestedCellIndexPath: IndexPath?

    private let accessibilityDateFormatter = DateFormatter()

    private var math: TFYSwiftCalendarMath {
        TFYSwiftCalendarMath(calendar: calendar)
    }

    private var numberOfPages: Int {
        switch scope {
        case .month:
            return math.numberOfMonths(from: minimumDate, through: maximumDate)
        case .week:
            return math.numberOfWeeks(from: minimumDate, through: maximumDate)
        }
    }

    private var rowsOnCurrentPage: Int {
        numberOfRows(in: pageIndex(for: currentPage))
    }

    public override init(frame: CGRect) {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        super.init(frame: frame)
        commonInit()
    }

    public required init?(coder: NSCoder) {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = .systemBackground
        clipsToBounds = true
        isAccessibilityElement = false

        isApplyingCalendarConfiguration = true
        var configuredCalendar = calendar
        configuredCalendar.locale = locale
        configuredCalendar.timeZone = timeZone
        configuredCalendar.firstWeekday = Self.normalizedFirstWeekday(firstWeekday)
        calendar = configuredCalendar
        isApplyingCalendarConfiguration = false
        applyDefaultDateRangeIfNeeded()

        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.isPagingEnabled = pagingEnabled
        collectionViewLayout.continuousRowHeight = rowHeight
        collectionViewLayout.rowCountProvider = { [weak self] section in
            self?.numberOfRows(in: section) ?? 1
        }
        collectionView.allowsMultipleSelection = true
        collectionView.register(TFYSwiftCalendarCell.self, forCellWithReuseIdentifier: Self.defaultCellIdentifier)
        collectionView.register(TFYSwiftCalendarBlankCell.self, forCellWithReuseIdentifier: Self.blankCellIdentifier)
        collectionView.register(
            TFYSwiftCalendarSectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: TFYSwiftCalendarSectionHeaderView.reuseIdentifier
        )
        addSubview(calendarHeaderView)
        addSubview(calendarWeekdayView)
        addSubview(collectionView)

        calendarHeaderView.onPrevious = { [weak self] in self?.movePage(by: -1, animated: true) }
        calendarHeaderView.onNext = { [weak self] in self?.movePage(by: 1, animated: true) }

        scopeGestureRecognizer.addTarget(self, action: #selector(handleScopeGesture(_:)))
        scopeGestureRecognizer.delegate = self
        addGestureRecognizer(scopeGestureRecognizer)

        swipeToChooseGestureRecognizer.minimumPressDuration = 0.12
        swipeToChooseGestureRecognizer.allowableMovement = .greatestFiniteMagnitude
        swipeToChooseGestureRecognizer.addTarget(self, action: #selector(handleSwipeToChoose(_:)))
        swipeToChooseGestureRecognizer.isEnabled = false
        collectionView.addGestureRecognizer(swipeToChooseGestureRecognizer)

        accessibilityDateFormatter.dateStyle = .full
        accessibilityDateFormatter.timeStyle = .none
        isCalendarReady = true
        reloadData()
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        calendarHeaderView.frame = CGRect(x: 0, y: 0, width: bounds.width, height: max(0, headerHeight))
        calendarWeekdayView.frame = CGRect(x: 0, y: calendarHeaderView.frame.maxY, width: bounds.width, height: max(0, weekdayHeight))
        collectionView.frame = CGRect(
            x: 0,
            y: calendarWeekdayView.frame.maxY,
            width: bounds.width,
            height: max(0, bounds.height - calendarWeekdayView.frame.maxY)
        )
        if lastLaidOutSize != collectionView.bounds.size {
            lastLaidOutSize = collectionView.bounds.size
            collectionViewLayout.invalidateLayout()
            collectionView.layoutIfNeeded()
            scrollToPage(containing: currentPage, animated: false)
        }
    }

    open override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: preferredHeight)
    }

    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        CGSize(width: size.width, height: preferredHeight)
    }

    public func reloadData() {
        let lower = dataSource?.minimumDate(for: self) ?? configuredMinimumDate
        let upper = dataSource?.maximumDate(for: self) ?? configuredMaximumDate
        let normalizedLower = math.startOfDay(for: min(lower, upper))
        let normalizedUpper = math.startOfDay(for: max(lower, upper))
        minimumDate = normalizedLower
        maximumDate = normalizedUpper
        currentPage = clampedDate(currentPage)
        selectedDateValues = Dictionary(
            selectedDateValues.values.map { (dayKey(for: $0), math.startOfDay(for: $0)) },
            uniquingKeysWith: { _, latest in latest }
        ).filter { key, _ in
            key >= dayKey(for: minimumDate) && key <= dayKey(for: maximumDate)
        }
        pageCache.removeAll(keepingCapacity: true)
        collectionView.reloadData()
        collectionViewLayout.invalidateDataSourceMetrics()
        invalidateIntrinsicContentSize()
        updateChrome()
        setNeedsLayout()
        layoutIfNeeded()
        scrollToPage(containing: currentPage, animated: false)
    }

    public func invalidateAppearance() {
        updateChrome()
        reloadVisibleDates()
    }

    public func setScope(_ newScope: TFYSwiftCalendarScope, animated: Bool) {
        guard newScope != scope else { return }
        let oldHeight = preferredHeight
        scope = newScope
        currentPage = clampedDate(currentPage)
        pageCache.removeAll(keepingCapacity: true)
        collectionView.reloadData()
        collectionViewLayout.invalidateDataSourceMetrics()
        invalidateIntrinsicContentSize()
        let targetBounds = CGRect(x: bounds.minX, y: bounds.minY, width: bounds.width, height: preferredHeight)
        delegate?.calendar(self, boundingRectWillChange: targetBounds, animated: animated)

        let updates = {
            self.superview?.layoutIfNeeded()
            self.layoutIfNeeded()
        }
        if animated {
            UIView.animate(
                withDuration: TFYSwiftCalendarDefaults.animationDuration,
                delay: 0,
                options: [.curveEaseInOut, .beginFromCurrentState],
                animations: updates
            )
        } else {
            updates()
        }
        if oldHeight != preferredHeight { setNeedsLayout() }
        scrollToPage(containing: currentPage, animated: false)
        updateChrome()
    }

    public func setCurrentPage(_ date: Date, animated: Bool) {
        let target = clampedDate(date)
        guard pageIndex(for: target) != pageIndex(for: currentPage) else {
            currentPage = canonicalPageDate(for: target)
            updateChrome()
            return
        }
        currentPage = canonicalPageDate(for: target)
        scrollToPage(containing: currentPage, animated: animated)
        updateChrome()
        if adjustsBoundingRectWhenChangingMonths {
            invalidateIntrinsicContentSize()
            let targetBounds = CGRect(x: bounds.minX, y: bounds.minY, width: bounds.width, height: preferredHeight)
            delegate?.calendar(self, boundingRectWillChange: targetBounds, animated: animated)
        }
        delegate?.calendarCurrentPageDidChange(self)
    }

    public func selectDate(_ date: Date?, scrollToDate: Bool = true) {
        guard let date else { return }
        selectDates([date], replacingCurrentSelection: !allowsMultipleSelection, scrollToLastDate: scrollToDate)
    }

    public func deselectDate(_ date: Date) {
        let normalized = math.startOfDay(for: date)
        let key = dayKey(for: normalized)
        guard selectedDateValues[key] != nil else { return }
        let position = monthPosition(for: normalized, relativeTo: canonicalPageDate(for: normalized))
        guard delegate?.calendar(self, shouldDeselect: normalized, at: position) ?? true else { return }
        selectedDateValues.removeValue(forKey: key)
        if let indexPath = indexPath(for: normalized) {
            collectionView.deselectItem(at: indexPath, animated: false)
        }
        refreshDates(around: normalized)
        delegate?.calendar(self, didDeselect: normalized, at: position)
    }

    public func deselectAllDates() {
        removeAllSelections(except: nil, notifyDelegate: true)
    }

    public func selectDates(
        from startDate: Date,
        through endDate: Date,
        replacingCurrentSelection: Bool = true,
        scrollToLastDate: Bool = true
    ) {
        let lower = math.startOfDay(for: min(startDate, endDate))
        let upper = math.startOfDay(for: max(startDate, endDate))
        guard contains(lower), contains(upper) else { return }
        let previousMultipleSelection = allowsMultipleSelection
        allowsMultipleSelection = true
        var dates: [Date] = []
        dates.reserveCapacity(max(1, (calendar.dateComponents([.day], from: lower, to: upper).day ?? 0) + 1))
        var date = lower
        while dayKey(for: date) <= dayKey(for: upper) {
            dates.append(date)
            let next = math.addingDays(1, to: date)
            guard next > date else { break }
            date = next
        }
        selectDates(
            dates,
            replacingCurrentSelection: replacingCurrentSelection,
            scrollToLastDate: scrollToLastDate
        )
        allowsMultipleSelection = previousMultipleSelection || lower != upper
    }

    /// Selects multiple days with a single display refresh.
    public func selectDates(
        _ dates: [Date],
        replacingCurrentSelection: Bool = false,
        scrollToLastDate: Bool = false
    ) {
        guard allowsSelection else { return }

        var uniqueDates: [TFYSwiftCalendarDayKey: Date] = [:]
        for date in dates {
            let normalized = math.startOfDay(for: date)
            guard contains(normalized) else { continue }
            uniqueDates[dayKey(for: normalized)] = normalized
        }
        var candidates = uniqueDates.values.sorted()
        if !allowsMultipleSelection, let last = candidates.last {
            candidates = [last]
        }
        if candidates.isEmpty {
            if dates.isEmpty, replacingCurrentSelection {
                removeAllSelections(except: nil, notifyDelegate: true)
            }
            return
        }

        let candidateKeys = Set(candidates.map(dayKey(for:)))
        if replacingCurrentSelection, candidateKeys == Set(selectedDateValues.keys) { return }
        if !allowsMultipleSelection,
           candidateKeys.count == 1,
           candidateKeys == Set(selectedDateValues.keys) { return }

        let preservedDates = replacingCurrentSelection
            ? candidates.filter { selectedDateValues[dayKey(for: $0)] != nil }
            : []
        var accepted = candidates.filter { date in
            let key = dayKey(for: date)
            guard selectedDateValues[key] == nil else { return false }
            let position = monthPosition(for: date, relativeTo: canonicalPageDate(for: date))
            return delegate?.calendar(self, shouldSelect: date, at: position) ?? true
        }
        if let maximumSelectedDates {
            let retainedCount = replacingCurrentSelection ? preservedDates.count : selectedDateValues.count
            let available = max(0, maximumSelectedDates - retainedCount)
            if accepted.count > available {
                accepted = Array(accepted.prefix(available))
                delegate?.calendar(self, didReachMaximumSelectionCount: maximumSelectedDates)
            }
        }

        if replacingCurrentSelection {
            let finalKeys = Set((preservedDates + accepted).map(dayKey(for:)))
            guard !finalKeys.isEmpty else { return }
            let removals = selectedDates.filter { !finalKeys.contains(dayKey(for: $0)) }
            removeSelections(removals, notifyDelegate: true)
        } else if !allowsMultipleSelection, !accepted.isEmpty {
            removeAllSelections(except: nil, notifyDelegate: true)
        }
        guard !accepted.isEmpty else { return }

        for date in accepted { selectedDateValues[dayKey(for: date)] = date }
        refreshDates(around: accepted)
        for path in indexPaths(for: accepted, visibleOnly: true) {
            collectionView.selectItem(at: path, animated: false, scrollPosition: [])
        }
        if let last = accepted.last {
            if scrollToLastDate { setCurrentPage(last, animated: true) }
            if accepted.count == 1, let path = indexPath(for: last) {
                (collectionView.cellForItem(at: path) as? TFYSwiftCalendarCell)?.animateSelection()
            }
        }
        for date in accepted {
            let position = monthPosition(for: date, relativeTo: canonicalPageDate(for: date))
            delegate?.calendar(self, didSelect: date, at: position)
        }

        let announcement: String
        if accepted.count == 1, let date = accepted.first {
            announcement = accessibilityDateFormatter.string(from: date)
        } else {
            let format = TFYSwiftCalendarLocalization.string(
                "%ld dates selected",
                comment: "Calendar selection announcement"
            )
            announcement = String.localizedStringWithFormat(format, accepted.count)
        }
        UIAccessibility.post(notification: .announcement, argument: announcement)
    }

    public func reloadDates(_ dates: [Date]) {
        let paths = indexPaths(for: dates, visibleOnly: false)
        guard !paths.isEmpty else { return }
        UIView.performWithoutAnimation {
            collectionView.reloadItems(at: Array(paths))
            collectionView.layoutIfNeeded()
        }
    }

    public func isDateSelected(_ date: Date) -> Bool {
        selectedDateValues[dayKey(for: date)] != nil
    }

    public func date(at point: CGPoint) -> Date? {
        let collectionPoint = convert(point, to: collectionView)
        guard let indexPath = collectionView.indexPathForItem(at: collectionPoint) else { return nil }
        return item(at: indexPath)?.date
    }

    public func register(_ cellClass: AnyClass?, forCellReuseIdentifier identifier: String) {
        precondition(!identifier.isEmpty, "A calendar cell reuse identifier cannot be empty.")
        collectionView.register(cellClass, forCellWithReuseIdentifier: identifier)
    }

    public func register(
        _ cellClass: TFYSwiftCalendarCell.Type,
        forCellReuseIdentifier identifier: String
    ) {
        precondition(!identifier.isEmpty, "A calendar cell reuse identifier cannot be empty.")
        collectionView.register(cellClass, forCellWithReuseIdentifier: identifier)
    }

    public func dequeueReusableCell(
        withIdentifier identifier: String,
        for date: Date,
        at monthPosition: TFYSwiftCalendarMonthPosition
    ) -> TFYSwiftCalendarCell {
        guard let indexPath = requestedCellIndexPath ?? indexPath(for: date) else {
            preconditionFailure("The requested date is outside the configured calendar range.")
        }
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as? TFYSwiftCalendarCell else {
            preconditionFailure("Registered calendar cells must inherit from TFYSwiftCalendarCell.")
        }
        return cell
    }

    public func cell(for date: Date) -> TFYSwiftCalendarCell? {
        guard let indexPath = indexPath(for: date) else { return nil }
        return collectionView.cellForItem(at: indexPath) as? TFYSwiftCalendarCell
    }

    /// Returns the visible occurrence of a day, including adjacent-month placeholders.
    public func cell(
        for date: Date,
        at monthPosition: TFYSwiftCalendarMonthPosition
    ) -> TFYSwiftCalendarCell? {
        guard let indexPath = indexPath(for: date, at: monthPosition) else { return nil }
        return collectionView.cellForItem(at: indexPath) as? TFYSwiftCalendarCell
    }

    public func date(for cell: TFYSwiftCalendarCell) -> Date? {
        cell.representedDate
    }

    public func monthPosition(for cell: TFYSwiftCalendarCell) -> TFYSwiftCalendarMonthPosition {
        cell.monthPosition
    }

    public func frame(for date: Date) -> CGRect? {
        guard let indexPath = indexPath(for: date),
              let attributes = collectionViewLayout.layoutAttributesForItem(at: indexPath) else { return nil }
        return collectionView.convert(attributes.frame, to: self)
    }

    public func frame(
        for date: Date,
        at monthPosition: TFYSwiftCalendarMonthPosition
    ) -> CGRect? {
        guard let indexPath = indexPath(for: date, at: monthPosition),
              let attributes = collectionViewLayout.layoutAttributesForItem(at: indexPath) else { return nil }
        return collectionView.convert(attributes.frame, to: self)
    }

    @objc public func handleScopeGesture(_ sender: UIPanGestureRecognizer) {
        guard scrollDirection == .horizontal, sender.state == .ended else { return }
        let translation = sender.translation(in: self).y
        let velocity = sender.velocity(in: self).y
        let decision = abs(velocity) > 180 ? velocity : translation
        if scope == .month, decision < -24 {
            setScope(.week, animated: true)
        } else if scope == .week, decision > 24 {
            setScope(.month, animated: true)
        }
    }

    open override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer === scopeGestureRecognizer,
              scrollDirection == .horizontal,
              let pan = gestureRecognizer as? UIPanGestureRecognizer else {
            return super.gestureRecognizerShouldBegin(gestureRecognizer)
        }
        let velocity = pan.velocity(in: self)
        guard abs(velocity.y) > abs(velocity.x) else { return false }
        if scope == .month { return velocity.y < 0 }
        return velocity.y > 0
    }

    @objc private func handleSwipeToChoose(_ sender: UILongPressGestureRecognizer) {
        guard allowsSelection, sender.state == .began || sender.state == .changed else {
            if sender.state == .ended || sender.state == .cancelled { lastSwipeSelectedKey = nil }
            return
        }
        let point = sender.location(in: collectionView)
        guard let indexPath = collectionView.indexPathForItem(at: point),
              let date = item(at: indexPath)?.date else { return }
        let key = dayKey(for: date)
        guard key != lastSwipeSelectedKey else { return }
        lastSwipeSelectedKey = key
        selectDate(date, scrollToDate: false)
    }

    private static func normalizedFirstWeekday(_ value: Int) -> Int {
        max(1, min(7, value))
    }

    private func updateCalendarConfiguration(_ update: (inout Calendar) -> Void) {
        guard !isApplyingCalendarConfiguration else { return }
        isApplyingCalendarConfiguration = true
        var configuredCalendar = calendar
        update(&configuredCalendar)
        calendar = configuredCalendar
        isApplyingCalendarConfiguration = false
        calendarConfigurationDidChange()
    }

    private func calendarConfigurationDidChange() {
        guard isCalendarReady else { return }
        applyDefaultDateRangeIfNeeded()
        reloadData()
    }

    private func applyDefaultDateRangeIfNeeded() {
        guard usesDefaultDateRange else { return }
        configuredMinimumDate = calendar.date(
            from: DateComponents(calendar: calendar, timeZone: calendar.timeZone, year: 1970, month: 1, day: 1, hour: 12)
        ) ?? Date(timeIntervalSince1970: 0)
        configuredMaximumDate = calendar.date(
            from: DateComponents(calendar: calendar, timeZone: calendar.timeZone, year: 2099, month: 12, day: 31, hour: 12)
        ) ?? Date(timeIntervalSince1970: 4_102_358_400)
    }

    private func contains(_ date: Date) -> Bool {
        let key = dayKey(for: date)
        return key >= dayKey(for: minimumDate) && key <= dayKey(for: maximumDate)
    }

    private func dayKey(for date: Date) -> TFYSwiftCalendarDayKey {
        TFYSwiftCalendarDayKey(date: date, calendar: calendar)
    }

    private func clampedDate(_ date: Date) -> Date {
        let normalized = math.startOfDay(for: date)
        if dayKey(for: normalized) < dayKey(for: minimumDate) { return minimumDate }
        if dayKey(for: normalized) > dayKey(for: maximumDate) { return maximumDate }
        return normalized
    }

    private func canonicalPageDate(for date: Date) -> Date {
        switch scope {
        case .month: return math.startOfMonth(for: date)
        case .week: return math.startOfWeek(for: date)
        }
    }

    private func pageIndex(for date: Date) -> Int {
        min(max(0, math.pageIndex(for: date, scope: scope, startingAt: minimumDate)), max(0, numberOfPages - 1))
    }

    private func items(for section: Int) -> [TFYSwiftCalendarGridItem] {
        if let cached = pageCache[section] { return cached }
        guard section >= 0, section < numberOfPages else { return [] }
        let date = math.pageDate(at: section, scope: scope, startingAt: minimumDate)
        let result = math.gridItems(for: date, scope: scope, placeholderType: placeholderType)
        pageCache[section] = result
        trimPageCache(around: section)
        return result
    }

    private func numberOfRows(in section: Int) -> Int {
        guard section >= 0 else { return 1 }
        if scope == .week { return 1 }
        let date = math.pageDate(at: section, scope: scope, startingAt: minimumDate)
        return math.numberOfRows(inMonthContaining: date, placeholderType: placeholderType)
    }

    private func trimPageCache(around centerSection: Int) {
        guard pageCache.count > Self.maximumCachedPageCount else { return }
        let excess = pageCache.count - Self.maximumCachedPageCount
        let keysToRemove = pageCache.keys
            .sorted { abs($0 - centerSection) > abs($1 - centerSection) }
            .prefix(excess)
        for key in keysToRemove { pageCache.removeValue(forKey: key) }
    }

    private func item(at indexPath: IndexPath) -> TFYSwiftCalendarGridItem? {
        let values = items(for: indexPath.section)
        guard values.indices.contains(indexPath.item) else { return nil }
        return values[indexPath.item]
    }

    private func indexPath(for date: Date) -> IndexPath? {
        let normalized = math.startOfDay(for: date)
        guard contains(normalized) else { return nil }
        let section = pageIndex(for: normalized)
        let key = dayKey(for: normalized)
        guard let item = items(for: section).firstIndex(where: { value in
            value.date.map { dayKey(for: $0) == key } ?? false
        }) else { return nil }
        return IndexPath(item: item, section: section)
    }

    private func indexPath(
        for date: Date,
        at monthPosition: TFYSwiftCalendarMonthPosition
    ) -> IndexPath? {
        let normalized = math.startOfDay(for: date)
        if scope == .week {
            guard monthPosition == .current else { return nil }
            return indexPath(for: normalized)
        }

        let dateSection = math.monthOffset(of: normalized, from: minimumDate)
        let section: Int
        switch monthPosition {
        case .current: section = dateSection
        case .previous: section = dateSection + 1
        case .next: section = dateSection - 1
        case .notFound: return nil
        }
        guard section >= 0, section < numberOfPages else { return nil }
        let key = dayKey(for: normalized)
        guard let item = items(for: section).firstIndex(where: { value in
            value.monthPosition == monthPosition
                && (value.date.map { dayKey(for: $0) == key } ?? false)
        }) else { return nil }
        return IndexPath(item: item, section: section)
    }

    private func monthPosition(for date: Date, relativeTo pageDate: Date) -> TFYSwiftCalendarMonthPosition {
        guard scope == .month else { return .current }
        let offset = math.monthOffset(of: date, from: pageDate)
        if offset < 0 { return .previous }
        if offset > 0 { return .next }
        return .current
    }

    private func movePage(by offset: Int, animated: Bool) {
        let currentIndex = pageIndex(for: currentPage)
        let targetIndex = min(max(0, currentIndex + offset), max(0, numberOfPages - 1))
        guard targetIndex != currentIndex else { return }
        let target = math.pageDate(at: targetIndex, scope: scope, startingAt: minimumDate)
        setCurrentPage(target, animated: animated)
    }

    private func scrollToPage(containing date: Date, animated: Bool) {
        let section = pageIndex(for: date)
        let offset: CGPoint
        switch scrollDirection {
        case .horizontal:
            offset = CGPoint(x: CGFloat(section) * collectionView.bounds.width, y: 0)
        case .vertical:
            collectionView.layoutIfNeeded()
            offset = CGPoint(x: 0, y: collectionViewLayout.verticalOffset(forSection: section))
        }
        guard offset.x.isFinite, offset.y.isFinite else { return }
        collectionView.setContentOffset(offset, animated: animated)
    }

    private func updateCurrentPageFromScrollPosition() {
        let section: Int
        if scrollDirection == .vertical && !pagingEnabled {
            section = collectionViewLayout.section(atVerticalOffset: collectionView.contentOffset.y + 1)
        } else {
            let length = scrollDirection == .horizontal ? collectionView.bounds.width : collectionView.bounds.height
            guard length > 0 else { return }
            let offset = scrollDirection == .horizontal ? collectionView.contentOffset.x : collectionView.contentOffset.y
            section = min(max(0, Int(round(offset / length))), max(0, numberOfPages - 1))
        }
        let newPage = canonicalPageDate(for: math.pageDate(at: section, scope: scope, startingAt: minimumDate))
        guard pageIndex(for: newPage) != pageIndex(for: currentPage) else { return }
        currentPage = newPage
        updateChrome()
        invalidateIntrinsicContentSize()
        if adjustsBoundingRectWhenChangingMonths {
            let targetBounds = CGRect(x: bounds.minX, y: bounds.minY, width: bounds.width, height: preferredHeight)
            delegate?.calendar(self, boundingRectWillChange: targetBounds, animated: true)
        }
        delegate?.calendarCurrentPageDidChange(self)
    }

    private func updateChrome() {
        accessibilityDateFormatter.calendar = calendar
        accessibilityDateFormatter.locale = locale
        accessibilityDateFormatter.timeZone = timeZone
        calendarWeekdayView.update(calendar: calendar, locale: locale, appearance: appearance)
        let index = pageIndex(for: currentPage)
        calendarHeaderView.update(
            date: currentPage,
            calendar: calendar,
            locale: locale,
            appearance: appearance,
            canGoPrevious: index > 0,
            canGoNext: index < numberOfPages - 1
        )
    }

    private func invalidateCalendarLayout() {
        invalidateIntrinsicContentSize()
        setNeedsLayout()
        collectionViewLayout.invalidateLayout()
    }

    private func reloadVisibleDates() {
        let paths = collectionView.indexPathsForVisibleItems
        guard !paths.isEmpty else { return }
        reconfigureVisibleCells(at: Set(paths))
    }

    private func refreshDates(around date: Date) {
        refreshDates(around: [date])
    }

    private func refreshDates(around dates: [Date]) {
        var candidates: [Date] = []
        candidates.reserveCapacity(dates.count * 3)
        for date in dates {
            candidates.append(math.addingDays(-1, to: date))
            candidates.append(date)
            candidates.append(math.addingDays(1, to: date))
        }
        let paths = indexPaths(for: candidates, visibleOnly: true)
        reconfigureVisibleCells(at: paths)
    }

    private func reconfigureVisibleCells(at paths: Set<IndexPath>) {
        guard !paths.isEmpty else { return }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        UIView.performWithoutAnimation {
            for path in paths {
                guard let gridItem = item(at: path),
                      let date = gridItem.date,
                      let cell = collectionView.cellForItem(at: path) as? TFYSwiftCalendarCell else { continue }
                configure(cell, for: date, gridItem: gridItem)
                cell.layoutIfNeeded()
            }
        }
        CATransaction.commit()
    }

    private func indexPaths(for dates: [Date], visibleOnly: Bool) -> Set<IndexPath> {
        let keys = Set(dates.map(dayKey(for:)))
        var paths = Set<IndexPath>()
        if !visibleOnly {
            for date in dates {
                if let path = indexPath(for: date) { paths.insert(path) }
            }
        }
        for path in collectionView.indexPathsForVisibleItems {
            guard let date = item(at: path)?.date, keys.contains(dayKey(for: date)) else { continue }
            paths.insert(path)
        }
        return paths
    }

    private func removeAllSelections(except preservedDate: Date?, notifyDelegate: Bool) {
        let preservedKey = preservedDate.map(dayKey(for:))
        let dates = selectedDateValues
            .filter { $0.key != preservedKey }
            .map(\.value)
            .sorted()
        removeSelections(dates, notifyDelegate: notifyDelegate)
    }

    private func removeSelections(_ dates: [Date], notifyDelegate: Bool) {
        guard !dates.isEmpty else { return }
        for date in dates {
            selectedDateValues.removeValue(forKey: dayKey(for: date))
            if notifyDelegate {
                let position = monthPosition(for: date, relativeTo: canonicalPageDate(for: date))
                delegate?.calendar(self, didDeselect: date, at: position)
            }
        }
        for path in indexPaths(for: dates, visibleOnly: false) {
            collectionView.deselectItem(at: path, animated: false)
        }
        refreshDates(around: dates)
    }

    private func enforceMaximumSelectionCount() {
        guard let maximumSelectedDates, selectedDateValues.count > maximumSelectedDates else { return }
        let datesToRemove = Array(selectedDates.dropFirst(maximumSelectedDates))
        removeSelections(datesToRemove, notifyDelegate: true)
    }

    private func selectionPosition(for date: Date, style: TFYSwiftCalendarDayStyle) -> TFYSwiftCalendarSelectionPosition {
        if let position = style.selectionPosition { return position }
        guard selectedDateValues[dayKey(for: date)] != nil else { return .none }
        let previous = math.addingDays(-1, to: date)
        let next = math.addingDays(1, to: date)
        let previousSelected = selectedDateValues[dayKey(for: previous)] != nil &&
            calendar.component(.weekday, from: date) != firstWeekday
        let lastWeekday = (firstWeekday + 5) % 7 + 1
        let nextSelected = selectedDateValues[dayKey(for: next)] != nil &&
            calendar.component(.weekday, from: date) != lastWeekday
        switch (previousSelected, nextSelected) {
        case (false, false): return .single
        case (false, true): return .left
        case (true, true): return .middle
        case (true, false): return .right
        }
    }
}

extension TFYSwiftCalendar: UICollectionViewDataSource, UICollectionViewDelegate {
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        numberOfPages
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items(for: section).count
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader,
              let header = collectionView.dequeueReusableSupplementaryView(
                  ofKind: kind,
                  withReuseIdentifier: TFYSwiftCalendarSectionHeaderView.reuseIdentifier,
                  for: indexPath
              ) as? TFYSwiftCalendarSectionHeaderView else {
            return UICollectionReusableView()
        }
        let date = math.pageDate(at: indexPath.section, scope: scope, startingAt: minimumDate)
        header.update(date: date, calendar: calendar, locale: locale, appearance: appearance)
        return header
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let gridItem = item(at: indexPath), let date = gridItem.date else {
            return collectionView.dequeueReusableCell(withReuseIdentifier: Self.blankCellIdentifier, for: indexPath)
        }

        requestedCellIndexPath = indexPath
        let customCell = dataSource?.calendar(self, cellFor: date, at: gridItem.monthPosition)
        requestedCellIndexPath = nil
        let cell = customCell
            ?? collectionView.dequeueReusableCell(withReuseIdentifier: Self.defaultCellIdentifier, for: indexPath) as! TFYSwiftCalendarCell
        configure(cell, for: date, gridItem: gridItem)
        return cell
    }

    private func configure(
        _ cell: TFYSwiftCalendarCell,
        for date: Date,
        gridItem: TFYSwiftCalendarGridItem
    ) {
        let normalized = math.startOfDay(for: date)
        var state: TFYSwiftCalendarCellState = []
        if gridItem.monthPosition != .current { state.insert(.placeholder) }
        if !contains(normalized) { state.insert(.disabled) }
        if let today, math.isDate(normalized, inSameDayAs: today) { state.insert(.today) }
        if math.isWeekend(normalized) { state.insert(.weekend) }
        if selectedDateValues[dayKey(for: normalized)] != nil { state.insert(.selected) }

        let content = dataSource?.calendar(self, contentFor: normalized) ?? TFYSwiftCalendarDayContent()
        let style = delegate?.calendar(self, styleFor: normalized) ?? TFYSwiftCalendarDayStyle()
        cell.apply(
            date: normalized,
            monthPosition: gridItem.monthPosition,
            state: state,
            selectionPosition: selectionPosition(for: normalized, style: style),
            content: content,
            style: style,
            appearance: appearance,
            defaultTitle: String(calendar.component(.day, from: normalized)),
            defaultAccessibilityLabel: accessibilityDateFormatter.string(from: normalized)
        )
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        shouldSelectItemAt indexPath: IndexPath
    ) -> Bool {
        guard allowsSelection, let gridItem = item(at: indexPath), let date = gridItem.date, contains(date) else { return false }
        if selectedDateValues[dayKey(for: date)] != nil { return false }
        if allowsMultipleSelection,
           let maximumSelectedDates,
           selectedDateValues.count >= maximumSelectedDates {
            delegate?.calendar(self, didReachMaximumSelectionCount: maximumSelectedDates)
            return false
        }
        return delegate?.calendar(self, shouldSelect: date, at: gridItem.monthPosition) ?? true
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let gridItem = item(at: indexPath), let date = gridItem.date else { return }
        if !allowsMultipleSelection { removeAllSelections(except: date, notifyDelegate: true) }
        let normalized = math.startOfDay(for: date)
        selectedDateValues[dayKey(for: normalized)] = normalized
        refreshDates(around: normalized)
        (collectionView.cellForItem(at: indexPath) as? TFYSwiftCalendarCell)?.animateSelection()
        delegate?.calendar(self, didSelect: normalized, at: gridItem.monthPosition)
        if gridItem.monthPosition != .current { setCurrentPage(normalized, animated: true) }
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        shouldDeselectItemAt indexPath: IndexPath
    ) -> Bool {
        guard let gridItem = item(at: indexPath), let date = gridItem.date else { return false }
        return delegate?.calendar(self, shouldDeselect: date, at: gridItem.monthPosition) ?? true
    }

    public func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard let gridItem = item(at: indexPath), let date = gridItem.date else { return }
        let normalized = math.startOfDay(for: date)
        selectedDateValues.removeValue(forKey: dayKey(for: normalized))
        refreshDates(around: normalized)
        delegate?.calendar(self, didDeselect: normalized, at: gridItem.monthPosition)
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        guard let calendarCell = cell as? TFYSwiftCalendarCell, let date = calendarCell.representedDate else { return }
        if selectedDateValues[dayKey(for: date)] != nil {
            collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
        }
        delegate?.calendar(self, willDisplay: calendarCell, for: date)
    }
}

extension TFYSwiftCalendar: UIScrollViewDelegate {
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateCurrentPageFromScrollPosition()
    }

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        updateCurrentPageFromScrollPosition()
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate { updateCurrentPageFromScrollPosition() }
    }
}

extension TFYSwiftCalendar: UIGestureRecognizerDelegate {}
