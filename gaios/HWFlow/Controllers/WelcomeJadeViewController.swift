import UIKit

class WelcomeJadeViewController: HWFlowBaseViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var lblSlide1Title: UILabel!
    @IBOutlet weak var lblSlide1Hint: UILabel!
    @IBOutlet weak var lblSlide2Title: UILabel!
    @IBOutlet weak var lblSlide2Hint: UILabel!
    @IBOutlet weak var lblSlide3Title: UILabel!
    @IBOutlet weak var lblSlide3Hint: UILabel!

    @IBOutlet weak var btnConnectJade: UIButton!
    @IBOutlet weak var btnConnectOther: UIButton!
    @IBOutlet weak var btnCheckStore: UIButton!

    @IBOutlet weak var pageControl: UIPageControl!

    override func viewDidLoad() {
        super.viewDidLoad()

        mash.isHidden = true
        setContent()
        setStyle()
    }

    func setContent() {
        lblSlide1Title.text = "id_welcome_to_blockstream_jade".localized
        lblSlide1Hint.text = "id_jade_is_a_specialized_device".localized
        btnConnectJade.setTitle("id_connect_jade".localized, for: .normal)
        btnConnectOther.setTitle("id_connect_a_different_hardware".localized, for: .normal)
        btnCheckStore.setTitle( "id_dont_have_a_jade_check_our_store".localized, for: .normal)

        lblSlide2Title.text = "id_hardware_security".localized
        lblSlide2Hint.text = "id_your_bitcoin_and_liquid_assets".localized
        lblSlide3Title.text = "id_offline_key_storage".localized
        lblSlide3Hint.text = "id_jade_is_an_isolated_device_not".localized
    }

    func setStyle() {
        [lblSlide1Title, lblSlide2Title, lblSlide3Title].forEach {
            $0?.font = UIFont.systemFont(ofSize: 26.0, weight: .bold)
            $0?.textColor = .white
        }
        [lblSlide1Hint, lblSlide2Hint, lblSlide3Hint].forEach {
            $0?.font = UIFont.systemFont(ofSize: 14.0, weight: .regular)
            $0?.textColor = .white.withAlphaComponent(0.6)
        }
        btnConnectJade.setStyle(.primary)
        btnConnectOther.setStyle(.outlinedWhite)
        btnCheckStore.setStyle(.inline)
    }

    @IBAction func btnConnectJade(_ sender: Any) {
        let hwFlow = UIStoryboard(name: "HWFlow", bundle: nil)
        if let vc = hwFlow.instantiateViewController(withIdentifier: "JadeWaitViewController") as? JadeWaitViewController {
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    @IBAction func btnConnectOther(_ sender: Any) {
        let hwFlow = UIStoryboard(name: "HWFlow", bundle: nil)
        if let vc = hwFlow.instantiateViewController(withIdentifier: "LedgerWaitViewController") as? LedgerWaitViewController {
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    @IBAction func btnCheckStore(_ sender: Any) {
        SafeNavigationManager.shared.navigate( ExternalUrls.blockstreamStore )
    }
}

extension WelcomeJadeViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let pageIndex = round(scrollView.contentOffset.x/view.frame.width)
        pageControl.currentPage = Int(pageIndex)
    }
}
