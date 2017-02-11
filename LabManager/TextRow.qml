import QtQuick 2.0
import QtQuick.Controls 1.3
import QtQuick.Controls.Styles 1.3

Item {
    id: textRow
    width: textRowCotent.width
    height: textRowCotent.height

    property alias rowText: rowLabel.text
    property color textColor: "#949494"
    property alias rSpacing: textRowCotent.spacing
    property alias tPlaceholderText: rowText.placeholderText
    property real tWidth: 120
    property bool hasButton: false
    property string bButtonText: "default"

    Row{
        id: textRowCotent
        spacing: 10

        property var rowButton: null

        Label{
            id: rowLabel
            font.family:"宋体"
            font.pixelSize:12
            color: textColor

            Component.onCompleted: {
                if (hasButton){
                    var obj = Qt.createComponent("NormalButton.qml");
                    textRowCotent.rowButton = obj.createObject(textRowCotent, {buttonText:bButtonText,hasBorder: false,fillHeight: 0,fillWidth:0})
                    textRowCotent.rowButton.anchors.verticalCenter =  rowLabel.verticalCenter
                    textRowCotent.spacing = 7
                }
            }
        }

        TextField{
            id: rowText
            anchors.verticalCenter: rowLabel.verticalCenter
            style:TextFieldStyle{
                font: rowLabel.font
                textColor: textColor
                background: Rectangle {
                      implicitWidth: tWidth - (hasButton ? textRowCotent.rowButton.width : 0)
                      implicitHeight: 20
                      border.color: "#6CF"
                      border.width: 1
                }
            }
        }
    }
}
