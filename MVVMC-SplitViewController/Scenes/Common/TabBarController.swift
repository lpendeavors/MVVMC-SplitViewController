//
//  TabBarController.swift
//  MVVMC-SplitViewController
//
//  Created by Mathew Gacy on 1/8/18.
//  Copyright © 2018 Mathew Gacy. All rights reserved.
//

import UIKit

class TabBarController: UITabBarController {

    let detailNavigationController: UINavigationController

    // MARK: - Lifecycle

    init(detailNavigationController: UINavigationController) {
        self.detailNavigationController = detailNavigationController
        super.init(nibName: nil, bundle: nil)
        delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: -

    func updateSecondaryWithDetail(from primaryContainer: PrimaryContainerType, animated: Bool = false) {
        switch primaryContainer.detailView {
        case .collapsed(let detailViewController):
            detailNavigationController.setViewControllers([detailViewController], animated: animated)
        case .separated(let detailViewController):
            detailNavigationController.setViewControllers([detailViewController], animated: animated)
        case .placeholder:
            detailNavigationController.setViewControllers([primaryContainer.makePlaceholderViewController()],
                                                          animated: animated)
        }
    }

    func replaceDetail(withEmpty viewController: UIViewController & PlaceholderViewControllerType) {
        detailNavigationController.setViewControllers([viewController], animated: true)
    }

}

// MARK: - UITabBarControllerDelegate
extension TabBarController: UITabBarControllerDelegate {

    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        // Prevent selection of the same tab twice (which would reset its navigation controller)
        return selectedViewController === viewController ? false : true
    }

    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        guard let svc = splitViewController, let selectedNavController = viewController as? PrimaryContainerType else {
            fatalError("Wrong view controller type: \(viewController)")
        }
        // If split view controller is collapsed, detail view will already be on `selectedNavController.viewControllers`;
        // otherwise, we need to change the secondary view controller to the selected tab's detail view.
        if !svc.isCollapsed {
            updateSecondaryWithDetail(from: selectedNavController)
        }
    }

}

// MARK: - UISplitViewControllerDelegate
extension TabBarController: UISplitViewControllerDelegate {

    // MARK: Collapsing the Interface

    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        guard let navigationControllers = viewControllers as? [PrimaryContainerType] else {
            fatalError("Wrong view controller type: \(String(describing: viewControllers?.filter { !($0 is PrimaryContainerType) }))")
        }

        navigationControllers.forEach { $0.collapseDetail() }
        return true // Prevent UIKit from performing default collapse behavior
    }

    // MARK: Expanding the Interface

    func splitViewController(_ splitViewController: UISplitViewController, separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {
        guard
            let navigationControllers = viewControllers as? [PrimaryContainerType],
            let selectedNavController = selectedViewController as? PrimaryContainerType else {
                fatalError("Wrong view controller type: \(String(describing: viewControllers?.filter { !($0 is PrimaryContainerType) }))")
        }

        navigationControllers.forEach { $0.separateDetail() }

        // There is no point in hiding the primary view controller with a placeholder detail view
        if case .placeholder = selectedNavController.detailView, splitViewController.preferredDisplayMode == .primaryHidden {
            splitViewController.preferredDisplayMode = .allVisible
        }
        updateSecondaryWithDetail(from: selectedNavController)
        return detailNavigationController
    }

    // MARK: Overriding the Presentation Behavior

    func splitViewController(_ splitViewController: UISplitViewController, showDetail vc: UIViewController, sender: Any?) -> Bool {
        guard let selectedNavController = selectedViewController as? UINavigationController & PrimaryContainerType else {
            fatalError("\(#function) FAILED : wrong view controller type")
        }

        vc.navigationItem.leftItemsSupplementBackButton = true
        vc.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem

        if splitViewController.isCollapsed {
            selectedNavController.pushViewController(vc, animated: true)
            selectedNavController.detailView = .collapsed(vc)
        } else {
            switch selectedNavController.detailView {
            // Animate only the initial presentation of the detail vc
            case .placeholder:
                detailNavigationController.setViewControllers([vc], animated: true)
            default:
                detailNavigationController.setViewControllers([vc], animated: false)
            }
            selectedNavController.detailView = .separated(vc)
        }
        return true // Prevent UIKit from performing default behavior
    }

}
