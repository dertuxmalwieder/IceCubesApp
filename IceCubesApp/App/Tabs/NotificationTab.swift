import AppAccount
import DesignSystem
import Env
import Models
import Network
import Notifications
import SwiftUI
import Timeline

struct NotificationsTab: View {
  @Environment(\.isSecondaryColumn) private var isSecondaryColumn: Bool
  @Environment(\.scenePhase) private var scenePhase

  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var client: Client
  @EnvironmentObject private var watcher: StreamWatcher
  @EnvironmentObject private var appAccount: AppAccountsManager
  @EnvironmentObject private var currentAccount: CurrentAccount
  @EnvironmentObject private var userPreferences: UserPreferences
  @EnvironmentObject private var pushNotificationsService: PushNotificationsService
  @StateObject private var routerPath = RouterPath()
  @Binding var popToRootTab: Tab

  let lockedType: Models.Notification.NotificationType?

  var body: some View {
    NavigationStack(path: $routerPath.path) {
      NotificationsListView(lockedType: lockedType)
        .withAppRouter()
        .withSheetDestinations(sheetDestinations: $routerPath.presentedSheet)
        .toolbar {
          if !isSecondaryColumn {
            statusEditorToolbarItem(routerPath: routerPath,
                                    visibility: userPreferences.postVisibility)
            if UIDevice.current.userInterfaceIdiom != .pad {
              ToolbarItem(placement: .navigationBarLeading) {
                AppAccountsSelectorView(routerPath: routerPath)
              }
            }
          }
        }
        .toolbarBackground(theme.primaryBackgroundColor.opacity(0.50), for: .navigationBar)
        .id(client.id)
    }
    .onAppear {
      routerPath.client = client
      watcher.unreadNotificationsCount = 0
      userPreferences.pushNotificationsCount = 0
    }
    .withSafariRouter()
    .environmentObject(routerPath)
    .onChange(of: $popToRootTab.wrappedValue) { popToRootTab in
      if popToRootTab == .notifications {
        routerPath.path = []
      }
    }
    .onChange(of: pushNotificationsService.handledNotification) { notification in
      if let notification, let type = notification.notification.supportedType {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
          switch type {
          case .follow, .follow_request:
            routerPath.navigate(to: .accountDetailWithAccount(account: notification.notification.account))
          default:
            if let status = notification.notification.status {
              routerPath.navigate(to: .statusDetailWithStatus(status: status))
            }
          }
        }
      }
    }
    .onChange(of: scenePhase, perform: { scenePhase in
      switch scenePhase {
      case .active:
        if isSecondaryColumn {
          watcher.unreadNotificationsCount = 0
          userPreferences.pushNotificationsCount = 0
        }
      default:
        break
      }
    })
    .onChange(of: client.id) { _ in
      routerPath.path = []
    }
  }
}
