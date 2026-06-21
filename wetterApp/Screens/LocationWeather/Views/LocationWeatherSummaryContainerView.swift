import UIKit

final class LocationWeatherSummaryContainerView: UIView {

    // MARK: - Subviews

    let summaryView = LocationWeatherSummaryView()
    let statusView = LocationWeatherStatusView()

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
        [summaryView, statusView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        NSLayoutConstraint.activate([
            summaryView.topAnchor.constraint(equalTo: topAnchor),
            summaryView.leadingAnchor.constraint(equalTo: leadingAnchor),
            summaryView.trailingAnchor.constraint(equalTo: trailingAnchor),
            summaryView.bottomAnchor.constraint(equalTo: bottomAnchor),

            statusView.topAnchor.constraint(equalTo: topAnchor),
            statusView.leadingAnchor.constraint(equalTo: leadingAnchor),
            statusView.trailingAnchor.constraint(equalTo: trailingAnchor),
            statusView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
