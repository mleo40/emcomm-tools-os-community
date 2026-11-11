/* EmComm Tools installer slideshow for Calamares.
 *
 * Ported one-for-one from the r7 Ubiquity slideshow
 * (overlay/usr/share/ubiquity-slideshow/slides/*.html).
 */
import QtQuick 2.0;
import calamares.slideshow 1.0;

Presentation
{
    id: presentation

    function nextSlide() {
        presentation.goToNextSlide();
    }

    Timer {
        id: advanceTimer
        interval: 10000
        running: presentation.activatedInCalamares
        repeat: true
        onTriggered: nextSlide()
    }

    Slide {
        Text {
            id: title
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Welcome to EmComm Tools R7"
            font.pixelSize: 24
            font.bold: true
        }
        Image {
            id: image
            source: "background.png"
            anchors.top: title.bottom
            anchors.topMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(parent.width * 0.6, sourceSize.width)
            fillMode: Image.PreserveAspectFit
        }
        Text {
            anchors.top: image.bottom
            anchors.topMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width * 0.85
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            text: "Built for off-grid communications and field operations, EmComm Tools provides a ready-to-use environment focused on radio, preparedness, and resilient computing. Here are just a few of the tools and capabilities included in this release."
            font.pixelSize: 14
        }
    }

    Slide {
        Text {
            id: title
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Global User Configuration"
            font.pixelSize: 24
            font.bold: true
        }
        Image {
            id: image
            source: "screenshots/et-user.png"
            anchors.top: title.bottom
            anchors.topMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(parent.width * 0.6, sourceSize.width)
            fillMode: Image.PreserveAspectFit
        }
        Text {
            anchors.top: image.bottom
            anchors.topMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width * 0.85
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            text: "EmComm Tools User Configuration allows you to specify your operator details once. Supported applications automatically use this information to provide a consistent, zero-configuration experience."
            font.pixelSize: 14
        }
    }

    Slide {
        Text {
            id: title
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Radio Plug-and-Play"
            font.pixelSize: 24
            font.bold: true
        }
        Image {
            id: image
            source: "screenshots/et-radio.png"
            anchors.top: title.bottom
            anchors.topMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(parent.width * 0.6, sourceSize.width)
            fillMode: Image.PreserveAspectFit
        }
        Text {
            anchors.top: image.bottom
            anchors.topMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width * 0.85
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            text: "et-radio supports plug-and-play configuration for several radios.\n\nOpen a terminal, run \"et-radio\", then plug in your radio.\n\nNo configuration needed for any radio-based application!"
            font.pixelSize: 14
        }
    }

    Slide {
        Text {
            id: title
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Zero Configuration"
            font.pixelSize: 24
            font.bold: true
        }
        Image {
            id: image
            source: "screenshots/et-mode.png"
            anchors.top: title.bottom
            anchors.topMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(parent.width * 0.6, sourceSize.width)
            fillMode: Image.PreserveAspectFit
        }
        Text {
            anchors.top: image.bottom
            anchors.topMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width * 0.85
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            text: "et-mode supports zero-configuration when running your favorite radio applications and modes.\n\nOpen a terminal, run \"et-mode\" and select an application.\n\nNo configuration. Just operate!\n\nFor JS8Call or fldigi, just click the desktop icons."
            font.pixelSize: 14
        }
    }

    Slide {
        Text {
            id: title
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Offline HF Prediction"
            font.pixelSize: 24
            font.bold: true
        }
        Image {
            id: image
            source: "screenshots/et-predict.png"
            anchors.top: title.bottom
            anchors.topMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(parent.width * 0.6, sourceSize.width)
            fillMode: Image.PreserveAspectFit
        }
        Text {
            anchors.top: image.bottom
            anchors.topMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width * 0.85
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            text: "et-predict provides offline HF propagation prediction powered by VOACAP, helping operators take the guesswork out of establishing targeted contacts."
            font.pixelSize: 14
        }
    }

    Slide {
        Text {
            id: title
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Radio Email"
            font.pixelSize: 24
            font.bold: true
        }
        Image {
            id: image
            source: "screenshots/et-mail.png"
            anchors.top: title.bottom
            anchors.topMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(parent.width * 0.6, sourceSize.width)
            fillMode: Image.PreserveAspectFit
        }
        Text {
            anchors.top: image.bottom
            anchors.topMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width * 0.85
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            text: "et-mail provides a streamlined experience for radio based email by taking the guesswork out of which Winlink stations to connect to by incorporating real-time, offline HF prediction. It supports switching transport modes (AX.25, ardop, VARA) with zero configuration and without leaving the application."
            font.pixelSize: 14
        }
    }

    Slide {
        Text {
            id: title
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Offline Aircraft Tracking"
            font.pixelSize: 24
            font.bold: true
        }
        Image {
            id: image
            source: "screenshots/et-aircraft.png"
            anchors.top: title.bottom
            anchors.topMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(parent.width * 0.6, sourceSize.width)
            fillMode: Image.PreserveAspectFit
        }
        Text {
            anchors.top: image.bottom
            anchors.topMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width * 0.85
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            text: "et-aircraft provides offline aircraft tracking using supported SDRs like the RTL-SDR. There is no need for an Internet connection. Just plug in your SDR and click the airplane icon on the desktop."
            font.pixelSize: 14
        }
    }

    Slide {
        Text {
            id: title
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Reticulum"
            font.pixelSize: 24
            font.bold: true
        }
        Image {
            id: image
            source: "screenshots/et-reticulum.png"
            anchors.top: title.bottom
            anchors.topMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(parent.width * 0.6, sourceSize.width)
            fillMode: Image.PreserveAspectFit
        }
        Text {
            anchors.top: image.bottom
            anchors.topMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width * 0.85
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            text: "et-reticulum provides plug-and-play support for running the Reticulum Network Stack (RNS) with zero configuration. It includes sample \"blueprint\" configurations for quickly starting a Reticulum node that can communicate over LoRa, packet radio, modem73, the Mercury HF modem, Wi-Fi, Ethernet, and even the Internet\u2014if you must.\n\nThe Heltec v4 is the officially supported LoRa device for EmComm Tools."
            font.pixelSize: 14
        }
    }
}
