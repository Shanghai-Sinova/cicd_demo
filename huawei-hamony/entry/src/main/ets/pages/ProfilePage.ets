import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { AuthService, PointsService, PaymentsService } from '../network/Services';
import { apiClient } from '../network/ApiClient';

interface PointsBalance {
  usable_points?: number;
  level_name?: string;
}

interface TransactionItem {
  reason?: string;
  status?: string;
  amount?: number;
}

interface PlanPrice {
  amount_formatted?: string;
}

interface PlanItem {
  plan_id: string;
  name?: string;
  price?: PlanPrice;
  description?: string;
}

interface CredentialDetail {
  page_url?: string;
  code_url?: string;
}

interface PaymentCredential {
  alipay_page?: CredentialDetail;
  wechat_native?: CredentialDetail;
}

interface TransactionsResponse {
  transactions?: Array<TransactionItem>;
}

interface PlansResponse {
  plans?: Array<PlanItem>;
}

interface OrderResponse {
  credential?: PaymentCredential;
}

@Entry
@Component
struct ProfilePage {
  @State userName: string = '未登录';
  @State userEmail: string = '';
  @State points?: PointsBalance = undefined;
  @State transactions: Array<TransactionItem> = [];
  @State plans: Array<PlanItem> = [];
  @State selectedChannel: string = 'alipay_page';
  @State credential: PaymentCredential = {} as PaymentCredential;

  aboutToAppear(): void {
    this.fetchProfile();
    this.refreshCenter();
  }

  build() {
    Column() {
      Scroll() {
        Column({ space: 16 }) {
          this.renderAccount();
          this.renderTransactions();
          this.renderRecharge();
          Button('退出登录')
            .type(ButtonType.Capsule)
            .backgroundColor(0xff6b6b)
            .onClick(() => this.logout());
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
  renderAccount() {
    Column({ space: 8 }) {
      Text(this.userName).fontSize(24).fontWeight(FontWeight.Bold);
      Text(this.userEmail).fontSize(14).fontColor(0x666666);
      if (this.points) {
        Text(`可用积分：${this.points.usable_points ?? 0}`).fontSize(16);
        Text(`等级：${this.points.level_name ?? '-'}`).fontSize(14).fontColor(0x999999);
      }
      Button('刷新')
        .type(ButtonType.Capsule)
        .backgroundColor(0xeeeeff)
        .fontColor(0x333333)
        .onClick(() => this.refreshCenter());
    }
    .padding(24)
    .backgroundColor(0xffffff)
    .borderRadius(20);
  }

  @Builder
  renderTransactions() {
    Column({ space: 8 }) {
      Text('积分流水').fontSize(20).fontWeight(FontWeight.Medium);
      if (this.transactions.length === 0) {
        Text('暂无记录').fontColor(0x999999);
      } else {
        ForEach(this.transactions.slice(0, 5), (item: TransactionItem, index: number) => this.renderTransactionRow(item), (_item: TransactionItem, index: number) => `tx-${index}`);
      }
    }
    .padding(24)
    .backgroundColor(0xffffff)
    .borderRadius(20);
  }

  @Builder
  renderTransactionRow(item: TransactionItem) {
    Row() {
      Text(`${item.reason ?? ''} · ${item.status ?? ''}`);
      Blank();
      Text(`${(item.amount ?? 0) > 0 ? '+' : ''}${item.amount ?? 0}`)
        .fontColor((item.amount ?? 0) >= 0 ? 0x12b886 : 0xff6b6b);
    }
  }

  @Builder
  renderRecharge() {
    Column({ space: 12 }) {
      Text('充值 / 会员').fontSize(20).fontWeight(FontWeight.Medium);
      Row({ space: 12 }) {
        Button(this.selectedChannel === 'alipay_page' ? '支付宝' : '微信扫码')
          .type(ButtonType.Capsule)
          .backgroundColor(0x8a63ff)
          .onClick(() => {
            this.selectedChannel = this.selectedChannel === 'alipay_page' ? 'wechat_native' : 'alipay_page';
          });
      }
      ForEach(this.plans, (plan: PlanItem, index: number) => {
        Column({ space: 4 }) {
          Text(`${plan.name ?? ''} · ${plan.price?.amount_formatted ?? ''}`).fontSize(18).fontWeight(FontWeight.Bold);
          Text(plan.description ?? '').fontSize(14).fontColor(0x666666);
          Button('立即购买')
            .type(ButtonType.Capsule)
            .backgroundColor(0x8a63ff)
            .onClick(() => this.createOrder(plan.plan_id));
        }
        .padding(16)
        .backgroundColor(0xffffff)
        .borderRadius(16);
      }, (plan: PlanItem, index: number) => plan.plan_id ?? `plan-${index}`);
      if (this.credential?.alipay_page) {
        Text(`支付宝链接：${this.credential.alipay_page.page_url}`)
          .fontSize(12)
          .fontColor(0x8a63ff);
      }
      if (this.credential?.wechat_native) {
        Text(`微信扫码链接：${this.credential.wechat_native.code_url}`)
          .fontSize(12)
          .fontColor(0x12b886);
      }
    }
    .padding(24)
    .backgroundColor(0xffffff)
    .borderRadius(20);
  }

  async fetchProfile(): Promise<void> {
    try {
      const profile = await AuthService.profile() as Record<string, Object>;
      this.userName = (profile?.name ?? profile?.username ?? '未登录') as string;
      this.userEmail = (profile?.email ?? '') as string;
    } catch (_) {}
  }

  async refreshCenter(): Promise<void> {
    try {
      this.points = await PointsService.balance() as PointsBalance;
      const tx: TransactionsResponse = await PointsService.transactions() as TransactionsResponse;
      this.transactions = tx?.transactions ?? [];
      const plansResp: PlansResponse = await PaymentsService.listPlans() as PlansResponse;
      this.plans = plansResp?.plans ?? [];
    } catch (err) {
      promptAction.showToast({ message: err?.message ?? '加载失败' });
    }
  }

  async createOrder(planId: string): Promise<void> {
    try {
      const result: OrderResponse = await PaymentsService.createOrder(planId, this.selectedChannel) as OrderResponse;
      this.credential = result?.credential ?? {};
      promptAction.showToast({ message: '订单创建成功' });
    } catch (err) {
      promptAction.showToast({ message: err?.message ?? '下单失败' });
    }
  }

  logout(): void {
    apiClient.setToken('');
    router.replaceUrl({ url: 'pages/LoginPage' });
  }
}
