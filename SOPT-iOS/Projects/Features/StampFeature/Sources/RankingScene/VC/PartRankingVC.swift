//
//  PartRankingVC.swift
//  StampFeature
//
//  Created by Aiden.lee on 2024/03/31.
//  Copyright © 2024 SOPT-iOS. All rights reserved.
//

import UIKit

import Core
import Domain
import DSKit

import Combine
import SnapKit
import Then

import StampFeatureInterface
import BaseFeatureDependency

public class PartRankingVC: UIViewController, PartRankingViewControllable {

  // MARK: - Properties

  public var viewModel: PartRankingViewModel!
  private var cancelBag = CancelBag()

  lazy var dataSource: UICollectionViewDiffableDataSource<RankingSection, AnyHashable>! = nil

  // MARK: - RankingCoordinatable

  public var onCellTap: ((Part) -> Void)?
  public var onNaviBackTap: (() -> Void)?

  // MARK: - UI Components

  lazy var naviBar = STNavigationBar(self, type: .titleWithLeftButton, ignorePopAction: true)
    .setTitleTypoStyle(.SoptampFont.h2)
    .setTitle("파트별 랭킹")
    .setRightButton(.none)

  private lazy var rankingCollectionView: UICollectionView = {
    let cv = UICollectionView(frame: .zero, collectionViewLayout: self.createLayout())
    cv.showsVerticalScrollIndicator = true
    cv.backgroundColor = .white
    cv.refreshControl = refresher
    return cv
  }()

  private let refresher: UIRefreshControl = {
    let rf = UIRefreshControl()
    return rf
  }()

  // MARK: - View Life Cycle
  private let rankingViewType: RankingViewType

  init(rankingViewType: RankingViewType) {
    self.rankingViewType = rankingViewType

    super.init(nibName: nil, bundle: nil)

    guard case .currentGeneration(let info) = rankingViewType else { return }

    let navigationTitle = String(describing: info.currentGeneration) + "기 랭킹"
    self.naviBar.setTitle(navigationTitle)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public override func viewDidLoad() {
    super.viewDidLoad()
    self.setUI()
    self.setLayout()
    self.setDataSource()
    self.setDelegate()
    self.registerCells()
    self.bindViews()
    self.bindViewModels()
  }
}

// MARK: - UI & Layouts

extension PartRankingVC {

  private func setUI() {
    self.view.backgroundColor = .white
    self.navigationController?.isNavigationBarHidden = true
  }

  private func setLayout() {
    self.view.addSubviews(naviBar, rankingCollectionView)

    naviBar.snp.makeConstraints { make in
      make.leading.top.trailing.equalTo(view.safeAreaLayoutGuide)
    }

    rankingCollectionView.snp.makeConstraints { make in
      make.top.equalTo(naviBar.snp.bottom).offset(4)
      make.leading.trailing.equalToSuperview()
      make.bottom.equalToSuperview()
    }
  }
}

// MARK: - Methods

extension PartRankingVC {

  private func bindViews() {
    naviBar.leftButtonTapped
      .withUnretained(self)
      .sink { owner, _ in
        owner.onNaviBackTap?()
      }.store(in: cancelBag)
  }

  private func bindViewModels() {
    let refreshStarted = refresher.publisher(for: .valueChanged)
      .mapVoid()
      .asDriver()

    let input = PartRankingViewModel.Input(
      viewDidLoad: Driver.just(()),
      refreshStarted: refreshStarted
    )

    let output = self.viewModel.transform(from: input, cancelBag: self.cancelBag)

    output.partRanking
      .receive(on: DispatchQueue.main)
      .sink { [weak self] partRankingModels in
        self?.applySnapshot(model: partRankingModels)
      }.store(in: cancelBag)
  }

  private func setDelegate() {
    rankingCollectionView.delegate = self
  }

  private func registerCells() {
    PartRankingChartCVC.register(target: rankingCollectionView)
    PartRankingListCVC.register(target: rankingCollectionView)
  }

  private func setDataSource() {
    dataSource = UICollectionViewDiffableDataSource(collectionView: rankingCollectionView, cellProvider: { collectionView, indexPath, itemIdentifier in
      switch RankingSection.type(indexPath.section) {
      case .chart:
        guard let chartCell = collectionView.dequeueReusableCell(withReuseIdentifier: PartRankingChartCVC.className, for: indexPath) as? PartRankingChartCVC,
              let chartCellModel = itemIdentifier as? PartRankingChartModel else { return UICollectionViewCell() }
        chartCell.setData(model: chartCellModel)
        return chartCell

      case .list:
        guard let rankingListCell = collectionView.dequeueReusableCell(withReuseIdentifier: PartRankingListCVC.className, for: indexPath) as? PartRankingListCVC,
              let model = itemIdentifier as? PartRankingModel else { return UICollectionViewCell() }
        rankingListCell.setData(model: model)

        return rankingListCell
      }
    })
  }

  func applySnapshot(model: [PartRankingModel]) {
    var snapshot = NSDiffableDataSourceSnapshot<RankingSection, AnyHashable>()
    snapshot.appendSections([.chart, .list])
    let chartCellModel = PartRankingChartModel.init(ranking: model)
    snapshot.appendItems([chartCellModel], toSection: .chart)
    let listModels = model.sorted(by: { $0.rank < $1.rank })
    snapshot.appendItems(listModels, toSection: .list)
    dataSource.apply(snapshot, animatingDifferences: false)
    self.view.setNeedsLayout()
  }

  private func endRefresh() {
    self.refresher.endRefreshing()
  }
}

extension PartRankingVC: UICollectionViewDelegate {
  public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    guard indexPath.section >= 1 else { return }

    guard let tappedCell = collectionView.cellForItem(at: indexPath) as? PartRankingListCVC,
          let model = tappedCell.model else { return }
    guard let part = Part(rawValue: model.part) else { return }
    self.onCellTap?(part)
  }
}
