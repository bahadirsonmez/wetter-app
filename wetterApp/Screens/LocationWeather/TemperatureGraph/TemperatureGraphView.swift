import UIKit
import WeatherViewModel

final class TemperatureGraphView: UIView {

    private static let emptyCellReuseIdentifier = "EmptyForecastCell"
    private static let emptyHeaderReuseIdentifier = "EmptyForecastHeader"

    // MARK: - Subviews

    let collectionView: UICollectionView

    // MARK: - Properties

    private var viewData: HourlyForecastViewData?
    private let baseLayoutMetrics: TemperatureGraphLayoutMetrics?

    // MARK: - Initialization

    override init(frame: CGRect) {
        let layout = TemperatureGraphLayout()
        collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: layout
        )
        baseLayoutMetrics = layout.metrics
        super.init(frame: frame)
        setContentCompressionResistancePriority(
            UILayoutPriority(751),
            for: .vertical
        )
        setupView()
    }

    init(
        frame: CGRect = .zero,
        collectionView: UICollectionView
    ) {
        self.collectionView = collectionView
        baseLayoutMetrics = (
            collectionView.collectionViewLayout
                as? TemperatureGraphLayout
        )?.metrics
        super.init(frame: frame)
        setContentCompressionResistancePriority(
            UILayoutPriority(751),
            for: .vertical
        )
        setupView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        guard
            !isHidden,
            let layout = collectionView.collectionViewLayout
                as? TemperatureGraphLayout
        else {
            return CGSize(
                width: UIView.noIntrinsicMetric,
                height: .zero
            )
        }

        return CGSize(
            width: UIView.noIntrinsicMetric,
            height: layout.metrics.contentHeight
        )
    }

    override var isHidden: Bool {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        guard traitCollection.preferredContentSizeCategory
            != previousTraitCollection?.preferredContentSizeCategory
            || traitCollection.verticalSizeClass
                != previousTraitCollection?.verticalSizeClass else {
            return
        }

        updateLayout(
            for: traitCollection.preferredContentSizeCategory,
            verticalSizeClass: traitCollection.verticalSizeClass
        )
    }

    // MARK: - Configuration

    func configure(with viewData: HourlyForecastViewData) {
        guard self.viewData != viewData else {
            return
        }

        self.viewData = viewData
        collectionView.reloadData()
    }

    func reset() {
        guard viewData != nil else {
            return
        }

        viewData = nil
        collectionView.reloadData()
    }

    func invalidateLayoutForBoundsChange() {
        collectionView.collectionViewLayout.invalidateLayout()
    }

    func updateLayout(
        for contentSizeCategory: UIContentSizeCategory
    ) {
        updateLayout(
            for: contentSizeCategory,
            verticalSizeClass: traitCollection.verticalSizeClass
        )
    }

    func updateLayout(
        for contentSizeCategory: UIContentSizeCategory,
        verticalSizeClass: UIUserInterfaceSizeClass?
    ) {
        guard
            let layout = collectionView.collectionViewLayout
                as? TemperatureGraphLayout,
            let baseLayoutMetrics
        else {
            collectionView.collectionViewLayout.invalidateLayout()
            return
        }

        var metrics = baseLayoutMetrics.scaled(
            for: contentSizeCategory
        )
        if verticalSizeClass == .compact {
            metrics = metrics.compactedVertically()
        }

        guard layout.metrics != metrics else {
            return
        }

        layout.metrics = metrics
        invalidateIntrinsicContentSize()
    }
}

// MARK: - Setup

private extension TemperatureGraphView {

    func setupView() {
        backgroundColor = .clear

        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceHorizontal = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(
            HourlyForecastCell.self,
            forCellWithReuseIdentifier: HourlyForecastCell.reuseIdentifier
        )
        collectionView.register(
            UICollectionViewCell.self,
            forCellWithReuseIdentifier: Self.emptyCellReuseIdentifier
        )
        collectionView.register(
            ForecastDayHeaderView.self,
            forSupplementaryViewOfKind:
                ForecastDayHeaderView.elementKind,
            withReuseIdentifier: ForecastDayHeaderView.reuseIdentifier
        )
        collectionView.register(
            UICollectionReusableView.self,
            forSupplementaryViewOfKind:
                ForecastDayHeaderView.elementKind,
            withReuseIdentifier: Self.emptyHeaderReuseIdentifier
        )

        addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}

// MARK: - UICollectionViewDataSource

extension TemperatureGraphView: UICollectionViewDataSource {

    func numberOfSections(
        in collectionView: UICollectionView
    ) -> Int {
        guard let count = viewData?.days.count else {
            return 0
        }

        return count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        guard let days = viewData?.days, days.indices.contains(section) else {
            return 0
        }

        return days[section].items.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard
            let viewData,
            let item = item(at: indexPath, in: viewData)
        else {
            return collectionView.dequeueReusableCell(
                withReuseIdentifier: Self.emptyCellReuseIdentifier,
                for: indexPath
            )
        }
        guard
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: HourlyForecastCell.reuseIdentifier,
                for: indexPath
            ) as? HourlyForecastCell
        else {
            return collectionView.dequeueReusableCell(
                withReuseIdentifier: Self.emptyCellReuseIdentifier,
                for: indexPath
            )
        }

        let neighbors = neighboringTemperatures(
            at: indexPath,
            in: viewData
        )
        cell.configure(
            with: item,
            previousTemperature: neighbors.previous,
            nextTemperature: neighbors.next,
            minimumTemperature: viewData.minimumTemperature,
            maximumTemperature: viewData.maximumTemperature
        )
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        guard
            kind == ForecastDayHeaderView.elementKind,
            let days = viewData?.days,
            days.indices.contains(indexPath.section)
        else {
            return emptySupplementaryView(
                ofKind: kind,
                at: indexPath,
                in: collectionView
            )
        }
        guard
            let header = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: ForecastDayHeaderView.reuseIdentifier,
                for: indexPath
            ) as? ForecastDayHeaderView
        else {
            return emptySupplementaryView(
                ofKind: kind,
                at: indexPath,
                in: collectionView
            )
        }

        header.configure(title: days[indexPath.section].title)
        return header
    }
}

// MARK: - Helpers

private extension TemperatureGraphView {

    func emptySupplementaryView(
        ofKind kind: String,
        at indexPath: IndexPath,
        in collectionView: UICollectionView
    ) -> UICollectionReusableView {
        guard kind == ForecastDayHeaderView.elementKind else {
            return UICollectionReusableView()
        }

        return collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: Self.emptyHeaderReuseIdentifier,
            for: indexPath
        )
    }

    func item(
        at indexPath: IndexPath,
        in viewData: HourlyForecastViewData
    ) -> HourlyForecastItemViewData? {
        guard
            viewData.days.indices.contains(indexPath.section),
            viewData.days[indexPath.section].items.indices.contains(
                indexPath.item
            )
        else {
            return nil
        }

        return viewData.days[indexPath.section].items[indexPath.item]
    }

    func neighboringTemperatures(
        at indexPath: IndexPath,
        in viewData: HourlyForecastViewData
    ) -> (previous: Double?, next: Double?) {
        let items = viewData.days.flatMap(\.items)
        let itemOffset = viewData.days
            .prefix(indexPath.section)
            .reduce(0) { $0 + $1.items.count }
            + indexPath.item

        guard items.indices.contains(itemOffset) else {
            return (nil, nil)
        }

        let previous = items.indices.contains(itemOffset - 1)
            ? items[itemOffset - 1].temperatureValue
            : nil
        let next = items.indices.contains(itemOffset + 1)
            ? items[itemOffset + 1].temperatureValue
            : nil

        return (previous, next)
    }
}
