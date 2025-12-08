import { type NarrativeCompass, type CompassNode } from '../network/Services';

@Component
export default struct MemoryCompassCard {
  @Prop compass: NarrativeCompass;

  build() {
    Column({ space: 12 }) {
      Text(this.compass?.focus ?? '暂无焦点').fontSize(16).fontWeight(FontWeight.Medium);
      if (!this.compass || !this.compass.nodes || this.compass.nodes.length === 0) {
        Text('暂无记忆节点').fontSize(12).fontColor(0x999999);
      } else {
        ForEach(this.compass.nodes ?? [], (node: CompassNode, index: number) => this.renderNode(node, index), (_node: CompassNode, index: number) => `comp-${index}`);
      }
      if (this.compass?.last_updated) {
        Text(`更新于 ${this.compass.last_updated}`).fontSize(10).fontColor(0x999999);
      }
    }
    .padding(12)
    .backgroundColor(0xf7f7f9)
    .borderRadius(12);
  }

  @Builder
  renderNode(node: CompassNode, index: number) {
    Column({ space: 4 }) {
      Row({ space: 6 }) {
        Text(`#${index + 1} ${node.label}`).fontSize(14).fontWeight(FontWeight.Bold);
        Text(`情绪张力 ${this.formatScore(node.tension)}`).fontSize(10).fontColor(0x8a63ff);
        Text(`置信度 ${this.formatScore(node.confidence)}`).fontSize(10).fontColor(0x12b886);
      }
      Text(node.summary ?? '').fontSize(12).fontColor(0x444444);
    }
    .padding(10)
    .backgroundColor(0xffffff)
    .borderRadius(10);
  }

  formatScore(score?: number): string {
    const value = typeof score === 'number' ? Math.round(score * 100) / 100 : 0;
    return value.toFixed(2);
  }
}
