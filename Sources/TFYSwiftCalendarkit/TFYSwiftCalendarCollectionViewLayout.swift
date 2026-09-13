import UIKit

@MainActor
public final class TFYSwiftCalendarCollectionViewLayout: UICollectionViewLayout {
    public var scrollDirection: TFYSwiftCalendarScrollDirection = .horizontal {
        didSet { invalidateLayout() }
    }

    public var sectionInsets: UIEdgeInsets = .zero {
        didSet { invalidateLayout() }
    }

    private var pageSize: CGSize = .zero
    private var sectionCount = 0

    public override func prepare() {
        super.prepare()
        guard let collectionView else { return }
        pageSize = collectionView.bounds.size
        sectionCount = collectionView.numberOfSections
    }

    public override var collectionViewContentSize: CGSize {
        guard sectionCount > 0 else { return .zero }
        switch scrollDirection {
        case .horizontal:
            return CGSize(width: pageSize.width * CGFloat(sectionCount), height: pageSize.height)
        case .vertical:
            return CGSize(width: pageSize.width, height: pageSize.height * CGFloat(sectionCount))
        }
    }

    public override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let collectionView, sectionCount > 0, pageSize.width > 0, pageSize.height > 0 else { return [] }
        let pageLength = scrollDirection == .horizontal ? pageSize.width : pageSize.height
        let lower = scrollDirection == .horizontal ? rect.minX : rect.minY
        let upper = scrollDirection == .horizontal ? rect.maxX : rect.maxY
        let first = max(0, min(sectionCount - 1, Int(floor(lower / pageLength))))
        let last = max(first, min(sectionCount - 1, Int(floor(max(0, upper - 0.5) / pageLength))))
        var result: [UICollectionViewLayoutAttributes] = []
        for section in first...last {
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

        let rows = max(1, Int(ceil(Double(itemCount) / 7.0)))
        let usableWidth = max(0, pageSize.width - sectionInsets.left - sectionInsets.right)
        let usableHeight = max(0, pageSize.height - sectionInsets.top - sectionInsets.bottom)
        let column = indexPath.item % 7
        let row = indexPath.item / 7
        let columnWidth = usableWidth / 7
        let rowHeight = usableHeight / CGFloat(rows)
        let pageOrigin: CGPoint
        switch scrollDirection {
        case .horizontal:
            pageOrigin = CGPoint(x: CGFloat(indexPath.section) * pageSize.width, y: 0)
        case .vertical:
            pageOrigin = CGPoint(x: 0, y: CGFloat(indexPath.section) * pageSize.height)
        }

        let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        attributes.frame = CGRect(
            x: pageOrigin.x + sectionInsets.left + CGFloat(column) * columnWidth,
            y: pageOrigin.y + sectionInsets.top + CGFloat(row) * rowHeight,
            width: columnWidth,
            height: rowHeight
        ).integral
        return attributes
    }

    public override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        guard let collectionView else { return false }
        return newBounds.size != collectionView.bounds.size
    }

    public override func targetContentOffset(
        forProposedContentOffset proposedContentOffset: CGPoint,
        withScrollingVelocity velocity: CGPoint
    ) -> CGPoint {
        let length = scrollDirection == .horizontal ? pageSize.width : pageSize.height
        guard length > 0 else { return proposedContentOffset }
        let proposed = scrollDirection == .horizontal ? proposedContentOffset.x : proposedContentOffset.y
        let page = round(proposed / length)
        if scrollDirection == .horizontal {
            return CGPoint(x: page * length, y: 0)
        }
        return CGPoint(x: 0, y: page * length)
    }
}
