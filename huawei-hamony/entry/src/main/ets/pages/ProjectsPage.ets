import promptAction from '@ohos.promptAction';
import { ProjectService, type CreateProjectPayload, type ProjectSummary } from '../network/Services';

interface ProjectItem extends ProjectSummary {
  is_favorite?: boolean;
}

interface ProjectFilterOption {
  label: string;
  value: string;
}

const PROJECT_FILTER_OPTIONS: Array<ProjectFilterOption> = [
  { label: '全部', value: '' },
  { label: '创作中', value: 'in_progress' },
  { label: '完成', value: 'completed' },
  { label: '归档', value: 'archived' }
];

interface FavoriteTogglePayload {
  is_favorite: boolean;
}

@Entry
@Component
struct ProjectsPage {
  @State projects: Array<ProjectItem> = [];
  @State search: string = '';
  @State status: string = '';
  @State newName: string = '';
  @State newIdea: string = '';

  aboutToAppear(): void {
    this.fetchProjects();
  }

  build() {
    Column() {
      Scroll() {
        Column({ space: 16 }) {
          TextInput({ placeholder: '搜索项目', text: this.search })
            .onChange((value: string) => {
              this.search = value;
              this.fetchProjects();
            })
            .border({ color: 0xdddddd, width: 1, radius: 12 })
            .padding(12)
            .width('100%');
          this.renderFilters();
          this.renderCreator();
          this.renderList();
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
  renderFilters() {
    Row({ space: 12 }) {
      ForEach(PROJECT_FILTER_OPTIONS, (item: ProjectFilterOption) => {
        Text(item.label)
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .backgroundColor(this.status === item.value ? 0x8a63ff : 0xf2f2f2)
          .fontColor(this.status === item.value ? 0xffffff : 0x333333)
          .borderRadius(999)
          .onClick(() => {
            this.status = item.value;
            this.fetchProjects();
          });
      }, (item: ProjectFilterOption, index: number) => `${item.value}-${index}`);
    }
  }

  @Builder
  renderCreator() {
    Column({ space: 12 }) {
      TextInput({ placeholder: '项目名称', text: this.newName })
        .onChange((value: string) => this.newName = value)
        .border({ color: 0xdddddd, width: 1, radius: 12 })
        .padding(12)
        .width('100%');
      TextArea({ placeholder: '创作灵感', text: this.newIdea })
        .onChange((value: string) => this.newIdea = value)
        .border({ color: 0xdddddd, width: 1, radius: 12 })
        .padding(12)
        .width('100%');
      Button('创建项目')
        .type(ButtonType.Capsule)
        .backgroundColor(0x8a63ff)
        .enabled(!!this.newName)
        .onClick(() => this.createProject());
    }
  }

  @Builder
  renderList() {
    Column({ space: 12 }) {
      ForEach(this.projects, (project: ProjectItem, index: number) => {
        Column({ space: 6 }) {
          Row() {
            Column() {
              Text(project.project_name).fontSize(18).fontWeight(FontWeight.Bold);
              Text(project.status).fontSize(12).fontColor(0x8a63ff);
            }
            .layoutWeight(1);
            Button(project.is_favorite ? '取消收藏' : '收藏')
              .type(ButtonType.Normal)
              .fontColor(0x8a63ff)
              .backgroundColor(0xeeeeff)
              .onClick(() => this.toggleFavorite(project));
          }
          Text(project.story_core ?? '尚无故事核心').fontSize(14);
          Row({ space: 12 }) {
            Button('删除')
              .type(ButtonType.Normal)
              .fontColor(0xffffff)
              .backgroundColor(0xff6b6b)
              .onClick(() => this.deleteProject(project));
          }
        }
        .padding(16)
        .backgroundColor(0xffffff)
        .borderRadius(16);
      }, (project: ProjectItem, index: number) => project.project_id ?? project.projectId ?? `${index}`);
    }
  }

  async fetchProjects(): Promise<void> {
    const data = await ProjectService.list({ search: this.search, status: this.status });
    this.projects = data?.projects ?? [];
  }

  async createProject(): Promise<void> {
    try {
      const payload: CreateProjectPayload = { project_name: this.newName, first_idea: this.newIdea };
      await ProjectService.create(payload);
      promptAction.showToast({ message: '创建成功' });
      this.newName = '';
      this.newIdea = '';
      await this.fetchProjects();
    } catch (err) {
      promptAction.showToast({ message: err?.message ?? '创建失败' });
    }
  }

  async toggleFavorite(project: ProjectItem): Promise<void> {
    const payload: FavoriteTogglePayload = { is_favorite: !(project.is_favorite ?? false) };
    await ProjectService.update(project.project_id ?? project.projectId ?? '', payload);
    await this.fetchProjects();
  }

  async deleteProject(project: ProjectItem): Promise<void> {
    await ProjectService.remove(project.project_id ?? project.projectId ?? '');
    await this.fetchProjects();
  }
}
