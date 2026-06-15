//
//  LocationWeatherPageViewController.swift
//  wetterApp
//
//  Created by Bahadir Sonmez on 15.06.2026.
//

import UIKit

final class LocationWeatherPageViewController: UIViewController {

    // MARK: - Dependencies

    let pageViewController: UIPageViewController
    let pageControl: UIPageControl
    private let makeWeatherViewController: (WeatherLocationSource) -> LocationWeatherViewController

    // MARK: - State

    private(set) var sources: [WeatherLocationSource] = []
    var onSourceChange: ((WeatherLocationSource) -> Void)?

    // MARK: - Initialization

    init(
        makeWeatherViewController: @escaping (WeatherLocationSource) -> LocationWeatherViewController
    ) {
        self.makeWeatherViewController = makeWeatherViewController
        self.pageViewController = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            options: nil
        )
        self.pageControl = UIPageControl()
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .systemBackground

        addChild(pageViewController)
        view.addSubview(pageViewController.view)
        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        pageViewController.didMove(toParent: self)

        pageViewController.dataSource = self
        pageViewController.delegate = self

        view.addSubview(pageControl)
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        pageControl.addTarget(
            self,
            action: #selector(pageControlChanged),
            for: .valueChanged
        )
        // Ensure page control is visible on different backgrounds
        pageControl.pageIndicatorTintColor = .systemGray3
        pageControl.currentPageIndicatorTintColor = .label
        pageControl.currentPage = 0

        NSLayoutConstraint.activate([
            pageViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            pageViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pageViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            pageControl.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                constant: -4
            ),
            pageControl.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor)
        ])
    }

    // MARK: - Public API

    func update(
        sources: [WeatherLocationSource],
        selectedSource: WeatherLocationSource
    ) {
        self.sources = sources
        pageControl.numberOfPages = sources.count

        let targetIndex = sources.firstIndex(of: selectedSource) ?? 0
        pageControl.currentPage = targetIndex

        if let currentVC = currentWeatherViewController, currentVC.source == selectedSource {
            // Already displaying the correct source, skip updating page view controller to avoid flickering
            return
        }

        let direction: UIPageViewController.NavigationDirection = .forward
        let targetVC = makeWeatherViewController(selectedSource)

        pageViewController.setViewControllers(
            [targetVC],
            direction: direction,
            animated: false,
            completion: nil
        )
    }

    var currentWeatherViewController: LocationWeatherViewController? {
        pageViewController.viewControllers?.first as? LocationWeatherViewController
    }

    // MARK: - Actions

    @objc
    func pageControlChanged() {
        let index = pageControl.currentPage
        guard sources.indices.contains(index) else {
            return
        }

        let targetSource = sources[index]
        let currentSource = currentWeatherViewController?.source
        let currentIndex = sources.firstIndex(where: { $0 == currentSource }) ?? 0

        let direction: UIPageViewController.NavigationDirection = index > currentIndex ? .forward : .reverse
        let targetVC = makeWeatherViewController(targetSource)

        pageViewController.setViewControllers(
            [targetVC],
            direction: direction,
            animated: true,
            completion: nil
        )
        onSourceChange?(targetSource)
    }
}

// MARK: - UIPageViewControllerDataSource

extension LocationWeatherPageViewController: UIPageViewControllerDataSource {

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        guard
            let weatherVC = viewController as? LocationWeatherViewController,
            let index = sources.firstIndex(of: weatherVC.source),
            index > 0
        else {
            return nil
        }

        return makeWeatherViewController(sources[index - 1])
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        guard
            let weatherVC = viewController as? LocationWeatherViewController,
            let index = sources.firstIndex(of: weatherVC.source),
            index < sources.count - 1
        else {
            return nil
        }

        return makeWeatherViewController(sources[index + 1])
    }
}

// MARK: - UIPageViewControllerDelegate

extension LocationWeatherPageViewController: UIPageViewControllerDelegate {

    func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        guard
            completed,
            let weatherVC = pageViewController.viewControllers?.first as? LocationWeatherViewController,
            let index = sources.firstIndex(of: weatherVC.source)
        else {
            return
        }

        pageControl.currentPage = index
        onSourceChange?(weatherVC.source)
    }
}
