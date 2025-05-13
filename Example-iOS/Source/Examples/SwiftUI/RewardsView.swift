//
//  RewardsView.swift
//  Preview (iOS)
//
//  Created by David Skuza on 4/21/25.
//  Copyright © 2025 Rive. All rights reserved.
//

import SwiftUI
import RiveRuntime

class RewardsViewModel: RiveViewModel {
    enum RewardType: String, CaseIterable {
        case coin = "Coin"
        case gem = "Gem"
    }

    private var instance: RiveDataBindingViewModel.Instance? = nil

    @Published var rewardType: RewardType = .coin {
        didSet {
            rewardTypeProperty?.value = rewardType.rawValue
        }
    }

    private var rewardTypeProperty: RiveDataBindingViewModel.Instance.EnumProperty? {
        return instance?.enumProperty(fromPath: "Item_Selection/Item_Selection")
    }

    @Published var coinCount: Int = 0 {
        didSet {
            coinCountProperty?.value = Float(coinCount)
        }
    }

    private var coinCountProperty: RiveDataBindingViewModel.Instance.NumberProperty? {
        return instance?.numberProperty(fromPath: "Coin/Item_Value")
    }

    @Published var gemCount: Int = 0 {
        didSet {
            gemCountProperty?.value = Float(gemCount)
        }
    }

    private var gemCountProperty: RiveDataBindingViewModel.Instance.NumberProperty? {
        return instance?.numberProperty(fromPath: "Gem/Item_Value")
    }

    @Published var price: Int = 0 {
        didSet {
            priceProperty?.value = Float(price)
        }
    }

    private var priceProperty: RiveDataBindingViewModel.Instance.NumberProperty? {
        return instance?.numberProperty(fromPath: "Price_Value")
    }

    @Published var initialButtonText: String = "" {
        didSet {
            initialButtonTextProperty?.value = initialButtonText
        }
    }

    private var initialButtonTextProperty: RiveDataBindingViewModel.Instance.StringProperty? {
        return instance?.stringProperty(fromPath: "Button/State_1")
    }

    @Published var isPresentingAlert = false
    private(set) var alertMessage: String = ""

    init() {
        super.init(fileName: "rewards")

        riveModel?.enableAutoBind { [weak self] instance in
            guard let self else { return }
            self.instance = instance

            // Set new default values based on the auto-bound instance
            if let rewardTypeProperty, let reward = RewardType(rawValue: rewardTypeProperty.value) { rewardType = reward }
            if let coinCountProperty { coinCount = Int(coinCountProperty.value) }
            if let gemCountProperty { gemCount = Int(gemCountProperty.value) }
            if let priceProperty { price = Int(priceProperty.value) }
            if let initialButtonTextProperty { initialButtonText = initialButtonTextProperty.value }

            instance.triggerProperty(fromPath: "Coin/Icon_React")?.addListener { [weak self] in
                guard let self, let coins = coinCountProperty?.value else { return }
                alertMessage = "You have \(coins) coins!"
                isPresentingAlert = true
            }

            instance.triggerProperty(fromPath: "Gem/Icon_React")?.addListener { [weak self] in
                guard let self, let gems = gemCountProperty?.value else { return }
                alertMessage = "You have \(gems) gems!"
                isPresentingAlert = true
            }
        }
    }

    override func reset() {
        super.reset()
        
        rewardType = rewardType
        coinCount = coinCount
        gemCount = gemCount
        price = price
        initialButtonText = initialButtonText
    }
}

struct RewardsSettingsView: View {
    @ObservedObject private var viewModel: RewardsViewModel

    init(viewModel: RewardsViewModel) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
    }

    var body: some View {
        Form {
            Section("Reward") {
                Picker("Type", selection: $viewModel.rewardType) {
                    Text("Coin").tag(RewardsViewModel.RewardType.coin)
                    Text("Gem").tag(RewardsViewModel.RewardType.gem)
                }

                HStack {
                    Text("Coin Count")
                    TextField("Coin Count", value: $viewModel.coinCount, formatter: NumberFormatter()).multilineTextAlignment(.trailing)
                }

                HStack {
                    Text("Gem Count")
                    TextField("Gem Count", value: $viewModel.gemCount, formatter: NumberFormatter()).multilineTextAlignment(.trailing)
                }

                HStack {
                    Text("Price")
                    TextField("Price", value: $viewModel.price, formatter: NumberFormatter()).multilineTextAlignment(.trailing)
                }
            }

            Section("Button") {
                HStack {
                    Text("Initial Text")
                    TextField("Initial Text", text: $viewModel.initialButtonText).multilineTextAlignment(.trailing)
                }
            }

            Section {
                Button(role: .destructive) {
                    viewModel.reset()
                } label: {
                    Text("Reset")
                }
            }
        }
    }
}

struct RewardsView: DismissableView {
    var dismiss: () -> Void = {}

    @StateObject var rewardsViewModel: RewardsViewModel
    @State var isPresentingSettings = false

    init() {
        let viewModel = RewardsViewModel()
        _rewardsViewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        rewardsViewModel
            .view()
            .toolbar {
                Button("Settings") {
                    isPresentingSettings = true
                }
            }
            .sheet(isPresented: $isPresentingSettings) {
                if #available(iOS 16, *) {
                    RewardsSettingsView(viewModel: rewardsViewModel)
                        .presentationDetents([.medium])
                }
            }
            .alert("Congratulations!", isPresented: $rewardsViewModel.isPresentingAlert) {
                Button("Okay") { }
            } message: {
                Text(rewardsViewModel.alertMessage)
            }
    }
}
