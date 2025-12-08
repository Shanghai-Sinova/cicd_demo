import http from '@ohos.net.http';

const API_TIMEOUT_MS: number = 5000 * 1000;
const DEFAULT_BASE_URL: string = 'http://127.0.0.1:23004/api/v1';

export interface HeaderEntry {
  key: string;
  value: string;
}

class HeaderObject {
  set(key: string, value: string): void {
    Reflect.set(this, key, value);
  }
}

export interface RequestOptions {
  method?: http.RequestMethod;
  data?: string | Object;
  headers?: Array<HeaderEntry>;
}

export class ApiClient {
  private baseUrl: string = DEFAULT_BASE_URL;
  private authToken: string = '';

  setBaseUrl(url: string): void {
    this.baseUrl = url || DEFAULT_BASE_URL;
  }

  setToken(token: string): void {
    this.authToken = token;
  }

  clearToken(): void {
    this.authToken = '';
  }

  get token(): string {
    return this.authToken;
  }

  async request<T>(path: string, options: RequestOptions = {}): Promise<T> {
    const method: http.RequestMethod = options.method ?? http.RequestMethod.GET;
    const headerEntries: Array<HeaderEntry> = [
      { key: 'Content-Type', value: 'application/json' }
    ];
    if (options.headers) {
      headerEntries.push(...options.headers);
    }
    if (this.authToken) {
      headerEntries.push({ key: 'Authorization', value: `Bearer ${this.authToken}` });
    }
    const headerObject: HeaderObject = new HeaderObject();
    headerEntries.forEach((entry: HeaderEntry) => headerObject.set(entry.key, entry.value));

    const httpRequest = http.createHttp();
    try {
      const extraData: string = typeof options.data === 'string'
        ? options.data
        : options.data
          ? JSON.stringify(options.data)
          : '';

      const response = await httpRequest.request(this.baseUrl + path, {
        method,
        connectTimeout: API_TIMEOUT_MS,
        readTimeout: API_TIMEOUT_MS,
        header: headerObject as Object,
        extraData
      });

      if (response.responseCode === 401) {
        this.clearToken();
        throw new Error('未授权，请先登录');
      }
      if (response.responseCode < 200 || response.responseCode >= 300) {
        const errorMessage = typeof response.result === 'string'
          ? response.result
          : '请求失败';
        if (typeof errorMessage === 'string' && errorMessage.toLowerCase().includes('permission')) {
          throw new Error('无权限访问，请先登录');
        }
        throw new Error(errorMessage);
      }
      const body = typeof response.result === 'string'
        ? response.result
        : JSON.stringify(response.result ?? {});
      return JSON.parse(body) as T;
    } finally {
      httpRequest.destroy();
    }
  }
}

export const apiClient: ApiClient = new ApiClient();
