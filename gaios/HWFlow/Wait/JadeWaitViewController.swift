import UIKit
import CoreBluetooth
import RiveRuntime
import AsyncBluetooth
import Combine
import gdk
import core

class JadeWaitViewController: HWFlowBaseViewController {

    @IBOutlet weak var lblStepNumber: UILabel!
    @IBOutlet weak var lblStepTitle: UILabel!
    @IBOutlet weak var lblStepHint: UILabel!
    @IBOutlet weak var lblLoading: UILabel!
    @IBOutlet weak var infoBox: UIView!
    @IBOutlet weak var loaderPlaceholder: UIView!
    @IBOutlet weak var animateView: UIView!
    @IBOutlet weak var btnConnectWithQr: UIButton!

    let viewModel = JadeWaitViewModel()
    var scanViewModel: ScanViewModel?
    private var scanCancellable: AnyCancellable?
    var timer: Timer?
    var idx = 0

    private var activeToken, resignToken: NSObjectProtocol?
    private var selectedItem: ScanListItem?
    private var cancellables = Set<AnyCancellable>()

    let loadingIndicator: ProgressView = {
        let progress = ProgressView(colors: [UIColor.customMatrixGreen()], lineWidth: 2)
        progress.translatesAutoresizingMaskIntoConstraints = false
        return progress
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        setContent()
        setStyle()
        loadNavigationBtns()
        update()
        animateView.alpha = 0.0
    }

    override func viewDidAppear(_ animated: Bool) {
        activeToken = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main, using: applicationDidBecomeActive)
        resignToken = NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: .main, using: applicationWillResignActive)
        timer = Timer.scheduledTimer(timeInterval: Constants.jadeAnimInterval, target: self, selector: #selector(fireTimer), userInfo: nil, repeats: true)
        update()
        UIView.animate(withDuration: 0.3) {
            self.animateView.alpha = 1.0
        }
        start()
        startScan()
        scanViewModel?.centralManager.eventPublisher
            .sink { [weak self] in
                switch $0 {
                case .didUpdateState(let state):
                    DispatchQueue.main.async {
                        self?.onCentralManagerUpdateState(state)
                    }
                default:
                    break
                }
            }.store(in: &cancellables)
        scanCancellable = scanViewModel?.objectWillChange.sink(receiveValue: { [weak self] in
            DispatchQueue.main.async {
                self?.onUpdateScanViewModel()
            }
        })
    }

    @MainActor
    func onUpdateScanViewModel() {
        if selectedItem != nil { return }
        if let peripheral = scanViewModel?.peripherals.filter({ $0.jade }).first {
            selectedItem = peripheral
            stopScan()
            next()
        }
    }

    @MainActor
    func onCentralManagerUpdateState(_ state: CBManagerState) {
        switch state {
        case .poweredOn:
            lblLoading.text = "id_looking_for_device".localized
            startScan()
        case .poweredOff:
            lblLoading.text = "id_enable_bluetooth".localized
            stopScan()
        default:
            break
        }
    }

    func showBleUnavailable() {
        var state: BleUnavailableState = .other
        switch CentralManager.shared.bluetoothState {
        case .unauthorized:
            state = .unauthorized
        case .poweredOff:
            state = .powerOff
        default:
            state = .other
        }
        let storyboard = UIStoryboard(name: "BleUnavailable", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "BleUnavailableViewController") as? BleUnavailableViewController {
            vc.state = state
            vc.delegate = self
            vc.modalPresentationStyle = .overFullScreen
            present(vc, animated: false, completion: nil)
        }
    }

    @MainActor
    func startScan() {
        Task {
            selectedItem = nil
            do {
                try await scanViewModel?.scan(deviceType: .Jade)
            } catch {
                switch error {
                case BluetoothError.bluetoothUnavailable:
                    lblLoading.text = "id_enable_bluetooth".localized
                default:
                    lblLoading.text = error.localizedDescription
                }
                showBleUnavailable()
            }
        }
    }

    @MainActor
    func stopScan() {
        Task {
            await scanViewModel?.stopScan()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let token = activeToken {
            NotificationCenter.default.removeObserver(token)
        }
        if let token = resignToken {
            NotificationCenter.default.removeObserver(token)
        }
        stop()
        timer?.invalidate()
        stopScan()
        scanCancellable?.cancel()
        cancellables.forEach { $0.cancel() }
    }

    @objc func fireTimer() {
        refresh()
    }

    func setContent() {
        lblLoading.text = "id_looking_for_device".localized
        btnConnectWithQr.setTitle("Connect via QR".localized, for: .normal)
    }

    func refresh() {
        UIView.animate(withDuration: 0.25, animations: {
            [self.lblStepNumber, self.lblStepTitle, self.lblStepHint, self.animateView].forEach {
                $0?.alpha = 0.0
            }}, completion: { _ in
                if self.idx < 2 { self.idx += 1 } else { self.idx = 0}
                self.update()
                UIView.animate(withDuration: 0.4, animations: {
                    [self.lblStepNumber, self.lblStepTitle, self.lblStepHint, self.animateView].forEach {
                        $0?.alpha = 1.0
                    }
                })
            })
    }

    func update() {
        animateView.subviews.forEach({ $0.removeFromSuperview() })
        let riveView = viewModel.steps[idx].riveModel.createRiveView()
        animateView.addSubview(riveView)
        riveView.frame = CGRect(x: 0.0, y: 0.0, width: animateView.frame.width, height: animateView.frame.height)
        self.lblStepNumber.text = self.viewModel.steps[idx].titleStep
        self.lblStepTitle.text = self.viewModel.steps[idx].title
        self.lblStepHint.text = self.viewModel.steps[idx].hint
    }

    func loadNavigationBtns() {
        let settingsBtn = UIButton(type: .system)
        settingsBtn.titleLabel?.font = UIFont.systemFont(ofSize: 14.0, weight: .bold)
        settingsBtn.tintColor = UIColor.gGreenMatrix()
        settingsBtn.setTitle("id_setup_guide".localized, for: .normal)
        settingsBtn.addTarget(self, action: #selector(setupBtnTapped), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: settingsBtn)
    }

    func setStyle() {
        infoBox.cornerRadius = 5.0
        lblStepNumber.font = UIFont.systemFont(ofSize: 12.0, weight: .black)
        lblStepTitle.font = UIFont.systemFont(ofSize: 14.0, weight: .bold)
        lblStepHint.font = UIFont.systemFont(ofSize: 12.0, weight: .regular)
        lblLoading.font = UIFont.systemFont(ofSize: 12.0, weight: .bold)
        lblStepNumber.textColor = UIColor.gGreenMatrix()
        lblStepTitle.textColor = .white
        lblStepHint.textColor = .white.withAlphaComponent(0.6)
        lblLoading.textColor = .white
        btnConnectWithQr.setStyle(.outlinedWhite)
    }

    @objc func setupBtnTapped() {
        let hwFlow = UIStoryboard(name: "HWFlow", bundle: nil)
        if let vc = hwFlow.instantiateViewController(withIdentifier: "SetupJadeViewController") as? SetupJadeViewController {
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    func start() {
        loaderPlaceholder.addSubview(loadingIndicator)

        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor
                .constraint(equalTo: loaderPlaceholder.centerXAnchor),
            loadingIndicator.centerYAnchor
                .constraint(equalTo: loaderPlaceholder.centerYAnchor),
            loadingIndicator.widthAnchor
                .constraint(equalToConstant: loaderPlaceholder.frame.width),
            loadingIndicator.heightAnchor
                .constraint(equalTo: loaderPlaceholder.widthAnchor)
        ])

        loadingIndicator.isAnimating = true
    }

    func stop() {
        loadingIndicator.isAnimating = false
    }

    func next() {
        let hwFlow = UIStoryboard(name: "HWFlow", bundle: nil)
        if let vc = hwFlow.instantiateViewController(withIdentifier: "ScanViewController") as? ScanViewController {
            vc.deviceType = .Jade
            vc.scanViewModel = scanViewModel
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        start()
    }

    func applicationWillResignActive(_ notification: Notification) {
        stop()
    }

    @IBAction func tapConnectWithQr(_ sender: Any) {
        let hwFlow = UIStoryboard(name: "QRUnlockFlow", bundle: nil)
        if let vc = hwFlow.instantiateViewController(withIdentifier: "QRUnlockInfoAlertViewController") as? QRUnlockInfoAlertViewController {
            vc.delegate = self
            vc.modalPresentationStyle = .overFullScreen
            present(vc, animated: false, completion: nil)
        }
    }
}

extension JadeWaitViewController: BleUnavailableViewControllerDelegate {
    func onAction(_ action: BleUnavailableAction) {
        // navigationController?.popViewController(animated: true)
    }
}

extension JadeWaitViewController: QRUnlockInfoAlertViewControllerDelegate {
    func onTap(_ action: QRUnlockInfoAlertAction) {
        switch action {
        case .learnMore:
            let url = "https://help.blockstream.com/hc/en-us/sections/10426339090713-Air-gapped-Usage"
            if let url = URL(string: url) {
                if UIApplication.shared.canOpenURL(url) {
                    SafeNavigationManager.shared.navigate(url)
                }
            }
        case .setup:
            let storyboard = UIStoryboard(name: "QRUnlockFlow", bundle: nil)
            if let vc = storyboard.instantiateViewController(withIdentifier: "QRUnlockJadePinInfoViewController") as? QRUnlockJadePinInfoViewController {
                navigationController?.pushViewController(vc, animated: true)
            }
        case .alreadyUnlocked:
            let storyboard = UIStoryboard(name: "QRUnlockFlow", bundle: nil)
            if let vc = storyboard.instantiateViewController(withIdentifier: "QRUnlockJadeViewController") as? QRUnlockJadeViewController {
                vc.vm = QRUnlockJadeViewModel(scope: .xpub, testnet: false)
                vc.delegate = self
                vc.forceUserhelp = true
                vc.modalPresentationStyle = .overFullScreen
                present(vc, animated: true)
            }
        case .cancel:
            break
        }
    }
}

extension JadeWaitViewController: QRUnlockJadeViewControllerDelegate {
    func signerFlow() {
    }

    func signPsbt(_ psbt: String) {
    }

    func login(credentials: gdk.Credentials) {
        if let account = AccountsRepository.shared.current {
            AccountNavigator.goLogged(account: account)
        }
    }

    func abort() {
        DropAlert().error(message: "id_operation_failure".localized)
    }
}
