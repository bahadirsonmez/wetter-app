import UIKit
import WeatherViewModel

final class LocationWeatherSummaryView: UIView {

    // MARK: - Subviews

    let locationLabel = UILabel()
    let countryCodeLabel = UILabel()
    let temperatureLabel = UILabel()
    let conditionLabel = UILabel()
    let feelsLikeLabel = UILabel()
    let humidityTitleLabel = UILabel()
    let humidityValueLabel = UILabel()

    private let contentStackView = UIStackView()
    private let humidityStackView = UIStackView()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        reset()
        updateLayout(for: traitCollection.horizontalSizeClass)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func traitCollectionDidChange(
        _ previousTraitCollection: UITraitCollection?
    ) {
        super.traitCollectionDidChange(previousTraitCollection)

        guard previousTraitCollection?.horizontalSizeClass
            != traitCollection.horizontalSizeClass else {
            return
        }

        updateLayout(for: traitCollection.horizontalSizeClass)
    }

    // MARK: - Configuration

    func configure(with viewData: LocationWeatherViewData) {
        locationLabel.text = viewData.locationName
        countryCodeLabel.text = viewData.countryCode
        temperatureLabel.text = viewData.temperatureText
        conditionLabel.text = viewData.conditionText
        feelsLikeLabel.text = viewData.feelsLikeText
        humidityValueLabel.text = viewData.humidityText

        countryCodeLabel.isHidden = viewData.countryCode == nil
        conditionLabel.isHidden = viewData.conditionText == nil
    }

    func reset() {
        locationLabel.text = nil
        countryCodeLabel.text = nil
        temperatureLabel.text = nil
        conditionLabel.text = nil
        feelsLikeLabel.text = nil
        humidityTitleLabel.text = "Humidity"
        humidityValueLabel.text = nil

        countryCodeLabel.isHidden = true
        conditionLabel.isHidden = true
    }

    func updateLayout(for horizontalSizeClass: UIUserInterfaceSizeClass?) {
        let showsAdditionalInformation = horizontalSizeClass == .regular

        feelsLikeLabel.isHidden = !showsAdditionalInformation
        humidityTitleLabel.isHidden = !showsAdditionalInformation
        humidityValueLabel.isHidden = !showsAdditionalInformation
        humidityStackView.isHidden = !showsAdditionalInformation
    }

    // MARK: - Setup

    private func setupView() {
        directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 24,
            leading: 24,
            bottom: 24,
            trailing: 24
        )

        configureLabels()
        configureStackViews()

        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentStackView)

        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(
                equalTo: layoutMarginsGuide.topAnchor
            ),
            contentStackView.leadingAnchor.constraint(
                equalTo: layoutMarginsGuide.leadingAnchor
            ),
            contentStackView.trailingAnchor.constraint(
                equalTo: layoutMarginsGuide.trailingAnchor
            ),
            contentStackView.bottomAnchor.constraint(
                equalTo: layoutMarginsGuide.bottomAnchor
            )
        ])
    }

    private func configureLabels() {
        configure(
            locationLabel,
            textStyle: .title1,
            alignment: .center
        )
        configure(
            countryCodeLabel,
            textStyle: .headline,
            alignment: .center
        )
        configure(
            temperatureLabel,
            textStyle: .largeTitle,
            alignment: .center
        )
        configure(
            conditionLabel,
            textStyle: .title3,
            alignment: .center
        )
        configure(
            feelsLikeLabel,
            textStyle: .body,
            alignment: .center
        )
        configure(
            humidityTitleLabel,
            textStyle: .caption1,
            alignment: .center
        )
        configure(
            humidityValueLabel,
            textStyle: .body,
            alignment: .center
        )
    }

    private func configureStackViews() {
        humidityStackView.axis = .vertical
        humidityStackView.alignment = .fill
        humidityStackView.spacing = 4
        humidityStackView.addArrangedSubview(humidityTitleLabel)
        humidityStackView.addArrangedSubview(humidityValueLabel)

        contentStackView.axis = .vertical
        contentStackView.alignment = .fill
        contentStackView.spacing = 8
        contentStackView.addArrangedSubview(locationLabel)
        contentStackView.addArrangedSubview(countryCodeLabel)
        contentStackView.addArrangedSubview(temperatureLabel)
        contentStackView.addArrangedSubview(conditionLabel)
        contentStackView.addArrangedSubview(feelsLikeLabel)
        contentStackView.addArrangedSubview(humidityStackView)
    }

    private func configure(
        _ label: UILabel,
        textStyle: UIFont.TextStyle,
        alignment: NSTextAlignment
    ) {
        label.font = .preferredFont(forTextStyle: textStyle)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.textAlignment = alignment
    }
}
