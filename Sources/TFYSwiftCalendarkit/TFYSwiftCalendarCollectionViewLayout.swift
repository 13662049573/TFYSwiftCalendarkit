import UIKit

@MainActor
public final class TFYSwiftCalendarCollectionViewLayout: UICollectionViewLayout {
    public var scrollDirection: TFYSwiftCalendarScrollDirection = .horizontal {
        didSet { invalidateMetrics() }
    }

    public var sectionInsets: UIEdgeInsets = .zero {
        didSet { invalidateMetrics() }
    }

    internal var continuousRowHeight = TFYSwiftCalendarDefaults.rowHeight {
        didSet { invalidateMetrics() }
    }

    internal var continuousSectionHeaderHeight: CGFloat = 0 {
        didSet { invalidateMetrics() }
    }

    /// Supplies row counts without asking the collection view to materialize every page.
    internal var rowCountProvider: ((Int) -> Int)? {
        didSet { invalidateMetrics() }
    }

    private struct SectionMetric {
        let origin: CGFloat
        let length: CGFloat
        let rows: Int

        var range: Range<CGFloat> { origin..<(origin + length) }
    }

    private var pageSize: CGSize = .zero
    private var sectionCount = 0
    private var sectionMetrics: [SectionMetric] = []
    private var calculatedContentSize = CGSize.zero
    private var metricsAreDirty = true

    private var usesContinuousVerticalLayout: Bool {
        scrollDirection == .vertical && collectionView?.isPagingEnabled == false
    }

    public override func prepare() {
        super.prepare()
        guard let collectionView else { return }
        let newPageSize = collectionView.bounds.size
        let newSectionCount = collectionView.numberOfSections
        if newPageSize != pageSize || newSectionCount != sectionCount {
            metricsAreDirty = true
        }
        pageSize = newPageSize
        sectionCount = newSectionCount

        guard metricsAreDirty else { return }
        sectionMetrics.removeAll(keepingCapacity: true)

        guard usesContinuousVerticalLayout, sectionCount > 0 else {
            calculatedContentSize = scrollDirection == .horizontal
                ? CGSize(width: pageSize.width * CGFloat(sectionCount), height: pageSize.height)
                : CGSize(width: pageSize.width, height: pageSize.height * CGFloat(sectionCount))
            metricsAreDirty = false
            return
        }

        var origin: CGFloat = 0
        let itemHeight = max(1, continuousRowHeight)
        for section in 0..<sectionCount {
            let rows = max(1, rowCountProvider?(section) ?? rowsFromCollectionView(section))
            let length = max(0, continuousSectionHeaderHeight) + sectionInsets.top + CGFloat(rows) * itemHeight + sectionInsets.bottom
            sectionMetrics.append(SectionMetric(origin: origin, length: length, rows: rows))
            origin += length
        }
        let trailingSpace = max(0, pageSize.height - (sectionMetrics.last?.length ?? 0))
        calculatedContentSize = CGSize(width: pageSize.width, height: origin + trailingSpace)
        metricsAreDirty = false
    }

    public override var collectionViewContentSize: CGSize {
        calculatedContentSize
    }

    public override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let collectionView, sectionCount > 0, pageSize.width > 0, pageSize.height > 0 else { return [] }
        let sections: [Int]
        if usesContinuousVerticalLayout {
            sections = continuousSections(intersecting: rect)
        } else {
            let pageLength = scrollDirection == .horizontal ? pageSize.width : pageSize.height
            let lower = scrollDirection == .horizontal ? rect.minX : rect.minY
            let upper = scrollDirection == .horizontal ? rect.maxX : rect.maxY
            let first = max(0, min(sectionCount - 1, Int(floor(lower / pageLength))))
            let last = max(first, min(sectionCount - 1, Int(floor(max(0, upper - 0.5) / pageLength))))
            sections = Array(first...last)
        }
        var result: [UICollectionViewLayoutAttributes] = []
        for section in sections {
            if continuousSectionHeaderHeight > 0,
               let header = layoutAttributesForSupplementaryView(
                   ofKind: UICollectionView.elementKindSectionHeader,
                   at: IndexPath(item: 0, section: section)
               ),
               header.frame.intersects(rect) {
                result.append(header)
            }
            let count = collectionView.numberOfItems(inSection: section)
            result.reserveCapacity(result.count + count)
            for item in 0..<count {
                if let attributes = layoutAttributesForItem(at: IndexPath(item: item, section: section)),
                   attributes.frame.intersects(rect) {
                    result.append(attributes)
                }
            }
        }
        return result
    }

    public override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let collectionView, pageSize.width > 0, pageSize.height > 0 else { return nil }
        let itemCount = collectionView.numberOfItems(inSection: indexPath.section)
        guard indexPath.item < itemCount else { return nil }

        let rows = max(1, rowCountProvider?(indexPath.section) ?? Int(ceil(Double(itemCount) / 7.0)))
        let usableWidth = max(0, pageSize.width - sectionInsets.left - sectionInsets.right)
        let column = indexPath.item % 7
        let row = indexPath.item / 7
        let columnWidth = usableWidth / 7
        let rowHeight: CGFloat
        let pageOrigin: CGPoint
        if usesContinuousVerticalLayout, sectionMetrics.indices.contains(indexPath.section) {
            rowHeight = max(1, continuousRowHeight)
            pageOrigin = CGPoint(x: 0, y: sectionMetrics[indexPath.section].origin)
        } else if scrollDirection == .horizontal {
            let usableHeight = max(0, pageSize.height - sectionInsets.top - sectionInsets.bottom)
            rowHeight = usableHeight / CGFloat(rows)
            pageOrigin = CGPoint(x: CGFloat(indexPath.section) * pageSize.width, y: 0)
        } else {
            let usableHeight = max(0, pageSize.height - sectionInsets.top - sectionInsets.bottom)
            rowHeight = usableHeight / CGFloat(rows)
            pageOrigin = CGPoint(x: 0, y: CGFloat(indexPath.section) * pageSize.height)
        }

        let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        let scale = max(1, collectionView.traitCollection.displayScale)
        let contentMinX = pageOrigin.x + sectionInsets.left
        let rowMinY = pageOrigin.y + (usesContinuousVerticalLayout ? max(0, continuousSectionHeaderHeight) : 0)
            + sectionInsets.top
        let minX = pixelAligned(contentMinX + CGFloat(column) * columnWidth, scale: scale)
        let maxX = pixelAligned(contentMinX + CGFloat(column + 1) * columnWidth, scale: scale)
        let minY = pixelAligned(rowMinY + CGFloat(row) * rowHeight, scale: scale)
        let maxY = pixelAligned(rowMinY + CGFloat(row + 1) * rowHeight, scale: scale)
        attributes.frame = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        return attributes
    }

    private func pixelAligned(_ value: CGFloat, scale: CGFloat) -> CGFloat {
        (value * scale).rounded() / scale
    }

    public override func layoutAttributesForSupplementaryView(
        ofKind elementKind: String,
        at indexPath: IndexPath
    ) -> UICollectionViewLayoutAttributes? {
        guard elementKind == UICollectionView.elementKindSectionHeader,
              usesContinuousVerticalLayout,
              continuousSectionHeaderHeight > 0,
              sectionMetrics.indices.contains(indexPath.section),
              let collectionView else { return nil }
        let metric = sectionMetrics[indexPath.section]
        let nextOrigin = sectionMetrics.indices.contains(indexPath.section + 1)
            ? sectionMetrics[indexPath.section + 1].origin
            : metric.origin + metric.length
        let maximumY = nextOrigin - continuousSectionHeaderHeight
        let pinnedY = max(metric.origin, min(collectionView.contentOffset.y, maximumY))
        let attributes = UICollectionViewLayoutAttributes(
            forSupplementaryViewOfKind: elementKind,
            with: indexPath
        )
        attributes.frame = CGRect(
            x: 0,
            y: pinnedY,
            width: pageSize.width,
            height: continuousSectionHeaderHeight
        ).integral
        attributes.zIndex = 10
        return attributes
    }

    public override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        guard let collectionView else { return false }
        if newBounds.size != collectionView.bounds.size {
            metricsAreDirty = true
            return true
        }
        return usesContinuousVerticalLayout
            && continuousSectionHeaderHeight > 0
            && newBounds.origin != collectionView.bounds.origin
    }

    public override func targetContentOffset(
        forProposedContentOffset proposedContentOffset: CGPoint,
        withScrollingVelocity velocity: CGPoint
    ) -> CGPoint {
        if usesContinuousVerticalLayout { return proposedContentOffset }
        let length = scrollDirection == .horizontal ? pageSize.width : pageSize.height
        guard length > 0 else { return proposedContentOffset }
        let proposed = scrollDirection == .horizontal ? proposedContentOffset.x : proposedContentOffset.y
        let page = round(proposed / length)
        if scrollDirection == .horizontal {
            return CGPoint(x: page * length, y: 0)
        }
        return CGPoint(x: 0, y: page * length)
    }

    internal func verticalOffset(forSection section: Int) -> CGFloat {
        guard usesContinuousVerticalLayout, sectionMetrics.indices.contains(section) else {
            return CGFloat(section) * pageSize.height
        }
        return sectionMetrics[section].origin
    }

    internal func section(atVerticalOffset offset: CGFloat) -> Int {
        guard usesContinuousVerticalLayout, !sectionMetrics.isEmpty else {
            guard pageSize.height > 0 else { return 0 }
            return min(max(0, Int(round(offset / pageSize.height))), max(0, sectionCount - 1))
        }
        let normalizedOffset = max(0, offset)
        var lower = 0
        var upper = sectionMetrics.count
        while lower < upper {
            let middle = lower + (upper - lower) / 2
            if sectionMetrics[middle].origin <= normalizedOffset {
                lower = middle + 1
            } else {
                upper = middle
            }
        }
        return min(max(0, lower - 1), sectionMetrics.count - 1)
    }

    public override var flipsHorizontallyInOppositeLayoutDirection: Bool { true }

    internal func invalidateDataSourceMetrics() {
        invalidateMetrics()
    }

    private func invalidateMetrics() {
        metricsAreDirty = true
        invalidateLayout()
    }

    private func rowsFromCollectionView(_ section: Int) -> Int {
        guard let collectionView else { return 1 }
        return max(1, Int(ceil(Double(collectionView.numberOfItems(inSection: section)) / 7.0)))
    }

    private func continuousSections(intersecting rect: CGRect) -> [Int] {
        guard !sectionMetrics.isEmpty, rect.maxY > rect.minY else { return [] }

        var lower = 0
        var upper = sectionMetrics.count
        while lower < upper {
            let middle = lower + (upper - lower) / 2
            let metric = sectionMetrics[middle]
            if metric.origin + metric.length <= rect.minY {
                lower = middle + 1
            } else {
                upper = middle
            }
        }
        let first = lower

        lower = first
        upper = sectionMetrics.count
        while lower < upper {
            let middle = lower + (upper - lower) / 2
            if sectionMetrics[middle].origin < rect.maxY {
                lower = middle + 1
            } else {
                upper = middle
            }
        }
        let lastExclusive = lower
        guard first < lastExclusive else { return [] }
        return Array(first..<lastExclusive)
    }
}
