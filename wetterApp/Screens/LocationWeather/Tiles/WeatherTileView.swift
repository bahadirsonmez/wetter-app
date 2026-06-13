import UIKit
import WeatherViewModel

final class WeatherTileView: UIView {

    // MARK: - Subviews

    let symbolImageView = UIImageView()
    let titleLabel = UILabel()
    let valueLabel = UILabel()
    let detailLabel = UILabel()

    // MARK: - Constants

    private enum Layout {
        static let contentInset: CGFloat = 12
        static let symbolSize: CGFloat = 28
        static let titleSpacing: CGFloat = 8
        static let valueSpacing: CGFloat = 10
        static let detailSpacing: CGFloat = 4
        static let cornerRadius: CGFloat = 16
    }

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        reset()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func layoutSubviews() {
        super.layoutSubviews()

        let contentFrame = bounds.insetBy(
            dx: Layout.contentInset,
            dy: Layout.contentInset
        )
        guard contentFrame.width > 0, contentFrame.height > 0 else {
            clearFrames()
            return
        }

        let symbolSide = min(
            Layout.symbolSize,
            contentFrame.width,
            contentFrame.height
        )
        symbolImageView.frame = CGRect(
            x: contentFrame.minX,
            y: contentFrame.minY,
            width: symbolSide,
            height: symbolSide
        )

        let titleX = symbolImageView.frame.maxX + Layout.titleSpacing
        let titleWidth = max(.zero, contentFrame.maxX - titleX)
        titleLabel.frame = CGRect(
            x: titleX,
            y: contentFrame.minY,
            width: titleWidth,
            height: min(
                symbolSide,
                fittingHeight(for: titleLabel, width: titleWidth)
            )
        )

        var nextY = max(
            symbolImageView.frame.maxY,
            titleLabel.frame.maxY
        ) + Layout.valueSpacing
        valueLabel.frame = frame(
            for: valueLabel,
            x: contentFrame.minX,
            y: nextY,
            width: contentFrame.width,
            maximumY: contentFrame.maxY
        )

        nextY = valueLabel.frame.maxY + Layout.detailSpacing
        detailLabel.frame = detailLabel.isHidden
            ? .zero
            : frame(
                for: detailLabel,
                x: contentFrame.minX,
                y: nextY,
                width: contentFrame.width,
                maximumY: contentFrame.maxY
            )
    }

    // MARK: - Configuration

    func configure(with viewData: WeatherTileViewData) {
        symbolImageView.image = UIImage(systemName: viewData.symbolName)
        titleLabel.text = viewData.title
        valueLabel.text = viewData.valueText
        detailLabel.text = viewData.detailText
        detailLabel.isHidden = viewData.detailText == nil
        accessibilityLabel = "\(viewData.title), \(viewData.valueText)"
        setNeedsLayout()
    }

    func reset() {
        symbolImageView.image = nil
        titleLabel.text = nil
        valueLabel.text = nil
        detailLabel.text = nil
        detailLabel.isHidden = true
        accessibilityLabel = nil
        setNeedsLayout()
    }
}

// MARK: - Setup

private extension WeatherTileView {

    func setupView() {
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = Layout.cornerRadius
        layer.masksToBounds = true
        isAccessibilityElement = true

        symbolImageView.contentMode = .scaleAspectFit
        symbolImageView.tintColor = .systemBlue

        configure(
            titleLabel,
            textStyle: .caption1,
            baseFont: .systemFont(ofSize: 13, weight: .medium),
            color: .secondaryLabel
        )
        configure(
            valueLabel,
            textStyle: .title2,
            baseFont: .systemFont(ofSize: 22, weight: .semibold),
            color: .label
        )
        configure(
            detailLabel,
            textStyle: .caption2,
            baseFont: .systemFont(ofSize: 12),
            color: .secondaryLabel
        )

        addSubview(symbolImageView)
        addSubview(titleLabel)
        addSubview(valueLabel)
        addSubview(detailLabel)
    }

    func configure(
        _ label: UILabel,
        textStyle: UIFont.TextStyle,
        baseFont: UIFont,
        color: UIColor
    ) {
        label.font = UIFontMetrics(forTextStyle: textStyle).scaledFont(
            for: baseFont
        )
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 2
        label.textColor = color
    }
}

// MARK: - Layout Helpers

private extension WeatherTileView {

    func frame(
        for label: UILabel,
        x: CGFloat,
        y: CGFloat,
        width: CGFloat,
        maximumY: CGFloat
    ) -> CGRect {
        let availableHeight = max(.zero, maximumY - y)
        let height = min(
            availableHeight,
            fittingHeight(for: label, width: width)
        )

        return CGRect(
            x: x,
            y: min(y, maximumY),
            width: width,
            height: height
        )
    }

    func fittingHeight(for label: UILabel, width: CGFloat) -> CGFloat {
        guard width > 0 else {
            return .zero
        }

        return ceil(
            label.sizeThatFits(
                CGSize(
                    width: width,
                    height: .greatestFiniteMagnitude
                )
            ).height
        )
    }

    func clearFrames() {
        symbolImageView.frame = .zero
        titleLabel.frame = .zero
        valueLabel.frame = .zero
        detailLabel.frame = .zero
    }
}
