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

open class MessageSizeCalculator: CellSizeCalculator {

    public init(layout: MessagesCollectionViewFlowLayout? = nil) {
        super.init()
        
        self.layout = layout
    }
    
    public var editImageIcon = UIImage(named: "icBlackPenEdit")
    public var replyImageIcon = UIImage(named: "icBlackReply")
    
    public var editIconSize = CGSize(width: 14, height: 14)

    public var incomingAvatarSize = CGSize(width: 30, height: 30)
    public var outgoingAvatarSize = CGSize(width: 30, height: 30)

    public var incomingAvatarPosition = AvatarPosition(vertical: .cellBottom)
    public var outgoingAvatarPosition = AvatarPosition(vertical: .cellBottom)

    public var avatarLeadingTrailingPadding: CGFloat = 0

    public var incomingMessagePadding = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 30)
    public var outgoingMessagePadding = UIEdgeInsets(top: 0, left: 30, bottom: 0, right: 4)

    public var incomingCellTopLabelAlignment = LabelAlignment(textAlignment: .center, textInsets: UIEdgeInsets(top: 0, left: 7, bottom: 0, right: 7))
    public var outgoingCellTopLabelAlignment = LabelAlignment(textAlignment: .center, textInsets: UIEdgeInsets(top: 0, left: 7, bottom: 0, right: 7))
    
    public var incomingCellBottomLabelAlignment = LabelAlignment(textAlignment: .left, textInsets: UIEdgeInsets(left: 42))
    public var outgoingCellBottomLabelAlignment = LabelAlignment(textAlignment: .right, textInsets: UIEdgeInsets(right: 42))

    public var incomingMessageTopLabelAlignment = LabelAlignment(textAlignment: .left, textInsets: UIEdgeInsets(left: 42))
    public var outgoingMessageTopLabelAlignment = LabelAlignment(textAlignment: .right, textInsets: UIEdgeInsets(right: 42))

    public var incomingMessageBottomLabelAlignment = LabelAlignment(textAlignment: .left, textInsets: UIEdgeInsets(left: 42))
    public var outgoingMessageBottomLabelAlignment = LabelAlignment(textAlignment: .right, textInsets: UIEdgeInsets(right: 42))

    public var incomingAccessoryViewSize = CGSize.zero
    public var outgoingAccessoryViewSize = CGSize.zero

    public var incomingAccessoryViewPadding = HorizontalEdgeInsets.zero
    public var outgoingAccessoryViewPadding = HorizontalEdgeInsets.zero
    
    public var incomingAccessoryViewPosition: AccessoryPosition = .messageCenter
    public var outgoingAccessoryViewPosition: AccessoryPosition = .messageCenter
    
    public var incomingStatusViewPadding = HorizontalEdgeInsets.zero
    public var outgoingStatusViewPadding = HorizontalEdgeInsets.zero
    
    public var topReactionViewMargin: CGFloat = 8
    public var topMessageContainerViewMargin: CGFloat = 17
    public var leadingReactionViewMargin: CGFloat = 12
    public var trailingReactionViewMargin: CGFloat = 12
    public var reactionViewMaxHeight: CGFloat = 24
    
    public var linkPreviewHeigt: CGFloat = 150
    
    open override func configure(attributes: UICollectionViewLayoutAttributes) {
        guard let attributes = attributes as? MessagesCollectionViewLayoutAttributes else { return }

        let dataSource = messagesLayout.messagesDataSource
        let indexPath = attributes.indexPath
        let message = dataSource.messageForItem(at: indexPath, in: messagesLayout.messagesCollectionView)
        
        attributes.replyImageIcon = replyImageIcon
        attributes.editImageIcon = editImageIcon
        attributes.editIconSize = editIconSize

        attributes.avatarSize = avatarSize(for: message)
        attributes.avatarPosition = avatarPosition(for: message)
        attributes.avatarLeadingTrailingPadding = avatarLeadingTrailingPadding

        attributes.messageContainerPadding = messageContainerPadding(for: message)
        attributes.messageContainerSize = messageContainerSize(for: message)
        attributes.messageReplyContainerSize = messageReplySize(for: message)
        attributes.linkInfoContainerSize = linkPreviewSize(for: message)
        attributes.messageMediaDescriptionSize = messageMediaDescriptionSize(for: message)
        attributes.linkPreviewHeight = linkPreviewHeigt
        attributes.cellTopLabelSize = cellTopLabelSize(for: message, at: indexPath)
        attributes.cellTopLabelAlignment = cellTopLabelAlignment(for: message)
        attributes.cellBottomLabelSize = cellBottomLabelSize(for: message, at: indexPath)
        attributes.messageTimeLabelSize = messageTimeLabelSize(for: message, at: indexPath)
        attributes.cellBottomLabelAlignment = cellBottomLabelAlignment(for: message)
        attributes.messageTopLabelSize = messageTopLabelSize(for: message, at: indexPath)
        attributes.messageTopLabelAlignment = messageTopLabelAlignment(for: message)

        attributes.messageBottomLabelAlignment = messageBottomLabelAlignment(for: message)
        attributes.messageBottomLabelSize = messageBottomLabelSize(for: message, at: indexPath)

        attributes.accessoryViewSize = accessoryViewSize(for: message)
        attributes.accessoryViewPadding = accessoryViewPadding(for: message)
        attributes.accessoryViewPosition = accessoryViewPosition(for: message)
        
        attributes.statusViewSize = statusViewSize(for: message, at: indexPath)
        attributes.statusViewPadding = statusViewPadding(for: message)
        
        attributes.messageEditedStatus = message.isEdited
        attributes.messageReplied = message.isReplied
        attributes.messageSelectionImageSize = messageSelectionViewSize(for: message, at: indexPath)

        if message.hasReaction {
            attributes.reactionViewTrailingMargin = trailingReactionViewMargin
            attributes.reactionViewTopMargin = topReactionViewMargin
            attributes.reactionViewLeadingMargin = leadingReactionViewMargin
            attributes.reactionViewSize = reactionViewSize(for: message, at: indexPath)
            attributes.messageReaction = true
        } else {
            attributes.messageReaction = false
        }
    }

    open override func sizeForItem(at indexPath: IndexPath) -> CGSize {
        let dataSource = messagesLayout.messagesDataSource
        let message = dataSource.messageForItem(at: indexPath, in: messagesLayout.messagesCollectionView)
        let itemHeight = cellContentHeight(for: message, at: indexPath)
        return CGSize(width: messagesLayout.itemWidth, height: itemHeight)
    }

    open func cellContentHeight(for message: MessageType, at indexPath: IndexPath) -> CGFloat {
        let messageContainerHeight = messageContainerSize(for: message).height
        let cellBottomLabelHeight = cellBottomLabelSize(for: message, at: indexPath).height
        let messageBottomLabelHeight = messageBottomLabelSize(for: message, at: indexPath).height
        let cellTopLabelHeight = cellTopLabelSize(for: message, at: indexPath).height
        let messageTopLabelHeight = messageTopLabelSize(for: message, at: indexPath).height
        let messageVerticalPadding = messageContainerPadding(for: message).vertical
        let avatarHeight = avatarSize(for: message).height
        let avatarVerticalPosition = avatarPosition(for: message).vertical
        let accessoryViewHeight = accessoryViewSize(for: message).height
        let statusViewHeight = statusViewSize(for: message, at: indexPath).height
        let reactionViewHeight = message.hasReaction ? reactionViewSize(for: message, at: indexPath).height - topReactionViewMargin : 0
        let repliedViewHeight = message.isReplied ? messageReplySize(for: message).height - topMessageContainerViewMargin : 0

        switch avatarVerticalPosition {
        case .messageCenter:
            let totalLabelHeight: CGFloat = cellTopLabelHeight + messageTopLabelHeight + repliedViewHeight
                + messageContainerHeight + messageVerticalPadding + messageBottomLabelHeight + cellBottomLabelHeight + statusViewHeight + reactionViewHeight
            let cellHeight = max(avatarHeight, totalLabelHeight)
            return max(cellHeight, accessoryViewHeight)
        case .messageBottom:
            var cellHeight: CGFloat = 0
            cellHeight += messageBottomLabelHeight
            cellHeight += cellBottomLabelHeight
            cellHeight += statusViewHeight
            cellHeight += reactionViewHeight
            let labelsHeight = messageContainerHeight + messageVerticalPadding + cellTopLabelHeight + messageTopLabelHeight + repliedViewHeight
            cellHeight += max(labelsHeight, avatarHeight)
            return max(cellHeight, accessoryViewHeight)
        case .messageTop:
            var cellHeight: CGFloat = 0
            cellHeight += cellTopLabelHeight
            cellHeight += messageTopLabelHeight
            let labelsHeight = messageContainerHeight + messageVerticalPadding + messageBottomLabelHeight + cellBottomLabelHeight + statusViewHeight + reactionViewHeight + repliedViewHeight
            cellHeight += max(labelsHeight, avatarHeight)
            return max(cellHeight, accessoryViewHeight)
        case .messageLabelTop:
            var cellHeight: CGFloat = 0
            cellHeight += cellTopLabelHeight
            let messageLabelsHeight = messageContainerHeight + messageBottomLabelHeight + messageVerticalPadding + messageTopLabelHeight + cellBottomLabelHeight + statusViewHeight + reactionViewHeight + repliedViewHeight
            cellHeight += max(messageLabelsHeight, avatarHeight)
            return max(cellHeight, accessoryViewHeight)
        case .cellTop, .cellBottom:
            let totalLabelHeight: CGFloat = cellTopLabelHeight + messageTopLabelHeight
                + messageContainerHeight + messageVerticalPadding + messageBottomLabelHeight + cellBottomLabelHeight + statusViewHeight + reactionViewHeight + repliedViewHeight
            let cellHeight = max(avatarHeight, totalLabelHeight)
            return max(cellHeight, accessoryViewHeight)
        }
    }

    // MARK: - Avatar

    open func avatarPosition(for message: MessageType) -> AvatarPosition {
        let isFromCurrentSender = message.isOwner
        var position = isFromCurrentSender ? outgoingAvatarPosition : incomingAvatarPosition

        switch position.horizontal {
        case .cellTrailing, .cellLeading:
            break
        case .natural:
            position.horizontal = isFromCurrentSender ? .cellTrailing : .cellLeading
        }
        return position
    }

    open func avatarSize(for message: MessageType) -> CGSize {
        let isFromCurrentSender = message.isOwner
        return isFromCurrentSender ? outgoingAvatarSize : incomingAvatarSize
    }

    // MARK: - Top cell Label

    open func cellTopLabelSize(for message: MessageType, at indexPath: IndexPath) -> CGSize {
        let layoutDelegate = messagesLayout.messagesLayoutDelegate
        let collectionView = messagesLayout.messagesCollectionView
        let height = layoutDelegate.cellTopLabelHeight(for: message, at: indexPath, in: collectionView)
        return CGSize(width: messagesLayout.itemWidth, height: height)
    }

    open func cellTopLabelAlignment(for message: MessageType) -> LabelAlignment {
        let isFromCurrentSender = message.isOwner
        return isFromCurrentSender ? outgoingCellTopLabelAlignment : incomingCellTopLabelAlignment
    }
    
    // MARK: - Top message Label
    
    open func messageTopLabelSize(for message: MessageType, at indexPath: IndexPath) -> CGSize {
        let layoutDelegate = messagesLayout.messagesLayoutDelegate
        let collectionView = messagesLayout.messagesCollectionView
        let height = layoutDelegate.messageTopLabelHeight(for: message, at: indexPath, in: collectionView)
        return CGSize(width: messagesLayout.itemWidth, height: height)
    }
    
    open func messageTopLabelAlignment(for message: MessageType) -> LabelAlignment {
        let isFromCurrentSender = message.isOwner
        return isFromCurrentSender ? outgoingMessageTopLabelAlignment : incomingMessageTopLabelAlignment
    }

    // MARK: - Message time label

    open func messageTimeLabelSize(for message: MessageType, at indexPath: IndexPath) -> CGSize {
        let dataSource = messagesLayout.messagesDataSource
        guard let attributedText = dataSource.messageTimestampLabelAttributedText(for: message, at: indexPath) else {
            return .zero
        }
        let size = attributedText.size()
        return CGSize(width: size.width, height: size.height)
    }

    // MARK: - Bottom cell Label
    
    open func cellBottomLabelSize(for message: MessageType, at indexPath: IndexPath) -> CGSize {
        let layoutDelegate = messagesLayout.messagesLayoutDelegate
        let collectionView = messagesLayout.messagesCollectionView
        let height = layoutDelegate.cellBottomLabelHeight(for: message, at: indexPath, in: collectionView)
        return CGSize(width: messagesLayout.itemWidth, height: height)
    }
    
    open func cellBottomLabelAlignment(for message: MessageType) -> LabelAlignment {
        let isFromCurrentSender = message.isOwner
        return isFromCurrentSender ? outgoingCellBottomLabelAlignment : incomingCellBottomLabelAlignment
    }

    // MARK: - Bottom Message Label

    open func messageBottomLabelSize(for message: MessageType, at indexPath: IndexPath) -> CGSize {
        let layoutDelegate = messagesLayout.messagesLayoutDelegate
        let collectionView = messagesLayout.messagesCollectionView
        let height = layoutDelegate.messageBottomLabelHeight(for: message, at: indexPath, in: collectionView)
        return CGSize(width: messagesLayout.itemWidth, height: height)
    }

    open func messageBottomLabelAlignment(for message: MessageType) -> LabelAlignment {
        let isFromCurrentSender = message.isOwner
        return isFromCurrentSender ? outgoingMessageBottomLabelAlignment : incomingMessageBottomLabelAlignment
    }

    // MARK: - Accessory View

    public func accessoryViewSize(for message: MessageType) -> CGSize {
        let isFromCurrentSender = message.isOwner
        return isFromCurrentSender ? outgoingAccessoryViewSize : incomingAccessoryViewSize
    }

    public func accessoryViewPadding(for message: MessageType) -> HorizontalEdgeInsets {
        let isFromCurrentSender = message.isOwner
        return isFromCurrentSender ? outgoingAccessoryViewPadding : incomingAccessoryViewPadding
    }
    
    public func accessoryViewPosition(for message: MessageType) -> AccessoryPosition {
        let isFromCurrentSender = message.isOwner
        return isFromCurrentSender ? outgoingAccessoryViewPosition : incomingAccessoryViewPosition
    }
    
    // MARK: - Status View
    
    public func statusViewPadding(for message: MessageType) -> HorizontalEdgeInsets {
        let isFromCurrentSender = message.isOwner
        return isFromCurrentSender ? outgoingStatusViewPadding : incomingStatusViewPadding
    }
    
    public func statusViewSize(for message: MessageType, at indexPath: IndexPath) -> CGSize {
        let layoutDelegate = messagesLayout.messagesLayoutDelegate
        let collectionView = messagesLayout.messagesCollectionView
        let height = layoutDelegate.statusViewHeight(for: message, at: indexPath, in: collectionView)
        let width = messagesLayout.itemWidth - statusViewPadding(for: message).horizontal
        return CGSize(width: width, height: height)
    }
    
    public func reactionViewSize(for message: MessageType, at indexPath: IndexPath) -> CGSize {
        let layoutDelegate = messagesLayout.messagesLayoutDelegate
        let collectionView = messagesLayout.messagesCollectionView
        let width = layoutDelegate.reactionViewWidth(for: message, at: indexPath, in: collectionView)
        return CGSize(width: width, height: reactionViewMaxHeight)
    }

    // MARK: - MessageContainer

    open func messageContainerPadding(for message: MessageType) -> UIEdgeInsets {
        let isFromCurrentSender = message.isOwner
        return isFromCurrentSender ? outgoingMessagePadding : incomingMessagePadding
    }

    open func messageContainerSize(for message: MessageType) -> CGSize {
        // Returns .zero by default
        return .zero
    }
    
    open func messageReplySize(for message: MessageType) -> CGSize {
        // Returns .zero by default
        return .zero
    }
    
    open func linkPreviewSize(for message: MessageType) -> CGSize {
        // Returns .zero by default
        return .zero
    }
    
    open func messageMediaDescriptionSize(for message: MessageType) -> CGSize {
        return .zero
    }
    
    open func messageSelectionViewSize(for message: MessageType, at indexPath: IndexPath) -> CGSize {
        let layoutDelegate = messagesLayout.messagesLayoutDelegate
        let collectionView = messagesLayout.messagesCollectionView
        let size = layoutDelegate.messageSelectionViewSize(for: message, at: indexPath, in: collectionView)
        return size
    }

    open func messageContainerMaxWidth(for message: MessageType) -> CGFloat {
        let avatarWidth = avatarSize(for: message).width
        let messagePadding = messageContainerPadding(for: message)
        let accessoryWidth = accessoryViewSize(for: message).width
        let accessoryPadding = accessoryViewPadding(for: message)
        return messagesLayout.itemWidth - avatarWidth - messagePadding.horizontal - accessoryWidth - accessoryPadding.horizontal - avatarLeadingTrailingPadding
    }
    
    // MARK: - Helpers

    public var messagesLayout: MessagesCollectionViewFlowLayout {
        guard let layout = layout as? MessagesCollectionViewFlowLayout else {
            fatalError("Layout object is missing or is not a MessagesCollectionViewFlowLayout")
        }
        return layout
    }

    internal func labelSize(for attributedText: NSAttributedString, considering maxWidth: CGFloat) -> CGSize {
        let constraintBox = CGSize(width: maxWidth, height: .greatestFiniteMagnitude)
        let rect = attributedText.boundingRect(with: constraintBox, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).integral

        return rect.size
    }
}

fileprivate extension UIEdgeInsets {
    init(top: CGFloat = 0, bottom: CGFloat = 0, left: CGFloat = 0, right: CGFloat = 0) {
        self.init(top: top, left: left, bottom: bottom, right: right)
    }
}
