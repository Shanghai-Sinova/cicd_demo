import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { NarrativeService, TokenEstimator, type NarrativeLine, type NarrativeCompass, type TokenUsageEstimate } from '../network/Services';
import MemoryCompassCard from '../components/MemoryCompassCard';

interface LineForm {
  title: string;
  tone: string;
  goal: string;
}

@Entry
@Component
struct NarrativePage {
  @State projectId: string = '';
  @State lines: Array<NarrativeLine> = [];
  @State activeLineId: string = '';
  @State lineForm: LineForm = { title: '主线 A', tone: '紧凑', goal: '推进主角成长' };
  @State prompt: string = '';
  @State generatedPreview: string = '';
  @State compass: NarrativeCompass = {} as NarrativeCompass;
  @State tokenEstimate: TokenUsageEstimate = { tokens: 0, characters: 0, estimated_cost_cny: 0 };
  @State pricePerK: number = 0.12;

  aboutToAppear(): void {
    if (this.projectId) {
      this.loadLines();
    }
  }

  build() {
    Column() {
      Scroll() {
        Column({ space: 16 }) {
          this.renderProjectBinding();
          this.renderLineManager();
          this.renderBeatGenerator();
          this.renderTokenEstimator();
          this.renderCompass();
          Button('返回首页')
            .type(ButtonType.Capsule)
            .backgroundColor(0xeeeeff)
            .fontColor(0x333333)
            .onClick(() => router.pushUrl({ url: 'pages/HomePage' }));
        }
        .width('100%')
        .padding({ left: 24, right: 24, top: 32, bottom: 32 });
      }
      .width('100%')
      .layoutWeight(1);
    }
    .width('100%')
    .height('100%')
    .backgroundColor(0xf7f7f9)
    .alignItems(HorizontalAlign.Center);
  }

  @Builder
  renderProjectBinding() {
    Column({ space: 12 }) {
      Text('多线叙事控制台').fontSize(22).fontWeight(FontWeight.Bold);
      TextInput({ placeholder: '项目ID', text: this.projectId })
        .onChange((value: string) => this.projectId = value)
        .border({ color: 0xdddddd, width: 1, radius: 12 })
        .padding(12)
        .width('100%');
      Row({ space: 12 }) {
        Button('同步线路')
          .type(ButtonType.Capsule)
          .backgroundColor(0x8a63ff)
          .onClick(() => this.loadLines());
        Button('刷新记忆罗盘')
          .type(ButtonType.Capsule)
          .backgroundColor(0x12b886)
          .onClick(() => this.loadCompass());
      }
    }
    .padding(16)
    .backgroundColor(0xffffff)
    .borderRadius(16);
  }

  @Builder
  renderLineManager() {
    Column({ space: 12 }) {
      Text('线路管理').fontSize(18).fontWeight(FontWeight.Medium);
      Row({ space: 12 }) {
        TextInput({ placeholder: '路线标题', text: this.lineForm.title })
          .onChange((value: string) => this.lineForm = { ...this.lineForm, title: value })
          .border({ color: 0xdddddd, width: 1, radius: 12 })
          .padding(12)
          .layoutWeight(1);
        TextInput({ placeholder: '调性/风格', text: this.lineForm.tone })
          .onChange((value: string) => this.lineForm = { ...this.lineForm, tone: value })
          .border({ color: 0xdddddd, width: 1, radius: 12 })
          .padding(12)
          .layoutWeight(1);
      }
      TextInput({ placeholder: '剧情目标', text: this.lineForm.goal })
        .onChange((value: string) => this.lineForm = { ...this.lineForm, goal: value })
        .border({ color: 0xdddddd, width: 1, radius: 12 })
        .padding(12)
        .width('100%');
      Button('新增故事线')
        .type(ButtonType.Capsule)
        .backgroundColor(0xff6ed1)
        .onClick(() => this.createLine());
      Column({ space: 8 }) {
        ForEach(this.lines, (line: NarrativeLine) => this.renderLineRow(line), (line: NarrativeLine, index: number) => `${line.line_id}-${index}`);
      }
    }
    .padding(16)
    .backgroundColor(0xffffff)
    .borderRadius(16);
  }

  @Builder
  renderLineRow(line: NarrativeLine) {
    Column({ space: 6 }) {
      Row() {
        Column() {
          Text(line.title ?? '未命名故事线').fontSize(16).fontWeight(FontWeight.Bold);
          Text(`${line.tone ?? '风格未定'} · ${line.goal ?? '目标未定'}`).fontSize(12).fontColor(0x666666);
          Text(`进度：${line.progress ?? '未开始'}`).fontSize(12).fontColor(0x8a63ff);
        }
        .layoutWeight(1);
        Button(this.activeLineId === line.line_id ? '当前线路' : '设为当前')
          .type(ButtonType.Capsule)
          .backgroundColor(this.activeLineId === line.line_id ? 0x12b886 : 0xeeeeff)
          .fontColor(this.activeLineId === line.line_id ? 0xffffff : 0x333333)
          .onClick(() => this.activeLineId = line.line_id);
      }
      if (line.last_checkpoint) {
        Text(`最近片段：${line.last_checkpoint}`).fontSize(12).fontColor(0x444444);
      }
      Row({ space: 12 }) {
        Text(`消耗: ${line.tokens_used ?? 0} tokens`).fontSize(12).fontColor(0x999999);
        Button('合并至当前')
          .type(ButtonType.Normal)
          .backgroundColor(0xffffff)
          .border({ color: 0x8a63ff, width: 1, radius: 12 })
          .fontColor(0x8a63ff)
          .onClick(() => this.mergeToActive(line.line_id));
      }
    }
    .padding(12)
    .backgroundColor(0xf7f7f9)
    .borderRadius(12);
  }

  @Builder
  renderBeatGenerator() {
    Column({ space: 12 }) {
      Text('多线推进').fontSize(18).fontWeight(FontWeight.Medium);
      TextArea({ placeholder: '输入剧情提示，自动扩写当前故事线', text: this.prompt })
        .onChange((value: string) => this.updatePrompt(value))
        .border({ color: 0xdddddd, width: 1, radius: 12 })
        .padding(12)
        .width('100%');
      Button('生成片段并记录记忆')
        .type(ButtonType.Capsule)
        .backgroundColor(0x8a63ff)
        .onClick(() => this.generateBeat());
      if (this.generatedPreview) {
        Column({ space: 6 }) {
          Text('生成片段预览').fontSize(16).fontWeight(FontWeight.Medium);
          Text(this.generatedPreview).fontSize(14).fontColor(0x444444);
        }
        .padding(12)
        .backgroundColor(0xffffff)
        .borderRadius(12);
      }
    }
    .padding(16)
    .backgroundColor(0xffffff)
    .borderRadius(16);
  }

  @Builder
  renderTokenEstimator() {
    Column({ space: 8 }) {
      Text('本地 Token 估算 (CNY)').fontSize(18).fontWeight(FontWeight.Medium);
      Row({ space: 12 }) {
        Text(`字符数：${this.tokenEstimate.characters}`).fontSize(12).fontColor(0x666666);
        Text(`估算 Tokens：${this.tokenEstimate.tokens}`).fontSize(12).fontColor(0x666666);
        Text(`费用≈¥${this.tokenEstimate.estimated_cost_cny}`).fontSize(12).fontColor(0x12b886);
      }
      Slider({ value: this.pricePerK, min: 0.02, max: 1, step: 0.01 })
        .onChange((value: number) => this.updatePricePerK(value))
        .blockColor(0x8a63ff)
        .trackColor(0xeeeeff);
      Text(`单价 ¥${this.pricePerK.toFixed(2)} / 1000 tokens`).fontSize(12).fontColor(0x8a63ff);
    }
    .padding(16)
    .backgroundColor(0xffffff)
    .borderRadius(16);
  }

  @Builder
  renderCompass() {
    Column({ space: 8 }) {
      Text('记忆罗盘').fontSize(18).fontWeight(FontWeight.Medium);
      MemoryCompassCard({ compass: this.compass });
    }
    .padding(16)
    .backgroundColor(0xffffff)
    .borderRadius(16);
  }

  async loadLines(): Promise<void> {
    if (!this.projectId) {
      promptAction.showToast({ message: '请先填写项目ID' });
      return;
    }
    try {
      const data = await NarrativeService.list(this.projectId);
      this.lines = data?.lines ?? [];
      this.activeLineId = data?.active_line_id ?? (this.lines.length > 0 ? this.lines[0].line_id : '');
      this.compass = data?.compass ?? this.compass;
    } catch (err) {
      promptAction.showToast({ message: err?.message ?? '加载线路失败' });
    }
  }

  async loadCompass(): Promise<void> {
    if (!this.projectId) {
      promptAction.showToast({ message: '请先填写项目ID' });
      return;
    }
    try {
      this.compass = await NarrativeService.fetchCompass(this.projectId);
    } catch (err) {
      promptAction.showToast({ message: err?.message ?? '刷新罗盘失败' });
    }
  }

  async createLine(): Promise<void> {
    if (!this.projectId) {
      promptAction.showToast({ message: '请先填写项目ID' });
      return;
    }
    try {
      const created = await NarrativeService.createLine({ project_id: this.projectId, title: this.lineForm.title, tone: this.lineForm.tone, goal: this.lineForm.goal });
      this.lines = [...this.lines, created];
      this.activeLineId = created.line_id;
    } catch (err) {
      promptAction.showToast({ message: err?.message ?? '新增故事线失败' });
    }
  }

  async mergeToActive(sourceLineId: string): Promise<void> {
    if (!this.projectId || !this.activeLineId || sourceLineId === this.activeLineId) {
      return;
    }
    try {
      const result = await NarrativeService.mergeLines({ project_id: this.projectId, target_line_id: this.activeLineId, source_line_id: sourceLineId });
      promptAction.showToast({ message: result?.summary ?? '合并完成' });
      this.loadLines();
      if (result?.compass) {
        this.compass = result.compass;
      }
    } catch (err) {
      promptAction.showToast({ message: err?.message ?? '合并失败' });
    }
  }

  updatePrompt(value: string): void {
    this.prompt = value;
    this.runEstimate();
  }

  updatePricePerK(value: number): void {
    this.pricePerK = value;
    this.runEstimate();
  }

  runEstimate(): void {
    this.tokenEstimate = TokenEstimator.estimate([this.prompt, this.generatedPreview], this.pricePerK);
  }

  async generateBeat(): Promise<void> {
    if (!this.projectId || !this.activeLineId) {
      promptAction.showToast({ message: '请先选择故事线' });
      return;
    }
    try {
      const result = await NarrativeService.pushBeat({ project_id: this.projectId, line_id: this.activeLineId, prompt: this.prompt, word_preference: 'multi-thread' });
      this.generatedPreview = result?.content ?? '';
      this.compass = result?.compass ?? this.compass;
      this.runEstimate();
    } catch (err) {
      promptAction.showToast({ message: err?.message ?? '生成失败' });
    }
  }
}
