import UIKit
import WeatherViewModel

final class LocationWeatherSummaryView: UIView {

    // MARK: - Subviews

    let locationLabel = UILabel()
    let temperatureLabel = UILabel()
    let conditionLabel = UILabel()
    let feelsLikeLabel = UILabel()
    let humidityTitleLabel = UILabel()
    let humidityValueLabel = UILabel()

    private let contentStackView = UIStackView()
    private let humidityStackView = UIStackView()
    private var lastLayoutWidth: CGFloat = .zero
    private var isShowingAdditionalInformation: Bool?

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setContentCompressionResistancePriority(
            UILayoutPriority(752),
            for: .vertical
        )
        setupView()
        reset()
        updateLayout(
            for: traitCollection.horizontalSizeClass,
            verticalSizeClass: traitCollection.verticalSizeClass
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override var intrinsicContentSize: CGSize {
        let contentWidth = max(
            .zero,
            bounds.width
                - directionalLayoutMargins.leading
                - directionalLayoutMargins.trailing
        )
        let fittingWidth = contentWidth > .zero
            ? contentWidth
            : UIView.layoutFittingCompressedSize.width
        let fittingSize = contentStackView.systemLayoutSizeFitting(
            CGSize(
                width: fittingWidth,
                height: UIView.layoutFittingCompressedSize.height
            ),
            withHorizontalFittingPriority: contentWidth > .zero
                ? .required
                : .fittingSizeLevel,
            verticalFittingPriority: .fittingSizeLevel
        )

        return CGSize(
            width: UIView.noIntrinsicMetric,
            height: ceil(
                directionalLayoutMargins.top
                    + fittingSize.height
                    + directionalLayoutMargins.bottom
            )
        )
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        guard bounds.width != lastLayoutWidth else {
            return
        }

        lastLayoutWidth = bounds.width
        invalidateIntrinsicContentSize()
    }

    override func traitCollectionDidChange(
        _ previousTraitCollection: UITraitCollection?
    ) {
        super.traitCollectionDidChange(previousTraitCollection)

        if previousTraitCollection?.horizontalSizeClass
            != traitCollection.horizontalSizeClass
            || previousTraitCollection?.verticalSizeClass
                != traitCollection.verticalSizeClass {
            updateLayout(
                for: traitCollection.horizontalSizeClass,
                verticalSizeClass: traitCollection.verticalSizeClass
            )
        }

        if previousTraitCollection?.preferredContentSizeCategory
            != traitCollection.preferredContentSizeCategory {
            invalidateIntrinsicContentSize()
        }
    }

    // MARK: - Configuration

    func configure(with viewData: LocationWeatherViewData) {
        if let countryCode = viewData.countryCode, !countryCode.isEmpty {
            locationLabel.text = "\(viewData.locationName), \(countryCode)"
        } else {
            locationLabel.text = viewData.locationName
        }
        
        temperatureLabel.text = viewData.temperatureText
        conditionLabel.text = viewData.conditionText
        feelsLikeLabel.text = viewData.feelsLikeText
        humidityValueLabel.text = viewData.humidityText

        conditionLabel.isHidden = viewData.conditionText == nil
        invalidateIntrinsicContentSize()
    }

    func reset() {
        locationLabel.text = nil
        temperatureLabel.text = nil
        conditionLabel.text = nil
        feelsLikeLabel.text = nil
        humidityTitleLabel.text = "Humidity"
        humidityValueLabel.text = nil

        conditionLabel.isHidden = true
        invalidateIntrinsicContentSize()
    }

    func updateLayout(for horizontalSizeClass: UIUserInterfaceSizeClass?) {
        updateLayout(
            for: horizontalSizeClass,
            verticalSizeClass: nil
        )
    }

    func updateLayout(
        for horizontalSizeClass: UIUserInterfaceSizeClass?,
        verticalSizeClass: UIUserInterfaceSizeClass?
    ) {
        let showsAdditionalInformation = horizontalSizeClass == .regular
            && verticalSizeClass != .compact
        guard isShowingAdditionalInformation
            != showsAdditionalInformation else {
            return
        }
        isShowingAdditionalInformation = showsAdditionalInformation

        feelsLikeLabel.isHidden = !showsAdditionalInformation
        humidityTitleLabel.isHidden = !showsAdditionalInformation
        humidityValueLabel.isHidden = !showsAdditionalInformation
        humidityStackView.isHidden = !showsAdditionalInformation
        invalidateIntrinsicContentSize()
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
