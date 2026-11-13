/* EmComm Tools installer slideshow for Calamares.
 *
 * Ported one-for-one from the r7 Ubiquity slideshow
 * (overlay/usr/share/ubiquity-slideshow/slides/*.html). Each slide's layout is in
 * EtcSlide.qml.
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

    EtcSlide {
        slideTitle: "Welcome to EmComm Tools R7"
        slideImage: "background.png"
        slideText: "Built for off-grid communications and field operations, EmComm Tools provides a ready-to-use environment focused on radio, preparedness, and resilient computing. Here are just a few of the tools and capabilities included in this release."
    }

    EtcSlide {
        slideTitle: "Global User Configuration"
        slideImage: "screenshots/et-user.png"
        slideText: "EmComm Tools User Configuration allows you to specify your operator details once. Supported applications automatically use this information to provide a consistent, zero-configuration experience."
    }

    EtcSlide {
        slideTitle: "Radio Plug-and-Play"
        slideImage: "screenshots/et-radio.png"
        slideText: "et-radio supports plug-and-play configuration for several radios.\n\nOpen a terminal, run \"et-radio\", then plug in your radio.\n\nNo configuration needed for any radio-based application!"
    }

    EtcSlide {
        slideTitle: "Zero Configuration"
        slideImage: "screenshots/et-mode.png"
        slideText: "et-mode supports zero-configuration when running your favorite radio applications and modes.\n\nOpen a terminal, run \"et-mode\" and select an application.\n\nNo configuration. Just operate!\n\nFor JS8Call or fldigi, just click the desktop icons."
    }

    EtcSlide {
        slideTitle: "Offline HF Prediction"
        slideImage: "screenshots/et-predict.png"
        slideText: "et-predict provides offline HF propagation prediction powered by VOACAP, helping operators take the guesswork out of establishing targeted contacts."
    }

    EtcSlide {
        slideTitle: "Radio Email"
        slideImage: "screenshots/et-mail.png"
        slideText: "et-mail provides a streamlined experience for radio based email by taking the guesswork out of which Winlink stations to connect to by incorporating real-time, offline HF prediction. It supports switching transport modes (AX.25, ardop, VARA) with zero configuration and without leaving the application."
    }

    EtcSlide {
        slideTitle: "Offline Aircraft Tracking"
        slideImage: "screenshots/et-aircraft.png"
        slideText: "et-aircraft provides offline aircraft tracking using supported SDRs like the RTL-SDR. There is no need for an Internet connection. Just plug in your SDR and click the airplane icon on the desktop."
    }

    EtcSlide {
        slideTitle: "Reticulum"
        slideImage: "screenshots/et-reticulum.png"
        slideText: "et-reticulum provides plug-and-play support for running the Reticulum Network Stack (RNS) with zero configuration. It includes sample \"blueprint\" configurations for quickly starting a Reticulum node that can communicate over LoRa, packet radio, modem73, the Mercury HF modem, Wi-Fi, Ethernet, and even the Internet\u2014if you must.\n\nThe Heltec v4 is the officially supported LoRa device for EmComm Tools."
    }
}
