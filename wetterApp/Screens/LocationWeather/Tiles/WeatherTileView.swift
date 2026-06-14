import UIKit
import WeatherViewModel

final class WeatherTileView: UIView {

    // MARK: - Subviews

    let symbolImageView = UIImageView()
    let titleLabel = UILabel()
    let valueLabel = UILabel()
    let detailLabel = UILabel()

    // MARK: - Properties

    private(set) var identifier: WeatherTileIdentifier?
    var onMoveEarlier: (() -> Void)?
    var onMoveLater: (() -> Void)?

    // MARK: - Constants

    private enum Layout {
        static let contentInset: CGFloat = 16
        static let symbolSize: CGFloat = 28
        static let valueSpacing: CGFloat = 10
        static let detailSpacing: CGFloat = 4
        static let titleSpacing: CGFloat = 6
        static let cornerRadius: CGFloat = 8
    }

    private enum Typography {
        static let titleBaseFont = UIFont.systemFont(
            ofSize: 13,
            weight: .medium
        )
        static let valueBaseFont = UIFont.systemFont(
            ofSize: 28,
            weight: .bold
        )
        static let detailBaseFont = UIFont.systemFont(ofSize: 12)
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

        let titleHeight = min(
            fittingHeight(for: titleLabel, width: contentFrame.width),
            contentFrame.height
        )
        titleLabel.frame = CGRect(
            x: contentFrame.minX,
            y: max(contentFrame.minY, contentFrame.maxY - titleHeight),
            width: contentFrame.width,
            height: titleHeight
        )

        // Optional detail sits directly above the title and gives the large
        // value the remaining space between the symbol and lower labels.
        let detailMaximumY = max(
            contentFrame.minY,
            titleLabel.frame.minY - Layout.titleSpacing
        )
        if detailLabel.isHidden {
            detailLabel.frame = .zero
        } else {
            let detailHeight = min(
                fittingHeight(for: detailLabel, width: contentFrame.width),
                max(.zero, detailMaximumY - contentFrame.minY)
            )
            detailLabel.frame = CGRect(
                x: contentFrame.minX,
                y: detailMaximumY - detailHeight,
                width: contentFrame.width,
                height: detailHeight
            )
        }

        let valueY = symbolImageView.frame.maxY + Layout.valueSpacing
        let valueMaximumY = (
            detailLabel.isHidden
                ? titleLabel.frame.minY
                : detailLabel.frame.minY
        ) - Layout.detailSpacing
        valueLabel.frame = frame(
            for: valueLabel,
            x: contentFrame.minX,
            y: valueY,
            width: contentFrame.width,
            maximumY: max(valueY, valueMaximumY)
        )
    }

    // MARK: - Configuration

    func configure(with viewData: WeatherTileViewData) {
        let style = WeatherTileStyle(identifier: viewData.id)

        identifier = viewData.id
        backgroundColor = style.backgroundColor
        symbolImageView.image = UIImage(systemName: style.symbolName)
        symbolImageView.tintColor = style.foregroundColor
        titleLabel.text = viewData.title
        titleLabel.textColor = style.foregroundColor
        valueLabel.text = viewData.valueText
        valueLabel.textColor = style.foregroundColor
        detailLabel.text = viewData.detailText
        detailLabel.textColor = style.foregroundColor
        detailLabel.isHidden = viewData.detailText == nil
        accessibilityLabel = "\(viewData.title), \(viewData.valueText)"
        setNeedsLayout()
    }

    func reset() {
        identifier = nil
        onMoveEarlier = nil
        onMoveLater = nil
        accessibilityCustomActions = nil
        symbolImageView.image = nil
        titleLabel.text = nil
        valueLabel.text = nil
        detailLabel.text = nil
        detailLabel.isHidden = true
        accessibilityLabel = nil
        backgroundColor = .secondarySystemBackground
        symbolImageView.tintColor = .systemBlue
        titleLabel.textColor = .secondaryLabel
        valueLabel.textColor = .label
        detailLabel.textColor = .secondaryLabel
        setNeedsLayout()
    }

    func configureAccessibilityActions(
        canMoveEarlier: Bool,
        canMoveLater: Bool
    ) {
        var actions: [UIAccessibilityCustomAction] = []

        if canMoveEarlier {
            actions.append(
                UIAccessibilityCustomAction(
                    name: "Move Earlier",
                    target: self,
                    selector: #selector(performMoveEarlierAccessibilityAction)
                )
            )
        }

        if canMoveLater {
            actions.append(
                UIAccessibilityCustomAction(
                    name: "Move Later",
                    target: self,
                    selector: #selector(performMoveLaterAccessibilityAction)
                )
            )
        }

        accessibilityCustomActions = actions
    }

    @objc func performMoveEarlierAccessibilityAction() -> Bool {
        guard let onMoveEarlier else {
            return false
        }

        onMoveEarlier()
        return true
    }

    @objc func performMoveLaterAccessibilityAction() -> Bool {
        guard let onMoveLater else {
            return false
        }

        onMoveLater()
        return true
    }

    func makeLayoutItem(
        contentSizeCategory: UIContentSizeCategory? = nil
    ) -> WeatherTilesLayoutItem {
        let fonts = measurementFonts(
            contentSizeCategory: contentSizeCategory
        )
        let textWidths = [
            singleLineWidth(text: titleLabel.text, font: fonts.title),
            singleLineWidth(text: valueLabel.text, font: fonts.value),
            detailLabel.isHidden
                ? .zero
                : singleLineWidth(
                    text: detailLabel.text,
                    font: fonts.detail
                )
        ]
        let preferredContentWidth = max(
            Layout.symbolSize,
            textWidths.max() ?? .zero
        )

        return WeatherTilesLayoutItem(
            preferredWidth: ceil(
                preferredContentWidth + Layout.contentInset * 2
            ),
            minimumHeight: ceil(
                minimumContentHeight(
                    titleFont: fonts.title,
                    valueFont: fonts.value,
                    detailFont: fonts.detail
                )
            )
        )
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
            baseFont: Typography.titleBaseFont,
            color: .secondaryLabel
        )
        configure(
            valueLabel,
            textStyle: .title1,
            baseFont: Typography.valueBaseFont,
            color: .label
        )
        configure(
            detailLabel,
            textStyle: .caption2,
            baseFont: Typography.detailBaseFont,
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

    func singleLineWidth(text: String?, font: UIFont) -> CGFloat {
        guard let text, !text.isEmpty else {
            return .zero
        }

        return ceil(
            (text as NSString).size(
                withAttributes: [.font: font]
            ).width
        )
    }

    func minimumContentHeight(
        titleFont: UIFont,
        valueFont: UIFont,
        detailFont: UIFont
    ) -> CGFloat {
        let titleHeight = ceil(titleFont.lineHeight)
        let valueHeight = ceil(valueFont.lineHeight)
        let detailHeight = detailLabel.isHidden
            ? .zero
            : ceil(detailFont.lineHeight) + Layout.titleSpacing

        return Layout.contentInset
            + Layout.symbolSize
            + Layout.valueSpacing
            + valueHeight
            + Layout.detailSpacing
            + detailHeight
            + titleHeight
            + Layout.contentInset
    }

    func measurementFonts(
        contentSizeCategory: UIContentSizeCategory?
    ) -> (title: UIFont, value: UIFont, detail: UIFont) {
        guard let contentSizeCategory else {
            return (
                titleLabel.font,
                valueLabel.font,
                detailLabel.font
            )
        }

        let traits = UITraitCollection(
            preferredContentSizeCategory: contentSizeCategory
        )

        return (
            UIFontMetrics(forTextStyle: .caption1).scaledFont(
                for: Typography.titleBaseFont,
                compatibleWith: traits
            ),
            UIFontMetrics(forTextStyle: .title1).scaledFont(
                for: Typography.valueBaseFont,
                compatibleWith: traits
            ),
            UIFontMetrics(forTextStyle: .caption2).scaledFont(
                for: Typography.detailBaseFont,
                compatibleWith: traits
            )
        )
    }

    func clearFrames() {
        symbolImageView.frame = .zero
        titleLabel.frame = .zero
        valueLabel.frame = .zero
        detailLabel.frame = .zero
    }
}
