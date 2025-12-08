import SwiftUI

struct NarrativeLabView: View {
  @EnvironmentObject private var viewModel: NarrativeViewModel
  @EnvironmentObject private var creationViewModel: CreationViewModel
  @EnvironmentObject private var userCenterViewModel: UserCenterViewModel

  var body: some View {
    NavigationView {
      ScrollView {
        VStack(spacing: 16) {
          bindingSection
          TokenUsageStrip(usage: viewModel.tokenUsage)
          inputSection
          threadsSection
          beatsSection
          compassSection
          paymentShortcut
        }
        .padding()
      }
      .navigationTitle("多线叙事")
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button {
            Task { await viewModel.loadAll() }
          } label: {
            Image(systemName: "arrow.clockwise")
          }
        }
      }
      .task {
        await autoBindProject()
      }
      .alert(isPresented: Binding<Bool>(get: { viewModel.errorMessage != nil }, set: { _ in viewModel.errorMessage = nil })) {
        Alert(title: Text("提示"), message: Text(viewModel.errorMessage ?? ""), dismissButton: .default(Text("好的")))
      }
    }
  }

  private var bindingSection: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("项目绑定").font(.headline)
      TextField("项目ID", text: $viewModel.projectId)
        .keyboardType(.numbersAndPunctuation)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
      HStack {
        Button {
          Task { await viewModel.attachProject(viewModel.projectId) }
        } label: {
          Label("绑定并拉取", systemImage: "link")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        Button {
          Task { await viewModel.refreshCompass() }
        } label: {
          Label("更新罗盘", systemImage: "location.north.line")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
      }
    }
    .padding()
    .background(.ultraThinMaterial)
    .clipShape(RoundedRectangle(cornerRadius: 16))
  }

  private var inputSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("叙事线输入").font(.headline)
      TextField("叙事线标题", text: $viewModel.draftTitle)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
      TextField("概要 / 灵感", text: $viewModel.draftSummary, axis: .vertical)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
      TextField("扩写提示（可用于继续当前线）", text: $viewModel.draftExpansion, axis: .vertical)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))

      HStack {
        Button {
          viewModel.recalculateTokens()
          Task { await viewModel.createThread() }
        } label: {
          Label("新增叙事线", systemImage: "plus.circle.fill")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        Button {
          viewModel.recalculateTokens()
          Task { await viewModel.continueThread() }
        } label: {
          Label("续写当前线", systemImage: "play.fill")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .disabled(viewModel.selectedThreadId == nil)
      }
    }
    .padding()
    .background(Color(.systemBackground))
    .clipShape(RoundedRectangle(cornerRadius: 16))
    .onChange(of: viewModel.draftTitle) { _ in viewModel.recalculateTokens() }
    .onChange(of: viewModel.draftSummary) { _ in viewModel.recalculateTokens() }
    .onChange(of: viewModel.draftExpansion) { _ in viewModel.recalculateTokens() }
  }

  private var threadsSection: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        Text("叙事线").font(.headline)
        Spacer()
        Text("共 \(viewModel.threads.count) 条").font(.caption).foregroundStyle(.secondary)
      }
      LazyVStack(spacing: 10) {
        ForEach(viewModel.threads) { thread in
          NarrativeThreadCard(thread: thread, isSelected: thread.threadId == viewModel.selectedThreadId) {
            viewModel.selectedThreadId = thread.threadId
            Task { try? await viewModel.fetchBeatsIfNeeded() }
          }
        }
        if viewModel.isLoading {
          ProgressView().frame(maxWidth: .infinity)
        }
        if viewModel.threads.isEmpty && !viewModel.projectId.isEmpty {
          Text("还没有叙事线，先填入标题与概要再点击新增叙事线。")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
    }
  }

  private var beatsSection: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        Text("节拍 / 片段").font(.headline)
        Spacer()
        if let threadId = viewModel.selectedThreadId {
          Text("Line \(threadId)").font(.caption).foregroundStyle(.secondary)
        }
      }
      LazyVStack(alignment: .leading, spacing: 8) {
        ForEach(viewModel.beats) { beat in
          VStack(alignment: .leading, spacing: 6) {
            HStack {
              Text("#\(beat.orderIndex)")
                .font(.caption)
                .foregroundStyle(.secondary)
              Spacer()
              Text("\(beat.tokensUsed ?? 0) tks")
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            Text(beat.content)
              .font(.body)
            if let prompt = beat.prompt, !prompt.isEmpty {
              Text("提示: \(prompt)")
                .font(.caption)
                .foregroundStyle(.secondary)
            }
          }
          .padding()
          .background(Color(.secondarySystemBackground))
          .clipShape(RoundedRectangle(cornerRadius: 12))
        }
      }
    }
  }

  private var compassSection: some View {
    Group {
      if let compass = viewModel.compass {
        MemoryCompassPanel(compass: compass)
      } else {
        VStack(alignment: .leading, spacing: 8) {
          Text("记忆罗盘").font(.headline)
          Text("绑定项目并刷新后，展示叙事记忆锚点与决策。")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
      }
    }
  }

  private var paymentShortcut: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("算力与积分").font(.headline)
      Text("根据本地预估 Token 消耗，快速跳转支付补充积分。")
        .font(.caption)
        .foregroundStyle(.secondary)
      HStack {
        TokenUsageStrip(usage: viewModel.tokenUsage)
        Spacer()
        NavigationLink {
          PaymentCenterView()
            .environmentObject(userCenterViewModel)
        } label: {
          Label("去充值", systemImage: "creditcard")
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.green.opacity(0.15))
            .clipShape(Capsule())
        }
      }
    }
    .padding()
    .background(Color(.systemBackground))
    .clipShape(RoundedRectangle(cornerRadius: 16))
  }

  private func autoBindProject() async {
    if viewModel.projectId.isEmpty, !creationViewModel.projectId.isEmpty {
      viewModel.projectId = creationViewModel.projectId
      await viewModel.loadAll()
    }
  }
}
