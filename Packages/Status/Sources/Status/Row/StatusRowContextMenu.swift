import Env
import Foundation
import SwiftUI

struct StatusRowContextMenu: View {
  @EnvironmentObject private var preferences: UserPreferences
  @EnvironmentObject private var account: CurrentAccount
  @EnvironmentObject private var currentInstance: CurrentInstance

  @ObservedObject var viewModel: StatusRowViewModel

  var body: some View {
    if !viewModel.isRemote {
      Button { Task {
        if viewModel.isFavorited {
          await viewModel.unFavorite()
        } else {
          await viewModel.favorite()
        }
      } } label: {
        Label(viewModel.isFavorited ? "status.action.unfavorite" : "status.action.favorite", systemImage: "star")
      }
      Button { Task {
        if viewModel.isReblogged {
          await viewModel.unReblog()
        } else {
          await viewModel.reblog()
        }
      } } label: {
        Label(viewModel.isReblogged ? "status.action.unboost" : "status.action.boost", systemImage: "arrow.left.arrow.right.circle")
      }
      Button { Task {
        if viewModel.isBookmarked {
          await viewModel.unbookmark()
        } else {
          await viewModel.bookmark()
        }
      } } label: {
        Label(viewModel.isBookmarked ? "status.action.unbookmark" : "status.action.bookmark",
              systemImage: "bookmark")
      }
      Button {
        viewModel.routerPath.presentedSheet = .replyToStatusEditor(status: viewModel.status)
      } label: {
        Label("status.action.reply", systemImage: "arrowshape.turn.up.left")
      }
    }

    if viewModel.status.visibility == .pub, !viewModel.isRemote {
      Button {
        viewModel.routerPath.presentedSheet = .quoteStatusEditor(status: viewModel.status)
      } label: {
        Label("status.action.quote", systemImage: "quote.bubble")
      }
    }

    Divider()

    if let urlString = viewModel.status.reblog?.url ?? viewModel.status.url,
       let url = URL(string: urlString) {
      ShareLink(item: url,
                subject: Text(viewModel.status.reblog?.account.safeDisplayName ?? viewModel.status.account.safeDisplayName),
                message: Text(viewModel.status.reblog?.content.asRawText ?? viewModel.status.content.asRawText)) {
        Label("status.action.share", systemImage: "square.and.arrow.up")
      }
    }

    if let url = URL(string: viewModel.status.reblog?.url ?? viewModel.status.url ?? "") {
      Button { UIApplication.shared.open(url) } label: {
        Label("status.action.view-in-browser", systemImage: "safari")
      }
    }

    Button {
      UIPasteboard.general.string = viewModel.status.reblog?.content.asRawText ?? viewModel.status.content.asRawText
    } label: {
      Label("status.action.copy-text", systemImage: "doc.on.doc")
    }

    if let lang = preferences.serverPreferences?.postLanguage ?? Locale.current.language.languageCode?.identifier
    {
      Button {
        Task {
          await viewModel.translate(userLang: lang)
        }
      } label: {
        if let statusLang = viewModel.getStatusLang(),
           let languageName = Locale.current.localizedString(forLanguageCode: statusLang)
        {
          Label("status.action.translate-from-\(languageName)", systemImage: "captions.bubble")
        } else {
          Label("status.action.translate", systemImage: "captions.bubble")
        }
      }
    }

    if account.account?.id == viewModel.status.account.id {
      Section("status.action.section.your-post") {
        Button {
          Task {
            if viewModel.isPinned {
              await viewModel.unPin()
            } else {
              await viewModel.pin()
            }
          }
        } label: {
          Label(viewModel.isPinned ? "status.action.unpin" : "status.action.pin", systemImage: viewModel.isPinned ? "pin.fill" : "pin")
        }
        if currentInstance.isEditSupported {
          Button {
            viewModel.routerPath.presentedSheet = .editStatusEditor(status: viewModel.status)
          } label: {
            Label("status.action.edit", systemImage: "pencil")
          }
        }
        Button(role: .destructive,
               action: { viewModel.showDeleteAlert = true },
               label: { Label("status.action.delete", systemImage: "trash") })
      }
    } else {
      if !viewModel.isRemote {
        Section(viewModel.status.account.acct) {
          Button {
            viewModel.routerPath.presentedSheet = .mentionStatusEditor(account: viewModel.status.account, visibility: .pub)
          } label: {
            Label("status.action.mention", systemImage: "at")
          }
          Button {
            viewModel.routerPath.presentedSheet = .mentionStatusEditor(account: viewModel.status.account, visibility: .direct)
          } label: {
            Label("status.action.message", systemImage: "tray.full")
          }
        }
      }
      Section {
        Button(role: .destructive) {
          viewModel.routerPath.presentedSheet = .report(status: viewModel.status.reblogAsAsStatus ?? viewModel.status)
        } label: {
          Label("status.action.report", systemImage: "exclamationmark.bubble")
        }
      }
    }
  }
}
