import UIKit
import WeatherViewModel

final class HourlyForecastCell: UICollectionViewCell {

    static let reuseIdentifier = String(describing: HourlyForecastCell.self)

    let timeLabel = UILabel()
    let temperatureLabel = UILabel()
    let conditionLabel = UILabel()
    let temperatureGraphLineView = TemperatureGraphLineView()

    private let labelsStackView = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        timeLabel.text = nil
        temperatureLabel.text = nil
        conditionLabel.text = nil
        conditionLabel.isHidden = false
        temperatureGraphLineView.reset()
        accessibilityLabel = nil
    }

    func configure(
        with viewData: HourlyForecastItemViewData,
        previousTemperature: Double?,
        nextTemperature: Double?,
        minimumTemperature: Double,
        maximumTemperature: Double
    ) {
        timeLabel.text = viewData.timeText
        temperatureLabel.text = viewData.temperatureText
        conditionLabel.text = viewData.conditionText
        conditionLabel.isHidden = viewData.conditionText == nil

        temperatureGraphLineView.configure(
            currentTemperature: viewData.temperatureValue,
            previousTemperature: previousTemperature,
            nextTemperature: nextTemperature,
            minimumTemperature: minimumTemperature,
            maximumTemperature: maximumTemperature
        )

        accessibilityLabel = [
            viewData.timeText,
            viewData.temperatureText,
            viewData.conditionText
        ].compactMap { $0 }.joined(separator: ", ")
    }
}

// MARK: - Setup

private extension HourlyForecastCell {

    func setupView() {
        isAccessibilityElement = true

        configure(
            timeLabel,
            font: .preferredFont(forTextStyle: .caption1),
            color: .secondaryLabel
        )
        configure(
            temperatureLabel,
            font: .preferredFont(forTextStyle: .headline),
            color: .label
        )
        configure(
            conditionLabel,
            font: .preferredFont(forTextStyle: .caption2),
            color: .secondaryLabel
        )
        conditionLabel.numberOfLines = 2

        labelsStackView.axis = .vertical
        labelsStackView.alignment = .center
        labelsStackView.spacing = 2
        labelsStackView.translatesAutoresizingMaskIntoConstraints = false
        labelsStackView.addArrangedSubview(timeLabel)
        labelsStackView.addArrangedSubview(temperatureLabel)
        labelsStackView.addArrangedSubview(conditionLabel)

        temperatureGraphLineView.translatesAutoresizingMaskIntoConstraints =
            false

        contentView.addSubview(labelsStackView)
        contentView.addSubview(temperatureGraphLineView)

        NSLayoutConstraint.activate([
            labelsStackView.topAnchor.constraint(
                equalTo: contentView.topAnchor
            ),
            labelsStackView.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor
            ),
            labelsStackView.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor
            ),

            temperatureGraphLineView.topAnchor.constraint(
                equalTo: labelsStackView.bottomAnchor,
                constant: 8
            ),
            temperatureGraphLineView.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor
            ),
            temperatureGraphLineView.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor
            ),
            temperatureGraphLineView.bottomAnchor.constraint(
                equalTo: contentView.bottomAnchor
            ),
            temperatureGraphLineView.heightAnchor.constraint(
                greaterThanOrEqualToConstant: 40
            )
        ])
    }

    func configure(
        _ label: UILabel,
        font: UIFont,
        color: UIColor
    ) {
        label.font = font
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.textColor = color
    }
}
