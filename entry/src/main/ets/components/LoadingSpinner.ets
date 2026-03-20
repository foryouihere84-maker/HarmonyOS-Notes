/**
 * 加载进度组件
 * 用于显示加载动画
 * 
 * @author 开发者
 * @date 2026-03-19
 */

@Component
export struct LoadingSpinner {
  @Prop color: ResourceColor = Color.Blue;
  @Prop spinnerSize: number = 40;
  @Prop strokeWidth: number = 3;
  
  build() {
    Stack() {
      Circle()
        .width(this.spinnerSize)
        .height(this.spinnerSize)
        .fill(Color.Transparent)
        .stroke(this.color)
        .strokeWidth(this.strokeWidth)
        .rotate({ angle: this.angle })
        .animation({
          duration: 2000,
          iterations: -1,
          curve: Curve.Linear
        })
        .onAppear(() => {
          this.startRotation();
        })
    }
    .width(this.spinnerSize)
    .height(this.spinnerSize)
  }
  
  private startRotation(): void {
    this.angle = 360;
  }
  
  @State private angle: number = 0;
}
