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
            normalizeCalendarConfiguration()
            applyDefaultDateRangeIfNeeded()
            reloadData()
        }
    }

    public var locale: Locale = .current {
        didSet {
            calendar.locale = locale
        }
    }

    public var timeZone: TimeZone = .current {
        didSet {
            calendar.timeZone = timeZone
        }
    }

    public var firstWeekday: Int = Calendar.current.firstWeekday {
        didSet {
            firstWeekday = max(1, min(7, firstWeekday))
            calendar.firstWeekday = firstWeekday
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

    public var adjustsBoundingRectWhenChangingMonths = false

    public var pagingEnabled = true {
        didSet {
            collectionView.isPagingEnabled = pagingEnabled
            collectionViewLayout.invalidateLayout()
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

    public var visibleCells: [TFYSwiftCalendarCell] {
        collectionView.visibleCells.compactMap { $0 as? TFYSwiftCalendarCell }
    }

    public var preferredHeight: CGFloat {
        headerHeight + weekdayHeight + CGFloat(rowsOnCurrentPage) * rowHeight
    }

    private static let defaultCellIdentifier = "TFYSwiftCalendarCell"
    private static let blankCellIdentifier = "TFYSwiftCalendarBlankCell"

    private var configuredMinimumDate = Date(timeIntervalSince1970: 0)
    private var configuredMaximumDate = Date(timeIntervalSince1970: 4_102_444_799)
    private var usesDefaultDateRange = true
    private var selectedDateValues: [TFYSwiftCalendarDayKey: Date] = [:]
    private var pageCache: [Int: [TFYSwiftCalendarGridItem]] = [:]
    private var lastLaidOutSize = CGSize.zero
    private var isApplyingCalendarConfiguration = false
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
        switch scope {
        case .week:
            return 1
        case .month:
            return max(1, Int(ceil(Double(items(for: pageIndex(for: currentPage)).count) / 7.0)))
        }
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

        calendar.locale = locale
        calendar.timeZone = timeZone
        calendar.firstWeekday = firstWeekday
        applyDefaultDateRangeIfNeeded()

        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.isPagingEnabled = pagingEnabled
        collectionViewLayout.continuousRowHeight = rowHeight
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
        selectedDateValues = selectedDateValues.filter { key, _ in
            key >= dayKey(for: minimumDate) && key <= dayKey(for: maximumDate)
        }
        pageCache.removeAll(keepingCapacity: true)
        collectionView.reloadData()
        collectionViewLayout.invalidateLayout()
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
        collectionViewLayout.invalidateLayout()
        invalidateIntrinsicContentSize()
        let targetBounds = CGRect(x: bounds.minX, y: bounds.minY, width: bounds.width, height: preferredHeight)
        delegate?.calendar(self, boundingRectWillChange: targetBounds, animated: animated)

        let updates = {
            self.collectionView.alpha = 1
            self.superview?.layoutIfNeeded()
            self.layoutIfNeeded()
        }
        collectionView.alpha = animated ? 0.35 : 1
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
        guard allowsSelection, let date else { return }
        let normalized = math.startOfDay(for: date)
        guard contains(normalized) else { return }
        let position = monthPosition(for: normalized, relativeTo: canonicalPageDate(for: normalized))
        guard delegate?.calendar(self, shouldSelect: normalized, at: position) ?? true else { return }

        let key = dayKey(for: normalized)
        if selectedDateValues[key] != nil { return }
        if !allowsMultipleSelection {
            removeAllSelections(except: nil, notifyDelegate: true)
        }
        selectedDateValues[key] = normalized
        refreshDates(around: normalized)
        if scrollToDate { setCurrentPage(normalized, animated: true) }
        if let indexPath = indexPath(for: normalized) {
            collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
            (collectionView.cellForItem(at: indexPath) as? TFYSwiftCalendarCell)?.animateSelection()
        }
        UIAccessibility.post(notification: .announcement, argument: accessibilityDateFormatter.string(from: normalized))
        delegate?.calendar(self, didSelect: normalized, at: position)
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
        if replacingCurrentSelection { deselectAllDates() }
        let previousMultipleSelection = allowsMultipleSelection
        allowsMultipleSelection = true
        var date = lower
        while dayKey(for: date) <= dayKey(for: upper) {
            selectDate(date, scrollToDate: false)
            let next = math.addingDays(1, to: date)
            guard next > date else { break }
            date = next
        }
        allowsMultipleSelection = previousMultipleSelection || lower != upper
        if scrollToLastDate { setCurrentPage(upper, animated: true) }
    }

    public func reloadDates(_ dates: [Date]) {
        let paths = Set(dates.compactMap(indexPath(for:)))
        guard !paths.isEmpty else { return }
        collectionView.reloadItems(at: Array(paths))
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

    private func normalizeCalendarConfiguration() {
        guard !isApplyingCalendarConfiguration else { return }
        isApplyingCalendarConfiguration = true
        calendar.locale = locale
        calendar.timeZone = timeZone
        calendar.firstWeekday = max(1, min(7, firstWeekday))
        isApplyingCalendarConfiguration = false
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
        return result
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
        collectionView.reloadItems(at: paths)
    }

    private func refreshDates(around date: Date) {
        let candidates = [math.addingDays(-1, to: date), date, math.addingDays(1, to: date)]
        let paths = Set(candidates.compactMap(indexPath(for:)))
        let visible = paths.filter { collectionView.indexPathsForVisibleItems.contains($0) }
        if !visible.isEmpty { collectionView.reloadItems(at: Array(visible)) }
    }

    private func removeAllSelections(except preservedDate: Date?, notifyDelegate: Bool) {
        let preservedKey = preservedDate.map(dayKey(for:))
        let removals = selectedDateValues.filter { $0.key != preservedKey }
        for (key, date) in removals {
            selectedDateValues.removeValue(forKey: key)
            if let indexPath = indexPath(for: date) {
                collectionView.deselectItem(at: indexPath, animated: false)
            }
            if notifyDelegate {
                let position = monthPosition(for: date, relativeTo: canonicalPageDate(for: date))
                delegate?.calendar(self, didDeselect: date, at: position)
            }
            refreshDates(around: date)
        }
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
        return cell
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        shouldSelectItemAt indexPath: IndexPath
    ) -> Bool {
        guard allowsSelection, let gridItem = item(at: indexPath), let date = gridItem.date, contains(date) else { return false }
        if selectedDateValues[dayKey(for: date)] != nil { return false }
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
