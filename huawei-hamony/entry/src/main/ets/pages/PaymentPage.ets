import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { PaymentsService, PointsService, type PlanItem, type PaymentCredential } from '../network/Services';

interface PointsBalanceLite {
  usable_points?: number;
}

interface PlansResponseLite {
  plans?: Array<PlanItem>;
}

@Entry
@Component
struct PaymentPage {
  @State plans: Array<PlanItem> = [];
  @State selectedPlanId: string = '';
  @State selectedChannel: string = 'alipay_page';
  @State credential: PaymentCredential = {} as PaymentCredential;
  @State pointsBalance: number = 0;
  @State usePoints: boolean = true;

  aboutToAppear(): void {
    this.loadData();
  }

  build() {
    Column() {
      Scroll() {
        Column({ space: 16 }) {
          this.renderSummary();
          this.renderPlans();
          this.renderChannels();
          this.renderCredential();
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
  renderSummary() {
    Column({ space: 8 }) {
      Text('支付与会员积分').fontSize(22).fontWeight(FontWeight.Bold);
      Text(`可用积分：${this.pointsBalance} 分`).fontSize(14).fontColor(0x12b886);
      Row({ space: 10 }) {
        Toggle({ isOn: this.usePoints, textOn: '使用积分抵扣', textOff: '不使用', type: ToggleType.Switch })
          .onChange((value: boolean) => this.usePoints = value);
        Text(this.usePoints ? '开启' : '关闭').fontSize(12).fontColor(0x666666);
      }
    }
    .padding(16)
    .backgroundColor(0xffffff)
    .borderRadius(16);
  }

  @Builder
  renderPlans() {
    Column({ space: 10 }) {
      Text('选择会员套餐 (CNY)').fontSize(18).fontWeight(FontWeight.Medium);
      ForEach(this.plans, (plan: PlanItem, index: number) => {
        Column({ space: 6 }) {
          Row() {
            Column() {
              Text(plan.name ?? '未命名套餐').fontSize(16).fontWeight(FontWeight.Bold);
              Text(plan.description ?? '持续创作流量包').fontSize(12).fontColor(0x666666);
            }
            .layoutWeight(1);
            Text(`¥${this.getPlanPrice(plan).toFixed(2)}`).fontSize(16).fontWeight(FontWeight.Bold).fontColor(0x8a63ff);
          }
          Row({ space: 8 }) {
            Text(this.usePoints ? '积分抵扣已启用' : '不使用积分').fontSize(12).fontColor(0x999999);
            Text(`应付≈¥${this.calcPayable(plan).toFixed(2)}`).fontSize(12).fontColor(0x12b886);
          }
          Button(this.selectedPlanId === plan.plan_id ? '已选择' : '选择')
            .type(ButtonType.Capsule)
            .backgroundColor(this.selectedPlanId === plan.plan_id ? 0x12b886 : 0x8a63ff)
            .onClick(() => this.selectedPlanId = plan.plan_id);
        }
        .padding(14)
        .backgroundColor(0xffffff)
        .borderRadius(14);
      }, (plan: PlanItem, index: number) => plan.plan_id ?? `plan-${index}`);
      Button('创建支付订单')
        .type(ButtonType.Capsule)
        .backgroundColor(0xff6ed1)
        .onClick(() => this.createOrder());
    }
    .padding(16)
    .backgroundColor(0xffffff)
    .borderRadius(16);
  }

  @Builder
  renderChannels() {
    Column({ space: 10 }) {
      Text('支付渠道').fontSize(18).fontWeight(FontWeight.Medium);
      Row({ space: 12 }) {
        Button(this.selectedChannel === 'alipay_page' ? '支付宝' : '切换到支付宝')
          .type(ButtonType.Capsule)
          .backgroundColor(this.selectedChannel === 'alipay_page' ? 0x12b886 : 0xeeeeff)
          .fontColor(this.selectedChannel === 'alipay_page' ? 0xffffff : 0x333333)
          .onClick(() => this.selectedChannel = 'alipay_page');
        Button(this.selectedChannel === 'wechat_native' ? '微信扫码' : '切换到微信')
          .type(ButtonType.Capsule)
          .backgroundColor(this.selectedChannel === 'wechat_native' ? 0x12b886 : 0xeeeeff)
          .fontColor(this.selectedChannel === 'wechat_native' ? 0xffffff : 0x333333)
          .onClick(() => this.selectedChannel = 'wechat_native');
      }
    }
    .padding(16)
    .backgroundColor(0xffffff)
    .borderRadius(16);
  }

  @Builder
  renderCredential() {
    Column({ space: 8 }) {
      Text('支付凭证/跳转信息').fontSize(18).fontWeight(FontWeight.Medium);
      if (this.credential?.alipay_page) {
        Text(`支付宝收款页：${this.credential.alipay_page.page_url ?? '-'}`).fontSize(12).fontColor(0x8a63ff);
      }
      if (this.credential?.wechat_native) {
        Text(`微信扫码：${this.credential.wechat_native.code_url ?? '-'}`).fontSize(12).fontColor(0x12b886);
      }
      if (!this.credential?.alipay_page && !this.credential?.wechat_native) {
        Text('创建订单后将展示跳转链接或二维码地址').fontSize(12).fontColor(0x999999);
      }
    }
    .padding(16)
    .backgroundColor(0xffffff)
    .borderRadius(16);
  }

  async loadData(): Promise<void> {
    try {
      const plansResp: PlansResponseLite = await PaymentsService.listPlans() as PlansResponseLite;
      this.plans = plansResp?.plans ?? [];
      this.selectedPlanId = this.plans.length > 0 ? this.plans[0].plan_id : '';
      const points = await PointsService.balance() as PointsBalanceLite;
      this.pointsBalance = points?.usable_points ?? 0;
    } catch (err) {
      promptAction.showToast({ message: err?.message ?? '加载失败' });
    }
  }

  async createOrder(): Promise<void> {
    if (!this.selectedPlanId) {
      promptAction.showToast({ message: '请先选择套餐' });
      return;
    }
    try {
      const result = await PaymentsService.createOrder(this.selectedPlanId, this.selectedChannel) as { credential?: PaymentCredential };
      this.credential = result?.credential ?? {} as PaymentCredential;
      promptAction.showToast({ message: '订单已生成，请按照提示支付' });
    } catch (err) {
      promptAction.showToast({ message: err?.message ?? '下单失败' });
    }
  }

  getPlanPrice(plan: PlanItem): number {
    const raw = plan?.price?.amount_formatted ?? '0';
    const numeric = parseFloat(raw.replace(/[^0-9.]/g, ''));
    if (Number.isNaN(numeric)) {
      return 0;
    }
    return numeric;
  }

  calcPayable(plan: PlanItem): number {
    const price = this.getPlanPrice(plan);
    const deduction = this.usePoints ? Math.min(this.pointsBalance, price) : 0;
    return Math.max(0, price - deduction);
  }
}
