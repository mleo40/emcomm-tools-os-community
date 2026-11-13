/* One EmComm Tools installer slide: a title, a picture and a caption. */
import QtQuick 2.0;
import calamares.slideshow 1.0;

Slide {
    property string slideTitle
    property string slideImage
    property string slideText

    Text {
        id: heading
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        text: slideTitle
        font.pixelSize: 24
        font.bold: true
    }
    Image {
        id: picture
        source: slideImage
        anchors.top: heading.bottom
        anchors.topMargin: 12
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(parent.width * 0.6, sourceSize.width)
        fillMode: Image.PreserveAspectFit
    }
    Text {
        anchors.top: picture.bottom
        anchors.topMargin: 12
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width * 0.85
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignHCenter
        text: slideText
        font.pixelSize: 14
    }
}
