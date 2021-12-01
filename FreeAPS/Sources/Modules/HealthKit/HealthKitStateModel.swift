import Combine
import SwiftUI

extension AppleHealthKit {
    final class StateModel: BaseStateModel<Provider> {
        @Injected() var healthKitManager: HealthKitManager!

        @Published var useAppleHealth = false
        @Published var didRequestAppleHealthPermissions = false
        @Published var needShowInformationTextForSetPermissions = false

        override func subscribe() {
            useAppleHealth = settingsManager.settings.useAppleHealth

            subscribeSetting(\.needShowInformationTextForSetPermissions, on: $needShowInformationTextForSetPermissions) { _ in
                needShowInformationTextForSetPermissions = false
            }

            $useAppleHealth
                .removeDuplicates()
                .sink { [weak self] value in
                    guard let self = self else { return }
                    guard value else {
                        self.settingsManager.settings.useAppleHealth = false
                        self.needShowInformationTextForSetPermissions = false
                        return
                    }

                    if !self.didRequestAppleHealthPermissions {
                        self.healthKitManager.requestPermission { status, error in
                            guard error == nil else {
                                return
                            }
                            self.settingsManager.settings.useAppleHealth = status
                            DispatchQueue.main.async {
                                self.didRequestAppleHealthPermissions = true
                                if !self.healthKitManager.areAllowAllPermissions {
                                    self.needShowInformationTextForSetPermissions = true
                                }
                            }
                        }
                    } else {
                        if !self.healthKitManager.areAllowAllPermissions {
                            self.needShowInformationTextForSetPermissions = true
                        }
                        self.settingsManager.settings.useAppleHealth = true
                    }
                }
                .store(in: &lifetime)
        }
    }
}