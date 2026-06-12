import UIKit

final class LocationWeatherView: UIView {

    // MARK: - Subviews

    let scrollView = UIScrollView()
    let refreshControl = UIRefreshControl()
    let summaryView = LocationWeatherSummaryView()
    let forecastContainerView = UIView()
    let tilesContainerView = UIView()
    let loadingView = LocationWeatherLoadingView()
    let statusView = LocationWeatherStatusView()

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
            summaryView,
            forecastContainerView,
            tilesContainerView,
            loadingView,
            statusView
        ].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(summaryView)
        contentView.addSubview(forecastContainerView)
        contentView.addSubview(tilesContainerView)
        addSubview(loadingView)
        addSubview(statusView)

        loadingView.isHidden = true
        statusView.isHidden = true

        let placeholderHeightConstraints = [
            summaryView.heightAnchor.constraint(equalToConstant: 0),
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

            summaryView.topAnchor.constraint(equalTo: contentView.topAnchor),
            summaryView.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor
            ),
            summaryView.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor
            ),

            forecastContainerView.topAnchor.constraint(
                equalTo: summaryView.bottomAnchor
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
            loadingView.bottomAnchor.constraint(equalTo: bottomAnchor),

            statusView.topAnchor.constraint(
                equalTo: safeAreaLayoutGuide.topAnchor
            ),
            statusView.leadingAnchor.constraint(equalTo: leadingAnchor),
            statusView.trailingAnchor.constraint(equalTo: trailingAnchor),
            statusView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ] + placeholderHeightConstraints)
    }
}
