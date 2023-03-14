import UIKit

class PinCreateViewController: HWFlowBaseViewController {

    @IBOutlet weak var imgDevice: UIImageView!

    @IBOutlet weak var lblStepNumber: UILabel!
    @IBOutlet weak var lblStepTitle: UILabel!
    @IBOutlet weak var lblStepHint: UILabel!
    @IBOutlet weak var infoBox: UIView!
    @IBOutlet weak var lblWarn: UILabel!

    @IBOutlet weak var btnRemember: UIButton!
    @IBOutlet weak var rememberView: UIView!
    @IBOutlet weak var lblRemember: UILabel!
    @IBOutlet weak var iconRemember: UIImageView!
    @IBOutlet weak var loaderPlaceholder: UIView!

    var remember = false

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
    }

    deinit {
        print("Deinit")
    }

    override func viewDidAppear(_ animated: Bool) {
        start()
    }

    override func viewWillDisappear(_ animated: Bool) {
        stop()
    }

    func setContent() {
        lblStepNumber.text = "SETUP YOUR JADE"
        lblStepTitle.text = "Create a PIN"
        lblStepHint.text = "Enter and confirm a unique PIN that will be entered to unlock Jade."
        lblWarn.text = "If you forget your PIN, you will need to restore with your recovery phrase"
        lblRemember.text = "id_remember_my_device".localized
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
        [infoBox].forEach {
            $0?.cornerRadius = 5.0
            $0?.borderWidth = 2.0
            $0?.borderColor = UIColor.gGrayCard()
        }
        [lblStepNumber].forEach {
            $0?.font = UIFont.systemFont(ofSize: 12.0, weight: .black)
            $0?.textColor = UIColor.gGreenMatrix()
        }
        [lblStepTitle].forEach {
            $0?.font = UIFont.systemFont(ofSize: 14.0, weight: .bold)
            $0?.textColor = .white
        }
        [lblStepHint, lblWarn].forEach {
            $0?.font = UIFont.systemFont(ofSize: 12.0, weight: .regular)
            $0?.textColor = .white.withAlphaComponent(0.6)
        }
        rememberView.borderWidth = 2.0
        rememberView.borderColor = .white
        rememberView.cornerRadius = 4.0
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

    @objc func setupBtnTapped() {
        let hwFlow = UIStoryboard(name: "HWFlow", bundle: nil)
        if let vc = hwFlow.instantiateViewController(withIdentifier: "SetupJadeViewController") as? SetupJadeViewController {
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    @IBAction func btnRemember(_ sender: Any) {
        remember.toggle()
        iconRemember.image = remember ? UIImage(named: "ic_checkbox_on") : UIImage(named: "ic_checkbox_off")
    }
}
