/*
 MIT License

 Copyright (c) 2017-2019 MessageKit

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

import Foundation
import UIKit

/// A subclass of `MessageCollectionViewCell` used to display text, media, and location messages.
open class MessageContentCell: MessageCollectionViewCell, UIGestureRecognizerDelegate {
    
    /// The view displaying the reaction
    open var reactionView: UIView = UIView()
    
    /// The view displaying the status
    open var statusView: UIView = UIView()

    /// The image view displaying the avatar.
    open var avatarView: AvatarView = AvatarView()

    /// The container used for styling and holding the message's content view.
    open var messageContainerView: MessageContainerView = {
        let containerView = MessageContainerView()
        containerView.clipsToBounds = true
        containerView.layer.masksToBounds = true
        return containerView
    }()

    /// The top label of the cell.
    open var cellTopLabel: InsetLabel = {
        let label = InsetLabel()
        label.textInsets = UIEdgeInsets(top: 0, left: 7, bottom: 0, right: 7)
        label.numberOfLines = 1
        label.textAlignment = .center
        label.backgroundColor = .clear
        label.translatesAutoresizingMaskIntoConstraints = false
        
        return label
    }()
    
    open var sparateTopLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 17/255, green: 17/255, blue: 17/255, alpha: 0.1)
        view.translatesAutoresizingMaskIntoConstraints = false
        
        return view
    }()
    
    /// The bottom label of the cell.
    open var cellBottomLabel: InsetLabel = {
        let label = InsetLabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    /// The top label of the messageBubble.
    open var messageTopLabel: InsetLabel = {
        let label = InsetLabel()
        label.numberOfLines = 0
        return label
    }()

    /// The bottom label of the messageBubble.
    open var messageBottomLabel: InsetLabel = {
        let label = InsetLabel()
        label.numberOfLines = 0
        return label
    }()

    /// The time label of the messageBubble.
    open var messageTimestampLabel: InsetLabel = InsetLabel()

    // Should only add customized subviews - don't change accessoryView itself.
    open var accessoryView: UIView = UIView()
    
    lazy var replyIconImage: UIButton = {
        let replyIcon = UIButton()
        replyIcon.setImage(#imageLiteral(resourceName: "icBlackReply").withRenderingMode(.alwaysOriginal), for: .normal)
        replyIcon.tintColor = UIColor(red: 17/255, green: 17/255, blue: 17/255, alpha: 1)
        replyIcon.isUserInteractionEnabled = false
        replyIcon.contentEdgeInsets = UIEdgeInsets(top: 3, left: 3, bottom: 3, right: 3)
        replyIcon.layer.cornerRadius = 15
        replyIcon.backgroundColor = UIColor(red: 242/255, green: 242/255, blue: 242/255, alpha: 1)
        replyIcon.translatesAutoresizingMaskIntoConstraints = false
        replyIcon.alpha = 0
        
        return replyIcon
    }()
    
    lazy var editIconImage: UIButton = {
        let replyIcon = UIButton()
        replyIcon.setImage(#imageLiteral(resourceName: "icBlackPen").withRenderingMode(.alwaysOriginal), for: .normal)
        replyIcon.tintColor = UIColor(named: "111111")
        replyIcon.alpha = 0.4
        replyIcon.isUserInteractionEnabled = false
        
        return replyIcon
    }()
    
    /// Customized for gesture
    var startAnimation: Bool = false
    var presentMessage: MessageType!
    var isAvailableGesture: Bool = false
    var safePanWork: Bool = false

    /// The `MessageCellDelegate` for the cell.
    open weak var delegate: MessageCellDelegate?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        setupSubviews()
        setupGestures()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        setupSubviews()
        setupGestures()
    }
    
    open func setupGestures() {
        let panGesture = UIPanGestureRecognizer()
        panGesture.addTarget(self, action: #selector(handlePanGesture(_:)))
        panGesture.delegate = self
        contentView.addGestureRecognizer(panGesture)
    }

    open func setupSubviews() {
        contentView.addSubview(accessoryView)
        contentView.addSubview(sparateTopLine)
        contentView.addSubview(cellTopLabel)
        contentView.addSubview(messageTopLabel)
        contentView.addSubview(messageBottomLabel)
        contentView.addSubview(cellBottomLabel)
        contentView.addSubview(messageContainerView)
        contentView.addSubview(avatarView)
        contentView.addSubview(messageTimestampLabel)
        contentView.addSubview(editIconImage)
        contentView.addSubview(reactionView)
        contentView.addSubview(statusView)
    }

    open override func prepareForReuse() {
        super.prepareForReuse()
        cellTopLabel.text = nil
        cellBottomLabel.text = nil
        messageTopLabel.text = nil
        messageBottomLabel.text = nil
        messageTimestampLabel.attributedText = nil
    }

    // MARK: - Configuration

    open override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        guard let attributes = layoutAttributes as? MessagesCollectionViewLayoutAttributes else { return }
        var heightReactionAdded: CGFloat = 0
        var reactionSize: CGSize = .zero
        
        if attributes.messageReaction {
            reactionSize = attributes.reactionViewSize
            heightReactionAdded = reactionSize.height - attributes.reactionViewTopMargin
        } else {
            heightReactionAdded = 0
        }

        // Call this before other laying out other subviews
        layoutMessageContainerView(with: attributes, reactionAdded: heightReactionAdded)
        layoutEditIcon(with: attributes)
        layoutReactionView(with: attributes, reactionSize: reactionSize)
        layoutStatusView(with: attributes, reactionAdded: heightReactionAdded)
        layoutMessageBottomLabel(with: attributes)
        layoutCellBottomLabel(with: attributes)
        layoutCellTopLabel(with: attributes)
        layoutMessageTopLabel(with: attributes)
        layoutAvatarView(with: attributes)
        layoutAccessoryView(with: attributes)
        layoutTimeLabelView(with: attributes)
    }

    /// Used to configure the cell.
    ///
    /// - Parameters:
    ///   - message: The `MessageType` this cell displays.
    ///   - indexPath: The `IndexPath` for this cell.
    ///   - messagesCollectionView: The `MessagesCollectionView` in which this cell is contained.
    open func configure(with message: MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
        guard let dataSource = messagesCollectionView.messagesDataSource else {
            fatalError(MessageKitError.nilMessagesDataSource)
        }
        guard let displayDelegate = messagesCollectionView.messagesDisplayDelegate else {
            fatalError(MessageKitError.nilMessagesDisplayDelegate)
        }
    
        delegate = messagesCollectionView.messageCellDelegate
        presentMessage = message

        let messageColor = displayDelegate.backgroundColor(for: message, at: indexPath, in: messagesCollectionView)
        let messageStyle = displayDelegate.messageStyle(for: message, at: indexPath, in: messagesCollectionView)

        displayDelegate.configureAvatarView(avatarView, for: message, at: indexPath, in: messagesCollectionView)

        displayDelegate.configureAccessoryView(accessoryView, for: message, at: indexPath, in: messagesCollectionView)
        
        displayDelegate.configureStatusView(statusView, for: message, at: indexPath, in: messagesCollectionView)

        if message.hasReaction > 0 {
            displayDelegate.configureReactionView(reactionView, for: message, at: indexPath, in: messagesCollectionView)
        }
        
        messageContainerView.backgroundColor = messageColor
        backgroundColor = .clear
        messageContainerView.style = messageStyle

        let topCellLabelText = dataSource.cellTopLabelAttributedText(for: message, at: indexPath)
        let bottomCellLabelText = dataSource.cellBottomLabelAttributedText(for: message, at: indexPath)
        let topMessageLabelText = dataSource.messageTopLabelAttributedText(for: message, at: indexPath)
        let bottomMessageLabelText = dataSource.messageBottomLabelAttributedText(for: message, at: indexPath)
        let messageTimestampLabelText = dataSource.messageTimestampLabelAttributedText(for: message, at: indexPath)
        cellTopLabel.attributedText = topCellLabelText
        cellBottomLabel.attributedText = bottomCellLabelText
        messageTopLabel.attributedText = topMessageLabelText
        messageBottomLabel.attributedText = bottomMessageLabelText
        messageTimestampLabel.attributedText = messageTimestampLabelText
        messageTimestampLabel.isHidden = !messagesCollectionView.showMessageTimestampOnSwipeLeft
    }

    /// Handle tap gesture on contentView and its subviews.
    open override func handleTapGesture(_ gesture: UIGestureRecognizer) {
        let touchLocation = gesture.location(in: self)

        switch true {
        case messageContainerView.frame.contains(touchLocation) && !cellContentView(canHandle: convert(touchLocation, to: messageContainerView)):
            let location = convert(touchLocation, to: messageContainerView)
            if let subview = messageContainerView.subviews.first(where: {$0.tag != 999}), subview.frame.contains(location) && messageContainerView.subviews.count > 1 {
                delegate?.didTapRepliedMessage(in: self)
            } else {
                delegate?.didTapMessage(in: self, at: touchLocation)
            }
        case avatarView.frame.contains(touchLocation):
            delegate?.didTapAvatar(in: self)
        case cellTopLabel.frame.contains(touchLocation):
            delegate?.didTapCellTopLabel(in: self)
            delegate?.didTapAnywhere()
        case cellBottomLabel.frame.contains(touchLocation):
            delegate?.didTapCellBottomLabel(in: self)
            delegate?.didTapAnywhere()
        case messageTopLabel.frame.contains(touchLocation):
            delegate?.didTapMessageTopLabel(in: self)
            delegate?.didTapAnywhere()
        case messageBottomLabel.frame.contains(touchLocation):
            delegate?.didTapMessageBottomLabel(in: self)
        case accessoryView.frame.contains(touchLocation):
            delegate?.didTapAccessoryView(in: self)
            delegate?.didTapAnywhere()
        case statusView.frame.contains(touchLocation):
            delegate?.didTapStatusView(in: self)
        case reactionView.frame.contains(touchLocation):
            delegate?.didTapReactionView(in: self)
        default:
            delegate?.didTapBackground(in: self)
            delegate?.didTapAnywhere()
        }
    }
    
    open override func handleDoubleTapGesture(_ gesture: UIGestureRecognizer) {
        let touchLocation = gesture.location(in: self)
        switch true {
        case messageContainerView.frame.contains(touchLocation):
            delegate?.didDoubleTapMessage(in: self)
        default:
            break
        }
    }
    
    open override func handleHoldGesture(_ gesture: UIGestureRecognizer) {
        let touchLocation = gesture.location(in: self)
        
        switch true {
        case messageContainerView.frame.contains(touchLocation):
            if gesture.state == .began {
                UIView.animate(withDuration: 0.3) {
                    self.messageContainerView.transform = CGAffineTransform(scaleX: 0.88, y: 0.88)
                    self.reactionView.transform = CGAffineTransform(scaleX: 0.88, y: 0.88)
                    self.editIconImage.transform = CGAffineTransform(scaleX: 0.88, y: 0.88)
                } completion: { (done) in
                    self.delegate?.didHoldMessage(in: self, at: touchLocation)
                    UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0.7, options: [.allowUserInteraction]) {
                        self.messageContainerView.transform = .identity
                        self.reactionView.transform = .identity
                        self.editIconImage.transform = .identity
                    }
                }
            } else {
                return
            }
        default:
            break
        }
    }
    
    @objc open override func handlePanGesture(_ gesture: UIGestureRecognizer) {
        guard let panGesture = gesture as? UIPanGestureRecognizer else {
            return
        }
        
        switch panGesture.state {
        case .began:
            startAnimation = true
            isAvailableGesture = false
            safePanWork = messageContainerView.frame.contains(gesture.location(in: self))
            contentView.addSubview(replyIconImage)
            
            if presentMessage.isOwner {
                NSLayoutConstraint.activate([
                    replyIconImage.trailingAnchor.constraint(equalTo: messageContainerView.trailingAnchor, constant: 30),
                    replyIconImage.widthAnchor.constraint(equalToConstant: 30),
                    replyIconImage.heightAnchor.constraint(equalToConstant: 30),
                    replyIconImage.centerYAnchor.constraint(equalTo: messageContainerView.centerYAnchor)
                ])
            } else {
                NSLayoutConstraint.activate([
                    replyIconImage.leadingAnchor.constraint(equalTo: messageContainerView.leadingAnchor, constant: -30),
                    replyIconImage.widthAnchor.constraint(equalToConstant: 30),
                    replyIconImage.heightAnchor.constraint(equalToConstant: 30),
                    replyIconImage.centerYAnchor.constraint(equalTo: messageContainerView.centerYAnchor)
                ])
            }
            
            replyIconImage.alpha = 0
            replyIconImage.isHidden = true
        case .changed:
            if !safePanWork {
                return
            }
            let translation = panGesture.translation(in: messageContainerView)
            if presentMessage.isOwner {
                if translation.x < 0 {
                    self.messageContainerView.transform = CGAffineTransform(translationX: translation.x * 0.4, y: 0)
                    self.reactionView.transform = CGAffineTransform(translationX: translation.x * 0.4, y: 0)
                    self.editIconImage.transform = CGAffineTransform(translationX: translation.x * 0.4, y: 0)
                    self.accessoryView.transform = CGAffineTransform(translationX: translation.x * 0.4, y: 0)

                    self.replyIconImage.transform = CGAffineTransform(translationX: max(-40, translation.x * 0.3), y: 0).scaledBy(x: min(1.0, (abs(translation.x * 0.3)) / 40), y: min(1.0, (abs(translation.x * 0.3)) / 40))
                    
                    if abs(translation.x) >= 120 {
                        if startAnimation {
                            isAvailableGesture = true
                            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                            startAnimation = false
                        }
                    } else {
                        if abs(translation.x) >= 60 {
                            replyIconImage.alpha = (min(120, abs(translation.x)) - 60) / 60
                            replyIconImage.isHidden = false
                        } else {
                            replyIconImage.isHidden = true
                            replyIconImage.alpha = 0
                        }
                        
                        startAnimation = true
                        isAvailableGesture = false
                    }
                }
            } else {
                if translation.x > 0 {
                    self.messageContainerView.transform = CGAffineTransform(translationX: translation.x * 0.4, y: 0)
                    self.reactionView.transform = CGAffineTransform(translationX: translation.x * 0.4, y: 0)
                    self.editIconImage.transform = CGAffineTransform(translationX: translation.x * 0.4, y: 0)
                    self.accessoryView.transform = CGAffineTransform(translationX: translation.x * 0.4, y: 0)
                    
                    self.replyIconImage.transform = CGAffineTransform(translationX: min(40, translation.x * 0.3), y: 0).scaledBy(x: min(1.0, (abs(translation.x * 0.3)) / 40), y: min(1.0, (abs(translation.x * 0.3)) / 40))

                    if abs(translation.x) >= 120 {
                        if startAnimation {
                            isAvailableGesture = true
                            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                            startAnimation = false
                        }
                    } else {
                        if abs(translation.x) >= 60 {
                            replyIconImage.alpha = (min(120, abs(translation.x)) - 60) / 60
                            replyIconImage.isHidden = false
                        } else {
                            replyIconImage.isHidden = true
                            replyIconImage.alpha = 0
                        }
                        
                        startAnimation = true
                        isAvailableGesture = false
                    }
                }
            }
        case .ended:
            if !safePanWork { return }
            if isAvailableGesture {
                delegate?.didSwipeMessage(in: self)
            }
            UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.3, options: [.allowUserInteraction]) {
                self.messageContainerView.transform = .identity
                self.reactionView.transform = .identity
                self.editIconImage.transform = .identity
                self.accessoryView.transform = .identity

                self.replyIconImage.transform = .identity
                self.replyIconImage.alpha = 0
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.replyIconImage.isHidden = true
                    self.replyIconImage.removeFromSuperview()
                }
            } completion: { (ok) in

            }
        default:
            break
        }
    }

    /// Handle pan gesture, return true when gestureRecognizer's touch point in `ContentView`'s frame
    open override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer.isKind(of: UIPanGestureRecognizer.self) {
            guard let panGesture = gestureRecognizer as? UIPanGestureRecognizer, self.messageContainerView.frame.contains(panGesture.location(ofTouch: 0, in: self)) else { return false}
            let translation = panGesture.translation(in: self.messageContainerView)
            if abs(translation.x) > abs(translation.y) {
                return true
            }
            return false
        } else {
            return false
        }
    }

    /// Handle `ContentView`'s tap gesture, return false when `ContentView` doesn't needs to handle gesture
    open func cellContentView(canHandle touchPoint: CGPoint) -> Bool {
        return false
    }

    // MARK: - Origin Calculations

    /// Positions the cell's `AvatarView`.
    /// - attributes: The `MessagesCollectionViewLayoutAttributes` for the cell.
    open func layoutAvatarView(with attributes: MessagesCollectionViewLayoutAttributes) {
        var origin: CGPoint = .zero
        let padding = attributes.avatarLeadingTrailingPadding

        switch attributes.avatarPosition.horizontal {
        case .cellLeading:
            origin.x = padding
        case .cellTrailing:
            origin.x = attributes.frame.width - attributes.avatarSize.width - padding
        case .natural:
            fatalError(MessageKitError.avatarPositionUnresolved)
        }

        switch attributes.avatarPosition.vertical {
        case .messageLabelTop:
            origin.y = messageTopLabel.frame.minY
        case .messageTop: // Needs messageContainerView frame to be set
            origin.y = messageContainerView.frame.minY
        case .messageBottom: // Needs messageContainerView frame to be set
            origin.y = messageContainerView.frame.maxY - attributes.avatarSize.height
        case .messageCenter: // Needs messageContainerView frame to be set
            origin.y = messageContainerView.frame.midY - (attributes.avatarSize.height/2)
        case .cellBottom:
            origin.y = attributes.frame.height - attributes.avatarSize.height
        default:
            break
        }

        avatarView.frame = CGRect(origin: origin, size: attributes.avatarSize)
    }

    /// Positions the cell's `MessageContainerView`.
    /// - attributes: The `MessagesCollectionViewLayoutAttributes` for the cell.
    open func layoutMessageContainerView(with attributes: MessagesCollectionViewLayoutAttributes, reactionAdded: CGFloat) {
        var origin: CGPoint = .zero
        
        switch attributes.avatarPosition.vertical {
        case .messageBottom:
            origin.y = attributes.size.height - attributes.messageContainerPadding.bottom - attributes.cellBottomLabelSize.height - attributes.messageBottomLabelSize.height - attributes.messageContainerSize.height - attributes.messageContainerPadding.top - reactionAdded
        case .messageCenter:
            if attributes.avatarSize.height > attributes.messageContainerSize.height {
                let messageHeight = attributes.messageContainerSize.height + attributes.messageContainerPadding.vertical
                origin.y = (attributes.size.height / 2) - (messageHeight / 2)
            } else {
                fallthrough
            }
        default:
            if attributes.accessoryViewSize.height > attributes.messageContainerSize.height {
                let messageHeight = attributes.messageContainerSize.height + attributes.messageContainerPadding.vertical
                origin.y = (attributes.size.height / 2) - (messageHeight / 2)
            } else {
                origin.y = attributes.cellTopLabelSize.height + attributes.messageTopLabelSize.height + attributes.messageContainerPadding.top
            }
        }

        let avatarPadding = attributes.avatarLeadingTrailingPadding
        switch attributes.avatarPosition.horizontal {
        case .cellLeading:
            origin.x = attributes.avatarSize.width + attributes.messageContainerPadding.left + avatarPadding
        case .cellTrailing:
            origin.x = attributes.frame.width - attributes.avatarSize.width - attributes.messageContainerSize.width - attributes.messageContainerPadding.right - avatarPadding
        case .natural:
            fatalError(MessageKitError.avatarPositionUnresolved)
        }

        messageContainerView.frame = CGRect(origin: origin, size: attributes.messageContainerSize)
    }
    
    open func layoutEditIcon(with attributes: MessagesCollectionViewLayoutAttributes) {
        if attributes.messageEditedStatus {
            editIconImage.isHidden = false
            var origin: CGPoint = .zero

            if let _ = messageContainerView.subviews.first(where: {$0.tag == 999}) {
                let subviewSize = attributes.messageSubviewsSize
                origin.y = messageContainerView.frame.maxY - (subviewSize.height / 2) - 7

                switch attributes.avatarPosition.horizontal {
                case .cellLeading:
                    origin.x = messageContainerView.frame.minX + subviewSize.width + 8
                case .cellTrailing:
                    origin.x = messageContainerView.frame.maxX - 22 - subviewSize.width
                default:
                    break
                }
                
                editIconImage.frame = CGRect(origin: origin, size: CGSize(width: 14, height: 14))
            } else {
                origin.y = messageContainerView.frame.minY + (messageContainerView.frame.height / 2) - 7

                switch attributes.avatarPosition.horizontal {
                case .cellLeading:
                    origin.x = messageContainerView.frame.maxX + 8
                case .cellTrailing:
                    origin.x = messageContainerView.frame.minX - 22
                default:
                    break
                }
                
                editIconImage.frame = CGRect(origin: origin, size: CGSize(width: 14, height: 14))
            }
        } else {
            editIconImage.frame = .zero
            editIconImage.isHidden = true
        }
    }
    
    /// Positions the cell's reaction view.
    /// - attributes: The `MessagesCollectionViewLayoutAttributes` for the cell.
    open func layoutReactionView(with attributes: MessagesCollectionViewLayoutAttributes, reactionSize: CGSize) {
        
        if reactionSize == .zero {
            reactionView.frame = .zero
        } else {
            var origin: CGPoint = .zero

            origin.y = messageContainerView.frame.maxY - attributes.reactionViewTopMargin
            
            if let _ = messageContainerView.subviews.first(where: {$0.tag == 999}) {
                let messageSubviewWidth = attributes.messageSubviewsSize.width

                switch attributes.avatarPosition.horizontal {
                case .cellLeading:
                    if reactionSize.width > messageSubviewWidth - attributes.reactionViewLeadingMargin - attributes.reactionViewTrailingMargin {
                        origin.x = messageContainerView.frame.minX + attributes.reactionViewLeadingMargin
                    } else {
                        origin.x = messageContainerView.frame.minX + messageSubviewWidth - attributes.reactionViewTrailingMargin - reactionSize.width
                    }
                case .cellTrailing:
                    if reactionSize.width > messageSubviewWidth - attributes.reactionViewLeadingMargin - attributes.reactionViewTrailingMargin {
                        origin.x = messageContainerView.frame.maxX - attributes.reactionViewTrailingMargin - reactionSize.width
                    } else {
                        origin.x = messageContainerView.frame.maxX - messageSubviewWidth + attributes.reactionViewLeadingMargin
                    }
                default:
                    fatalError(MessageKitError.avatarPositionUnresolved)
                }
                
                reactionView.frame = CGRect(origin: origin, size: reactionSize)
            } else {
                let messageContainterWidth = messageContainerView.frame.width

                switch attributes.avatarPosition.horizontal {
                case .cellLeading:
                    if reactionSize.width > messageContainterWidth - attributes.reactionViewLeadingMargin - attributes.reactionViewTrailingMargin {
                        origin.x = messageContainerView.frame.minX + attributes.reactionViewLeadingMargin
                    } else {
                        origin.x = messageContainerView.frame.maxX - attributes.reactionViewTrailingMargin - reactionSize.width
                    }
                case .cellTrailing:
                    if reactionSize.width > messageContainterWidth - attributes.reactionViewLeadingMargin - attributes.reactionViewTrailingMargin {
                        origin.x = messageContainerView.frame.maxX - attributes.reactionViewTrailingMargin - reactionSize.width
                    } else {
                        origin.x = messageContainerView.frame.minX + attributes.reactionViewLeadingMargin
                    }
                default:
                    fatalError(MessageKitError.avatarPositionUnresolved)
                }
                
                reactionView.frame = CGRect(origin: origin, size: reactionSize)
            }
        }
    }
    
    /// Positions the cell's status view.
    /// - attributes: The `MessagesCollectionViewLayoutAttributes` for the cell.
    open func layoutStatusView(with attributes: MessagesCollectionViewLayoutAttributes, reactionAdded: CGFloat) {
        var origin = CGPoint.zero

        origin.x = attributes.statusViewPadding.left
        origin.y = messageContainerView.frame.maxY + attributes.messageContainerPadding.bottom + reactionAdded
        
        statusView.frame = CGRect(origin: origin, size: attributes.statusViewSize)
    }

    /// Positions the cell's top label.
    /// - attributes: The `MessagesCollectionViewLayoutAttributes` for the cell.
    open func layoutCellTopLabel(with attributes: MessagesCollectionViewLayoutAttributes) {
        cellTopLabel.textAlignment = attributes.cellTopLabelAlignment.textAlignment
        cellTopLabel.textInsets = attributes.cellTopLabelAlignment.textInsets
        
        NSLayoutConstraint.activate([
            cellTopLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            cellTopLabel.heightAnchor.constraint(equalToConstant: attributes.cellTopLabelSize.height),
            cellTopLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            cellTopLabel.bottomAnchor.constraint(equalTo: messageTopLabel.topAnchor),
            
            sparateTopLine.heightAnchor.constraint(equalToConstant: 0.5),
            sparateTopLine.centerYAnchor.constraint(equalTo: cellTopLabel.centerYAnchor),
            sparateTopLine.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            sparateTopLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
        ])
        sparateTopLine.isHidden = true
    }
    
    /// Positions the cell's bottom label.
    /// - attributes: The `MessagesCollectionViewLayoutAttributes` for the cell.
    open func layoutCellBottomLabel(with attributes: MessagesCollectionViewLayoutAttributes) {
        cellBottomLabel.textAlignment = attributes.cellBottomLabelAlignment.textAlignment
        cellBottomLabel.textInsets = attributes.cellBottomLabelAlignment.textInsets
        
        let y = messageBottomLabel.frame.maxY
        let origin = CGPoint(x: 0, y: y)
        
        cellBottomLabel.frame = CGRect(origin: origin, size: attributes.cellBottomLabelSize)
    }
    
    /// Positions the message bubble's top label.
    /// - attributes: The `MessagesCollectionViewLayoutAttributes` for the cell.
    open func layoutMessageTopLabel(with attributes: MessagesCollectionViewLayoutAttributes) {
        messageTopLabel.textAlignment = attributes.messageTopLabelAlignment.textAlignment
        messageTopLabel.textInsets = attributes.messageTopLabelAlignment.textInsets

        let y = messageContainerView.frame.minY - attributes.messageContainerPadding.top - attributes.messageTopLabelSize.height
        let origin = CGPoint(x: 0, y: y)
        
        messageTopLabel.frame = CGRect(origin: origin, size: attributes.messageTopLabelSize)
    }

    /// Positions the message bubble's bottom label.
    /// - attributes: The `MessagesCollectionViewLayoutAttributes` for the cell.
    open func layoutMessageBottomLabel(with attributes: MessagesCollectionViewLayoutAttributes) {
        messageBottomLabel.textAlignment = attributes.messageBottomLabelAlignment.textAlignment
        messageBottomLabel.textInsets = attributes.messageBottomLabelAlignment.textInsets

        let y = statusView.frame.maxY
        let origin = CGPoint(x: 0, y: y)

        messageBottomLabel.frame = CGRect(origin: origin, size: attributes.messageBottomLabelSize)
    }

    /// Positions the cell's accessory view.
    /// - attributes: The `MessagesCollectionViewLayoutAttributes` for the cell.
    open func layoutAccessoryView(with attributes: MessagesCollectionViewLayoutAttributes) {
        
        var origin: CGPoint = .zero
        
        // Accessory view is set at the side space of the messageContainerView
        switch attributes.accessoryViewPosition {
        case .messageLabelTop:
            origin.y = messageTopLabel.frame.minY
        case .messageTop:
            origin.y = messageContainerView.frame.minY
        case .messageBottom:
            origin.y = messageContainerView.frame.maxY - attributes.accessoryViewSize.height
        case .messageCenter:
            origin.y = messageContainerView.frame.midY - (attributes.accessoryViewSize.height / 2)
        case .cellBottom:
            origin.y = attributes.frame.height - attributes.accessoryViewSize.height
        default:
            break
        }
        
        let iconEditMaxX = editIconImage.isHidden == true ? 0 : editIconImage.frame.maxX
        let iconEditMinX = editIconImage.isHidden == true ? 0 : editIconImage.frame.width + 8

        // Accessory view is always on the opposite side of avatar
        switch attributes.avatarPosition.horizontal {
        case .cellLeading:
            origin.x = messageContainerView.frame.maxX + attributes.accessoryViewPadding.left + iconEditMaxX
        case .cellTrailing:
            origin.x = messageContainerView.frame.minX - attributes.accessoryViewPadding.right - attributes.accessoryViewSize.width - iconEditMinX
        case .natural:
            fatalError(MessageKitError.avatarPositionUnresolved)
        }

        accessoryView.frame = CGRect(origin: origin, size: attributes.accessoryViewSize)
    }

    ///  Positions the message bubble's time label.
    /// - attributes: The `MessagesCollectionViewLayoutAttributes` for the cell.
    open func layoutTimeLabelView(with attributes: MessagesCollectionViewLayoutAttributes) {
        let paddingLeft: CGFloat = 10
        let origin = CGPoint(x: UIScreen.main.bounds.width + paddingLeft,
                             y: messageContainerView.frame.minY + messageContainerView.frame.height * 0.5 - messageTimestampLabel.font.ascender * 0.5)
        let size = CGSize(width: attributes.messageTimeLabelSize.width, height: attributes.messageTimeLabelSize.height)
        messageTimestampLabel.frame = CGRect(origin: origin, size: size)
    }
    
    open func highlightMessageContainerView(with color: UIColor) {
        UIView.animate(withDuration: 0.2) {
            self.messageContainerView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            self.reactionView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        } completion: { (done) in
            UIView.animate(withDuration: 0.8, delay: 0, usingSpringWithDamping: 0.35, initialSpringVelocity: 0.6, options: .allowUserInteraction) {
                self.messageContainerView.transform = .identity
                self.reactionView.transform = .identity
                if let subview = self.messageContainerView.subviews.first(where: {$0.tag == 999}) {
                    subview.layer.animateBackgroundColor(from: subview.backgroundColor ?? .clear, to: color, withDuration: 0.8)
                } else if let subview = self.messageContainerView.subviews.first {
                    subview.layer.animateBackgroundColor(from: subview.backgroundColor ?? .clear, to: color, withDuration: 0.8)
                } else {
                    self.messageContainerView.layer.animateBackgroundColor(from: self.messageContainerView.backgroundColor ?? .clear, to: color, withDuration: 0.8)
                }
            }
        }
    }
}
