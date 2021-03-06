
import UIKit
import BinartOCLayout
import BinartOCStickerKeyboard

/// A powerful InputAccessoryView ideal for messaging applications
open class InputBarAccessoryView: UIView, UITextViewDelegate {
    
    // MARK: - Properties
    
    /// A delegate to broadcast notifications from the `InputBarAccessoryView`
    open weak var delegate: InputBarAccessoryViewDelegate?
    
    /// The background UIView anchored to the bottom, left, and right of the InputBarAccessoryView
    /// with a top anchor equal to the bottom of the top InputStackView
    open var backgroundView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 13, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }
        return view
    }()
    
    /// A content UIView that holds the left/right/bottom InputStackViews
    /// and the middleContentView. Anchored to the bottom of the
    /// topStackView and inset by the padding UIEdgeInsets
    open var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    /**
     A UIVisualEffectView that adds a blur effect to make the view appear transparent.
     
     ## Important Notes ##
     1. The blurView is initially not added to the backgroundView to improve performance when not needed. When `isTranslucent` is set to TRUE for the first time the blurView is added and anchored to the `backgroundView`s edge anchors
    */
    open lazy var blurView: UIVisualEffectView = {
        var blurEffect = UIBlurEffect(style: .light)
        if #available(iOS 13, *) {
            blurEffect = UIBlurEffect(style: .systemMaterial)
        }
        let view = UIVisualEffectView(effect: blurEffect)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    /// Determines if the InputBarAccessoryView should have a translucent effect
    open var isTranslucent: Bool = false {
        didSet {
            if isTranslucent && blurView.superview == nil {
                backgroundView.addSubview(blurView)
                blurView.fillSuperview()
            }
            blurView.isHidden = !isTranslucent
            let color: UIColor = backgroundView.backgroundColor ?? .white
            backgroundView.backgroundColor = isTranslucent ? color.withAlphaComponent(0.75) : color
        }
    }

    /// A SeparatorLine that is anchored at the top of the InputBarAccessoryView
    public let separatorLine = SeparatorLine()
    
    /// The stack view position in the InputBarItemPosition
    public enum StackItemPosition {
        case left, right, bottom, top
    }
    
    /**
     The InputStackView at the InputStackView.top position
     
     ## Important Notes ##
     1. It's axis is initially set to .vertical
     2. It's alignment is initially set to .fill
     
     contentView 外面
     */
//    public let topStackView: BAStackView = {
//        let stackView = BAStackView() //InputStackView(axis: .vertical, spacing: 0)
//        stackView.axis = BALayoutAxisVertical
//        stackView.translatesAutoresizingMaskIntoConstraints = false
////        stackView.alignment = .fill
//        stackView.whc_Height(0)
//        return stackView
//    }()
    
    /**
     The InputStackView at the InputStackView.left position
     
     ## Important Notes ##
     1. It's axis is initially set to .horizontal
     */
    public let leftStackView: BAStackView = {
        let stackView = BAStackView() //InputStackView(axis: .horizontal, spacing: 0)
        stackView.flex.direction = BADirectionRow // 水平为主轴，且从左往右排列，纵轴为交叉轴
        stackView.flex.align = BAAlignItemsEnd // 交叉轴从下而上排列
        stackView.arrangedSubviewHeight = 33
        
        stackView.padding.bottom = 0
        stackView.horizontalSpacing = 0
        stackView.verticalSpacing = 0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        return stackView
    }()
    
    /**
     The InputStackView at the InputStackView.right position
     
     ## Important Notes ##
     1. It's axis is initially set to .horizontal
     */
    public let rightStackView: BAStackView = {
        let stackView = BAStackView() //InputStackView(axis: .horizontal, spacing: 0)
        stackView.flex.direction = BADirectionRow
        stackView.flex.align = BAAlignItemsEnd // 交叉轴从下而上排列
        stackView.arrangedSubviewHeight = 33
        
        stackView.padding.bottom = 0
        stackView.verticalSpacing = 0
        stackView.horizontalSpacing = 0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    /**
     底部StackView
     */
    public let bottomStackView: BAStackView = {
       let stackView = BAStackView()
        stackView.flex.direction = BADirectionRow
        stackView.flex.align = BAAlignItemsStart
        stackView.flex.wrap = BAWrapWrap
        
        stackView.columns = 4
        stackView.padding = UIEdgeInsets(top: 20, left: 12, bottom: 12, right: 12)
        stackView.verticalSpacing = 0
        stackView.horizontalSpacing = 28
        stackView.arrangedSubviewHeight = 50
        stackView.arrangedSubviewWidth = 50
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    /**
     The main view component of the InputBarAccessoryView

     The default value is the `InputTextView`.

     ## Important Notes ##
     1. This view should self-size with constraints or an
        intrinsicContentSize to auto-size the InputBarAccessoryView
     2. Override with `setMiddleContentView(view: UIView?, animated: Bool)`
     */
    public private(set) weak var middleContentView: UIView?

    /// A view to wrap the `middleContentView` inside
    private let middleContentViewWrapper: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    /// 文本输入视图
//    open lazy var inputTextView: InputTextView = {
//        let inputTextView = InputTextView()
//        inputTextView.translatesAutoresizingMaskIntoConstraints = false
//        inputTextView.inputBarAccessoryView = self
//        // UIReturnKeySearch
//        // UIReturnKeyJoin
//        // UIReturnKeyNext
//        // UIReturnKeyDone
//        // UIReturnKeySend
//        inputTextView.returnKeyType = .send
//        inputTextView.enablesReturnKeyAutomatically = true // 输入框没有输入的时候，发送按钮是置灰的
//        inputTextView.keyboardType = .default
//        inputTextView.delegate = self
//
//
//
//        return inputTextView
//    }()
    
    open lazy var inputHelper: BAInputHelper = {
        let inputHelper = BAInputHelper.withInputView(self, delegate: self)
        
        inputHelper.inputModeDelegate = self
        
        // 设置文本输入视图点击事件
        let click = UITapGestureRecognizer.init(target: self, action: #selector(onInputTextViewClicked))
        inputHelper.textView.addGestureRecognizer(click)
        
        return inputHelper
    }()

    /// 水平边缘内边距
    open var frameInsets: HorizontalEdgePadding = .zero {
        didSet {
//            updateFrameInsets()
        }
    }
    
    /**
     The anchor constants used by the InputStackView's and InputTextView to create padding
     within the InputBarAccessoryView
     
     ## Important Notes ##
     
     ````
     V:|...[InputStackView.top]-(padding.top)-[contentView]-(padding.bottom)-|
     
     H:|-(frameInsets.left)-(padding.left)-[contentView]-(padding.right)-(frameInsets.right)-|
     ````
     
     */
    open var padding: UIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0) {
        didSet {
            updatePadding()
        }
    }
    
    /**
     The anchor constants used by the top InputStackView
     
     ## Important Notes ##
     1. The topStackViewPadding.bottom property is not used. Use padding.top
     
     ````
     V:|-(topStackViewPadding.top)-[InputStackView.top]-(padding.top)-[middleContentView]-...|
     
     H:|-(frameInsets.left)-(topStackViewPadding.left)-[InputStackView.top]-(topStackViewPadding.right)-(frameInsets.right)-|
     ````
     
     */
    open var topStackViewPadding: UIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0) {
        didSet {
            updateTopStackViewPadding()
        }
    }
    
    /**
     The anchor constants used by the middleContentView
     
     ````
     V:|...-(padding.top)-(middleContentViewPadding.top)-[middleContentView]-(middleContentViewPadding.bottom)-[InputStackView.bottom]-...|
     
     H:|...-[InputStackView.left]-(middleContentViewPadding.left)-[middleContentView]-(middleContentViewPadding.right)-[InputStackView.right]-...|
     ````
     
     */
    open var middleContentViewPadding: UIEdgeInsets = UIEdgeInsets(top: 10, left: 4, bottom: 10, right: 4) {
        didSet {
            updateMiddleContentViewPadding()
        }
    }
    
    /// Returns the most recent size calculated by `calculateIntrinsicContentSize()`
    open override var intrinsicContentSize: CGSize {
        return cachedIntrinsicContentSize
    }
    
    /// The intrinsicContentSize can change a lot so the delegate method
    /// `inputBar(self, didChangeIntrinsicContentTo: size)` only needs to be called
    /// when it's different
    public private(set) var previousIntrinsicContentSize: CGSize?
    
    /// The most recent calculation of the intrinsicContentSize
    private lazy var cachedIntrinsicContentSize: CGSize = calculateIntrinsicContentSize()
    
    /// A boolean that indicates if the maxTextViewHeight has been met. Keeping track of this
    /// improves the performance
    public private(set) var isOverMaxTextViewHeight = false
    
    /// A boolean that when set as `TRUE` will always enable the `InputTextView` to be anchored to the
    /// height of `maxTextViewHeight`
    /// The default value is `FALSE`
    public private(set) var shouldForceTextViewMaxHeight = false
    
    /// A boolean that determines if the `maxTextViewHeight` should be maintained automatically.
    /// To control the maximum height of the view yourself, set this to `false`.
    open var shouldAutoUpdateMaxTextViewHeight = true

    /// The maximum height that the InputTextView can reach.
    /// This is set automatically when `shouldAutoUpdateMaxTextViewHeight` is true.
    /// To control the height yourself, make sure to set `shouldAutoUpdateMaxTextViewHeight` to false.
    open var maxTextViewHeight: CGFloat = 0 {
        didSet {
            textViewHeightAnchor?.constant = maxTextViewHeight
        }
    }
    
    /// A boolean that determines whether the sendButton's `isEnabled` state should be managed automatically.
    open var shouldManageSendButtonEnabledState = true
    
    /// The height that will fit the current text in the InputTextView based on its current bounds
    public var requiredInputTextViewHeight: CGFloat {
        guard middleContentView == inputHelper.textView else {
            return middleContentView?.intrinsicContentSize.height ?? 0
        }
        
        let maxTextViewSize = CGSize(width: inputHelper.textView.bounds.width, height: .greatestFiniteMagnitude)
        return inputHelper.textView.sizeThatFits(maxTextViewSize).height.rounded(.down)
    }
    
    /// The fixed widthAnchor constant of the leftStackView
    public private(set) var leftStackViewWidthConstant: CGFloat = 0 {
        didSet {
            leftStackView.whc_Width(leftStackViewWidthConstant)
//            leftStackViewLayoutSet?.width?.constant = leftStackViewWidthConstant
        }
    }
    
    /// The fixed widthAnchor constant of the rightStackView
    public private(set) var rightStackViewWidthConstant: CGFloat = 0 {
        didSet {
            rightStackView.whc_Width(rightStackViewWidthConstant)
        
//            rightStackViewLayoutSet?.width?.constant = rightStackViewWidthConstant
        }
    }
    
    /// Holds the InputPlugin plugins that can be used to extend the functionality of the InputBarAccessoryView
    open var inputPlugins = [InputPlugin]()

    /// The InputBarItems held in the leftStackView
    public private(set) var leftStackViewItems: [InputItem] = []
    
    /// The InputBarItems held in the rightStackView
    public private(set) var rightStackViewItems: [InputItem] = []
    
    /// The InputBarItems held in the bottomStackView
    public private(set) var bottomStackViewItems: [InputItem] = []
    
    /// The InputBarItems held in the topStackView
    public private(set) var topStackViewItems: [InputItem] = []
    
    /// The InputBarItems held to make use of their hooks but they are not automatically added to a UIStackView
    open var nonStackViewItems: [InputItem] = []
    
    /// Returns a flatMap of all the items in each of the UIStackViews
    public var items: [InputItem] {
        return [leftStackViewItems, rightStackViewItems, bottomStackViewItems, topStackViewItems, nonStackViewItems].flatMap { $0 }
    }

    // MARK: - Auto-Layout Constraint Sets
    
    private var middleContentViewLayoutSet: NSLayoutConstraintSet?
    private var textViewHeightAnchor: NSLayoutConstraint?
    private var topStackViewLayoutSet: NSLayoutConstraintSet?
    private var leftStackViewLayoutSet: NSLayoutConstraintSet?
    private var rightStackViewLayoutSet: NSLayoutConstraintSet?
//    private var bottomStackViewLayoutSet: NSLayoutConstraintSet?
    private var contentViewLayoutSet: NSLayoutConstraintSet?
    private var windowAnchor: NSLayoutConstraint?
    private var backgroundViewLayoutSet: NSLayoutConstraintSet?
    
    // MARK: - Initialization
    
    public convenience init() {
        self.init(frame: .zero)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    open override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        guard newSuperview != nil else {
//            deactivateConstraints()
            return
        }
//        activateConstraints()
    }

    open override func didMoveToWindow() {
        super.didMoveToWindow()
        setupConstraints(to: window)
    }
    
    // MARK: - Setup
    
    /// Sets up the default properties
    open func setup() {

        backgroundColor = .white
        autoresizingMask = [.flexibleHeight]
        setupSubviews()
        setupConstraints()
        setupObservers()
        setupGestureRecognizers()
    }
    
    /// Adds the required notification observers
    private func setupObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(InputBarAccessoryView.orientationDidChange),
                                               name: UIDevice.orientationDidChangeNotification, object: nil)
//        NotificationCenter.default.addObserver(self,
//                                               selector: #selector(InputBarAccessoryView.inputTextViewDidChange),
//                                               name: UITextView.textDidChangeNotification, object: inputTextView)
//        NotificationCenter.default.addObserver(self,
//                                               selector: #selector(InputBarAccessoryView.inputTextViewDidBeginEditing),
//                                               name: UITextView.textDidBeginEditingNotification, object: inputTextView)
//        NotificationCenter.default.addObserver(self,
//                                               selector: #selector(InputBarAccessoryView.inputTextViewDidEndEditing),
//                                               name: UITextView.textDidEndEditingNotification, object: inputTextView)
    }
    
    /// Adds a UISwipeGestureRecognizer for each direction to the InputTextView
    private func setupGestureRecognizers() {
//        let directions: [UISwipeGestureRecognizer.Direction] = [.left, .right]
//        for direction in directions {
//            let gesture = UISwipeGestureRecognizer(target: self,
//                                                   action: #selector(InputBarAccessoryView.didSwipeTextView(_:)))
//            gesture.direction = direction
//            inputTextView.addGestureRecognizer(gesture)
//        }
    }
    
    /// Adds all of the subviews
    private func setupSubviews() {
        
        addSubview(backgroundView)
//        addSubview(topStackView)
        addSubview(contentView)
        addSubview(separatorLine)
        contentView.addSubview(middleContentViewWrapper)
        contentView.addSubview(leftStackView)
        contentView.addSubview(rightStackView)
        contentView.addSubview(bottomStackView)
        
        // separatorLine
        // backgroundView
        // topStackView
        // contentView
            // contentView -> middleContentViewWrapper -> inputTextView
            // contentView -> leftStackView
            // contentView -> rightStackView
            // contentView -> bottomStackView
        
        // middleContentViewWrapper 左侧以 leftStackView为主
        // middleContentViewWrapper 右侧以 rightStackView为主
        // middleContentViewWrapper 上侧以 superview 为主
        // middleContentViewWrapper 下侧以 bottomStackView 为主
        
        middleContentViewWrapper.addSubview(inputHelper.textView) // inputTextView fill middleContentViewWrapper
        middleContentView = inputHelper.textView
    }
    
    /// Sets up the initial constraints of each subview
    private func setupConstraints() {
        
        // The constraints within the InputBarAccessoryView
        separatorLine.whc_TopSpace(0)
        separatorLine.whc_LeftSpace(0)
        separatorLine.whc_RightSpace(0)
        separatorLine.whc_Height(separatorLine.height)

        backgroundView.whc_TopSpace(0)
        backgroundView.whc_BottomSpace(0)
        backgroundView.whc_LeftSpace(0)
        backgroundView.whc_RightSpace(0)

        
        contentView.whc_TopSpace(padding.top)
        contentView.whc_BottomSpace(-padding.bottom)
        contentView.whc_LeftSpace(padding.left)
        contentView.whc_RightSpace(padding.right)

        // Constraints Within the contentView
        middleContentViewWrapper.whc_TopSpace(middleContentViewPadding.top)
        middleContentViewWrapper.whc_LeftSpace(middleContentViewPadding.left, toView: leftStackView)
        middleContentViewWrapper.whc_RightSpace(middleContentViewPadding.right, toView: rightStackView)
        middleContentViewWrapper.whc_BottomSpace(-middleContentViewPadding.bottom, toView: bottomStackView)
        
        inputHelper.textView.fillSuperview()
        maxTextViewHeight = calculateMaxTextViewHeight()
//        textViewHeightAnchor = inputTextView.heightAnchor.constraint(equalToConstant: maxTextViewHeight)
        
        leftStackView.whc_TopSpace(0)
        leftStackView.whc_LeftSpace(0)
        leftStackView.whc_Width(leftStackViewWidthConstant)
        leftStackView.whc_BottomSpaceEqualView(middleContentViewWrapper)
        
        rightStackView.whc_TopSpace(0)
        rightStackView.whc_RightSpace(0)
        rightStackView.whc_Width(rightStackViewWidthConstant)
        rightStackView.whc_BottomSpaceEqualView(middleContentViewWrapper)
        
        //
        bottomStackView.whc_Height(0)
        bottomStackView.whc_BottomSpace(0)
        bottomStackView.whc_LeftSpace(0)
        bottomStackView.whc_RightSpace(0)
    }
    
    /// Respect window safeAreaInsets
    /// Adds a constraint to anchor the bottomAnchor of the contentView to the window's safeAreaLayoutGuide.bottomAnchor
    ///
    /// - Parameter window: The window to anchor to
    private func setupConstraints(to window: UIWindow?) {
        guard let window = window, window.safeAreaInsets.bottom > 0 else { return }
        windowAnchor?.isActive = false
        windowAnchor = contentView.bottomAnchor.constraint(lessThanOrEqualToSystemSpacingBelow: window.safeAreaLayoutGuide.bottomAnchor, multiplier: 1)
        windowAnchor?.constant = -padding.bottom
        windowAnchor?.priority = UILayoutPriority(rawValue: 750)
        windowAnchor?.isActive = true
        backgroundViewLayoutSet?.bottom?.constant = window.safeAreaInsets.bottom
    }
    
    // MARK: - Constraint Layout Updates

    private func updateFrameInsets() {
        backgroundViewLayoutSet?.left?.constant = frameInsets.left
        backgroundViewLayoutSet?.right?.constant = -frameInsets.right
        updatePadding()
        updateTopStackViewPadding()
    }
    
    /// Updates the constraint constants that correspond to the padding UIEdgeInsets
    private func updatePadding() {
        topStackViewLayoutSet?.bottom?.constant = -padding.top
        contentViewLayoutSet?.top?.constant = padding.top
        contentViewLayoutSet?.left?.constant = padding.left + frameInsets.left
        contentViewLayoutSet?.right?.constant = -(padding.right + frameInsets.right)
        contentViewLayoutSet?.bottom?.constant = -padding.bottom
        windowAnchor?.constant = -padding.bottom
    }
    
    /// Updates the constraint constants that correspond to the middleContentViewPadding UIEdgeInsets
    private func updateMiddleContentViewPadding() {
        middleContentViewLayoutSet?.top?.constant = middleContentViewPadding.top
        middleContentViewLayoutSet?.left?.constant = middleContentViewPadding.left
        middleContentViewLayoutSet?.right?.constant = -middleContentViewPadding.right
        middleContentViewLayoutSet?.bottom?.constant = -middleContentViewPadding.bottom
//        bottomStackViewLayoutSet?.top?.constant = middleContentViewPadding.bottom
    }
    
    /// Updates the constraint constants that correspond to the topStackViewPadding UIEdgeInsets
    private func updateTopStackViewPadding() {
        topStackViewLayoutSet?.top?.constant = topStackViewPadding.top
        topStackViewLayoutSet?.left?.constant = topStackViewPadding.left + frameInsets.left
        topStackViewLayoutSet?.right?.constant = -(topStackViewPadding.right + frameInsets.right)
    }

    /// Invalidates the view’s intrinsic content size
    open override func invalidateIntrinsicContentSize() {
        super.invalidateIntrinsicContentSize()
        cachedIntrinsicContentSize = calculateIntrinsicContentSize()
        if previousIntrinsicContentSize != cachedIntrinsicContentSize {
            delegate?.inputBar(self, didChangeIntrinsicContentTo: cachedIntrinsicContentSize)
            previousIntrinsicContentSize = cachedIntrinsicContentSize
        }
    }
    
    /// Calculates the correct intrinsicContentSize of the InputBarAccessoryView
    ///
    /// - Returns: The required intrinsicContentSize
    open func calculateIntrinsicContentSize() -> CGSize {
        
        var inputTextViewHeight = requiredInputTextViewHeight
        if inputTextViewHeight >= maxTextViewHeight {
            if !isOverMaxTextViewHeight {
                textViewHeightAnchor?.isActive = true
                inputHelper.textView.isScrollEnabled = true
                isOverMaxTextViewHeight = true
            }
            inputTextViewHeight = maxTextViewHeight
        } else {
            if isOverMaxTextViewHeight {
                textViewHeightAnchor?.isActive = false || shouldForceTextViewMaxHeight
                inputHelper.textView.isScrollEnabled = false
                isOverMaxTextViewHeight = false
                inputHelper.textView.invalidateIntrinsicContentSize()
            }
        }
        
        // Calculate the required height
        let totalPadding = padding.top + padding.bottom + topStackViewPadding.top + middleContentViewPadding.top + middleContentViewPadding.bottom
        
        // FIXME: Still worked??????
        let topStackViewHeight: CGFloat = 0
        let bottomStackViewHeight: CGFloat = bottomStackView.arrangedSubviewCount > 0 ? bottomStackView.whc_h : 0
//        let bottomStackViewHeight: CGFloat = bottomStackView.subviews.count > 0 ? bottomStackView.whc_h : 0
        let verticalStackViewHeight = topStackViewHeight + bottomStackViewHeight
        let requiredHeight = inputTextViewHeight + totalPadding + verticalStackViewHeight
        return CGSize(width: UIView.noIntrinsicMetric, height: requiredHeight)
    }

    open override func layoutIfNeeded() {
        super.layoutIfNeeded()
        
        inputHelper.textView.layoutIfNeeded()
    }

    open override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard frameInsets.left != 0 || frameInsets.right != 0 else {
            return super.point(inside: point, with: event)
        }
        // Allow touches to pass through base view
        return subviews.contains {
            !$0.isHidden && $0.point(inside: convert(point, to: $0), with: event)
        }
    }
    
    /// Returns the max height the InputTextView can grow to based on the UIScreen
    ///
    /// - Returns: Max Height
    open func calculateMaxTextViewHeight() -> CGFloat {
        if traitCollection.verticalSizeClass == .regular {
            return (UIScreen.main.bounds.height / 3).rounded(.down)
        }
        return (UIScreen.main.bounds.height / 5).rounded(.down)
    }
    
    // MARK: - Layout Helper Methods
    
    /// Layout the given InputStackView's
    ///
    /// - Parameter positions: The InputStackView's to layout
    public func layoutStackViews(_ positions: [StackItemPosition] = [.left, .right, .bottom, .top]) {
        
        guard superview != nil else { return }
        for position in positions {
            switch position {
            case .left:
                leftStackView.setNeedsLayout()
                leftStackView.layoutIfNeeded()
            case .right:
                rightStackView.setNeedsLayout()
                rightStackView.layoutIfNeeded()
            case .bottom:
                bottomStackView.setNeedsLayout()
                bottomStackView.layoutIfNeeded()
            case .top:
                break
//                topStackView.setNeedsLayout()
//                topStackView.layoutIfNeeded()
            }
        }
    }
    
    /// Performs a layout over the main thread
    ///
    /// - Parameters:
    ///   - animated: If the layout should be animated
    ///   - animations: Animation logic
    internal func performLayout(_ animated: Bool, _ animations: @escaping () -> Void) {
        if animated {
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.3, animations: animations)
            }
        } else {
            UIView.performWithoutAnimation { animations() }
        }
    }

    /// Removes the current `middleContentView` and assigns a new one.
    ///
    /// WARNING: This will remove the `InputTextView`
    ///
    /// - Parameters:
    ///   - view: New view
    ///   - animated: If the layout should be animated
    open func setMiddleContentView(_ view: UIView?, animated: Bool) {
        middleContentView?.removeFromSuperview()
        middleContentView = view
        guard let view = view else { return }
        middleContentViewWrapper.addSubview(view)
        view.fillSuperview()

        performLayout(animated) { [weak self] in
            guard self?.superview != nil else { return }
            self?.middleContentViewWrapper.layoutIfNeeded()
            self?.invalidateIntrinsicContentSize()
        }
    }
    
    /// Removes all of the arranged subviews from the InputStackView and adds the given items.
    /// Sets the inputBarAccessoryView property of the InputBarButtonItem
    ///
    /// Note: If you call `animated = true`, the `items` property of the stack view items will not be updated until the 
    /// views are done being animated. If you perform a check for the items after they're set, setting animated to `false`
    /// will apply the body of the closure immediately.
    ///
    /// The send button is attached to `rightStackView` so remember to remove it if you're setting it to a different
    /// stack.
    ///
    /// - Parameters:
    ///   - items: New InputStackView arranged views
    ///   - position: The targeted InputStackView
    ///   - animated: If the layout should be animated
    open func setStackViewItems(_ items: [InputItem], forStack position: StackItemPosition, animated: Bool) {
        
        func setNewItems() {
            switch position {
            case .left:
                leftStackView.subviews.forEach { $0.removeFromSuperview() }
                leftStackViewItems = items
                leftStackViewItems.forEach {
                    $0.inputBarAccessoryView = self
                    $0.parentStackViewPosition = position
                    if let view = $0 as? UIView {
                        leftStackView.addSubview(view)
                    }
                }
                
//                leftStackView.whc_AutoWidth(44, top: 10, right: 10, height: 84)
                leftStackView.layoutMe()
                
                guard superview != nil else { return }
                
                leftStackView.layoutIfNeeded()

            case .right:
                rightStackView.subviews.forEach { $0.removeFromSuperview() }
                rightStackViewItems = items
                rightStackViewItems.forEach {
                    $0.inputBarAccessoryView = self
                    $0.parentStackViewPosition = position
                    if let view = $0 as? UIView {
                        rightStackView.addSubview(view)
                    }
                }
                
                rightStackView.layoutMe()
                
                guard superview != nil else { return }
            
                rightStackView.layoutIfNeeded()
            case .bottom:
                bottomStackView.subviews.forEach { $0.removeFromSuperview() }
                bottomStackViewItems = items
                bottomStackViewItems.forEach {
                    $0.inputBarAccessoryView = self
                    $0.parentStackViewPosition = position
                    if let view = $0 as? UIView {
                        bottomStackView.addSubview(view)
                    }
                }
                
                
                bottomStackView.autoHeight()
//                bottomStackView.whc_Height(CGFloat(bottomStackView.subviews.count * 50))
                
                bottomStackView.layoutMe()
                
                guard superview != nil else { return }
                
                bottomStackView.layoutIfNeeded()
                
//                inputTextView.resignFirstResponder()
//                inputTextView.isEditable = false
//                inputTextView.inputView = bottomStackView
//                inputTextView.becomeFirstResponder()
                
            case .top:
//                topStackView.subviews.forEach { $0.removeFromSuperview() }
//                topStackViewItems = items
//                topStackViewItems.forEach {
//                    $0.inputBarAccessoryView = self
//                    $0.parentStackViewPosition = position
//                    if let view = $0 as? UIView {
//                        topStackView.addSubview(view)
//                    }
//                }
//
////                topStackView.whc_AutoWidth(0, top: 10, right: 10, height: 0)
//                topStackView.layoutMe()
//
                guard superview != nil else { return }
//
//                topStackView.layoutIfNeeded()
            }
            invalidateIntrinsicContentSize()
        }
        
        performLayout(animated) {
            setNewItems()
        }
    }
    
    /// 设置输入面板
    open func setInputBoardView (view: UIView?) {
        
        if let view = view {
            inputHelper.textView.resignFirstResponder()
            inputHelper.textView.isEditable = false
            inputHelper.textView.inputView = view
            
            // 只是为了拉起键盘，使inputView生效；同时将inputTextView设置为不可编辑
            // @bugreport 如果对inputView的设置和becomeFirstResponder在一次UI操作的commit中，会出现输入框先跳到两个叠加高度，然后回到预期位置
//            inputTextView.becomeFirstResponder()
            
            // @bugfix 跳1个runloop帧
            inputHelper.textView.perform(#selector(becomeFirstResponder), with: nil, afterDelay: 0.017)
            
            // 更好的方案, 用它的话，isEditable要始终为true，且自己控制游标
//            inputTextView.reloadInputViews()
            
            if UIDevice.isFullScreen {
                delBottomSpacingForSafeArea()
            }
            
        } else {
//            inputTextView.resignFirstResponder()
            
            // FIXME: 这里的处理，不能和微信媲美，需要继续优化！！！！！
//            let view = inputTextView.inputView
            
            inputHelper.textView.perform(#selector(resignFirstResponder), with: nil, afterDelay: 0.017)
//            UIView.animate(withDuration: 0.16) {
////                view?.frame = CGRect(origin: view?.frame.origin, size: CGSize(width: view?.frame.width, height: 0))
//                view?.transform = CGAffineTransform(scaleX: 1, y: 0)
//                view?.alpha = 0
//            } completion: { (complete) in
//                self.inputTextView.inputView = nil
//            }

            inputHelper.textView.inputView = nil;
//            inputTextView.reloadInputViews()
            
            if UIDevice.isFullScreen {
                addBottomSpacingForSafeArea()
            }
            
        }
    }
    
    func addBottomSpacingForSafeArea () {
        // 利用bottomView做安全区域适配
        
        bottomStackView.columns = 1
        bottomStackView.padding = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        bottomStackView.verticalSpacing = 0
        bottomStackView.horizontalSpacing = 0
        bottomStackView.arrangedSubviewHeight = UIDevice.kBottomSafeHeight
        bottomStackView.arrangedSubviewWidth = 0
        
        // 试一试，理论上应该在特定状态才显示
        setStackViewItems([InputBarButtonItem()], forStack: .bottom, animated: false)
    }
    
    func delBottomSpacingForSafeArea () {
        setStackViewItems([], forStack: .bottom, animated: false)
    }
    
    @objc func onInputTextViewClicked (_ tap: UITapGestureRecognizer) {
        if inputHelper.textView.isFirstResponder && inputHelper.textView.isEditable {
            return
        }
        
        setInputBoardView(view: nil)

        // Enable editing
        inputHelper.textView.isEditable = true
        inputHelper.textView.perform(#selector(becomeFirstResponder), with: nil, afterDelay: 0.017)
    }
    
    func setInputAccessoryView () {
        
    }
    
    /// Sets the leftStackViewWidthConstant
    ///
    /// - Parameters:
    ///   - newValue: New widthAnchor constant
    ///   - animated: If the layout should be animated
    open func setLeftStackViewWidthConstant(to newValue: CGFloat, animated: Bool) {
        performLayout(animated) { 
            self.leftStackViewWidthConstant = newValue
            self.layoutStackViews([.left])
            guard self.superview?.superview != nil else { return }
            self.superview?.superview?.layoutIfNeeded()
        }
    }
    
    /// Sets the rightStackViewWidthConstant
    ///
    /// - Parameters:
    ///   - newValue: New widthAnchor constant
    ///   - animated: If the layout should be animated
    open func setRightStackViewWidthConstant(to newValue: CGFloat, animated: Bool) {
        performLayout(animated) { 
            self.rightStackViewWidthConstant = newValue
            self.layoutStackViews([.right])
            guard self.superview?.superview != nil else { return }
            self.superview?.superview?.layoutIfNeeded()
        }
    }
    
    // MARK: - Notifications/Hooks
    
    /// Invalidates the intrinsicContentSize
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.verticalSizeClass != previousTraitCollection?.verticalSizeClass || traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass {
            if shouldAutoUpdateMaxTextViewHeight {
                maxTextViewHeight = calculateMaxTextViewHeight()
            } else {
                invalidateIntrinsicContentSize()
            }
        }
    }
    
    /// Invalidates the intrinsicContentSize
    @objc
    open func orientationDidChange() {
        if shouldAutoUpdateMaxTextViewHeight {
            maxTextViewHeight = calculateMaxTextViewHeight()
        }
        invalidateIntrinsicContentSize()
    }

    /// Enables/Disables the sendButton based on the InputTextView's text being empty
    /// Calls each items `textViewDidChangeAction` method
    /// Calls the delegates `textViewTextDidChangeTo` method
    /// Invalidates the intrinsicContentSize
//    @objc
//    open func inputTextViewDidChange() {
//
//        let trimmedText = inputTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
//
//        if shouldManageSendButtonEnabledState {
//            var isEnabled = !trimmedText.isEmpty
//            if !isEnabled {
//                // The images property is more resource intensive so only use it if needed
//                isEnabled = inputTextView.images.count > 0
//            }
////            sendButton.isEnabled = isEnabled
//        }
//
//        // Capture change before iterating over the InputItem's
//        let shouldInvalidateIntrinsicContentSize = requiredInputTextViewHeight != inputTextView.bounds.height
//
//        items.forEach { $0.textViewDidChangeAction(with: self.inputTextView) }
//        delegate?.inputBar(self, textViewTextDidChangeTo: trimmedText)
//
//        if shouldInvalidateIntrinsicContentSize {
//            // Prevent un-needed content size invalidation
//            invalidateIntrinsicContentSize()
//        }
//    }
    
    /// Calls each items `keyboardEditingBeginsAction` method
//    @objc
//    open func inputTextViewDidBeginEditing() {
//        items.forEach { $0.keyboardEditingBeginsAction() }
//
//
//        delegate?.inputBar(self, textViewBeginEditing: "")
//    }
    
    /// Calls each items `keyboardEditingEndsAction` method
//    @objc
//    open func inputTextViewDidEndEditing() {
//        items.forEach { $0.keyboardEditingEndsAction() }
//    }
    
    // MARK: = UITextViewDelegate
        
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
//        textView.attributedText
        
        if (text.elementsEqual("\n")) {
            
            if (textView.text != nil && textView.text.count > 0) {
                // 发送！！！
//                didSelectSendButton()
            }
            
            return false
        }
        
        // true here
        delegate?.inputBar(self, didChangeTextIn: range, toText: text)
        
        return true
    }
    
    // MARK: - Plugins
    
    /// Reloads each of the plugins
    open func reloadPlugins() {
        inputPlugins.forEach { $0.reloadData() }
    }
    
    /// Invalidates each of the plugins
    open func invalidatePlugins() {
        inputPlugins.forEach { $0.invalidate() }
    }
    
    
    
    // MARK: - User Actions
    
    /// Calls each items `keyboardSwipeGestureAction` method
    /// Calls the delegates `didSwipeTextViewWith` method
    @objc
    open func didSwipeTextView(_ gesture: UISwipeGestureRecognizer) {
        items.forEach { $0.keyboardSwipeGestureAction(with: gesture) }
        delegate?.inputBar(self, didSwipeTextViewWith: gesture)
    }
    
    /// Calls the delegates `didPressSendButtonWith` method
    /// Assumes that the InputTextView's text has been set to empty and calls `inputTextViewDidChange()`
    /// Invalidates each of the InputPlugins
//    open func didSelectSendButton() {
//        delegate?.inputBar(self, didPressSendButtonWith: inputTextView.text)
//
//        inputTextView.text = String()
//
//        inputTextView.resignFirstResponder()
//    }
}

// MARK: - BAInputHelperDelegate

extension InputBarAccessoryView: BAInputHelperDelegate {
    public func onInputDidChange(_ inputHelper: BAInputHelper) {

        let trimmedText = inputHelper.plainText.trimmingCharacters(in: .whitespacesAndNewlines)

//        if shouldManageSendButtonEnabledState {
//            var isEnabled = !trimmedText.isEmpty
//            if !isEnabled {
//                // The images property is more resource intensive so only use it if needed
//                isEnabled = inputTextView.images.count > 0
//            }
////            sendButton.isEnabled = isEnabled
//        }

        // Capture change before iterating over the InputItem's
        let shouldInvalidateIntrinsicContentSize = requiredInputTextViewHeight != inputHelper.textView.bounds.height

//        items.forEach { $0.textViewDidChangeAction(with: inputHelper.textView) }
        
        delegate?.inputBar(self, textViewTextDidChangeTo: trimmedText)

        if shouldInvalidateIntrinsicContentSize {
            // Prevent un-needed content size invalidation
            invalidateIntrinsicContentSize()
        }
        
        delegate?.inputBar(self, textViewTextDidChangeTo: inputHelper.plainText)
    }
    
    public func onInputDidEndEditing(_ inputHelper: BAInputHelper) {
        items.forEach { $0.keyboardEditingEndsAction() }
    }
    
    public func onInput(_ inputHelper: BAInputHelper, sendText text: String) {
        delegate?.inputBar(self, didPressSendButtonWith: text)
    }
    
    public func onInput(_ inputHelper: BAInputHelper, send sticker: BASticker) {
        delegate?.inputBar(self, didPressSend: sticker)
    }

    public func onInputShouldBeginEditing(_ inputHelper: BAInputHelper) -> Bool {
        return true;
    }
    
    public func onInput(_ helper: BAInputHelper, didBeginEditing textView: UITextView) {
        delegate?.inputBar(self, textViewBeginEditing: "")
    }
    
    public func onInput(_ helper: BAInputHelper, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        return true;
    }
}

// MARK: - BAInputModeDelegate

extension InputBarAccessoryView: BAInputModeDelegate {
    public func inputModeSwitch(to type: PPKeyboardType) {
        if type == .none {
            
        } else if type == .system {
            setInputBoardView(view: nil)
            
            // Enable editing
            inputHelper.textView.isEditable = true
            inputHelper.textView.perform(#selector(becomeFirstResponder), with: nil, afterDelay: 0.017)
        } else if type == .sticker {
            
        }
        
//        switch type {
//        case PPKeyboardTypeNone:
//
//            break;
//        case PPKeyboardTypeSystem:
//            break;
//
//        case PPKeyboardTypeSticker:
//            break;
//        default:
//            break;
//        }
        
        
//        switch (type) {
//                case PPKeyboardTypeNone:
//                    [self.emojiToggleButton setImage:BAInputConfig.shared.toggleEmoji forState:UIControlStateNormal];
//        //            self.textView.inputView = nil;
//                    break;
//                case PPKeyboardTypeSystem:
//                    [self.emojiToggleButton setImage:BAInputConfig.shared.toggleEmoji forState:UIControlStateNormal];
//        //            self.textView.inputView = nil;                          // 切换到系统键盘
//        //            [self.textView reloadInputViews];                       // 调用reloadInputViews方法会立刻进行键盘的切换
//                    break;
//                case PPKeyboardTypeSticker:
//                    [self.emojiToggleButton setImage:BAInputConfig.shared.toggleKeyboard forState:UIControlStateNormal];
//        //            self.textView.inputView = self.stickerKeyboard;         // 切换到自定义的表情键盘
//        //            [self.textView reloadInputViews];
//                    break;
//                default:
//                    break;
//            }
    }
    
    
}
