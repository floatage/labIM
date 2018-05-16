import QtQuick 2.10
import QtQuick.Controls 2.3

DialogFrame {
    id: requestMsgRoot
    titleText: "我的请求消息"
    fileName: "RequestMsg.qml"
    viewMap: {
        "/img/executing.png": [requestMsgList, "requestMsgList", true],
        "/img/history.png":[reqHistoryList, 'reqHistoryList', false],
        "/img/settingIcon.png": [requestMsgSetting, "requestMsgSetting", false]
    }

    property color textDColor: "#5E5E5E"
    property color textUDColor: "#333"
    property real colSpacing: 35

    property string localUUid: SessionManager.getLocalUuid()

    property var requestTypePicMap: [
        "/img/fileTransferIcon.png",
        "/img/memGroupIcon_light.png",
        "/img/memGroupIcon_light.png",
        "/img/screeBctIcon.png",
        "/img/remoteHelpIcon.png"
    ]
    property var requestTypeTextMap:[
        "请求发送文件", "请求加入组",
        "邀请加入组", "请求屏幕广播",
        "请求屏幕控制"
    ]
    property var requestStateTextMap:[
        "等待中", "请求已同意",
        "请求已拒绝", "请求已取消",
        "请求超时", "未知错误"
    ]
    property var requestPassiveStateTextMap:[
        "等待中", "对方已同意",
        "对方已拒绝", "对方已取消",
        "请求超时", "未知错误"
    ]

    function updateRequestModel(){
        //rid,rtype,rdata,rstate,rdate,rsource,rdest,uname
        var reqList = UserReuqestManager.listWaitingRequest()
        waitingReqModel.clear()
        for (var begin = 0; begin < reqList.length; ++begin){
            //rid, rtype, sourceId, sourceName, rdata
            waitingReqModel.append({
                rid: reqList[begin][0]
                , rtype: reqList[begin][1]
                , sourceId: reqList[begin][6]
                , sourceName: reqList[begin][7]
                , rdata: reqList[begin][2]
                , rstate: reqList[begin][3]
                , isSend: reqList[begin][5] == localUUid ? true : false
                , isRecv: reqList[begin][6] == localUUid ? true : false
            })
        }
    }

    function insertReqToModel(req){
        waitingReqModel.append({
            rid: req["rid"]
            , rtype: req["rtype"]
            , sourceId: req["rsource"]
            , sourceName: req["uname"]
            , rdata: req["rdata"]
            , rstate: req["rstate"]
            , isSend: req["rsource"] == localUUid ? true : false
            , isRecv: req["rdest"] == localUUid ? true : false
        })
    }

    ListModel{
        id: waitingReqModel
    }

    Component {
        id: requestMsgList

        Item {
            width: parent.width
            height: parent.height

            Rectangle {
                width: parent.width * 0.85
                height: parent.height * 0.9
                anchors.centerIn: parent

                ListView {
                    id: curRequestMsgView
                    anchors.fill: parent
                    spacing: 10

                    Component.onCompleted: {
                        updateRequestModel()
                    }

                    model: waitingReqModel

                    delegate: Item {
                        width: parent.width
                        height: 40

                        Image {
                            id: requestType
                            width: 26
                            height: 22
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            source: requestMsgRoot.requestTypePicMap[rtype]
                        }

                        TextArea {
                            function getReqStr(){
                                var reqInfor = sourceName + "(" + sourceId + ")" + requestMsgRoot.requestTypeTextMap[rtype]
                                if (rtype == 0){
                                    var data = JSON.parse(rdata)
                                    reqInfor += data["fileName"] + "(" + Math.round(data["fileSize"]/1024) + "kb)"
                                }

                                return reqInfor
                            }

                            id: requestInforText
                            width: parent.width - requestType.sourceSize.width - anchors.leftMargin
                            anchors.left: requestType.right
                            anchors.top: parent.top
                            anchors.topMargin: 3
                            anchors.leftMargin: 5
                            font.family: "宋体"
                            color: textDColor
                            font.pixelSize: 11
                            renderType: Text.NativeRendering
                            text: getReqStr()

                            verticalAlignment: Text.AlignTop
                            selectByMouse: true
                            readOnly: true
                            hoverEnabled: true
                            clip: true

                            ToolTip {
                                delay: 0
                                visible: requestInforText.hovered
                                text: requestInforText.text
                            }
                        }

                        Flow {
                            id: reqActionArea
                            width:requestInforText.width
                            spacing: 3
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 2
                            anchors.right: requestInforText.right
                            layoutDirection: Qt.RightToLeft

                            NormalButton{
                                visible: isRecv ? true : false
                                buttonText: "同意"
                                hasBorder: false
                                buttonTextSize: 11
                                fillHeight: 0
                                fillWidth:0
                                onButtonClicked: {
                                    UserReuqestManager.agreeRequest(rid, sourceId)
                                    waitingReqModel.remove(index)
                                }
                            }

                            NormalButton{
                                visible: isRecv ? true : false
                                buttonTextSize: 11
                                buttonText: "拒绝"
                                hasBorder: false
                                fillHeight: 0
                                fillWidth:0

                                onButtonClicked: {
                                    UserReuqestManager.rejectRequest(rid, sourceId)
                                    waitingReqModel.remove(index)
                                }
                            }

                            NormalButton{
                                visible: isSend ? true : false
                                buttonTextSize: 11
                                buttonText: "取消"
                                hasBorder: false
                                fillHeight: 0
                                fillWidth:0

                                onButtonClicked: {
                                    UserReuqestManager.cancelRequest(rid, sourceId)
                                    waitingReqModel.remove(index)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: reqHistoryList

        Item {
            width: parent.width
            height: parent.height

            Rectangle {
                width: parent.width * 0.85
                height: parent.height * 0.9
                anchors.centerIn: parent

                ListView {
                    id: reqHistoryView
                    anchors.fill: parent
                    spacing: 10

                    Component.onCompleted: {
                        //rid,rtype,rdata,rstate,rdate,rsource,rdest,uname
                        var reqList = UserReuqestManager.listHandledRequest()
                        for (var begin = 0; begin < reqList.length; ++begin){
                            //rid, rtype, sourceId, sourceName, rdata
                            model.append({
                                rid: reqList[begin][0]
                                , rtype: reqList[begin][1]
                                , sourceId: reqList[begin][6]
                                , sourceName: reqList[begin][7]
                                , rdata: reqList[begin][2]
                                , rstate: reqList[begin][3]
                                , rdate: reqList[begin][4]
                                , isSend: reqList[begin][5] == localUUid ? true : false
                            })
                        }
                    }

                    model: ListModel{
                    }

                    delegate: Item {
                        width: parent.width
                        height: 40

                        Image {
                            id: requestType
                            width: 26
                            height: 22
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            source: requestMsgRoot.requestTypePicMap[rtype]
                        }

                        TextArea {
                            function getReqStr(){
                                var reqInfor = sourceName + "(" + sourceId + ")" + requestMsgRoot.requestTypeTextMap[rtype]
                                if (rtype == 0){
                                    var data = JSON.parse(rdata)
                                    reqInfor += data["fileName"] + "(" + Math.round(data["fileSize"]/1024) + "kb)"
                                }

                                return reqInfor
                            }

                            id: requestInforText
                            width: parent.width - requestType.width - anchors.leftMargin
                            anchors.left: requestType.right
                            anchors.top: parent.top
                            anchors.topMargin: 3
                            anchors.leftMargin: 5
                            font.family: "宋体"
                            renderType: Text.NativeRendering
                            color: textDColor
                            font.pixelSize: 11
                            text: getReqStr()

                            verticalAlignment: Text.AlignTop
                            selectByMouse: true
                            readOnly: true
                            hoverEnabled: true
                            clip: true

                            ToolTip {
                                delay: 0
                                visible: requestInforText.hovered
                                text: requestInforText.text
                            }
                        }

                        Rectangle {
                            id: reqStateArea
                            width: requestInforText.width - 10
                            height: 15
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 3

                            Label{
                                anchors.left: parent.left
                                font.family: "宋体"
                                color: textDColor
                                font.pixelSize: 11
                                renderType: Text.NativeRendering
                                text: rdate.slice(5, 16)
                            }

                            Label{
                                anchors.right: parent.right
                                font.family: "宋体"
                                color: "#69F"
                                font.pixelSize: 11
                                renderType: Text.NativeRendering
                                text: isSend ? requestMsgRoot.requestStateTextMap[rstate] : requestMsgRoot.requestPassiveStateTextMap[rstate]
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: requestMsgSetting

        Item {
            width: parent.width
            height: parent.height

            Rectangle {
                id: requestMsgSettingRoot
                width: parent.width * 0.85
                height: parent.height * 0.9
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.leftMargin: parent.width * 0.075
                anchors.topMargin: parent.height * 0.07

                Column {
                    width: parent.width
                    height: parent.height
                    spacing: colSpacing

                    NormalCheckbox {
                        checkboxText: "允许自动接受请求"
                    }

                    NormalCheckbox {
                        checkboxText: "允许开启器请求提示音"
                    }

                    Row {
                        width: parent.width

                        Rectangle {
                            width: (parent.width - requestMsgSettingButton.width) * 0.5
                            height: parent.height
                        }

                        NormalButton {
                            id: requestMsgSettingButton
                            buttonText: "应 用 设 置"
                        }
                    }
                }
            }
        }
    }
}
