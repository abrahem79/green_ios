import UIKit

enum OnBoardingFlowType {
    case add
    case restore
    case watchonly
}

enum OnBoardingChainType {
    case mainnet
    case testnet
}

enum ActionOnButton {
    case new
    case restore
    case watchOnly
}

enum LandingScope {
    case onBoard
    case hwTerms
}

protocol LandingViewControllerDelegate: AnyObject {
    func didPressContinue()
}

class LandingViewController: UIViewController {

    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblHint: UILabel!
    @IBOutlet weak var lblTerms: UILabel!
    @IBOutlet weak var btnTerms: UIButton!

    @IBOutlet weak var btnCheckTerms: CheckButton!
    @IBOutlet weak var btnNewWallet: UIButton!
    @IBOutlet weak var btnRestoreWallet: UIButton!
    @IBOutlet weak var btnWatchOnly: UIButton!
    @IBOutlet weak var btnContinue: UIButton!

    @IBOutlet weak var iconPlus: UIImageView!
    @IBOutlet weak var iconRestore: UIImageView!
    @IBOutlet weak var iconWatch: UIImageView!

    static var flowType: OnBoardingFlowType = .add
    static var chainType: OnBoardingChainType = .mainnet

    var actionOnButton: ActionOnButton?
    var iAgree: Bool = false
    var landingScope: LandingScope = .onBoard

    weak var delegate: LandingViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        switch landingScope {
        case .onBoard:
            btnContinue.isHidden = true
        case .hwTerms:
            [btnNewWallet, btnRestoreWallet, btnWatchOnly, iconPlus, iconRestore, iconWatch]
                .forEach { $0?.alpha = 0.0}
        }

        iAgree = AccountsRepository.shared.swAccounts.count > 0

        customBack()
        setContent()
        setStyle()
        updateUI()

        view.accessibilityIdentifier = AccessibilityIdentifiers.LandingScreen.view
        btnCheckTerms.accessibilityIdentifier = AccessibilityIdentifiers.LandingScreen.acceptTermsBtn
        btnNewWallet.accessibilityIdentifier = AccessibilityIdentifiers.LandingScreen.newWalletBtn
        btnRestoreWallet.accessibilityIdentifier = AccessibilityIdentifiers.LandingScreen.restoreWalletBtn
        btnWatchOnly.accessibilityIdentifier = AccessibilityIdentifiers.LandingScreen.watchOnlyWalletBtn

        if landingScope == .onBoard {
            AnalyticsManager.shared.recordView(.onBoardIntro)
        }
    }

    func customBack() {
        var arrow = UIImage.init(named: "backarrow")
        if #available(iOS 13.0, *) {
            arrow = UIImage(systemName: "chevron.backward")
        }
        let newBackButton = UIBarButtonItem(image: arrow, style: UIBarButtonItem.Style.plain, target: self, action: #selector(LandingViewController.back(sender:)))
        navigationItem.leftBarButtonItem = newBackButton
        navigationItem.hidesBackButton = true
    }

    @objc func back(sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }

    func setContent() {
        lblTitle.text = NSLocalizedString("id_blockstream_greennsimple_and", comment: "")
        lblHint.text = NSLocalizedString("id_well_get_you_set_up_in_no_time", comment: "")
        lblTerms.text = NSLocalizedString("id_i_agree_to_the", comment: "")
        btnNewWallet.setTitle(NSLocalizedString("id_new_wallet", comment: ""), for: .normal)
        btnRestoreWallet.setTitle(NSLocalizedString("id_restore_wallet", comment: ""), for: .normal)
        btnWatchOnly.setTitle(NSLocalizedString("id_watchonly", comment: ""), for: .normal)
        btnContinue.setTitle("id_continue".localized, for: .normal)
    }

    func setStyle() {
        btnNewWallet.cornerRadius = 4.0
        btnRestoreWallet.cornerRadius = 4.0
        btnWatchOnly.cornerRadius = 4.0
        btnWatchOnly.borderWidth = 1.0
        btnWatchOnly.borderColor = UIColor.customGrayLight()
        btnContinue.setStyle(.primaryDisabled)
    }

    func updateUI() {
        btnCheckTerms.isSelected = iAgree
        btnNewWallet.isEnabled = iAgree
        btnRestoreWallet.isEnabled = iAgree
        btnWatchOnly.isEnabled = iAgree

        if iAgree {
            btnNewWallet.backgroundColor = UIColor.customMatrixGreen()
            btnRestoreWallet.backgroundColor = UIColor.customMatrixGreen()
            btnNewWallet.setTitleColor(.white, for: .normal)
            btnRestoreWallet.setTitleColor(.white, for: .normal)
            btnWatchOnly.setTitleColor(UIColor.customMatrixGreen(), for: .normal)
            iconPlus.image = iconPlus.image?.maskWithColor(color: .white)
            iconRestore.image = iconRestore.image?.maskWithColor(color: .white)
            iconWatch.image = iconWatch.image?.maskWithColor(color: UIColor.customMatrixGreen())
            btnContinue.setStyle(.primary)
        } else {
            btnNewWallet.backgroundColor = UIColor.customBtnOff()
            btnRestoreWallet.backgroundColor = UIColor.customBtnOff()
            btnNewWallet.setTitleColor(UIColor.customGrayLight(), for: .normal)
            btnRestoreWallet.setTitleColor(UIColor.customGrayLight(), for: .normal)
            btnWatchOnly.setTitleColor(UIColor.customGrayLight(), for: .normal)
            iconPlus.image = iconPlus.image?.maskWithColor(color: UIColor.customGrayLight())
            iconRestore.image = iconRestore.image?.maskWithColor(color: UIColor.customGrayLight())
            iconWatch.image = iconWatch.image?.maskWithColor(color: UIColor.customGrayLight())
            btnContinue.setStyle(.primaryDisabled)
        }
    }

    func onNext(_ action: ActionOnButton) {
        if AnalyticsManager.shared.consent == .notDetermined {
            actionOnButton = action

            let storyboard = UIStoryboard(name: "Dialogs", bundle: nil)
            if let vc = storyboard.instantiateViewController(withIdentifier: "DialogCountlyViewController") as? DialogCountlyViewController {
                vc.modalPresentationStyle = .overFullScreen
                vc.delegate = self
                self.present(vc, animated: true, completion: nil)
            }
            return
        }
        switch action {
        case .new:
            LandingViewController.flowType = .add
        case .restore:
            LandingViewController.flowType = .restore
        case .watchOnly:
            LandingViewController.flowType = .watchonly
        }
        let testnetAvailable = UserDefaults.standard.bool(forKey: AppStorage.testnetIsVisible) == true
        if testnetAvailable {
            selectNetwork()
        } else {
            next()
        }
    }

    func selectNetwork() {
        let storyboard = UIStoryboard(name: "Dialogs", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "DialogListViewController") as? DialogListViewController {
            vc.delegate = self
            vc.viewModel = DialogListViewModel(title: "Select Network", type: .networkPrefs, items: NetworkPrefs.getItems())
            vc.modalPresentationStyle = .overFullScreen
            present(vc, animated: false, completion: nil)
        }
    }

    func next() {
        let storyboard = UIStoryboard(name: "OnBoard", bundle: nil)
        switch LandingViewController.flowType {
        case .add:
            let vc = storyboard.instantiateViewController(withIdentifier: "OnBoardInfoViewController")
            navigationController?.pushViewController(vc, animated: true)
        case .restore:
            let vc = storyboard.instantiateViewController(withIdentifier: "MnemonicViewController")
            navigationController?.pushViewController(vc, animated: true)
        case .watchonly:
            let vc = storyboard.instantiateViewController(withIdentifier: "WatchOnlyViewController")
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    @IBAction func btnCheckTerms(_ sender: Any) {
        print(btnCheckTerms.isSelected)
        iAgree = btnCheckTerms.isSelected
        updateUI()
    }

    @IBAction func btnTerms(_ sender: Any) {
        if let url = URL(string: "https://blockstream.com/green/terms/") {
            UIApplication.shared.open(url)
        }
    }

    @IBAction func btnNewWallet(_ sender: Any) {
        AnalyticsManager.shared.newWallet()
        onNext(.new)
    }

    @IBAction func btnRestoreWallet(_ sender: Any) {
        onNext(.restore)
    }

    @IBAction func btnWatchOnly(_ sender: Any) {
        onNext(.watchOnly)
    }

    @IBAction func btnContinue(_ sender: Any) {
        delegate?.didPressContinue()
    }
}

extension LandingViewController: DialogCountlyViewControllerDelegate {
    func didChangeConsent() {
        switch AnalyticsManager.shared.consent {
        case .notDetermined:
            break
        case .denied, .authorized:
            if let actionOnButton = actionOnButton {
                onNext(actionOnButton)
            }
        }
    }
}

extension LandingViewController: DialogListViewControllerDelegate {
    func didSelectIndex(_ index: Int, with type: DialogType) {
        switch NetworkPrefs(rawValue: index) {
        case .mainnet:
            LandingViewController.chainType = .mainnet
            next()
        case .testnet:
            LandingViewController.chainType = .testnet
            next()
        case .none:
            break
        }
    }
}
