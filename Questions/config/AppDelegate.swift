import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?
	var wasPlaying = Bool()
	private let blurView = UIVisualEffectView(frame: UIScreen.main.bounds)
	
	// Home Screen Quick Actions [3D Touch]

	enum ShortcutItemType: String {
		case QRCode
	}
	
	static var windowReference: UIWindow?
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
		
		// Load configuration file (if it doesn't exist it creates a new one when the app goes to background)
		if let mySettings = NSKeyedUnarchiver.unarchiveObject(withFile: DataStoreArchiver.path) as? DataStoreArchiver {
			DataStoreArchiver.shared = mySettings
		}
		//
		
		AppDelegate.windowReference = self.window

		let navController = window?.rootViewController as? UINavigationController
		
		if #available(iOS 11.0, *) {
			navController?.navigationBar.prefersLargeTitles = true
		}
		
		let readQRCode = UIMutableApplicationShortcutItem(type: ShortcutItemType.QRCode.rawValue,
														 localizedTitle: "Scan QR Code".localized,
														 localizedSubtitle: nil,
														 icon: UIApplicationShortcutIcon(templateImageName: "QRCodeIcon"))
		
		application.shortcutItems = [readQRCode]

		AppDelegate.updateVolumeBarTheme()
		VolumeBar.shared.start()
		
		self.window?.dontInvertIfDarkModeIsEnabled()
		
		if QuestionsAppOptions.privacyFeaturesEnabled {
			self.setupBlurView()
		}
		
		return true
	}
	
	private func setupBlurView() {
		blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		blurView.effect = UserDefaultsManager.darkThemeSwitchIsOn ? UIBlurEffect(style: .dark) : UIBlurEffect(style: .light)
		blurView.isHidden = true
		self.window?.addSubview(blurView)
	}
	
	func applicationWillResignActive(_ application: UIApplication) {
		guard QuestionsAppOptions.privacyFeaturesEnabled else { return }
		blurView.isHidden = false
		self.window?.bringSubviewToFront(blurView)
	}
	
	func applicationDidBecomeActive(_ application: UIApplication) {
		
		if wasPlaying {
			AudioSounds.bgMusic?.play()
		}
		
		self.window?.dontInvertIfDarkModeIsEnabled()
		
		if QuestionsAppOptions.privacyFeaturesEnabled {
			self.blurView.isHidden = true
		}
	}

	static func updateVolumeBarTheme() {
		VolumeBar.shared.backgroundColor = .themeStyle(dark: .black, light: .white)
		VolumeBar.shared.tintColor = .themeStyle(dark: .lightGray, light: .black)
		VolumeBar.shared.trackTintColor = .themeStyle(dark: UIColor.lightGray.withAlphaComponent(0.3), light: UIColor.black.withAlphaComponent(0.1))
	}
	
	@available(iOS 9.0, *)
	func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
		
		if let itemType = ShortcutItemType(rawValue: shortcutItem.type) {
		
			switch itemType {
			
			case .QRCode:
				
				if let questionsVC = window?.rootViewController?.presentedViewController as? QuestionsViewController {
					questionsVC.performSegue(withIdentifier: "unwindToMainMenu", sender: self)
				}
				
				if let presentedViewController = window?.rootViewController as? UINavigationController {
					
					if presentedViewController.topViewController is QRScannerViewController {
						return
					} else if !(presentedViewController.topViewController is MainViewController) {
						presentedViewController.popToRootViewController(animated: false)
					}
					
					presentedViewController.topViewController?.performSegue(withIdentifier: "QRScannerVC", sender: self)
				}
				else if (window?.rootViewController == nil) {
					
					let storyboard = UIStoryboard(name: "Main", bundle: nil)
					if let viewController = storyboard.instantiateViewController(withIdentifier: "mainViewController") as? MainViewController {
						
						let navController = UINavigationController(rootViewController: viewController)
						if #available(iOS 11.0, *) {
							navController.navigationBar.prefersLargeTitles = true
						}
						
						window?.rootViewController?.present(navController, animated: false)
						
						viewController.performSegue(withIdentifier: "QRScannerVC", sender: self)
					}
				}
			}
		}
	}

	func applicationDidEnterBackground(_ application: UIApplication) {
		
		if AudioSounds.bgMusic?.isPlaying ?? false {
			AudioSounds.bgMusic?.pause()
			wasPlaying = true
		}
		else {
			wasPlaying = false
		}
		
		guard DataStoreArchiver.shared.save() else { print("Error saving settings"); return }
		
		self.window?.dontInvertIfDarkModeIsEnabled()
	}
}
