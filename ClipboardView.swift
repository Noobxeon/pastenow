import SwiftUI
import AppKit

extension Notification.Name {
    static let togglePinNotification = Notification.Name("togglePinNotification")
}

struct ClipboardView: View {
    @StateObject var viewModel = ClipboardViewModel()
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                TextField("搜索...", text: $viewModel.searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Spacer()
                Button("清空全部") {
                    viewModel.clearAll()
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)

            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(viewModel.filteredItems) { item in
                        ClipboardCard(
                            item: item,
                            onCopy: { viewModel.copy(item) },
                            onTogglePin: { viewModel.togglePin(item) },
                            onDelete: { viewModel.delete(item) }
                        )
                        .padding(.horizontal)
                    }
                }
            }
        }
        .frame(minWidth: 360, minHeight: 450)
        .background(Color.clear)
    }
}

struct ClipboardCard: View {
    let item: ClipboardItem
    var onCopy: () -> Void
    var onTogglePin: () -> Void
    var onDelete: () -> Void

    @State private var isHovering = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        // 背景和边框变量拆分
        let cardFill: Material = .ultraThin
        let cardStroke: Color = item.isPinned ? Color.yellow : Color.clear
        let shadowOpacity: Double = isHovering ? 0.2 : 0.05
        let shadowRadius: CGFloat = isHovering ? 4 : 1
        let shadowYOffset: CGFloat = isHovering ? 2 : 1

        HStack(spacing: 12) {
            if let image = item.image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .cornerRadius(8)
                    .shadow(radius: 2, y: 1)
                    .background(Material.ultraThin)
                    .cornerRadius(10)
            } else {
                Text(item.content)
                    .lineLimit(3)
                    .font(.body)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            VStack(spacing: 8) {
                Button(action: onCopy) {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(BorderlessButtonStyle())
                .help("复制")

                Button(action: onDelete) {
                    Image(systemName: "trash")
                }
                .buttonStyle(BorderlessButtonStyle())
                .help("删除")
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(cardFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(item.isPinned ? (colorScheme == .dark ? Color.yellow.opacity(0.2) : Color.yellow.opacity(0.1)) : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(cardStroke, lineWidth: 2)
                )
                .shadow(color: .black.opacity(shadowOpacity), radius: shadowRadius, y: shadowYOffset)
        )
        .scaleEffect(isHovering ? 1.02 : 1.0)
        .onHover { hovering in
            withAnimation(.interactiveSpring(response: 0.22, dampingFraction: 0.8, blendDuration: 0.1)) {
                isHovering = hovering
            }
        }
        .contextMenu {
            Button(item.isPinned ? "取消固定" : "固定") {
                onTogglePin()
            }
        }
    }
}
