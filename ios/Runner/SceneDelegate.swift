import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    for urlContext in connectionOptions.urlContexts {
      WakeSagaAlarmEngine.shared.recordLaunch(
        from: urlContext.url,
        source: "coldStart"
      )
    }
    super.scene(scene, willConnectTo: session, options: connectionOptions)
  }

  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    for urlContext in URLContexts {
      WakeSagaAlarmEngine.shared.recordLaunch(
        from: urlContext.url,
        source: "warmAction"
      )
    }
    super.scene(scene, openURLContexts: URLContexts)
  }
}
