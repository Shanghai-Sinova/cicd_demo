import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { AuthService } from '../network/Services';

interface AuthModeToggleConfig {
  textOn: string;
  textOff: string;
  isOn: boolean;
  type: ToggleType;
}

@Entry
@Component
struct LoginPage {
  @State username: string = 'user001';
  @State password: string = 'abcd123456';
  @State email: string = 'user001@example.com';
  @State nickname: string = '';
  @State isRegisterMode: boolean = false;
  @State loading: boolean = false;
  @State error: string = '';

  private buildToggleConfig(): AuthModeToggleConfig {
    return {
      textOn: '注册',
      textOff: '登录',
      isOn: this.isRegisterMode,
      type: ToggleType.Switch
    };
  }

  build() {
    // 登录/注册表单，使用状态切换注册模式
    Column() {
      Column({ space: 20 }) {
        Text('AI 创作助手')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
        Toggle(this.buildToggleConfig())
          .onChange((value: boolean) => this.isRegisterMode = value)
        TextInput({ placeholder: '用户名', text: this.username })
          .onChange((value) => this.username = value)
          .border({ color: 0xdddddd, width: 1, radius: 12 })
          .padding(12)
          .width('100%')
        if (this.isRegisterMode) {
          TextInput({ placeholder: '邮箱', text: this.email })
            .onChange((value) => this.email = value)
            .border({ color: 0xdddddd, width: 1, radius: 12 })
            .padding(12)
            .width('100%')
          TextInput({ placeholder: '昵称(可选)', text: this.nickname })
            .onChange((value) => this.nickname = value)
            .border({ color: 0xdddddd, width: 1, radius: 12 })
            .padding(12)
            .width('100%')
        }

        TextInput({ placeholder: '密码', text: this.password })
          .type(InputType.Password)
          .onChange((value) => this.password = value)
          .border({ color: 0xdddddd, width: 1, radius: 12 })
          .padding(12)
          .width('100%')
        Button(this.loading ? '处理中...' : (this.isRegisterMode ? '注册并登录' : '登录'))
          .type(ButtonType.Capsule)
          .width('100%')
          .backgroundColor(0x8a63ff)
          .onClick(() => {
            if (this.isRegisterMode) {
              this.handleRegister();
            } else {
              this.handleLogin();
            }
          })
          .enabled(!this.loading)
        if (this.error) {
          Text(this.error).fontColor(0xff4d4f).width('100%')
        }
      }
      .width('100%')
      .padding({ left: 24, right: 24, top: 48, bottom: 48 })
      .backgroundColor(0xffffff)
      .borderRadius(24)
      .shadow({ radius: 6, color: 0x11000000 });
    }
    .width('100%')
    .height('100%')
    .backgroundColor(0xf7f7f9)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  async handleLogin() {
    if (!this.username || !this.password) {
      this.error = '请输入账号和密码';
      return;
    }
    this.loading = true;
    this.error = '';
    try {
      // 登录成功后存储 token 并跳转首页
      await AuthService.login({ username: this.username, password: this.password });
      promptAction.showToast({ message: '登录成功' });
      router.replaceUrl({ url: 'pages/HomePage' });
    } catch (err) {
      this.error = err?.message ?? '登录失败';
    } finally {
      this.loading = false;
    }
  }

  async handleRegister() {
    if (!this.username || !this.password || !this.email) {
      this.error = '请填写完整信息';
      return;
    }
    this.loading = true;
    this.error = '';
    try {
      await AuthService.register({
        username: this.username,
        password: this.password,
        email: this.email,
        nickname: this.nickname
      });
      promptAction.showToast({ message: '注册成功' });
      await this.handleLogin();
    } catch (err) {
      this.error = err?.message ?? '注册失败';
    } finally {
      this.loading = false;
    }
  }
}
