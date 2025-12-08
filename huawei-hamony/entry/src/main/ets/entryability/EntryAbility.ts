import UIAbility from '@ohos.app.ability.UIAbility';
import window from '@ohos.window';
import abilityAccessCtrl, { PermissionRequestResult } from '@ohos.abilityAccessCtrl';
import promptAction from '@ohos.promptAction';

export default class EntryAbility extends UIAbility {
  onWindowStageCreate(windowStage: window.WindowStage) {
    windowStage.loadContent('pages/LoginPage', (err) => {
      if (err.code) {
        console.error('加载 LoginPage 失败: ' + JSON.stringify(err));
      }
    });
    this.ensureNetworkPermissions();
  }

  private async ensureNetworkPermissions(): Promise<void> {
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const permissions: Array<string> = [
        'ohos.permission.INTERNET',
        'ohos.permission.GET_NETWORK_INFO'
      ];
      const grantStatus: PermissionRequestResult = await atManager.requestPermissionsFromUser(this.context, permissions);
      const denied = grantStatus.permissions.filter((_, index: number) => grantStatus.authResults[index] !== 0);
      if (denied.length > 0) {
        promptAction.showToast({ message: `权限未授予: ${denied.join(', ')}` });
      }
    } catch (err) {
      console.error('请求网络权限失败: ' + JSON.stringify(err));
    }
  }
}
