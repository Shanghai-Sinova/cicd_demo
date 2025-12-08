import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { ProjectService, ProjectStatus, ProjectListResponse, ProjectSummary } from '../network/Services';

interface StatItem {
  label: string;
  value: string;
}

interface ProjectItem extends ProjectSummary {
  project_id?: string;
  projectId?: string;
  project_name?: string;
  projectName?: string;
  story_core?: string;
}

@Entry
@Component
struct HomePage {
  @State stats: Array<StatItem> = [];
  @State projects: Array<ProjectItem> = [];
  @State loading: boolean = false;

  aboutToAppear(): void {
    this.fetchProjects();
  }

  build() {
    Column() {
      Scroll() {
        Column({ space: 16 }) {
          this.renderHeader();
          this.renderStats();
          this.renderActions();
          this.renderProjects();
        }
        .width('100%')
        .padding({ left: 24, right: 24, top: 32, bottom: 32 })
        .alignItems(HorizontalAlign.Center);
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
  renderHeader() {
    Column({ space: 8 }) {
      Text('欢迎回来').fontSize(24).fontWeight(FontWeight.Medium);
      Text('准备好继续创作了吗？').fontSize(16).fontColor(0x666666);
      Button('登录 / 注册')
        .type(ButtonType.Capsule)
        .backgroundColor(0xffffff)
        .fontColor(0x8a63ff)
        .border({ color: 0x8a63ff, width: 1, radius: 999 })
        .onClick(() => router.pushUrl({ url: 'pages/LoginPage' }));
    }
    .alignItems(HorizontalAlign.Center);
  }

  @Builder
  renderStats() {
    if (this.stats.length === 0) {

    }
    Row({ space: 12 }) {
      ForEach(this.stats, (item: StatItem) => {
        Column() {
          Text(item.label).fontSize(14).fontColor(0x999999);
          Text(item.value).fontSize(22).fontWeight(FontWeight.Bold);
        }
        .padding(16)
        .backgroundColor(0xf7f2ff)
        .borderRadius(16)
        .layoutWeight(1);
      }, (item: StatItem, index: number) => `${item.label}-${index}`);
    }
  }

  @Builder
  renderActions() {
    Column({ space: 12 }) {
      Button('生成灵感')
        .type(ButtonType.Capsule)
        .backgroundColor(0x8a63ff)
        .onClick(() => router.pushUrl({ url: 'pages/CreationPage' }));
      Button('前往项目列表')
        .type(ButtonType.Capsule)
        .backgroundColor(0xff6ed1)
        .onClick(() => router.pushUrl({ url: 'pages/ProjectsPage' }));
      Button('多线叙事 / 记忆罗盘')
        .type(ButtonType.Capsule)
        .backgroundColor(0x12b886)
        .onClick(() => router.pushUrl({ url: 'pages/NarrativePage' }));
      Button('支付与会员中心')
        .type(ButtonType.Capsule)
        .backgroundColor(0xffd166)
        .fontColor(0x333333)
        .onClick(() => router.pushUrl({ url: 'pages/PaymentPage' }));
    }
  }

  @Builder
  renderProjects() {
    Column({ space: 12 }) {
      Text('最新项目').fontSize(18).fontWeight(FontWeight.Medium);
      ForEach(this.projects, (project: ProjectItem) => {
        Column({ space: 6 }) {
          Text(project.project_name ?? project.projectName ?? '未命名项目')
            .fontSize(16)
            .fontWeight(FontWeight.Bold);
          Text(project.story_core ?? '尚未生成故事核心')
            .fontSize(14)
            .fontColor(0x666666);
        }
        .padding(16)
        .backgroundColor(0xffffff)
        .borderRadius(16)
        .shadow({ radius: 4, color: 0x11000000 });
      }, (project: ProjectItem, index: number) => project.project_id ?? project.projectId ?? `${index}`);
    }
  }

  async fetchProjects(): Promise<void> {
    if (this.loading) {
      return;
    }
    this.loading = true;
    try {
      const response: ProjectListResponse = await ProjectService.list({ limit: 4 });
      const list: Array<ProjectItem> = response.projects ?? [];
      this.projects = list;
      const total = response.total ?? list.length;
      const active = list.filter((item: ProjectItem) => item.status === 'in_progress' || item.status === 'active').length;
      const completed = list.filter((item: ProjectItem) => item.status === 'completed').length;
      this.stats = [
        { label: '项目', value: `${total}` },
        { label: '进行中', value: `${active}` },
        { label: '已完成', value: `${completed}` }
      ];
    } catch (err) {
      const message = (err as Error)?.message ?? '加载失败';
      promptAction.openToast({ message });
    } finally {
      this.loading = false;
    }
  }
}
