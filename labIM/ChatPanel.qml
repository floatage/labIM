import QtQuick 2.10
import QtQuick.Controls 2.3
import QtQuick.Dialogs 1.3
import QtGraphicalEffects 1.0

Item{
    id: chatMsgControler

    property var panelTarget
    property var panelParent

    property int commonLeftMargin: 15

    //0:msg, 1:pic, 2:anemation
    //mid, msource, mduuid, mtype, mdata, mdate, mmode, uanme
    function appendMsg(msg){
        var bSend = (msg[1] == panelParent.localUUid)
        chatMsgControlerContentListView.model.append({
            msgSenderPic: bSend ? panelParent.localPic : (panelParent.curSeesionType == 2 ? "/img/defaultPic.jpg" : panelParent.curSeesionDestPic)
            , isGroup: panelParent.curSeesionType == 2
            , msgSenderRole: "成员"
            , msgSender: bSend ?  "我" : msg[7]
            , msgSenderUuid: msg[1]
            , isSend: bSend
            , msgType: msg[3]
            , msgRealData: msg[4]
            , msgDate: msg[5]
        })
    }

    function updateMsgModel(){
        var msgList = SessionManager.getChatMsgs(panelParent.curSeesionDestId, panelParent.curSeesionType == 2)
        chatMsgControlerContentListView.model.clear()

        for (var begin = 0; begin < msgList.length; ++begin)
            appendMsg(msgList[begin])

        chatMsgControlerContentListView.positionViewAtEnd()
    }

    Connections{
        target: panelTarget
        onCurrentSessionChanged:{
            if (panelParent.panelStackView.currentItem == panelParent.panelMap['ChatPanel']){
                chatMsgControlerDestObjectName.text = panelParent.curSessionName
                updateMsgModel()
            }
        }
    }

    Connections{
        target: DBOP
        onSessionMsgRecv: {
            console.log("Recv text and update model! session: ", panelParent.curSeesionDestId, recvMsg)

            if (recvMsg[6] == 1){
                if ((isSend ? recvMsg[2] : recvMsg[1]) != panelParent.curSeesionDestId) return
            }
            else if (recvMsg[6] == 2){
                if (recvMsg[2] != panelParent.curSeesionDestId) return
            }

            appendMsg(recvMsg)
            chatMsgControlerContentListView.positionViewAtEnd()
        }
    }

    FileDialog{
        id: picSelectFileDialog
        title: qsTr("请选择发送图片")
        selectFolder: false
        selectMultiple: false
        nameFilters: ['Pictures (*.png *.jpg *.jpeg *.bmp *.svg *.gif)']
        onAccepted: {
            if (panelParent.curSeesionDestId == "") {
                panelTarget.messageDialog.text = "请选择图片发送对象！"
                panelTarget.messageDialog.open()
                return
            }

            console.log("You chose send pic path: " + picSelectFileDialog.fileUrl)
            console.log(picSelectFileDialog.fileUrl.toString().match(/.*\.gif/) ? true : false)

            SessionManager.sendPic(panelParent.curSeesionType,
                                   panelParent.curSeesionDestId,
                                   picSelectFileDialog.fileUrl,
                                   picSelectFileDialog.fileUrl.toString().match(/.*\.gif/))
        }
    }

    FileDialog{
        id: fileSelectFileDialog
        title: qsTr("请选择发送文件")
        selectFolder: false
        selectMultiple: false
        nameFilters: ['All Files (*.*)']
        onAccepted: {
            if (panelParent.curSeesionDestId === ""){
                panelTarget.messageDialog.text = "请选择文件发送对象！"
                panelTarget.messageDialog.open()
                return
            }

            console.log("You chose send file path: " + fileSelectFileDialog.fileUrl)
            SessionManager.sendFile(panelParent.curSeesionType, panelParent.curSeesionDestId, fileSelectFileDialog.fileUrl)
        }
    }

    Column{
        anchors.fill: parent

        Rectangle {
            id: chatMsgControlerTitle
            height: parent.height / 16
            width: parent.width

            Rectangle {
                id: chatMsgControlerDestObject
                height: parent.height * 0.7
                width: parent.width * 0.5
                anchors.top: parent.top
                anchors.topMargin: parent.height * 0.13
                anchors.left: parent.left
                anchors.leftMargin: commonLeftMargin

                Label{
                    id: chatMsgControlerDestObjectName
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    horizontalAlignment: Text.AlignVCenter
                    text: "请选择通信对象"
                    font.family: "微软雅黑"
                    font.weight: Font.Thin
                    font.letterSpacing: 1
                    font.pixelSize: 15
                    renderType: Text.NativeRendering
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: "#6FF"
                anchors.left: parent.left
                anchors.bottom: parent.bottom
            }
        }

        Rectangle {
            id: chatMsgControlerContent
            height: parent.height / 16 * 10.5
            width: parent.width

            onVisibleChanged: {
                if (visible)
                    updateMsgModel()
            }

            ListView {
                id: chatMsgControlerContentListView
                width: parent.width - 20
                height: parent.height - 20
                anchors.centerIn: parent
                spacing: 15
                clip: true
                ScrollBar.vertical: ScrollBar {}

                model: ListModel{
                }

                delegate: Rectangle{
                    id: msgItem
                    width: chatMsgControlerContentListView.width + msgItemSenderPic.width
                    height: msgItemDescription.height + (msgType === 0 ? msgItemRealmsg.height : 0) + (msgType === 1 || msgType === 2 ? msgItemPic.height : 0)

                    Rectangle {
                        id: msgItemSenderPic
                        width: 36
                        height: width
                        radius: width * 0.5
                        anchors.left: parent.left

                        Image {
                            id: msgItemSenderPicImg
                            smooth: true
                            visible: false
                            antialiasing: true
                            anchors.fill: parent
                            source: msgSenderPic
                            sourceSize: Qt.size(parent.width, parent.height)
                        }

                        Rectangle{
                            id: mask
                            anchors.fill: parent
                            radius: width * 0.5
                            visible: false
                            smooth: true
                            antialiasing: true
                        }

                        OpacityMask {
                            anchors.fill: msgItemSenderPic
                            source: msgItemSenderPicImg
                            maskSource: mask
                            visible: true
                            antialiasing: true
                        }
                    }

                    Rectangle{
                        id: msgItemDescription
                        height: msgItemDescriptionText.height
                        anchors.left: msgItemSenderPic.right
                        anchors.leftMargin: 5

                        TextArea{
                            id: msgItemDescriptionText
                            font.family: "微软雅黑"
                            font.pixelSize: 12
                            font.weight: Font.Thin
                            color: "#6d757a"
                            selectByMouse: true
                            readOnly: true
                            renderType: Text.NativeRendering
                            leftPadding: 0
                            topPadding: 0
                            bottomPadding: 3
                            text: "" + (isGroup ? "【" + msgSenderRole + "】 " : " ") + msgSender + (isSend ? " ": "(" + msgSenderUuid + ") ") + msgDate
                        }
                    }

                    Rectangle {
                        id: msgItemRealmsg
                        visible: msgType === 0 ? true : false
                        width: msgItemRealmsgText.width
                        height: msgItemRealmsgText.height
                        anchors.left: msgItemDescription.left
                        anchors.top: msgItemDescription.bottom
                        radius: 4
                        color: isSend ? "#2683F5" : "#FEE"

                        TextArea{
                            id: msgItemRealmsgText
                            font.family: "微软雅黑"
                            font.pixelSize: 13
                            font.weight: Font.Thin
                            color: isSend ? "#FFF": "#333"
                            selectByMouse: true
                            selectionColor: isSend ? "#59B0E0E6": "#2683F5"
                            readOnly: true
                            leftPadding: 8
                            rightPadding: 8
                            topPadding: 6
                            bottomPadding: 6
                            renderType: Text.NativeRendering
                            anchors.centerIn: parent
                            anchors.left: parent.left
                            text: msgRealData
                        }
                    }

                    Rectangle{
                        id: msgItemPic
                        width: 12 + (msgType === 1 ? msgItemPicImg.width : 0) + (msgType === 2 ? msgItemPicAnimatedImg.width : 0)
                        height: 12 + (msgType === 1 ? msgItemPicImg.height : 0) + (msgType === 2 ? msgItemPicAnimatedImg.height : 0)
                        anchors.left: msgItemDescription.left
                        anchors.top: msgItemDescription.bottom
                        radius: 4
                        color: isSend ? "#2683F5" : "#FEE"
                        visible: msgType === 1 || msgType === 2 ? true : false

                        Image {
                            id: msgItemPicImg
                            visible: msgType === 1 ? true : false
                            asynchronous: true
                            anchors.centerIn: parent
                            source: msgType === 1 ? msgRealData : ""
                            sourceSize.width: 600
                            sourceSize.height: 400
                        }

                        AnimatedImage{
                            id: msgItemPicAnimatedImg
                            visible: msgType === 2 ? true : false
                            asynchronous: true
                            anchors.centerIn: parent
                            source: msgType === 2 ? msgRealData : ""
                        }
                    }
                }
            }
        }

        Rectangle {
            id: chatMsgControlerInputWay
            height: parent.height / 16
            width: parent.width

            Rectangle {
                id: chatMsgControlerInputWayTopline
                width: parent.width
                height: 1
                color: "#6FF"
                anchors.left: parent.left
                anchors.bottom: parent.top
            }

            Row{
                width: parent.width * 0.9
                height: parent.height * 0.7
                anchors.left: parent.left
                anchors.leftMargin: commonLeftMargin
                anchors.top: chatMsgControlerInputWayTopline.bottom
                anchors.topMargin: parent.height * 0.13

                spacing: 20

                Component {
                    id: iconItem

                    Rectangle{
                        id: iconRect
                        width: 25
                        height: 25
                        radius: 2
                        visible: false

                        signal picLoad(Image img)
                        signal iconClicked()

                        Image {
                            id:iconPic
                            anchors.centerIn: parent
                            sourceSize.width: 18
                            sourceSize.height: 18
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton

                            onExited: parent.color = "#FFF"
                            onEntered: parent.color = "#D8FAF5"
                            onPressed: parent.color = "#F8FABF"
                            onReleased: parent.color = "#D8FAF5"
                            onClicked: iconRect.iconClicked()
                        }

                        onVisibleChanged: picLoad(iconPic)
                    }
                }

                Loader {
                    id: sendTextIcon
                    sourceComponent: iconItem
                    onLoaded: item.visible = true

                    Connections{
                        target:sendTextIcon.item
                        onPicLoad: img.source = "/img/text.svg"
                        onIconClicked: {
                        }
                    }
                }

                Loader {
                    id: sendFaceIcon
                    sourceComponent: iconItem
                    onLoaded: item.visible = true

                    Connections{
                        target:sendFaceIcon.item
                        onPicLoad: img.source = "/img/Smile.svg"
                        onIconClicked: {
                        }
                    }
                }

                Loader {
                    id: sendPicIcon
                    sourceComponent: iconItem
                    onLoaded: item.visible = true

                    Connections{
                        target:sendPicIcon.item
                        onPicLoad: img.source = "/img/pic.svg"
                        onIconClicked: {
                            picSelectFileDialog.open()
                        }
                    }
                }

                Loader {
                    id: sendFileIcon
                    sourceComponent: iconItem
                    onLoaded: item.visible = true

                    Connections{
                        target:sendFileIcon.item
                        onPicLoad: img.source = "/img/folder.svg"
                        onIconClicked: {
                            fileSelectFileDialog.open()
                        }
                    }
                }
            }
        }

        Rectangle {
            id: chatMsgControlerInput
            height: parent.height / 16 * 2
            width: parent.width

            ScrollView {
                 anchors.fill: parent

                 TextArea {
                     id: chatMsgControlerInputArea
                     selectByMouse: true
                     font.family: "微软雅黑"
                     font.pixelSize: 13
                     font.weight: Font.Thin
                     color: "#333"
                     wrapMode: TextEdit.Wrap
                     renderType: Text.NativeRendering
                 }
            }
        }

        Rectangle {
            id: chatMsgControlerInputAction
            height: parent.height / 16 * 1.5
            width: parent.width

            Row{
                anchors.fill: parent
                spacing: 30
                layoutDirection: Qt.RightToLeft
                rightPadding: 30

                NormalButton {
                    id: sendMsgButton
                    reversal: true
                    buttonText: "发送"
                    onButtonClicked: {
                        if (panelParent.curSeesionDestId == ""){
                            panelTarget.messageDialog.text = "请选择消息发送对象！"
                            panelTarget.messageDialog.open()
                            return
                        }

                        var sendText = chatMsgControlerInputArea.text.replace(/^[\s\uFEFF\xA0]+|[\s\uFEFF\xA0]+$/g, '')
                        if (sendText.length !== 0){
                            SessionManager.sendChatMsg(panelParent.curSeesionType, panelParent.curSeesionDestId, sendText)
                        }
                        chatMsgControlerInputArea.clear()
                    }
                }

                NormalButton{
                    reversal: true
                    buttonText: "清空"
                    onButtonClicked: {
                        chatMsgControlerInputArea.clear()
                    }
                }
            }
        }
    }
}
