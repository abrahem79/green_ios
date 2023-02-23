import UIKit
import PromiseKit

protocol TwoFactorAuthenticationViewControllerDelegate: AnyObject {
    func userLogout()
}

class TwoFactorAuthenticationViewController: UIViewController {

    @IBOutlet weak var lblEnable2faTitle: UILabel!
    @IBOutlet weak var lblEnable2faHint: UILabel!
    @IBOutlet weak var lbl2faMethods: UILabel!
    @IBOutlet weak var tableView2faMethods: UITableView!
    @IBOutlet weak var lbl2faThresholdTitle: UILabel!
    @IBOutlet weak var lbl2faThresholdHint: UILabel!
    @IBOutlet weak var lbl2faThresholdCardTitle: UILabel!
    @IBOutlet weak var lbl2faThresholdCardHint: UILabel!
    @IBOutlet weak var thresholdCardDisclosure: UIImageView!
    @IBOutlet weak var btn2faThreshold: UIButton!
    @IBOutlet weak var bg2faThreshold: UIView!
    @IBOutlet weak var thresholdView: UIStackView!
    @IBOutlet weak var lblReset2faTitle: UILabel!
    @IBOutlet weak var lblReset2faCardTitle: UILabel!
    @IBOutlet weak var reset2faCardDisclosure: UIImageView!
    @IBOutlet weak var bgReset2fa: UIView!
    @IBOutlet weak var reset2faView: UIStackView!
    @IBOutlet weak var lbl2faExpiryTitle: UILabel!
    @IBOutlet weak var lbl2faExpiryHint: UILabel!
    @IBOutlet weak var tableViewCsvTime: DynamicTableView!
    @IBOutlet weak var lblRecoveryTool: UILabel!
    @IBOutlet weak var btnRecoveryTool: UIButton!
    @IBOutlet weak var networkSegmentedControl: UISegmentedControl!
    @IBOutlet weak var expiryView: UIStackView!

    private let viewModel = TwoFactorSettingsViewModel()
    private var factors = [TwoFactorItem]()
    private var connected = true
    private var updateToken: NSObjectProtocol?
    private var session: SessionManager { viewModel.sessions[networkSegmentedControl.selectedSegmentIndex] }
    private var csvTypes: [Settings.CsvTime] { Settings.CsvTime.all(for: session.gdkNetwork) }
    private var csvValues: [Int] { Settings.CsvTime.values(for: session.gdkNetwork) ?? [] }
    weak var delegate: TwoFactorAuthenticationViewControllerDelegate?
    var showBitcoin = true

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "2FA"
        setContent()
        setStyle()

        AnalyticsManager.shared.recordView(.walletSettings2FA, sgmt: AnalyticsManager.shared.sessSgmt(AccountsManager.shared.current))
    }

    func setContent() {
        lblEnable2faTitle.text = NSLocalizedString("id_enable_twofactor_authentication", comment: "")
        lblEnable2faHint.text = NSLocalizedString("id_tip_we_recommend_you_enable", comment: "")
        lbl2faMethods.text = NSLocalizedString("id_2fa_methods", comment: "")
        lbl2faThresholdTitle.text = NSLocalizedString("id_2fa_threshold", comment: "")
        lbl2faThresholdHint.text = NSLocalizedString("id_spend_your_bitcoin_without_2fa", comment: "")
        lbl2faThresholdCardTitle.text = NSLocalizedString("id_2fa_threshold", comment: "")
        lbl2faThresholdCardHint.text = NSLocalizedString("id_set_twofactor_threshold", comment: "")
        lbl2faExpiryTitle.text = NSLocalizedString("id_2fa_expiry", comment: "")
        lbl2faExpiryHint.text = NSLocalizedString("id_customize_2fa_expiration_of", comment: "")
        lblRecoveryTool.text = NSLocalizedString("id_your_2fa_expires_so_that_if_you", comment: "")
        btnRecoveryTool.setTitle(NSLocalizedString("id_recovery_tool", comment: ""), for: .normal)
        lblReset2faTitle.text = NSLocalizedString("id_request_twofactor_reset", comment: "")
        lblReset2faCardTitle.text = NSLocalizedString("id_i_lost_my_2fa", comment: "")
        viewModel.networks.enumerated().forEach { (i, net) in
            let title = getGdkNetwork(net).name
            networkSegmentedControl.setTitle(title, forSegmentAt: i)
        }
    }

    func setStyle() {
        lblEnable2faTitle.font = UIFont.systemFont(ofSize: 18.0, weight: .bold)
        lblEnable2faHint.font = UIFont.systemFont(ofSize: 16.0, weight: .regular)
        lblEnable2faTitle.textColor = .white
        lblEnable2faHint.textColor = UIColor.customGrayLight()
        lbl2faMethods.font = UIFont.systemFont(ofSize: 20.0, weight: .heavy)
        lbl2faMethods.textColor = .white
        lbl2faThresholdTitle.font = UIFont.systemFont(ofSize: 20.0, weight: .heavy)
        lbl2faThresholdHint.font = UIFont.systemFont(ofSize: 16.0, weight: .regular)
        lbl2faThresholdCardTitle.font = UIFont.systemFont(ofSize: 18.0, weight: .bold)
        lbl2faThresholdCardHint.font = UIFont.systemFont(ofSize: 16.0, weight: .regular)
        lbl2faThresholdTitle.textColor = .white
        lbl2faThresholdHint.textColor = UIColor.customGrayLight()
        lbl2faThresholdCardTitle.textColor = .white
        lbl2faThresholdCardHint.textColor = UIColor.customGrayLight()
        bg2faThreshold.layer.cornerRadius = 5.0
        lbl2faExpiryTitle.font = UIFont.systemFont(ofSize: 20.0, weight: .heavy)
        lbl2faExpiryHint.font = UIFont.systemFont(ofSize: 16.0, weight: .regular)
        lbl2faExpiryTitle.textColor = .white
        lbl2faExpiryHint.textColor = UIColor.customGrayLight()
        lblRecoveryTool.font = UIFont.systemFont(ofSize: 16.0, weight: .regular)
        lblRecoveryTool.textColor = UIColor.customGrayLight()
        btnRecoveryTool.setStyle(.primary)
        thresholdCardDisclosure.image = UIImage(named: "rightArrow")?.maskWithColor(color: .white)
        lblReset2faTitle.font = UIFont.systemFont(ofSize: 20.0, weight: .heavy)
        lblReset2faCardTitle.font = UIFont.systemFont(ofSize: 18.0, weight: .bold)
        reset2faCardDisclosure.image = UIImage(named: "rightArrow")?.maskWithColor(color: .white)

        networkSegmentedControl.setTitleTextAttributes (
            [NSAttributedString.Key.foregroundColor: UIColor.black], for: .selected)
        networkSegmentedControl.setTitleTextAttributes (
            [NSAttributedString.Key.foregroundColor: UIColor.white], for: .normal)
        networkSegmentedControl.selectedSegmentIndex = showBitcoin ? 0 : 1
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateToken = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: EventType.Network.rawValue), object: nil, queue: .main, using: updateConnection)
        reloadData()
    }

    @IBAction func changeNetwork(_ sender: Any) {
        reloadData()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let token = updateToken {
            NotificationCenter.default.removeObserver(token)
        }
    }

    func reloadData() {
        let liquid = session.gdkNetwork.liquid
        tableViewCsvTime.estimatedRowHeight = 80
        tableViewCsvTime.rowHeight = UITableView.automaticDimension
        tableViewCsvTime.reloadData()
        tableViewCsvTime.isHidden = !session.logged || liquid
        lbl2faExpiryTitle.isHidden = !session.logged
        lbl2faExpiryHint.isHidden = !session.logged
        btnRecoveryTool.isHidden = !session.logged
        lblRecoveryTool.isHidden = !session.logged
        tableViewCsvTime.isHidden = !session.logged || liquid
        reset2faView.isHidden = !session.logged || liquid
        thresholdView.isHidden = !session.logged || liquid
        expiryView.isHidden = !session.logged
        viewModel.getTwoFactors(session: session)
            .done { factors in
                self.factors = factors
                self.tableView2faMethods.reloadData()
                self.reloadThreshold()
            }.catch { err in print(err) }
    }

    func reloadThreshold() {
        if let twoFactorConfig = viewModel.twoFactorConfig,
            twoFactorConfig.anyEnabled,
            let settings = session.settings {
            let limits = twoFactorConfig.limits
            var (amount, den) = ("", "")
            if limits.isFiat {
                let balance = Balance.fromFiat(limits.fiat ?? "0")
                (amount, den) = balance?.toDenom() ?? ("", "")
            } else {
                let denom = settings.denomination.rawValue
                let assetId = session.gdkNetwork.getFeeAsset()
                let balance = Balance.fromDenomination(limits.get(TwoFactorConfigLimits.CodingKeys(rawValue: denom)!) ?? "0", assetId: assetId)
                (amount, den) = balance?.toFiat() ?? ("", "")
            }
            let thresholdValue = String(format: "%@ %@", amount, den)
            lbl2faThresholdCardTitle.text = NSLocalizedString("id_twofactor_threshold", comment: "")
            lbl2faThresholdCardHint.text = String(format: NSLocalizedString(thresholdValue == "" ? "" : "%@", comment: ""), thresholdValue)
        }
    }

    func updateConnection(_ notification: Notification) {
        if let data = notification.userInfo,
              let json = try? JSONSerialization.data(withJSONObject: data, options: []),
              let connection = try? JSONDecoder().decode(Connection.self, from: json) {
            self.connected = connection.connected
        }
    }

    func disable(_ type: TwoFactorType) {
        self.startLoader()
        firstly { Guarantee() }
            .then { self.viewModel.disable(session: self.session, type: type) }
            .ensure { self.stopLoader() }
            .done { _ in
                self.reloadData()
                let notification = NSNotification.Name(rawValue: EventType.TwoFactorReset.rawValue)
                NotificationCenter.default.post(name: notification, object: nil, userInfo: nil)
            }.catch { error in
                if let twofaError = error as? TwoFactorCallError {
                    switch twofaError {
                    case .failure(let localizedDescription), .cancel(let localizedDescription):
                        DropAlert().error(message: localizedDescription)
                    }
                } else {
                    DropAlert().error(message: error.localizedDescription)
                }
            }
    }

    func setCsvTimeLock(csv: Settings.CsvTime) {
        self.startLoader()
        firstly { Guarantee() }
            .then { self.viewModel.setCsvTimeLock(session: self.session, csv: csv) }
            .ensure { self.stopLoader() }
            .done { _ in
                self.reloadData()
                DropAlert().success(message: String(format: "%@: %@", NSLocalizedString("id_twofactor_authentication_expiry", comment: ""), csv.label()))
            }.catch { error in
                if let twofaError = error as? TwoFactorCallError {
                    switch twofaError {
                    case .failure(let localizedDescription), .cancel(let localizedDescription):
                        DropAlert().error(message: localizedDescription)
                    }
                } else {
                    DropAlert().error(message: "Error changing csv time")
                }
            }
    }

    func showResetTwoFactor() {
        let hint = "jane@example.com"
        let alert = UIAlertController(title: NSLocalizedString("id_request_twofactor_reset", comment: ""), message: NSLocalizedString("id_resetting_your_twofactor_takes", comment: ""), preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = hint
            textField.keyboardType = .emailAddress
        }
        alert.addAction(UIAlertAction(title: NSLocalizedString("id_cancel", comment: ""), style: .cancel) { _ in })
        alert.addAction(UIAlertAction(title: NSLocalizedString("id_save", comment: ""), style: .default) { _ in
            let textField = alert.textFields!.first
            let email = textField!.text
            self.resetTwoFactor(email: email!)
        })
        self.present(alert, animated: true, completion: nil)
    }

    func resetTwoFactor(email: String) {
        //AnalyticsManager.shared.recordView(.walletSettings2FAReset, sgmt: AnalyticsManager.shared.twoFacSgmt(AccountsManager.shared.current, walletType: wallet?.type, twoFactorType: nil))
        self.startLoader()
        firstly { Guarantee() }
            .then { self.viewModel.resetTwoFactor(session: self.session, email: email) }
            .ensure { self.stopLoader() }
            .done { _ in
                self.reloadData()
                DropAlert().success(message: NSLocalizedString("id_2fa_reset_in_progress", comment: ""))
                let notification = NSNotification.Name(rawValue: EventType.TwoFactorReset.rawValue)
                NotificationCenter.default.post(name: notification, object: nil, userInfo: nil)
                self.delegate?.userLogout()
            }.catch { error in
                if let twofaError = error as? TwoFactorCallError {
                    switch twofaError {
                    case .failure(let localizedDescription), .cancel(let localizedDescription):
                        self.showError(localizedDescription)
                    }
                } else {
                    DropAlert().error(message: error.localizedDescription)
                }
            }
    }

    @IBAction func btnReset2fa(_ sender: Any) {
        showResetTwoFactor()
    }

    @IBAction func btn2faThreshold(_ sender: Any) {
        let storyboard = UIStoryboard(name: "UserSettings", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "TwoFactorLimitViewController") as? TwoFactorLimitViewController {
            vc.session = session
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    @IBAction func btnRecoveryTool(_ sender: Any) {
        if let url = URL(string: "https://github.com/greenaddress/garecovery") {
            UIApplication.shared.open(url)
        }
    }
}

extension TwoFactorAuthenticationViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == tableView2faMethods {
            let item: TwoFactorItem = factors[indexPath.row]
            if let cell = tableView.dequeueReusableCell(withIdentifier: "TwoFaMethodsCell") as? TwoFaMethodsCell {
                cell.configure(item)
                cell.selectionStyle = .none
                return cell
            }
        } else if tableView == tableViewCsvTime {
            let item: Settings.CsvTime = csvTypes[indexPath.row]
            if let cell = tableView.dequeueReusableCell(withIdentifier: "TwoFaCsvTimeCell") as? TwoFaCsvTimeCell {
                cell.configure(item: item, current: session.settings?.csvtime, gdkNetwork: session.gdkNetwork)
                cell.selectionStyle = .none
                return cell
            }
        }
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == tableView2faMethods {
            return self.factors.count
        } else if tableView == tableViewCsvTime {
            return csvTypes.count
        } else {
            return 0
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        if tableView == tableView2faMethods {
            let selectedFactor: TwoFactorItem = self.factors[indexPath.row]
            if selectedFactor.enabled {
                disable(selectedFactor.type)
                return
            }
            switch selectedFactor.type {
            case .email:
                let storyboard = UIStoryboard(name: "AuthenticatorFactors", bundle: nil)
                if let vc = storyboard.instantiateViewController(withIdentifier: "SetEmailViewController") as? SetEmailViewController {
                    vc.session = session
                    navigationController?.pushViewController(vc, animated: true)
                }
            case .sms:
                let storyboard = UIStoryboard(name: "AuthenticatorFactors", bundle: nil)
                if let vc = storyboard.instantiateViewController(withIdentifier: "SetPhoneViewController") as? SetPhoneViewController {
                    vc.sms = true
                    vc.session = session
                    navigationController?.pushViewController(vc, animated: true)
                }
            case .phone:
                let storyboard = UIStoryboard(name: "AuthenticatorFactors", bundle: nil)
                if let vc = storyboard.instantiateViewController(withIdentifier: "SetPhoneViewController") as? SetPhoneViewController {
                    vc.phoneCall = true
                    vc.session = session
                    navigationController?.pushViewController(vc, animated: true)
                }
            case .gauth:
                let storyboard = UIStoryboard(name: "AuthenticatorFactors", bundle: nil)
                if let vc = storyboard.instantiateViewController(withIdentifier: "SetGauthViewController") as? SetGauthViewController {
                    vc.session = session
                    navigationController?.pushViewController(vc, animated: true)
                }
            }

            //AnalyticsManager.shared.recordView(.walletSettings2FASetup, sgmt: AnalyticsManager.shared.twoFacSgmt(AccountsManager.shared.current, walletType: wallet?.type, twoFactorType: selectedFactor.type))
        } else if tableView == tableViewCsvTime {
            let selected = csvTypes[indexPath.row]
            if let newCsv = selected.value(for: session.gdkNetwork),
               let index = csvValues.firstIndex(of: newCsv),
               newCsv != session.settings?.csvtime ?? 0 {
                setCsvTimeLock(csv: csvTypes[index])
            } else {
                self.showAlert(title: NSLocalizedString("Error", comment: ""), message: "Select a new value to change csv")
            }
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView == tableView2faMethods {
            return 80.0
        } else if tableView == tableViewCsvTime {
            return UITableView.automaticDimension
        } else {
            return 0
        }
    }
}
