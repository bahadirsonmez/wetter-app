import UIKit

final class LocationWeatherStatusView: UIView {

    // MARK: - Subviews

    let titleLabel = UILabel()
    let messageLabel = UILabel()
    let actionButton = UIButton(type: .system)

    private let contentStackView = UIStackView()

    // MARK: - Properties

    var onAction: (() -> Void)?

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuration

    func configure(
        title: String,
        message: String,
        actionTitle: String?
    ) {
        titleLabel.text = title
        messageLabel.text = message
        actionButton.setTitle(actionTitle, for: .normal)
        actionButton.isHidden = actionTitle == nil
    }

    // MARK: - Actions

    @objc
    private func actionButtonTapped() {
        onAction?()
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
        configureActionButton()
        configureContentStackView()

        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentStackView)

        NSLayoutConstraint.activate([
            contentStackView.centerYAnchor.constraint(
                equalTo: centerYAnchor
            ),
            contentStackView.leadingAnchor.constraint(
                equalTo: layoutMarginsGuide.leadingAnchor
            ),
            contentStackView.trailingAnchor.constraint(
                equalTo: layoutMarginsGuide.trailingAnchor
            ),
            contentStackView.topAnchor.constraint(
                greaterThanOrEqualTo: layoutMarginsGuide.topAnchor
            ),
            contentStackView.bottomAnchor.constraint(
                lessThanOrEqualTo: layoutMarginsGuide.bottomAnchor
            )
        ])
    }

    private func configureLabels() {
        titleLabel.font = .preferredFont(forTextStyle: .title2)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center

        messageLabel.font = .preferredFont(forTextStyle: .body)
        messageLabel.adjustsFontForContentSizeCategory = true
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
    }

    private func configureActionButton() {
        actionButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        actionButton.titleLabel?.adjustsFontForContentSizeCategory = true
        actionButton.isHidden = true
        actionButton.addTarget(
            self,
            action: #selector(actionButtonTapped),
            for: .touchUpInside
        )
    }

    private func configureContentStackView() {
        contentStackView.axis = .vertical
        contentStackView.alignment = .fill
        contentStackView.spacing = 12
        contentStackView.addArrangedSubview(titleLabel)
        contentStackView.addArrangedSubview(messageLabel)
        contentStackView.addArrangedSubview(actionButton)
    }
}
