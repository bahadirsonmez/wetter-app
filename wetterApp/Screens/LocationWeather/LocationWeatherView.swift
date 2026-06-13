import UIKit

final class LocationWeatherView: UIView {

    // MARK: - Subviews

    let scrollView = UIScrollView()
    let refreshControl = UIRefreshControl()
    let summaryContainerView = LocationWeatherSummaryContainerView()
    let forecastContainerView = LocationWeatherForecastContainerView()
    let tilesContainerView = UIView()
    let loadingView = LocationWeatherLoadingView()

    private let contentView = UIView()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupView() {
        backgroundColor = .systemBackground
        scrollView.alwaysBounceVertical = true
        scrollView.refreshControl = refreshControl

        [
            scrollView,
            contentView,
            summaryContainerView,
            forecastContainerView,
            tilesContainerView,
            loadingView
        ].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(summaryContainerView)
        contentView.addSubview(forecastContainerView)
        contentView.addSubview(tilesContainerView)
        addSubview(loadingView)

        loadingView.isHidden = true
        summaryContainerView.statusView.isHidden = true
        forecastContainerView.temperatureGraphView.isHidden = true
        forecastContainerView.statusView.isHidden = true

        let placeholderHeightConstraints = [
            summaryContainerView.heightAnchor.constraint(equalToConstant: 0),
            forecastContainerView.heightAnchor.constraint(equalToConstant: 0),
            tilesContainerView.heightAnchor.constraint(equalToConstant: 0)
        ]
        placeholderHeightConstraints.forEach {
            $0.priority = .defaultLow
        }

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            contentView.topAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.topAnchor
            ),
            contentView.leadingAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.leadingAnchor
            ),
            contentView.trailingAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.trailingAnchor
            ),
            contentView.bottomAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.bottomAnchor
            ),
            contentView.widthAnchor.constraint(
                equalTo: scrollView.frameLayoutGuide.widthAnchor
            ),

            summaryContainerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            summaryContainerView.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor
            ),
            summaryContainerView.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor
            ),

            forecastContainerView.topAnchor.constraint(
                equalTo: summaryContainerView.bottomAnchor
            ),
            forecastContainerView.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor
            ),
            forecastContainerView.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor
            ),

            tilesContainerView.topAnchor.constraint(
                equalTo: forecastContainerView.bottomAnchor
            ),
            tilesContainerView.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor
            ),
            tilesContainerView.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor
            ),
            tilesContainerView.bottomAnchor.constraint(
                equalTo: contentView.bottomAnchor
            ),

            loadingView.topAnchor.constraint(
                equalTo: safeAreaLayoutGuide.topAnchor
            ),
            loadingView.leadingAnchor.constraint(equalTo: leadingAnchor),
            loadingView.trailingAnchor.constraint(equalTo: trailingAnchor),
            loadingView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ] + placeholderHeightConstraints)
    }
}
