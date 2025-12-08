import http from '@ohos.net.http';
import { apiClient, type RequestOptions } from './ApiClient';

export type ProjectStatus = 'created' | 'in_progress' | 'completed' | 'archived' | 'active';

interface ApiEnvelope<T> {
  data?: T;
  total?: number;
  projects?: Array<ProjectSummary>;
}

function unwrapResponse<T>(payload: T | ApiEnvelope<T>): T {
  const envelope = payload as ApiEnvelope<T>;
  if (envelope && envelope.data !== undefined) {
    return envelope.data;
  }
  return payload as T;
}

export interface RegisterPayload {
  username: string;
  email: string;
  password: string;
  nickname?: string;
}

export interface LoginPayload {
  username: string;
  password: string;
}

export interface LoginResponse {
  token: string;
  user: Object;
}

export interface ProjectSummary {
  project_id?: string;
  projectId?: string;
  project_name?: string;
  projectName?: string;
  first_idea?: string;
  firstIdea?: string;
  story_core?: string;
  status?: ProjectStatus;
}

export interface ProjectListParams {
  search?: string;
  status?: string;
  limit?: number;
}

export interface ProjectListResponse {
  projects?: Array<ProjectSummary>;
  total?: number;
}

export interface CreateProjectPayload {
  project_name: string;
  first_idea?: string;
}

interface BrainstormPayload {
  project_id: string;
  first_idea: string;
  num_ideas: number;
}

interface StoryCoreAdvancePayload {
  project_id: string;
  story_core: string;
}

interface ProtagonistPayload {
  project_id: string;
  leading_quantity: number;
}

interface PlotPayload {
  project_id: string;
}

interface BeatPayload {
  project_id: string;
  sequence_id: string;
}

interface ScriptVariablesPayload {
  project_id: string;
  current_seq_beats: Array<string>;
}

interface ScriptMetadataPayload {
  project_id: string;
}

interface ScriptGenerationPayload {
  template_name: string;
  variables: ScriptVariablesPayload;
  metadata: ScriptMetadataPayload;
}

interface PaymentOrderPayload {
  plan_id: string;
  channel: string;
}

interface NarrativeLinePayload {
  project_id: string;
  title: string;
  tone?: string;
  goal?: string;
}

interface NarrativeBeatPayload {
  project_id: string;
  line_id: string;
  prompt: string;
  word_preference?: string;
}

interface NarrativeMergePayload {
  project_id: string;
  target_line_id: string;
  source_line_id: string;
}

export interface NarrativeLine {
  line_id: string;
  title?: string;
  tone?: string;
  goal?: string;
  progress?: string;
  last_checkpoint?: string;
  tokens_used?: number;
}

export interface CompassNode {
  label: string;
  summary: string;
  confidence?: number;
  tension?: number;
}

export interface NarrativeCompass {
  focus?: string;
  nodes?: Array<CompassNode>;
  last_updated?: string;
}

export interface NarrativeLinesResponse {
  lines?: Array<NarrativeLine>;
  active_line_id?: string;
  compass?: NarrativeCompass;
  project_id?: string;
}

export interface NarrativeBeatResponse {
  content?: string;
  tokens_used?: number;
  line_id?: string;
  project_id?: string;
  compass?: NarrativeCompass;
}

export interface NarrativeMergeResponse {
  merged_to?: string;
  merged_from?: string;
  summary?: string;
  compass?: NarrativeCompass;
}

export interface TokenUsageEstimate {
  tokens: number;
  characters: number;
  estimated_cost_cny: number;
}

export interface AuthServiceInterface {
  register(payload: RegisterPayload): Promise<Object>;
  login(payload: LoginPayload): Promise<LoginResponse>;
  profile(): Promise<Object>;
}

class AuthServiceImpl implements AuthServiceInterface {
  async register(payload: RegisterPayload): Promise<Object> {
    const requestOptions: RequestOptions = {
      method: http.RequestMethod.POST,
      data: payload
    };
    const data = await apiClient.request<Object | ApiEnvelope<Object>>('/users/register', requestOptions);
    return unwrapResponse<Object>(data);
  }

  async login(payload: LoginPayload): Promise<LoginResponse> {
    const requestOptions: RequestOptions = {
      method: http.RequestMethod.POST,
      data: payload
    };
    const data = await apiClient.request<LoginResponse | ApiEnvelope<LoginResponse>>('/auth/login', requestOptions);
    const result = unwrapResponse<LoginResponse>(data);
    if (result.token) {
      apiClient.setToken(result.token);
    }
    return result;
  }

  async profile(): Promise<Object> {
    const data = await apiClient.request<Object | ApiEnvelope<Object>>('/auth/profile');
    return unwrapResponse<Object>(data);
  }
}

export const AuthService: AuthServiceInterface = new AuthServiceImpl();

function buildProjectQuery(params: ProjectListParams): string {
  const parts: Array<string> = [];
  if (params.search) {
    parts.push('search=' + encodeURIComponent(params.search));
  }
  if (params.status) {
    parts.push('status=' + encodeURIComponent(params.status));
  }
  const limitValue = params.limit ?? 20;
  parts.push('limit=' + encodeURIComponent(String(limitValue)));
  return parts.length > 0 ? `?${parts.join('&')}` : '';
}

function mapToProjectList(input: ProjectListResponse | Array<ProjectSummary>): ProjectListResponse {
  if (input instanceof Array) {
    const normalized: ProjectListResponse = { projects: input, total: input.length };
    return normalized;
  }
  return input as ProjectListResponse;
}

export interface ProjectServiceInterface {
  list(params?: ProjectListParams): Promise<ProjectListResponse>;
  create(payload: CreateProjectPayload): Promise<ProjectSummary>;
  update(projectId: string, payload: Object): Promise<ProjectSummary>;
  remove(projectId: string): Promise<void>;
  detail(projectId: string): Promise<ProjectSummary>;
}

class ProjectServiceImpl implements ProjectServiceInterface {
  async list(params?: ProjectListParams): Promise<ProjectListResponse> {
    const safeParams: ProjectListParams = params ?? {};
    const query = buildProjectQuery(safeParams);
    const data = await apiClient.request<ProjectListResponse | Array<ProjectSummary> | ApiEnvelope<ProjectListResponse>>(`/projects${query}`);
    const normalized = unwrapResponse<ProjectListResponse | Array<ProjectSummary>>(data);
    return mapToProjectList(normalized);
  }

  async create(payload: CreateProjectPayload): Promise<ProjectSummary> {
    const requestOptions: RequestOptions = {
      method: http.RequestMethod.POST,
      data: payload
    };
    const data = await apiClient.request<ProjectSummary | ApiEnvelope<ProjectSummary>>('/projects', requestOptions);
    return unwrapResponse<ProjectSummary>(data);
  }

  async update(projectId: string, payload: Object): Promise<ProjectSummary> {
    const requestOptions: RequestOptions = {
      method: http.RequestMethod.PUT,
      data: payload
    };
    const data = await apiClient.request<ProjectSummary | ApiEnvelope<ProjectSummary>>(`/projects/${projectId}`, requestOptions);
    return unwrapResponse<ProjectSummary>(data);
  }

  async remove(projectId: string): Promise<void> {
    const requestOptions: RequestOptions = {
      method: http.RequestMethod.DELETE
    };
    await apiClient.request<Object | ApiEnvelope<Object>>(`/projects/${projectId}`, requestOptions);
  }

  async detail(projectId: string): Promise<ProjectSummary> {
    const data = await apiClient.request<ProjectSummary | ApiEnvelope<ProjectSummary>>(`/projects/${projectId}`);
    return unwrapResponse<ProjectSummary>(data);
  }
}

export const ProjectService: ProjectServiceInterface = new ProjectServiceImpl();

export interface CreationServiceInterface {
  brainstorm(projectId: string, firstIdea: string): Promise<Object>;
  advanceStoryCore(projectId: string, storyCore: string): Promise<Object>;
  generateProtagonist(projectId: string): Promise<Object>;
  generateSupporting(projectId: string): Promise<Object>;
  generatePlot(projectId: string): Promise<Object>;
  generateBeats(projectId: string): Promise<Object>;
  generateScripts(projectId: string, beats: Array<string>): Promise<Object>;
}

class CreationServiceImpl implements CreationServiceInterface {
  async brainstorm(projectId: string, firstIdea: string): Promise<Object> {
    const payload: BrainstormPayload = { project_id: projectId, first_idea: firstIdea, num_ideas: 5 };
    const requestOptions: RequestOptions = {
      method: http.RequestMethod.POST,
      data: payload
    };
    const data = await apiClient.request<Object | ApiEnvelope<Object>>('/llm/brainstorm', requestOptions);
    return unwrapResponse<Object>(data);
  }

  async advanceStoryCore(projectId: string, storyCore: string): Promise<Object> {
    const payload: StoryCoreAdvancePayload = { project_id: projectId, story_core: storyCore };
    const requestOptions: RequestOptions = {
      method: http.RequestMethod.POST,
      data: payload
    };
    const data = await apiClient.request<Object | ApiEnvelope<Object>>(`/projects/${projectId}/story-core/advance`, requestOptions);
    return unwrapResponse<Object>(data);
  }

  async generateProtagonist(projectId: string): Promise<Object> {
    const payload: ProtagonistPayload = { project_id: projectId, leading_quantity: 1 };
    const requestOptions: RequestOptions = {
      method: http.RequestMethod.POST,
      data: payload
    };
    const data = await apiClient.request<Object | ApiEnvelope<Object>>('/protagonist/generate', requestOptions);
    return unwrapResponse<Object>(data);
  }

  async generateSupporting(projectId: string): Promise<Object> {
    const requestOptions: RequestOptions = {
      method: http.RequestMethod.POST
    };
    const data = await apiClient.request<Object | ApiEnvelope<Object>>(`/projects/${projectId}/generate/supporting`, requestOptions);
    return unwrapResponse<Object>(data);
  }

  async generatePlot(projectId: string): Promise<Object> {
    const payload: PlotPayload = { project_id: projectId };
    const requestOptions: RequestOptions = {
      method: http.RequestMethod.POST,
      data: payload
    };
    const data = await apiClient.request<Object | ApiEnvelope<Object>>('/sequence-act/generate', requestOptions);
    return unwrapResponse<Object>(data);
  }

  async generateBeats(projectId: string): Promise<Object> {
    const payload: BeatPayload = { project_id: projectId, sequence_id: 'seq_main' };
    const requestOptions: RequestOptions = {
      method: http.RequestMethod.POST,
      data: payload
    };
    const data = await apiClient.request<Object | ApiEnvelope<Object>>('/sequence-beat/generate', requestOptions);
    return unwrapResponse<Object>(data);
  }

  async generateScripts(projectId: string, beats: Array<string>): Promise<Object> {
    const payload: ScriptGenerationPayload = {
      template_name: 'sequence_scripts',
      variables: {
        project_id: projectId,
        current_seq_beats: beats
      },
      metadata: { project_id: projectId }
    };
    const requestOptions: RequestOptions = {
      method: http.RequestMethod.POST,
      data: payload
    };
    const data = await apiClient.request<Object | ApiEnvelope<Object>>('/llm/generate-universal', requestOptions);
    return unwrapResponse<Object>(data);
  }
}

export const CreationService: CreationServiceInterface = new CreationServiceImpl();

export interface PointsServiceInterface {
  balance(): Promise<Object>;
  transactions(): Promise<Object>;
}

class PointsServiceImpl implements PointsServiceInterface {
  async balance(): Promise<Object> {
    const data = await apiClient.request<Object | ApiEnvelope<Object>>('/points/balance');
    return unwrapResponse<Object>(data);
  }

  async transactions(): Promise<Object> {
    const data = await apiClient.request<Object | ApiEnvelope<Object>>('/points/transactions');
    return unwrapResponse<Object>(data);
  }
}

export const PointsService: PointsServiceInterface = new PointsServiceImpl();

export interface PaymentsServiceInterface {
  listPlans(): Promise<Object>;
  createOrder(planId: string, channel: string): Promise<Object>;
}

class PaymentsServiceImpl implements PaymentsServiceInterface {
  async listPlans(): Promise<Object> {
    const data = await apiClient.request<Object | ApiEnvelope<Object>>('/payments/plans');
    return unwrapResponse<Object>(data);
  }

  async createOrder(planId: string, channel: string): Promise<Object> {
    const payload: PaymentOrderPayload = { plan_id: planId, channel };
    const requestOptions: RequestOptions = {
      method: http.RequestMethod.POST,
      data: payload
    };
    const data = await apiClient.request<Object | ApiEnvelope<Object>>('/payments/orders', requestOptions);
    return unwrapResponse<Object>(data);
  }
}

export const PaymentsService: PaymentsServiceInterface = new PaymentsServiceImpl();

export interface NarrativeServiceInterface {
  list(projectId: string): Promise<NarrativeLinesResponse>;
  createLine(payload: NarrativeLinePayload): Promise<NarrativeLine>;
  pushBeat(payload: NarrativeBeatPayload): Promise<NarrativeBeatResponse>;
  mergeLines(payload: NarrativeMergePayload): Promise<NarrativeMergeResponse>;
  fetchCompass(projectId: string): Promise<NarrativeCompass>;
}

class NarrativeServiceImpl implements NarrativeServiceInterface {
  async list(projectId: string): Promise<NarrativeLinesResponse> {
    const data = await apiClient.request<NarrativeLinesResponse | ApiEnvelope<NarrativeLinesResponse>>(`/projects/${projectId}/narratives/lines`);
    return unwrapResponse<NarrativeLinesResponse>(data);
  }

  async createLine(payload: NarrativeLinePayload): Promise<NarrativeLine> {
    const requestOptions: RequestOptions = {
      method: http.RequestMethod.POST,
      data: payload
    };
    const data = await apiClient.request<NarrativeLine | ApiEnvelope<NarrativeLine>>(`/projects/${payload.project_id}/narratives/lines`, requestOptions);
    return unwrapResponse<NarrativeLine>(data);
  }

  async pushBeat(payload: NarrativeBeatPayload): Promise<NarrativeBeatResponse> {
    const requestOptions: RequestOptions = {
      method: http.RequestMethod.POST,
      data: payload
    };
    const data = await apiClient.request<NarrativeBeatResponse | ApiEnvelope<NarrativeBeatResponse>>(`/projects/${payload.project_id}/narratives/lines/${payload.line_id}/beats`, requestOptions);
    return unwrapResponse<NarrativeBeatResponse>(data);
  }

  async mergeLines(payload: NarrativeMergePayload): Promise<NarrativeMergeResponse> {
    const requestOptions: RequestOptions = {
      method: http.RequestMethod.POST,
      data: payload
    };
    const data = await apiClient.request<NarrativeMergeResponse | ApiEnvelope<NarrativeMergeResponse>>(`/projects/${payload.project_id}/narratives/merge`, requestOptions);
    return unwrapResponse<NarrativeMergeResponse>(data);
  }

  async fetchCompass(projectId: string): Promise<NarrativeCompass> {
    const data = await apiClient.request<NarrativeCompass | ApiEnvelope<NarrativeCompass>>(`/projects/${projectId}/narratives/compass`);
    return unwrapResponse<NarrativeCompass>(data);
  }
}

export const NarrativeService: NarrativeServiceInterface = new NarrativeServiceImpl();

export class TokenEstimator {
  static estimate(texts: Array<string>, pricePerKTokenCny: number = 0.12): TokenUsageEstimate {
    const characters = texts.reduce((acc: number, item: string) => acc + (item?.length ?? 0), 0);
    const tokens = Math.max(1, Math.ceil(characters / 2));
    const estimated_cost_cny = parseFloat(((tokens / 1000) * pricePerKTokenCny).toFixed(4));
    const result: TokenUsageEstimate = { tokens, characters, estimated_cost_cny };
    return result;
  }
}
