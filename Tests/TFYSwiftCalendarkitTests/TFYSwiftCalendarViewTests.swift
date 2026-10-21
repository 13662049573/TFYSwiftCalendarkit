import XCTest
@testable import TFYSwiftCalendarkit

@MainActor
final class TFYSwiftCalendarViewTests: XCTestCase {
    private var systemCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.firstWeekday = 2
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        systemCalendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    func testSelectionHonorsSingleAndMultipleSelectionModes() {
        let view = makeCalendarView()
        let first = date(2024, 5, 5)
        let second = date(2024, 5, 6)

        view.selectDate(first, scrollToDate: false)
        view.selectDate(second, scrollToDate: false)
        XCTAssertEqual(view.selectedDates.count, 1)
        XCTAssertTrue(systemCalendar.isDate(view.selectedDates[0], inSameDayAs: second))

        view.allowsMultipleSelection = true
        view.selectDate(first, scrollToDate: false)
        XCTAssertEqual(view.selectedDates.count, 2)

        view.deselectDate(second)
        XCTAssertEqual(view.selectedDates.count, 1)
        XCTAssertTrue(systemCalendar.isDate(view.selectedDates[0], inSameDayAs: first))
    }

    func testOutOfRangeDateIsRejectedWithoutCrashing() {
        let view = makeCalendarView()
        let selected = date(2024, 5, 5)
        view.selectDate(selected, scrollToDate: false)
        view.selectDate(date(2030, 1, 1), scrollToDate: false)
        XCTAssertEqual(view.selectedDates.count, 1)
        XCTAssertTrue(view.isDateSelected(selected))
    }

    func testRejectedSingleSelectionPreservesCurrentDate() {
        let view = makeCalendarView()
        let selected = date(2024, 5, 5)
        view.selectDate(selected, scrollToDate: false)
        let spy = DelegateSpy()
        spy.allowsSelection = false
        view.delegate = spy

        view.selectDate(date(2024, 5, 6), scrollToDate: false)

        XCTAssertEqual(view.selectedDates.count, 1)
        XCTAssertTrue(view.isDateSelected(selected))
    }

    func testDefaultRangeUsesCivilDatesInConfiguredTimeZone() {
        let view = TFYSwiftCalendar()
        view.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        let lower = view.calendar.dateComponents([.year, .month, .day], from: view.minimumDate)
        let upper = view.calendar.dateComponents([.year, .month, .day], from: view.maximumDate)
        XCTAssertEqual(lower.year, 1970)
        XCTAssertEqual(lower.month, 1)
        XCTAssertEqual(lower.day, 1)
        XCTAssertEqual(upper.year, 2099)
        XCTAssertEqual(upper.month, 12)
        XCTAssertEqual(upper.day, 31)
    }

    func testScopeChangesPreferredHeightAndNotifiesDelegate() {
        let view = makeCalendarView()
        let spy = DelegateSpy()
        view.delegate = spy
        let monthHeight = view.preferredHeight

        view.setScope(.week, animated: false)

        XCTAssertEqual(view.scope, .week)
        XCTAssertLessThan(view.preferredHeight, monthHeight)
        XCTAssertEqual(spy.boundingRectChanges.count, 1)
        XCTAssertEqual(spy.boundingRectChanges[0].height, view.preferredHeight, accuracy: 0.1)
    }

    func testScopeGestureRequiresExplicitOptIn() {
        let view = makeCalendarView()

        XCTAssertFalse(view.allowsScopeGesture)
        XCTAssertFalse(view.scopeGestureRecognizer.isEnabled)

        view.allowsScopeGesture = true

        XCTAssertTrue(view.scopeGestureRecognizer.isEnabled)
    }

    func testDataSourceCanOverrideRangeAndContent() {
        let view = makeCalendarView()
        let source = DataSourceStub(
            minimum: date(2024, 4, 1),
            maximum: date(2024, 4, 30)
        )
        view.dataSource = source
        view.reloadData()

        XCTAssertTrue(systemCalendar.isDate(view.minimumDate, inSameDayAs: source.minimum))
        XCTAssertTrue(systemCalendar.isDate(view.maximumDate, inSameDayAs: source.maximum))
        XCTAssertEqual(source.calendar(view, contentFor: date(2024, 4, 3)).subtitle, "Event")
    }

    func testCurrentPageIsClampedToRange() {
        let view = makeCalendarView()
        view.setCurrentPage(date(2030, 1, 1), animated: false)
        XCTAssertTrue(systemCalendar.isDate(view.currentPage, equalTo: date(2024, 12, 1), toGranularity: .month))
    }

    func testVisibleCellReceivesContentAndAccessibilityConfiguration() {
        let view = makeCalendarView()
        let source = DataSourceStub(
            minimum: date(2024, 1, 1),
            maximum: date(2024, 12, 31)
        )
        view.dataSource = source
        view.reloadData()
        view.layoutIfNeeded()
        view.collectionView.layoutIfNeeded()

        let cell = view.cell(for: date(2024, 5, 5))
        XCTAssertNotNil(cell)
        XCTAssertEqual(cell?.subtitleLabel.text, "Event")
        XCTAssertFalse(cell?.accessibilityLabel?.isEmpty ?? true)
    }

    func testRangeSelectionCreatesAContiguousSet() {
        let view = makeCalendarView()
        let spy = DelegateSpy()
        view.delegate = spy
        view.selectDates(
            from: date(2024, 5, 5),
            through: date(2024, 5, 9),
            replacingCurrentSelection: true,
            scrollToLastDate: false
        )
        XCTAssertEqual(view.selectedDates.count, 5)
        XCTAssertEqual(spy.selectedDates.count, 5)
        XCTAssertEqual(view.selectedDateBounds?.lowerBound, view.selectedDates.first)
        XCTAssertEqual(view.selectedDateBounds?.upperBound, view.selectedDates.last)
        XCTAssertTrue(view.isDateSelected(date(2024, 5, 7)))
    }

    func testBatchSelectionReplacesExistingDatesInOneOperation() {
        let view = makeCalendarView()
        view.allowsMultipleSelection = true
        view.selectDate(date(2024, 4, 1), scrollToDate: false)

        view.selectDates(
            [date(2024, 5, 2), date(2024, 5, 3), date(2024, 5, 3)],
            replacingCurrentSelection: true
        )

        XCTAssertEqual(view.selectedDates.count, 2)
        XCTAssertFalse(view.isDateSelected(date(2024, 4, 1)))
        XCTAssertTrue(view.isDateSelected(date(2024, 5, 2)))
        XCTAssertTrue(view.isDateSelected(date(2024, 5, 3)))
    }

    func testReplacingBatchRetainsDatesAlreadyInRequestedSelection() {
        let view = makeCalendarView()
        view.allowsMultipleSelection = true
        let retained = date(2024, 5, 1)
        view.selectDate(retained, scrollToDate: false)

        view.selectDates(
            [retained, date(2024, 5, 2)],
            replacingCurrentSelection: true
        )

        XCTAssertEqual(view.selectedDates.count, 2)
        XCTAssertTrue(view.isDateSelected(retained))
        XCTAssertTrue(view.isDateSelected(date(2024, 5, 2)))
    }

    func testMaximumSelectionCountCapsBatchAndTrimsExistingSelection() {
        let view = makeCalendarView()
        let spy = DelegateSpy()
        view.delegate = spy
        view.allowsMultipleSelection = true
        view.maximumSelectedDates = 2

        view.selectDates(
            [date(2024, 5, 1), date(2024, 5, 2), date(2024, 5, 3)],
            replacingCurrentSelection: true
        )

        XCTAssertEqual(view.selectedDates.count, 2)
        XCTAssertEqual(spy.reachedSelectionLimits, [2])

        view.maximumSelectedDates = 1
        XCTAssertEqual(view.selectedDates.count, 1)
    }

    func testEmptyEventColorArrayIsSafe() {
        let indicator = TFYSwiftCalendarEventIndicator(frame: CGRect(x: 0, y: 0, width: 80, height: 8))
        indicator.colors = []
        indicator.layoutIfNeeded()
        XCTAssertTrue(indicator.layer.sublayers?.isEmpty ?? true)
    }

    func testEventIndicatorReusesLayersAcrossLayouts() {
        let indicator = TFYSwiftCalendarEventIndicator(frame: CGRect(x: 0, y: 0, width: 80, height: 8))
        indicator.colors = [.systemRed, .systemBlue, .systemGreen]
        indicator.layoutIfNeeded()
        let initialLayers = indicator.layer.sublayers ?? []

        indicator.frame.size.width = 120
        indicator.setNeedsLayout()
        indicator.layoutIfNeeded()
        let updatedLayers = indicator.layer.sublayers ?? []

        XCTAssertEqual(initialLayers.count, 3)
        XCTAssertEqual(updatedLayers.count, 3)
        XCTAssertTrue(zip(initialLayers, updatedLayers).allSatisfy { $0 === $1 })
    }

    func testEventIndicatorUsesCenteredSlotBelowSubtitle() {
        let cell = TFYSwiftCalendarCell(frame: CGRect(x: 0, y: 0, width: 70, height: 60))
        cell.apply(
            date: date(2024, 5, 5),
            monthPosition: .current,
            state: [],
            selectionPosition: .none,
            content: TFYSwiftCalendarDayContent(subtitle: "廿七", eventColors: [.systemRed, .systemBlue]),
            style: TFYSwiftCalendarDayStyle(),
            appearance: TFYSwiftCalendarAppearance(),
            defaultTitle: "5",
            defaultAccessibilityLabel: "May 5, 2024"
        )

        cell.layoutIfNeeded()

        XCTAssertFalse(cell.eventIndicator.isHidden)
        XCTAssertEqual(cell.eventIndicator.frame.midX, cell.contentView.bounds.midX, accuracy: 0.01)
        XCTAssertLessThanOrEqual(cell.titleLabel.frame.maxY, cell.subtitleLabel.frame.minY)
        XCTAssertLessThanOrEqual(cell.subtitleLabel.frame.maxY, cell.eventIndicator.frame.minY)
    }

    func testChineseSingleCharacterWeekdaysRemainDistinct() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "zh_CN")
        calendar.firstWeekday = 2
        let appearance = TFYSwiftCalendarAppearance()
        appearance.caseOptions = [.weekdaySingleCharacter]
        let weekdayView = TFYSwiftCalendarWeekdayView()

        weekdayView.update(calendar: calendar, locale: Locale(identifier: "zh_CN"), appearance: appearance)

        XCTAssertEqual(weekdayView.weekdayLabels.compactMap(\.text), ["一", "二", "三", "四", "五", "六", "日"])
    }

    func testWeekdayBarSupportsPerDaySymbolsColorsAndPillStyling() {
        var calendar = systemCalendar
        calendar.firstWeekday = 2
        let appearance = TFYSwiftCalendarAppearance()
        appearance.weekdaySymbols = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        appearance.weekdayTextColors = [
            .systemRed, .systemBlue, .systemGreen, .systemOrange,
            .systemPurple, .systemTeal, .systemPink
        ]
        appearance.weekdayLabelBackgroundColors = [
            .systemGray, .systemGray2, .systemGray3, .systemGray4,
            .systemGray5, .systemGray6, .systemBrown
        ]
        appearance.weekdaySpacing = 4
        appearance.weekdayContentInsets = UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6)
        appearance.weekdayLabelCornerRadius = 9
        appearance.weekdayLabelBorderColor = .systemIndigo
        appearance.weekdayLabelBorderWidth = 1.5
        let weekdayView = TFYSwiftCalendarWeekdayView()

        weekdayView.update(calendar: calendar, locale: Locale(identifier: "en_US"), appearance: appearance)

        XCTAssertEqual(weekdayView.weekdayLabels.compactMap(\.text), ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"])
        XCTAssertTrue(weekdayView.weekdayLabels[0].textColor.isEqual(UIColor.systemBlue))
        XCTAssertTrue(weekdayView.weekdayLabels[6].backgroundColor?.isEqual(UIColor.systemGray) == true)
        XCTAssertEqual(weekdayView.weekdayLabels[0].layer.cornerRadius, 9)
        XCTAssertEqual(weekdayView.weekdayLabels[0].layer.borderWidth, 1.5)
        XCTAssertEqual(weekdayView.stackView.spacing, 0)
        XCTAssertEqual(weekdayView.stackView.layoutMargins, .zero)

        weekdayView.frame = CGRect(x: 0, y: 0, width: 350, height: 40)
        weekdayView.layoutIfNeeded()

        XCTAssertEqual(weekdayView.stackView.spacing, 4)
        XCTAssertEqual(weekdayView.stackView.layoutMargins, appearance.weekdayContentInsets)
    }

    func testDenseCalendarLabelsCapDynamicTypeWithoutDisablingIt() {
        let cell = TFYSwiftCalendarCell()
        let header = TFYSwiftCalendarHeaderView()
        let weekday = TFYSwiftCalendarWeekdayView()

        XCTAssertTrue(cell.titleLabel.adjustsFontForContentSizeCategory)
        XCTAssertEqual(cell.titleLabel.maximumContentSizeCategory, .extraExtraLarge)
        XCTAssertTrue(header.titleLabel.adjustsFontForContentSizeCategory)
        XCTAssertEqual(header.titleLabel.maximumContentSizeCategory, .extraExtraExtraLarge)
        XCTAssertTrue(weekday.weekdayLabels.allSatisfy(\.adjustsFontForContentSizeCategory))
        XCTAssertTrue(weekday.weekdayLabels.allSatisfy { $0.maximumContentSizeCategory == .extraExtraLarge })
    }

    func testCircularBorderFactoryCreatesRoundedSeparateStyle() {
        let style = TFYSwiftCalendarDayStyle.circularBorder(
            borderColor: .systemIndigo,
            borderWidth: 2.5,
            selectionFillColor: .systemIndigo
        )

        XCTAssertEqual(style.fillType, .separate)
        XCTAssertEqual(style.borderRadius, 1)
        XCTAssertEqual(style.borderWidth, 2.5)
        XCTAssertEqual(style.selectionBorderWidth, 2.5)
        XCTAssertTrue(style.fillColor?.isEqual(UIColor.clear) == true)
        XCTAssertTrue(style.borderColor?.isEqual(UIColor.systemIndigo) == true)
    }

    func testBorderedFactorySupportsCircleRoundedAndSquareShapes() {
        let circle = TFYSwiftCalendarDayStyle.bordered(
            shape: .circle,
            borderColor: .systemIndigo
        )
        let rounded = TFYSwiftCalendarDayStyle.bordered(
            shape: .rounded(cornerRadiusRatio: 0.35),
            borderColor: .systemTeal
        )
        let square = TFYSwiftCalendarDayStyle.squareBorder(
            borderColor: .systemOrange,
            borderWidth: -2
        )

        XCTAssertEqual(circle.borderRadius, 1)
        XCTAssertEqual(rounded.borderRadius, 0.35)
        XCTAssertEqual(square.borderRadius, 0)
        XCTAssertEqual(square.borderWidth, 0)
        XCTAssertEqual(square.selectionBorderWidth, 0)
    }

    func testCompletedPageChangeReconfiguresLegacyPageAwareContentInPlace() {
        let view = makeCalendarView()
        let source = CurrentPageAwareDataSource()
        view.dataSource = source
        view.reloadData()
        view.layoutIfNeeded()
        view.collectionView.layoutIfNeeded()

        let destinationDate = date(2024, 6, 6)
        let destinationOffset = CGPoint(
            x: view.collectionView.contentOffset.x + view.collectionView.bounds.width,
            y: 0
        )
        view.collectionView.setContentOffset(destinationOffset, animated: false)
        view.collectionView.layoutIfNeeded()
        let cellBeforePageUpdate = view.cell(for: destinationDate)

        XCTAssertNotNil(cellBeforePageUpdate)
        XCTAssertNil(cellBeforePageUpdate?.subtitleLabel.text)

        view.scrollViewDidEndDecelerating(view.collectionView)

        let cellAfterPageUpdate = view.cell(for: destinationDate)
        XCTAssertTrue(cellBeforePageUpdate === cellAfterPageUpdate)
        XCTAssertEqual(cellAfterPageUpdate?.subtitleLabel.text, "Badge")
        XCTAssertTrue(systemCalendar.isDate(view.currentPage, equalTo: destinationDate, toGranularity: .month))
    }

    func testPositionAwareContentReceivesStableGridPosition() {
        let view = makeCalendarView()
        let source = PositionAwareDataSource()
        view.dataSource = source
        view.reloadData()
        view.layoutIfNeeded()
        view.collectionView.layoutIfNeeded()

        XCTAssertEqual(view.cell(for: date(2024, 5, 6))?.subtitleLabel.text, "current")
        XCTAssertNil(view.cell(for: date(2024, 4, 29), at: .previous)?.subtitleLabel.text)
        XCTAssertTrue(source.receivedPositions.contains(.current))
        XCTAssertTrue(source.receivedPositions.contains(.previous))
    }

    func testPerDateBorderWidthIsAppliedToCellLayer() {
        let cell = TFYSwiftCalendarCell(frame: CGRect(x: 0, y: 0, width: 54, height: 54))
        let appearance = TFYSwiftCalendarAppearance()
        let style = TFYSwiftCalendarDayStyle.circularBorder(
            borderColor: .systemTeal,
            borderWidth: 3,
            selectionFillColor: .systemTeal
        )

        cell.apply(
            date: date(2024, 5, 11),
            monthPosition: .current,
            state: [],
            selectionPosition: .none,
            content: TFYSwiftCalendarDayContent(),
            style: style,
            appearance: appearance,
            defaultTitle: "11",
            defaultAccessibilityLabel: "May 11, 2024"
        )
        cell.layoutIfNeeded()

        XCTAssertEqual(cell.shapeLayer.lineWidth, 3)
        let pathBounds = cell.shapeLayer.path?.boundingBox ?? .zero
        XCTAssertEqual(pathBounds.width, pathBounds.height, accuracy: 0.001)
    }

    func testPrepareForReuseRemovesPendingCellAndShapeAnimations() {
        let cell = TFYSwiftCalendarCell()
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.duration = 1
        cell.layer.add(animation, forKey: "cell-fade")
        cell.shapeLayer.add(animation, forKey: "shape-fade")

        cell.prepareForReuse()

        XCTAssertNil(cell.layer.animationKeys())
        XCTAssertNil(cell.shapeLayer.animationKeys())
    }

    func testNonPagingVerticalLayoutUsesCompactContinuousSections() {
        let view = TFYSwiftCalendar(frame: CGRect(x: 0, y: 0, width: 390, height: 700))
        view.calendar = systemCalendar
        view.configuredDateRange = date(2024, 1, 1)...date(2024, 3, 31)
        view.placeholderType = .fillSixRows
        view.rowHeight = 50
        view.continuousSectionHeaderHeight = 44
        view.pagingEnabled = false
        view.scrollDirection = .vertical
        view.reloadData()
        view.layoutIfNeeded()
        view.collectionView.layoutIfNeeded()

        let firstCell = view.collectionViewLayout.layoutAttributesForItem(at: IndexPath(item: 0, section: 0))
        XCTAssertEqual(firstCell?.frame.height ?? 0, 50, accuracy: 0.1)
        XCTAssertEqual(firstCell?.frame.minY ?? 0, 44, accuracy: 0.1)
        let secondCell = view.collectionViewLayout.layoutAttributesForItem(at: IndexPath(item: 1, section: 0))
        XCTAssertEqual(firstCell?.frame.maxX ?? 0, secondCell?.frame.minX ?? -1, accuracy: 0.001)
        XCTAssertEqual(firstCell?.frame.intersection(secondCell?.frame ?? .zero).width ?? -1, 0, accuracy: 0.001)
        let firstCellOfSecondRow = view.collectionViewLayout.layoutAttributesForItem(
            at: IndexPath(item: 7, section: 0)
        )
        XCTAssertEqual(firstCell?.frame.maxY ?? 0, firstCellOfSecondRow?.frame.minY ?? -1, accuracy: 0.001)
        let firstHeader = view.collectionViewLayout.layoutAttributesForSupplementaryView(
            ofKind: UICollectionView.elementKindSectionHeader,
            at: IndexPath(item: 0, section: 0)
        )
        XCTAssertEqual(firstHeader?.frame.height ?? 0, 44, accuracy: 0.1)
        XCTAssertLessThan(view.collectionView.contentSize.height, view.collectionView.bounds.height * 3)

        view.collectionView.contentOffset.y = 120
        let pinnedHeader = view.collectionViewLayout.layoutAttributesForSupplementaryView(
            ofKind: UICollectionView.elementKindSectionHeader,
            at: IndexPath(item: 0, section: 0)
        )
        XCTAssertEqual(pinnedHeader?.frame.minY ?? 0, 120, accuracy: 0.1)

        view.setCurrentPage(date(2024, 3, 1), animated: false)
        XCTAssertEqual(view.collectionView.contentOffset.y, 688, accuracy: 0.1)
    }

    func testLargeContinuousRangeDoesNotMaterializeEveryPage() {
        let view = TFYSwiftCalendar(frame: CGRect(x: 0, y: 0, width: 390, height: 700))
        view.calendar = systemCalendar
        view.pagingEnabled = false
        view.scrollDirection = .vertical
        view.layoutIfNeeded()
        view.collectionView.layoutIfNeeded()

        XCTAssertLessThanOrEqual(view.cachedPageCount, 48)
        XCTAssertGreaterThan(view.collectionView.numberOfSections, 1_000)
    }

    func testCalendarConfigurationReloadsDataSourceOnce() {
        let view = makeCalendarView()
        let source = CountingDataSource()
        view.dataSource = source

        view.locale = Locale(identifier: "zh_CN")

        XCTAssertEqual(source.minimumRequestCount, 1)
        XCTAssertEqual(source.maximumRequestCount, 1)
        XCTAssertEqual(view.calendar.locale?.identifier, "zh_CN")
    }

    func testPlaceholderOccurrenceCanBeQueriedExplicitly() {
        let view = makeCalendarView()
        view.setCurrentPage(date(2024, 6, 1), animated: false)
        view.layoutIfNeeded()
        view.collectionView.layoutIfNeeded()

        let placeholder = view.cell(for: date(2024, 5, 31), at: .previous)

        XCTAssertNotNil(placeholder)
        XCTAssertEqual(placeholder?.monthPosition, .previous)
        XCTAssertNotNil(view.frame(for: date(2024, 5, 31), at: .previous))
    }

    func testCustomCellsCanBeDequeuedForBoundaryPlaceholders() {
        let view = TFYSwiftCalendar(frame: CGRect(x: 0, y: 0, width: 390, height: 300))
        view.calendar = systemCalendar
        view.configuredDateRange = date(2024, 5, 1)...date(2024, 5, 31)
        view.placeholderType = .fillHeadTail
        view.register(TestCalendarCell.self, forCellReuseIdentifier: "custom")
        let source = CustomCellDataSource()
        view.dataSource = source
        view.reloadData()
        view.setCurrentPage(date(2024, 5, 1), animated: false)
        view.layoutIfNeeded()
        view.collectionView.layoutIfNeeded()

        XCTAssertGreaterThan(source.dequeuedCellCount, 0)
        XCTAssertTrue(view.visibleCells.contains { $0 is TestCalendarCell })
    }

    func testSelectionUpdatesVisibleCustomCellWithoutRedequeueing() {
        let view = makeCalendarView()
        view.register(TestCalendarCell.self, forCellReuseIdentifier: "custom")
        let source = CustomCellDataSource()
        view.dataSource = source
        view.reloadData()
        view.layoutIfNeeded()
        view.collectionView.layoutIfNeeded()
        let selectedDate = date(2024, 5, 11)
        let originalCell = view.cell(for: selectedDate)
        let dequeueCount = source.dequeuedCellCount

        view.selectDate(selectedDate, scrollToDate: false)

        let updatedCell = view.cell(for: selectedDate)
        XCTAssertTrue(originalCell === updatedCell)
        XCTAssertTrue(updatedCell?.cellState.contains(.selected) == true)
        XCTAssertEqual(source.dequeuedCellCount, dequeueCount)
    }


    func testRepeatedContentTogglesPreserveCellsSelectionAndScrollPosition() {
        for continuous in [false, true] {
            let view = makeCalendarView()
            if continuous {
                view.scrollDirection = .vertical
                view.pagingEnabled = false
            }
            view.register(TestCalendarCell.self, forCellReuseIdentifier: "custom")
            let source = CustomCellDataSource()
            view.dataSource = source
            view.reloadData()
            view.allowsMultipleSelection = true
            view.appearance.fillType = .linked
            view.selectDates([date(2024, 5, 15), date(2024, 5, 16), date(2024, 5, 17)], scrollToLastDate: false)
            view.layoutIfNeeded()
            view.collectionView.layoutIfNeeded()
            let originalCells = view.visibleCells
            XCTAssertFalse(originalCells.isEmpty)
            let dequeueCount = source.dequeuedCellCount
            let selectedDates = view.selectedDates
            let page = view.currentPage
            let offset = view.collectionView.contentOffset
            let height = view.preferredHeight

            for toggle in 0..<20 {
                source.subtitle = toggle.isMultiple(of: 2) ? "农历" : nil
                source.eventColors = toggle.isMultiple(of: 3) ? [.systemRed, .systemBlue] : []
                view.reloadVisibleDates()
                XCTAssertEqual(source.dequeuedCellCount, dequeueCount)
                XCTAssertEqual(view.selectedDates, selectedDates)
                XCTAssertEqual(view.currentPage, page)
                XCTAssertEqual(view.collectionView.contentOffset, offset)
                XCTAssertEqual(view.preferredHeight, height)
                for cell in originalCells {
                    XCTAssertTrue(view.cell(for: cell.representedDate!, at: cell.monthPosition) === cell)
                    XCTAssertEqual(cell.subtitleLabel.text, source.subtitle)
                    XCTAssertEqual(cell.eventIndicator.colors, source.eventColors)
                    XCTAssertEqual(cell.isSelected, view.isDateSelected(cell.representedDate!))
                }
            }
        }
    }

    func testDefaultRangeKeepsGregorianYearsWhenUsingChineseCalendar() {
        let view = TFYSwiftCalendar()
        var chinese = Calendar(identifier: .chinese)
        chinese.timeZone = systemCalendar.timeZone
        view.calendar = chinese
        XCTAssertEqual(systemCalendar.component(.year, from: view.minimumDate), 1970)
        XCTAssertEqual(systemCalendar.component(.year, from: view.maximumDate), 2099)
    }

    func testScopeSwitchPreservesRequestedDayAndSelectedWeek() {
        let view = makeCalendarView()
        let requested = date(2024, 5, 22)
        view.setCurrentPage(requested, animated: false)
        view.setScope(.week, animated: false)
        XCTAssertTrue(view.calendar.isDate(view.currentPage, equalTo: requested, toGranularity: .weekOfYear))
        view.selectDate(date(2024, 5, 24), scrollToDate: false)
        view.setScope(.month, animated: false)
        view.setScope(.week, animated: false)
        XCTAssertTrue(view.calendar.isDate(view.currentPage, equalTo: requested, toGranularity: .weekOfYear))
    }

    func testLayoutModeChangesKeepCurrentPageAligned() {
        let view = makeCalendarView()
        view.scrollDirection = .vertical
        view.layoutIfNeeded()
        XCTAssertEqual(view.collectionView.contentOffset.y, view.collectionView.bounds.height * 4, accuracy: 0.1)
        view.pagingEnabled = false
        view.rowHeight = 50
        view.continuousSectionHeaderHeight = 44
        view.sectionInsets = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)
        view.layoutIfNeeded()
        view.collectionView.layoutIfNeeded()
        XCTAssertEqual(view.collectionView.contentOffset.y, (300 + 44 + 16) * 4, accuracy: 0.1)
        XCTAssertEqual(view.calendar.component(.month, from: view.currentPage), 5)
    }

    func testReselectingDateCanNavigateBackToItsPage() {
        let view = makeCalendarView()
        let selected = date(2024, 5, 11)
        view.selectDate(selected, scrollToDate: false)
        view.setCurrentPage(date(2024, 9, 1), animated: false)
        view.selectDate(selected, scrollToDate: true)
        XCTAssertEqual(view.calendar.component(.month, from: view.currentPage), 5)
    }

    func testDisabledSelectionRejectsUserDeselection() {
        let view = makeCalendarView()
        view.selectDate(date(2024, 5, 11), scrollToDate: false)
        view.allowsSelection = false
        let path = IndexPath(item: 12, section: 4) // May 11 with Monday first
        XCTAssertFalse(view.collectionView(view.collectionView, shouldDeselectItemAt: path))
    }

    func testInvalidLayoutMetricsAreSanitized() {
        let view = makeCalendarView()
        view.headerHeight = -10
        view.weekdayHeight = .nan
        view.rowHeight = -.infinity
        view.continuousSectionHeaderHeight = .infinity
        view.sectionInsets = UIEdgeInsets(top: -50, left: .nan, bottom: 0, right: 0)
        view.layoutIfNeeded()
        XCTAssertGreaterThanOrEqual(view.preferredHeight, 0)
        XCTAssertTrue(view.preferredHeight.isFinite)
        XCTAssertTrue(view.collectionView.frame.width.isFinite)
        XCTAssertEqual(view.headerHeight, 0)
        XCTAssertEqual(view.sectionInsets.top, 0)
        XCTAssertEqual(view.sectionInsets.left, 0)
    }

    func testRangeSelectionStopsAtLimitWithoutCheckingEveryDay() {
        let view = makeCalendarView()
        let spy = DelegateSpy()
        view.delegate = spy
        view.maximumSelectedDates = 3
        view.selectDates(from: date(2024, 1, 1), through: date(2024, 12, 31), scrollToLastDate: false)
        XCTAssertEqual(view.selectedDates.count, 3)
        XCTAssertEqual(spy.selectionRequestCount, 4)
        XCTAssertEqual(spy.selectionChangeCount, 1)
        XCTAssertEqual(spy.reachedSelectionLimits, [3])
    }

    func testSelectionChangeCallbackReportsFinalReplacementAndRangePruning() {
        let view = makeCalendarView()
        let spy = DelegateSpy()
        view.delegate = spy
        view.allowsMultipleSelection = true
        view.selectDates([date(2024, 5, 1), date(2024, 5, 2)])
        XCTAssertEqual(spy.selectionChangeCount, 1)
        view.selectDates([date(2024, 6, 1), date(2024, 6, 2)], replacingCurrentSelection: true)
        XCTAssertEqual(spy.selectionChangeCount, 2)
        XCTAssertEqual(spy.lastSelection, view.selectedDates)
        view.configuredDateRange = date(2024, 1, 1)...date(2024, 5, 31)
        XCTAssertEqual(spy.selectionChangeCount, 3)
        XCTAssertEqual(spy.lastSelection, [])
    }

    func testChineseLeapMonthRangeAndSelectionUseAbsoluteDays() {
        let view = makeCalendarView()
        var chinese = Calendar(identifier: .chinese)
        chinese.timeZone = systemCalendar.timeZone
        view.calendar = chinese
        view.configuredDateRange = date(2023, 2, 20)...date(2023, 4, 19)
        view.allowsMultipleSelection = true
        view.selectDates([date(2023, 2, 20), date(2023, 3, 22)])
        XCTAssertEqual(view.selectedDates.count, 2)
        view.selectDates(from: date(2023, 3, 20), through: date(2023, 3, 24), scrollToLastDate: false)
        XCTAssertEqual(view.selectedDates.count, 5)
        XCTAssertTrue(view.isDateSelected(date(2023, 3, 22)))
    }

    func testInvalidIndexPathsReturnNilInsteadOfQueryingCollectionView() {
        let view = makeCalendarView()
        XCTAssertNil(view.collectionViewLayout.layoutAttributesForItem(at: IndexPath(item: 0, section: 1000)))
        XCTAssertNil(view.collectionViewLayout.layoutAttributesForItem(at: IndexPath(item: -1, section: 0)))
    }

    func testRightToLeftPagingShowsRequestedMonth() {
        let view = makeCalendarView()
        view.semanticContentAttribute = .forceRightToLeft
        view.collectionView.semanticContentAttribute = .forceRightToLeft
        view.collectionViewLayout.invalidateDataSourceMetrics()
        view.setCurrentPage(date(2024, 7, 15), animated: false)
        view.layoutIfNeeded()
        view.collectionView.layoutIfNeeded()
        XCTAssertNotNil(view.cell(for: date(2024, 7, 15)))
        XCTAssertEqual(view.calendar.component(.month, from: view.currentPage), 7)
        let width = view.collectionView.bounds.width
        XCTAssertEqual(view.collectionView.contentOffset.x, width * 5, accuracy: 0.1)
        let first = view.collectionViewLayout.layoutAttributesForItem(at: IndexPath(item: 0, section: 6))
        let last = view.collectionViewLayout.layoutAttributesForItem(at: IndexPath(item: 6, section: 6))
        XCTAssertGreaterThan(first?.frame.minX ?? 0, last?.frame.minX ?? 0)
        view.setCurrentPage(date(2024, 8, 15), animated: false)
        view.collectionView.layoutIfNeeded()
        XCTAssertNotNil(view.cell(for: date(2024, 8, 15)))
        view.collectionView.setContentOffset(CGPoint(x: width * 5, y: 0), animated: false)
        view.scrollViewDidEndDecelerating(view.collectionView)
        XCTAssertEqual(view.calendar.component(.month, from: view.currentPage), 7)
    }

    func testPlaceholderCopiesShareCollectionSelectionState() {
        let view = makeCalendarView()
        view.scrollDirection = .vertical
        view.pagingEnabled = false
        view.frame.size.height = 700
        view.setCurrentPage(date(2024, 5, 1), animated: false)
        view.layoutIfNeeded()
        view.collectionView.layoutIfNeeded()
        let selected = date(2024, 5, 31)
        view.selectDate(selected, scrollToDate: false)
        let current = view.cell(for: selected, at: .current)
        let placeholder = view.cell(for: selected, at: .previous)
        XCTAssertNotNil(current)
        XCTAssertNotNil(placeholder)
        XCTAssertTrue(current?.isSelected == true)
        XCTAssertTrue(placeholder?.isSelected == true)
        view.deselectDate(selected)
        XCTAssertFalse(current?.isSelected == true)
        XCTAssertFalse(placeholder?.isSelected == true)
    }

    func testHiddenPlaceholdersDoNotJoinSelectionAcrossMonths() {
        let view = makeCalendarView()
        view.placeholderType = .none
        view.selectDates(from: date(2024, 5, 31), through: date(2024, 6, 1), scrollToLastDate: false)
        XCTAssertEqual(view.cell(for: date(2024, 5, 31))?.selectionPosition, .single)
    }

    func testCalendarLocaleControlsAccessibilityStringsAndStyleEventCount() {
        let view = makeCalendarView()
        view.locale = Locale(identifier: "zh_CN")
        view.today = date(2024, 5, 11)
        view.selectDate(date(2024, 5, 11), scrollToDate: false)
        let cell = view.cell(for: date(2024, 5, 11))
        XCTAssertTrue(cell?.accessibilityValue?.contains("今天") == true)
        XCTAssertEqual(view.calendarHeaderView.nextButton.accessibilityLabel, "下一页")

        let eventCell = TFYSwiftCalendarCell(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        var style = TFYSwiftCalendarDayStyle()
        style.eventColors = [.systemBlue, .systemRed]
        eventCell.apply(date: date(2024, 5, 11), monthPosition: .current, state: [], selectionPosition: .none,
                        content: .init(), style: style, appearance: view.appearance,
                        defaultTitle: "11", defaultAccessibilityLabel: "May 11", locale: Locale(identifier: "en_US"))
        XCTAssertEqual(eventCell.accessibilityValue, "2 events")
    }
    private func makeCalendarView() -> TFYSwiftCalendar {
        let view = TFYSwiftCalendar(frame: CGRect(x: 0, y: 0, width: 390, height: 300))
        view.calendar = systemCalendar
        view.locale = Locale(identifier: "en_US_POSIX")
        view.timeZone = TimeZone(secondsFromGMT: 0)!
        view.firstWeekday = 2
        view.configuredDateRange = date(2024, 1, 1)...date(2024, 12, 31)
        view.setCurrentPage(date(2024, 5, 1), animated: false)
        view.layoutIfNeeded()
        return view
    }
}

@MainActor
private final class DelegateSpy: TFYSwiftCalendarDelegate {
    var boundingRectChanges: [CGRect] = []
    var selectedDates: [Date] = []
    var reachedSelectionLimits: [Int] = []
    var allowsSelection = true
    var selectionRequestCount = 0
    var selectionChangeCount = 0
    var lastSelection: [Date] = []

    func calendar(
        _ calendar: TFYSwiftCalendar,
        shouldSelect date: Date,
        at monthPosition: TFYSwiftCalendarMonthPosition
    ) -> Bool {
        selectionRequestCount += 1
        return allowsSelection
    }

    func calendarSelectionDidChange(_ calendar: TFYSwiftCalendar) {
        selectionChangeCount += 1
        lastSelection = calendar.selectedDates
    }

    func calendar(_ calendar: TFYSwiftCalendar, boundingRectWillChange bounds: CGRect, animated: Bool) {
        boundingRectChanges.append(bounds)
    }

    func calendar(
        _ calendar: TFYSwiftCalendar,
        didSelect date: Date,
        at monthPosition: TFYSwiftCalendarMonthPosition
    ) {
        selectedDates.append(date)
    }

    func calendar(_ calendar: TFYSwiftCalendar, didReachMaximumSelectionCount maximum: Int) {
        reachedSelectionLimits.append(maximum)
    }
}

@MainActor
private final class DataSourceStub: TFYSwiftCalendarDataSource {
    let minimum: Date
    let maximum: Date

    init(minimum: Date, maximum: Date) {
        self.minimum = minimum
        self.maximum = maximum
    }

    func minimumDate(for calendar: TFYSwiftCalendar) -> Date? { minimum }
    func maximumDate(for calendar: TFYSwiftCalendar) -> Date? { maximum }

    func calendar(_ calendar: TFYSwiftCalendar, contentFor date: Date) -> TFYSwiftCalendarDayContent {
        TFYSwiftCalendarDayContent(subtitle: "Event")
    }
}

@MainActor
private final class CurrentPageAwareDataSource: TFYSwiftCalendarDataSource {
    func calendar(_ calendar: TFYSwiftCalendar, contentFor date: Date) -> TFYSwiftCalendarDayContent {
        guard calendar.calendar.isDate(date, equalTo: calendar.currentPage, toGranularity: .month),
              calendar.calendar.component(.day, from: date) == 6 else {
            return TFYSwiftCalendarDayContent()
        }
        return TFYSwiftCalendarDayContent(subtitle: "Badge")
    }
}

@MainActor
private final class PositionAwareDataSource: TFYSwiftCalendarDataSource {
    var receivedPositions = Set<TFYSwiftCalendarMonthPosition>()

    func calendar(
        _ calendar: TFYSwiftCalendar,
        contentFor date: Date,
        at monthPosition: TFYSwiftCalendarMonthPosition
    ) -> TFYSwiftCalendarDayContent {
        receivedPositions.insert(monthPosition)
        return TFYSwiftCalendarDayContent(
            subtitle: monthPosition == .current ? "current" : nil
        )
    }
}

@MainActor
private final class TestCalendarCell: TFYSwiftCalendarCell {}

@MainActor
private final class CustomCellDataSource: TFYSwiftCalendarDataSource {
    var dequeuedCellCount = 0
    var subtitle: String?
    var eventColors: [UIColor] = []

    func calendar(_ calendar: TFYSwiftCalendar, contentFor date: Date) -> TFYSwiftCalendarDayContent {
        TFYSwiftCalendarDayContent(subtitle: subtitle, eventColors: eventColors)
    }

    func calendar(
        _ calendar: TFYSwiftCalendar,
        cellFor date: Date,
        at monthPosition: TFYSwiftCalendarMonthPosition
    ) -> TFYSwiftCalendarCell? {
        dequeuedCellCount += 1
        return calendar.dequeueReusableCell(withIdentifier: "custom", for: date, at: monthPosition)
    }
}

@MainActor
private final class CountingDataSource: TFYSwiftCalendarDataSource {
    var minimumRequestCount = 0
    var maximumRequestCount = 0

    func minimumDate(for calendar: TFYSwiftCalendar) -> Date? {
        minimumRequestCount += 1
        return nil
    }

    func maximumDate(for calendar: TFYSwiftCalendar) -> Date? {
        maximumRequestCount += 1
        return nil
    }
}
