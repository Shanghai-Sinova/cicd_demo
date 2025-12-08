import promptAction from '@ohos.promptAction';
import { ProjectService, CreationService, type CreateProjectPayload } from '../network/Services';

type StepId =
  | 'inspiration'
  | 'story-core'
  | 'protagonist'
  | 'relationships'
  | 'plot'
  | 'writing';

type StepStatus = 'idle' | 'running' | 'completed' | 'failed';

interface StepTemplate {
  id: StepId;
  title: string;
  desc: string;
}

interface CreationStep extends StepTemplate {
  status: StepStatus;
  preview: string;
}

interface GeneratedTypeLiteralInterface_1 {
  brainstorm_ideas?: Array<string>;
}

interface BrainstormResponse {
  data?: GeneratedTypeLiteralInterface_1;
}

interface GeneratedTypeLiteralInterface_2 {
  leading_brief?: string;
}

interface ProtagonistResponse {
  data?: GeneratedTypeLiteralInterface_2;
}

interface SupportingResponse {
  content?: string;
  data?: Object;
}

interface GeneratedTypeLiteralInterface_3 {
  scene_beats?: Array<string>;
}

interface BeatResponse {
  data?: GeneratedTypeLiteralInterface_3;
}

interface GeneratedTypeLiteralInterface_4 {
  generated_content?: string;
}

interface ScriptResponse {
  data?: GeneratedTypeLiteralInterface_4;
}

const STEP_TEMPLATES: ReadonlyArray<StepTemplate> = [
  { id: 'inspiration', title: '输入灵感', desc: '生成灵感与故事核心' },
  { id: 'story-core', title: '故事核心', desc: '推进故事骨架' },
  { id: 'protagonist', title: '主角人物', desc: '生成主角小传' },
  { id: 'relationships', title: '配角关系', desc: '生成配角' },
  { id: 'plot', title: '情节序列', desc: '生成情节与节拍' },
  { id: 'writing', title: '正文生成', desc: '根据节拍输出正文' }
];

@Entry
@Component
struct CreationPage {
  @State projectId: string = '';
  @State projectName: string = '';
  @State firstIdea: string = '';
  @State storyCore: string = '';
  @State beats: Array<string> = [];
  @State script: string = '';
  @State steps: Array<CreationStep> = STEP_TEMPLATES.map<CreationStep>((step: StepTemplate) => {
    const createdStep: CreationStep = {
      id: step.id,
      title: step.title,
      desc: step.desc,
      status: 'idle',
      preview: ''
    };
    return createdStep;
  });

  build(): void {
    Column() {
      Scroll() {
        Column({ space: 16 }) {
          this.renderBinding();
          ForEach(this.steps, (step: CreationStep) => this.renderStep(step), (step: CreationStep) => step.id);
          if (this.script) {
            Column({ space: 8 }) {
              Text('正文输出').fontSize(18).fontWeight(FontWeight.Medium);
              Text(this.script).fontSize(14).fontColor(0x555555);
            }
            .padding(16)
            .backgroundColor(0xffffff)
            .borderRadius(16);
          }
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
  renderBinding(): void {
    Column({ space: 12 }) {
      TextInput({ placeholder: '项目ID', text: this.projectId })
        .onChange((value: string) => this.projectId = value)
        .border({ color: 0xdddddd, width: 1, radius: 12 })
        .padding(12)
        .width('100%');
      TextInput({ placeholder: '项目名称', text: this.projectName })
        .onChange((value: string) => this.projectName = value)
        .border({ color: 0xdddddd, width: 1, radius: 12 })
        .padding(12)
        .width('100%');
      TextArea({ placeholder: '创作灵感', text: this.firstIdea })
        .onChange((value: string) => this.firstIdea = value)
        .border({ color: 0xdddddd, width: 1, radius: 12 })
        .padding(12)
        .width('100%');
      Row({ space: 12 }) {
        Button('新建/绑定').type(ButtonType.Capsule).backgroundColor(0x8a63ff).onClick(() => this.ensureProject());
        Button('同步项目')
          .type(ButtonType.Capsule)
          .backgroundColor(0xeeeeff)
          .fontColor(0x444444)
          .onClick(() => this.syncProject());
      }
    }
  }

  @Builder
  renderStep(step: CreationStep): void {
    Column({ space: 8 }) {
      Row({ space: 8 }) {
        Column() {
          Text(step.title).fontSize(18).fontWeight(FontWeight.Medium);
          Text(step.desc).fontSize(14).fontColor(0x666666);
        }
        .layoutWeight(1);

        Text(step.status === 'idle' ? '待处理' :
          step.status === 'running' ? '执行中' : step.status === 'completed' ? '已完成' : '失败')
          .fontSize(12)
          .fontColor(step.status === 'failed' ? 0xff6b6b : 0x8a63ff);
      }

      if (step.preview) {
        Text(step.preview).fontSize(14).fontColor(0x555555);
      }
      Button('执行')
        .type(ButtonType.Capsule)
        .backgroundColor(0x8a63ff)
        .onClick(() => this.handleRun(step.id));
    }
    .padding(16)
    .backgroundColor(0xffffff)
    .borderRadius(16);
  }

  async ensureProject() {
    if (this.projectId) {
      promptAction.showToast({ message: '已绑定' });
      return;
    }
    const payload: CreateProjectPayload = {
      project_name: this.projectName || 'Harmony 项目',
      first_idea: this.firstIdea
    };
    const created = await ProjectService.create(payload);
    this.projectId = created.project_id ?? created.projectId ?? '';
    promptAction.openToast({ message: '绑定成功' });
  }

  async syncProject() {
    if (!this.projectId) {
      return;
    }
    const data = await ProjectService.detail(this.projectId);
    if (!data) {
      promptAction.openToast({ message: '未找到项目' });
      return;
    }
    this.projectName = data.project_name ?? data.projectName ?? '';
    this.firstIdea = data.first_idea ?? data.firstIdea ?? '';
  }

  setStepStatus(id: StepId, status: StepStatus, preview: string = '') {
    const updated = this.steps.map((step: CreationStep) => {
      if (step.id !== id) {
        return step;
      }
      const nextStep: CreationStep = {
        id: step.id,
        title: step.title,
        desc: step.desc,
        status,
        preview
      };
      return nextStep;
    });
    this.steps = updated;
  }

  async handleRun(kind: StepId) {
    if (!this.projectId) {
      promptAction.openToast({ message: '请先绑定项目' });
      return;
    }
    this.setStepStatus(kind, 'running');
    try {
      switch (kind) {
        case 'inspiration': {
          const idea = this.firstIdea || '请生成一个现代幻想故事';
          const result = await CreationService.brainstorm(this.projectId, idea) as BrainstormResponse;
          let ideas: Array<string> = [];
          if (result && result.data && result.data.brainstorm_ideas) {
            ideas = result.data.brainstorm_ideas;
          }
          if (ideas.length === 0) {
            ideas = [idea];
          }
          this.storyCore = ideas[0];
          await CreationService.advanceStoryCore(this.projectId, this.storyCore);
          this.setStepStatus(kind, 'completed', this.storyCore);
          break;
        }
        case 'story-core': {
          await CreationService.advanceStoryCore(this.projectId, this.storyCore);
          this.setStepStatus(kind, 'completed', this.storyCore);
          break;
        }
        case 'protagonist': {
          const protagonist = await CreationService.generateProtagonist(this.projectId) as ProtagonistResponse;
          let brief = '';
          if (protagonist && protagonist.data && protagonist.data.leading_brief) {
            brief = protagonist.data.leading_brief;
          }
          this.setStepStatus(kind, 'completed', brief);
          break;
        }
        case 'relationships': {
          const supporting = await CreationService.generateSupporting(this.projectId) as SupportingResponse;
          let contentPreview = '';
          if (supporting) {
            if (supporting.content) {
              contentPreview = supporting.content;
            } else if (supporting.data) {
              contentPreview = JSON.stringify(supporting.data);
            }
          }
          const slicedContent = contentPreview.length > 0 ? contentPreview.slice(0, 120) : '';
          this.setStepStatus(kind, 'completed', slicedContent);
          break;
        }
        case 'plot': {
          await CreationService.generatePlot(this.projectId);
          const beatResult = await CreationService.generateBeats(this.projectId) as BeatResponse;
          if (beatResult && beatResult.data && beatResult.data.scene_beats) {
            this.beats = beatResult.data.scene_beats;
          } else {
            this.beats = [];
          }
          this.setStepStatus(kind, 'completed', JSON.stringify(this.beats.slice(0, 2)));
          break;
        }
        case 'writing': {
          const beatsToUse = this.beats.length > 0 ? this.beats : ['Scene 1'];
          const script = await CreationService.generateScripts(this.projectId, beatsToUse) as ScriptResponse;
          if (script && script.data && script.data.generated_content) {
            this.script = script.data.generated_content;
          } else {
            this.script = '';
          }
          this.setStepStatus(kind, 'completed', this.script.slice(0, 120));
          break;
        }
      }
    } catch (err) {
      promptAction.showToast({ message: err?.message ?? '执行失败' });
      this.setStepStatus(kind, 'failed', err?.message ?? '');
    }
  }
}
