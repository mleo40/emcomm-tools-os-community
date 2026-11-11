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
            id: title1
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Welcome to EmComm Tools R7"
            font.pixelSize: 24
            font.bold: true
        }
        Image {
            id: image1
            source: "background.png"
            anchors.top: title1.bottom
            anchors.topMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(parent.width * 0.6, sourceSize.width)
            fillMode: Image.PreserveAspectFit
        }
        Text {
            anchors.top: image1.bottom
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
            id: title2
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Global User Configuration"
            font.pixelSize: 24
            font.bold: true
        }
        Image {
            id: image2
            source: "screenshots/et-user.png"
            anchors.top: title2.bottom
            anchors.topMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(parent.width * 0.6, sourceSize.width)
            fillMode: Image.PreserveAspectFit
        }
        Text {
            anchors.top: image2.bottom
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
            id: title3
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Radio Plug-and-Play"
            font.pixelSize: 24
            font.bold: true
        }
        Image {
            id: image3
            source: "screenshots/et-radio.png"
            anchors.top: title3.bottom
            anchors.topMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(parent.width * 0.6, sourceSize.width)
            fillMode: Image.PreserveAspectFit
        }
        Text {
            anchors.top: image3.bottom
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
            id: title4
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Zero Configuration"
            font.pixelSize: 24
            font.bold: true
        }
        Image {
            id: image4
            source: "screenshots/et-mode.png"
            anchors.top: title4.bottom
            anchors.topMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(parent.width * 0.6, sourceSize.width)
            fillMode: Image.PreserveAspectFit
        }
        Text {
            anchors.top: image4.bottom
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
            id: title5
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Offline HF Prediction"
            font.pixelSize: 24
            font.bold: true
        }
        Image {
            id: image5
            source: "screenshots/et-predict.png"
            anchors.top: title5.bottom
            anchors.topMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(parent.width * 0.6, sourceSize.width)
            fillMode: Image.PreserveAspectFit
        }
        Text {
            anchors.top: image5.bottom
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
            id: title6
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Radio Email"
            font.pixelSize: 24
            font.bold: true
        }
        Image {
            id: image6
            source: "screenshots/et-mail.png"
            anchors.top: title6.bottom
            anchors.topMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(parent.width * 0.6, sourceSize.width)
            fillMode: Image.PreserveAspectFit
        }
        Text {
            anchors.top: image6.bottom
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
            id: title7
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Offline Aircraft Tracking"
            font.pixelSize: 24
            font.bold: true
        }
        Image {
            id: image7
            source: "screenshots/et-aircraft.png"
            anchors.top: title7.bottom
            anchors.topMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(parent.width * 0.6, sourceSize.width)
            fillMode: Image.PreserveAspectFit
        }
        Text {
            anchors.top: image7.bottom
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
            id: title8
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Reticulum"
            font.pixelSize: 24
            font.bold: true
        }
        Image {
            id: image8
            source: "screenshots/et-reticulum.png"
            anchors.top: title8.bottom
            anchors.topMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(parent.width * 0.6, sourceSize.width)
            fillMode: Image.PreserveAspectFit
        }
        Text {
            anchors.top: image8.bottom
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
