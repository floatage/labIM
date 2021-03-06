import QtQuick 2.0
import QtQuick.Controls 1.3
import QtQuick.Controls.Styles 1.3

Item {
    id: normalButton
    width: sourceButton.width
    height: sourceButton.height

    property alias buttonText: sourceButton.bText
    property real fillWidth: 30
    property real fillHeight: 18
    property real buttonTextSize: 12
    property color buttonTextColor: "#169BD5"
    property bool hasBorder: true
    property bool reversal: false

    signal buttonClicked()

    Button{
        id: sourceButton
        property string bText: "value"
        onClicked: buttonClicked()

        style: ButtonStyle {
                label: Label{
                    color: (reversal ? !control.hovered : control.hovered) ? "#FFF": buttonTextColor
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    font.family: "宋体"
                    font.pixelSize: buttonTextSize
                    text: sourceButton.bText
                }

                background: Rectangle {
                    Label{
                        id: textInfor
                        visible: false
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                        font.family: "宋体"
                        font.pixelSize: buttonTextSize
                        text: sourceButton.bText
                    }

                    implicitWidth: textInfor.contentWidth + fillWidth
                    implicitHeight: textInfor.contentHeight + fillHeight
                    radius: 10
                    border.color: (reversal ? !control.pressed : control.pressed) ? "#6FF" : "#6CF"
                    border.width: hasBorder || control.pressed ? (control.pressed ? 2 : 1) : 0
                    color: (reversal ? !control.hovered : control.hovered) ? buttonTextColor : "#FFF"
                }
        }
    }
}

