import QtQuick 2.5
import QtQml 2.7
import QtQuick.Controls 2.10
import QtQuick.Layouts 1.3
import QtQuick.Controls.Styles 1.4
import QtGraphicalEffects 1.0
import QtQuick.Controls.Material 2.2

import Vedder.vesc.vescinterface 1.0
import Vedder.vesc.utility 1.0
import Vedder.vesc.commands 1.0
import Vedder.vesc.configparams 1.0

Item {
    id: rtData
    property var dialogParent: ApplicationWindow.overlay
    anchors.fill: parent
    property alias updateData: commandsUpdate.enabled

    property Commands mCommands: VescIf.commands()
    property ConfigParams mMcConf: VescIf.mcConfig()
    property int odometerValue: 0
    property double efficiency_lpf: 0
    property bool isHorizontal: rtData.width > rtData.height

    property int gaugeSize: (isHorizontal ? Math.min((height)/1.25, width / 2.5 - 20) :
                                            Math.min(width / 1.37, (height) / 2.4 - 10 ))
    property int gaugeSize2: gaugeSize * 0.55

    // ============================================================
    // USTAWIENIA DOMYŚLNE – edytuj tutaj przed wgraniem na VESC
    // ============================================================

    // Mnożnik kalibracji napięcia.
    // 1.0 = bez korekcji. Zwiększ jeśli VESC pokazuje za niskie napięcie,
    // zmniejsz jeśli pokazuje za wysokie. Dokładność: 0.001
    // Przykład: 1.022 oznacza korektę +2.2%
    readonly property real defaultVoltageCalibMultiplier: 1.0000

    // Tabela napięć ogniwa 1S [V] dla poziomów 0%, 5%, 10% ... 100%
    // 21 wartości rosnąco – zmień na krzywą swojego ogniwa
    readonly property var defaultSocVoltages: [
    //   0%     5%     10%    15%    20%    25%    30%
        3.007, 3.183, 3.323, 3.429, 3.494, 3.537, 3.583,
    //  35%    40%    45%    50%    55%    60%    65%
        3.626, 3.678, 3.728, 3.777, 3.821, 3.863, 3.896,
    //  70%    75%    80%    85%    90%    95%   100%
        3.940, 3.996, 4.041, 4.061, 4.076, 4.093, 4.200
    ]
    // ============================================================

    property real voltageCalibMultiplier: defaultVoltageCalibMultiplier
    property real calibratedVoltage: 0.0
    property int batterySeriesCells: 20
ListModel { id: socTableModel }
property var interpolatedSocVoltage: []   // 0% → 100% (101 wartości)

function populateSocTable() {
    socTableModel.clear()
    for (var i = 0; i < 21; i++) {
        socTableModel.append({ "soc": i*5, "voltage": defaultSocVoltages[i] })
    }
}

function updateInterpolatedTable() {
    interpolatedSocVoltage = new Array(101)
    for (var i = 0; i <= 100; i++) {
        var pos = i / 5.0
        var low = Math.floor(pos)
        var high = Math.ceil(pos)
        var frac = pos - low
        var vLow = socTableModel.get(low).voltage * batterySeriesCells
        var vHigh = (low === high) ? vLow : socTableModel.get(high).voltage * batterySeriesCells
        interpolatedSocVoltage[i] = vLow * (1 - frac) + vHigh * frac
    }
}

function getCustomSoc(v) {
    if (v >= interpolatedSocVoltage[100]) return 100.0
    if (v <= interpolatedSocVoltage[0]) return 0.0
    for (var p = 0; p < 100; p++) {
        if (v >= interpolatedSocVoltage[p] && v <= interpolatedSocVoltage[p+1]) {
            var frac = (v - interpolatedSocVoltage[p]) / (interpolatedSocVoltage[p+1] - interpolatedSocVoltage[p])
            return p + frac
        }
    }
    return 0.0
}
Component.onCompleted: {
    // emitEmptySetupValues removed - caused fake 45V/50% when disconnected
    populateSocTable()
    updateInterpolatedTable()
}

    // Make background slightly darker
    Rectangle {
        anchors.fill: parent
        color: {color = Utility.getAppHexColor("darkBackground")}
    }

SwipeView {
    id: swipeView
    anchors.fill: parent
    orientation: Qt.Vertical
    currentIndex: 0
    clip: true

    // === EKRAN 1 – oryginalne wskaźniki (tutaj wklejasz swój stary GridLayout) ===
    Item {
        GridLayout {
            anchors.fill: parent
            columns: isHorizontal ? 2 : 1
            columnSpacing: 0
            rowSpacing: 0

               GridLayout {
        width: parent.width
        height: parent.height
        columns: isHorizontal ? 2 : 1
        columnSpacing: 0
        rowSpacing: 0
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            Layout.rowSpan: 1
            Layout.preferredHeight: gaugeSize2*1.1
            color: "transparent"
            CustomGauge {
                id: currentGauge
                width:gaugeSize2
                height:gaugeSize2
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: -0.675*gaugeSize2
                anchors.verticalCenterOffset: 0.1*gaugeSize2
                minimumValue: -60
                maximumValue: 60
                value: 0
                labelStep: maximumValue > 60 ? 20 : 10
                nibColor: {nibColor = Utility.getAppHexColor("tertiary1")}
                unitText: "A"
                typeText: "Phase\nCurrent"
                minAngle: -210
                maxAngle: 15
                CustomGauge {
                    id: batCurrentGauge
                    width: gaugeSize2
                    height: gaugeSize2
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: gaugeSize2*1.35
                    maximumValue: 99
                    minimumValue: -60
                    minAngle: 210
                    maxAngle: -15
                    labelStep: 25
                    value: 0
                    unitText: "A"
                    typeText: "Battery\nCurrent"
                    nibColor: {nibColor = Utility.getAppHexColor("tertiary1")}
                    CustomGauge {
                        id: powerGauge
                        width: gaugeSize2*1.05
                        height: gaugeSize2*1.05
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: -0.675*gaugeSize2
                        anchors.verticalCenterOffset: -0.1*gaugeSize2
                        maximumValue: 10000
                        minimumValue: -10000
                        tickmarkScale: 0.001
                        tickmarkSuffix: "k"
                        labelStep: maximumValue > 6000 ? 2000 : 1000
                        value: 0
                        unitText: "W"
                        typeText: "Power"
                        nibColor: {nibColor = Utility.getAppHexColor("tertiary2")}
                    }
                }
            }
        }

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            Layout.preferredHeight: gaugeSize
            Layout.fillHeight: true
            color: "transparent"
            Layout.rowSpan: isHorizontal ? 3:1

            CustomGauge {
                id: speedGauge
                width: gaugeSize
                height: gaugeSize
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: (width/4 - gaugeSize2)/2
                minimumValue: 0
                maximumValue: 60
                minAngle: -225
                maxAngle: 45
                labelStep: maximumValue > 60 ? 20 : 10
                value: 0
                unitText: VescIf.useImperialUnits() ? "mph" : "km/h"
                typeText: "Speed"

                Image {
                    anchors.centerIn: parent
                    antialiasing: true
                    opacity: 0.4
                    height: parent.height*0.05
                    fillMode: Image.PreserveAspectFit
                    source: {source = "qrc" + Utility.getThemePath() + "icons/vesc-96.png"}
                    anchors.horizontalCenterOffset: (gaugeSize)/3.25 + gaugeSize2/2
                    anchors.verticalCenterOffset: -0.8*(gaugeSize)/2
                }

                Button {
                    id: button
                    anchors.centerIn:  parent
                    anchors.horizontalCenterOffset: -0.75*(gaugeSize)/2
                    anchors.verticalCenterOffset: 0.75*(gaugeSize)/2
                    onClicked: {
                        var impFact = VescIf.useImperialUnits() ? 0.621371192 : 1.0
                        odometerBox.realValue = odometerValue*impFact/1000.0
                        settingsDialog.open()
                    }

                    Dialog {
                        id: settingsDialog
                        modal: true
                        focus: true
                        width: parent.width - 20
                        height: Math.min(implicitHeight, parent.height - 60)
                        closePolicy: Popup.CloseOnEscape

                        Overlay.modal: Rectangle {
                            color: "#AA000000"
                        }

                        x: 10
                        y: Math.max((parent.height - height) / 2, 10)
                        parent: dialogParent
                        standardButtons: Dialog.Ok | Dialog.Cancel

                        onOpened: {
                            negSpeedBox.checked = VescIf.speedGaugeUseNegativeValues()
                        }

                        onAccepted: {
                            VescIf.setSpeedGaugeUseNegativeValues(negSpeedBox.checked)
                            mCommands.emitEmptySetupValues()
                        }

                        ColumnLayout {
                            id: scrollColumn
                            anchors.fill: parent

                            ScrollView {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true
                                contentWidth: parent.width

                                ColumnLayout {
                                    anchors.fill: parent
                                    spacing: 10

                                    GroupBox {
                                        title: qsTr("Update Odometer")
                                        Layout.fillWidth: true

                                        RowLayout {
                                            anchors.fill: parent

                                            DoubleSpinBox {
                                                id: odometerBox
                                                decimals: 2
                                                realFrom: 0.0
                                                realTo: 20000000
                                                Layout.fillWidth: true
                                            }

                                            Button {
                                                text: "Set"

                                                onClicked: {
                                                    var impFact = VescIf.useImperialUnits() ? 0.621371192 : 1.0
                                                    mCommands.setOdometer(Math.round(odometerBox.realValue*1000/impFact))
                                                }
                                            }
                                        }
                                    }

                                    GroupBox {
                                        title: qsTr("Settings")
                                        Layout.fillWidth: true

                                        CheckBox {
                                            id: negSpeedBox
                                            anchors.fill: parent
                                            text: "Use Negative Speed"
                                            checked: VescIf.speedGaugeUseNegativeValues()
                                        }
                                    }
                                }
                            }
                        }
                    }
                    background: Rectangle {
                        color: {color = Utility.isDarkMode() ? Utility.getAppHexColor("darkBackground") : Utility.getAppHexColor("normalBackground")}
                        opacity: button.down ? 0 : 1
                        implicitWidth: gaugeSize2*0.28
                        implicitHeight: gaugeSize2*0.28
                        radius: 400
                        Image {
                            anchors.centerIn: parent
                            antialiasing: true
                            opacity: 0.5
                            height: parent.width*0.6
                            width: height
                            source: {source = "qrc" + Utility.getThemePath() + "icons/Settings-96.png"}
                        }
                        Canvas {
                            anchors.fill: parent
                            Component.onCompleted: requestPaint()
                            property real outerRadius: parent.width/2.0;
                            property real borderWidth: outerRadius*0.1;
                            property color lightBG: {lightBG = Utility.getAppHexColor("lightestBackground")}
                            property color darkBG: {darkBG = Utility.getAppHexColor("darkBackground")}
                            onPaint: {
                                var ctx = getContext("2d");
                                //create outer gauge metal bezel effect
                                ctx.beginPath();
                                var gradient2 = ctx.createLinearGradient(parent.width,0,0 ,parent.height);
                                // Add three color stops
                                gradient2.addColorStop(1, lightBG);
                                gradient2.addColorStop(0.7, darkBG);
                                gradient2.addColorStop(0.1, lightBG);
                                ctx.strokeStyle = gradient2;
                                ctx.lineWidth = borderWidth;
                                ctx.arc(outerRadius,
                                        outerRadius,
                                        outerRadius - borderWidth/2,
                                        0, 2 * Math.PI);
                                ctx.stroke();
                                ctx.beginPath();
                                var gradient3 = ctx.createLinearGradient(parent.width,0,0 ,parent.height);
                                // Add three color stops
                                gradient3.addColorStop(1, darkBG);
                                gradient3.addColorStop(0.8, lightBG);
                                gradient3.addColorStop(0, darkBG);
                                ctx.strokeStyle = gradient3;
                                ctx.lineWidth = borderWidth;
                                ctx.arc(outerRadius,
                                        outerRadius,
                                        outerRadius - 3*borderWidth/2,
                                        0, 2 * Math.PI);
                                ctx.stroke();
                            }
                        }
                    }
                }
                CustomGauge {
                    id: batteryGauge
                    width: gaugeSize2
                    height: gaugeSize2
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: parent.width/4 + width/2
                    minAngle: -225
                    maxAngle: 45
                    minimumValue: 0
                    maximumValue: 100
                    value: 0
                    centerTextVisible: false
                    property color greenColor: {greenColor = "green"}
                    property color orangeColor: {orangeColor = Utility.getAppHexColor("orange")}
                    property color redColor: {redColor = "red"}
                    nibColor: value > 50 ? greenColor : value > 20 ? orangeColor : redColor
                    Text {
                        id: batteryLabel
                        color: {color = Utility.getAppHexColor("lightText")}
                        text: "BATTERY"
                        font.pixelSize: gaugeSize2/18.0
                        verticalAlignment: Text.AlignVCenter
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: - gaugeSize2*0.12
                        anchors.margins: 10
                        font.family:  "Roboto"
                    }
                    Text {
                        id: rangeValLabel
                        color: {color = Utility.getAppHexColor("lightText")}
                        text: "∞"
                        font.pixelSize: text === "∞"? gaugeSize2/6.3 : gaugeSize2/8.0
                        anchors.verticalCenterOffset: text === "∞"? -0.015*gaugeSize2 : 0
                        verticalAlignment: Text.AlignVCenter
                        anchors.centerIn: parent
                        anchors.margins: 10
                        font.family:  "Roboto"
                    }
                    Text {
                        id: rangeLabel
                        color: {color = Utility.getAppHexColor("lightText")}
                        text: "KM RANGE"
                        font.pixelSize: gaugeSize2/20.0
                        verticalAlignment: Text.AlignVCenter
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: gaugeSize2*0.3
                        anchors.margins: 10
                        font.family:  "Roboto"
                    }
                    Text {
                        id: battValLabel
                        color: {color = Utility.getAppHexColor("lightText")}
                        text: parseFloat(batteryGauge.value).toFixed(0) +"%"
                        font.pixelSize: gaugeSize2/12.0
                        verticalAlignment: Text.AlignVCenter
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: gaugeSize2*0.15
                        //anchors.horizontalCenterOffset: (width -parent.width)/2
                        anchors.margins: 10
                        font.family:  "Roboto"
                    }
                    Behavior on nibColor {
                        ColorAnimation {
                            duration: 1000;
                            easing.type: Easing.InOutSine
                            easing.overshoot: 3
                        }
                    }
                }
            }

            Item {
                id: voltmeterRect
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: parent.width/4 + gaugeSize2*0.18
                anchors.verticalCenterOffset: gaugeSize2*0.72
                width: gaugeSize2*0.86
                height: gaugeSize2*0.36
                z: 1

                Canvas {
                    id: voltmeterCanvas
                    anchors.fill: parent
                    property color bgColor: Utility.getAppHexColor("darkBackground")
                    property color borderColor: Utility.getAppHexColor("lightestBackground")
                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)
                        var r = 8
                        var cut = height * 0.55
                        var bw = 3

                        // --- wypełnienie ---
                        ctx.beginPath()
                        ctx.moveTo(cut, 0)
                        ctx.lineTo(width - r, 0)
                        ctx.arcTo(width, 0, width, r, r)
                        ctx.lineTo(width, height - r)
                        ctx.arcTo(width, height, width - r, height, r)
                        ctx.lineTo(r, height)
                        ctx.arcTo(0, height, 0, height - r, r)
                        ctx.lineTo(0, cut)
                        ctx.closePath()
                        ctx.fillStyle = bgColor
                        ctx.fill()

                        // --- obwódka ---
                        ctx.beginPath()
                        ctx.moveTo(cut, 0)
                        ctx.lineTo(width - r, 0)
                        ctx.arcTo(width, 0, width, r, r)
                        ctx.lineTo(width, height - r)
                        ctx.arcTo(width, height, width - r, height, r)
                        ctx.lineTo(r, height)
                        ctx.arcTo(0, height, 0, height - r, r)
                        ctx.lineTo(0, cut)
                        ctx.closePath()
                        ctx.strokeStyle = borderColor
                        ctx.lineWidth = bw
                        ctx.stroke()
                    }
                    Connections {
                        target: voltmeterRect
                        function onWidthChanged() { voltmeterCanvas.requestPaint() }
                        function onHeightChanged() { voltmeterCanvas.requestPaint() }
                    }
                }

                Text {
                    id: voltmeterValue
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: voltmeterRect.height * 0.1
                    color: {color = Utility.getAppHexColor("lightText")}
                    text: parseFloat(calibratedVoltage).toFixed(1) + " V"
                    font.pixelSize: gaugeSize2 * 0.22
                    font.bold: false
                    font.family: "Roboto"
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            Layout.preferredHeight: gaugeSize2*1.1
            Layout.rowSpan: 3
            color: "transparent"
            CustomGauge {
                id: escTempGauge
                width:gaugeSize2
                height:gaugeSize2
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: -0.675*gaugeSize2
                anchors.verticalCenterOffset: -0.1*gaugeSize2
                minimumValue: 0
                maximumValue: 100
                value: 0
                labelStep: 20
                property real throttleStartValue: 70
                property color blueColor: {blueColor = Utility.getAppHexColor("tertiary2")}
                property color orangeColor: {orangeColor = Utility.getAppHexColor("orange")}
                property color redColor: {redColor = "red"}
                nibColor: value > throttleStartValue ? redColor : (value > 40 ? orangeColor: blueColor)
                Behavior on nibColor {
                    ColorAnimation {
                        duration: 1000;
                        easing.type: Easing.InOutSine
                        easing.overshoot: 3
                    }
                }
                unitText: "°C"
                typeText: "TEMP\nESC"
                minAngle: -195
                maxAngle: 30
                CustomGauge {
                    id: motTempGauge
                    width: gaugeSize2
                    height: gaugeSize2
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: gaugeSize2*1.35
                    maximumValue: 100
                    minimumValue: 0
                    minAngle: 195
                    maxAngle: -30
                    labelStep: 20
                    value: 0
                    unitText: "°C"
                    typeText: "TEMP\nMOTOR"
                    property real throttleStartValue: 70
                    property color blueColor: {blueColor = Utility.getAppHexColor("tertiary2")}
                    property color orangeColor: {orangeColor = Utility.getAppHexColor("orange")}
                    property color redColor: {redColor = "red"}
                    nibColor: value > throttleStartValue ? redColor : (value > 40 ? orangeColor: blueColor)
                    Behavior on nibColor {
                        ColorAnimation {
                            duration: 1000;
                            easing.type: Easing.InOutSine
                            easing.overshoot: 3
                        }
                    }
                    CustomGauge {
                        id: efficiencyGauge
                        width: gaugeSize2*1.05
                        height: gaugeSize2*1.05
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: -0.675*gaugeSize2
                        anchors.verticalCenterOffset: 0.1*gaugeSize2
                        minimumValue: -50
                        maximumValue:  50
                        minAngle: -127
                        maxAngle: 127
                        labelStep: maximumValue > 60 ? 20 : 10
                        value: 0
                        unitText: VescIf.useImperialUnits() ? "Wh/mi" : "Wh/km"
                        typeText: "Consump."
                        property color blueColor: {blueColor = Utility.getAppHexColor("tertiary2")}
                        property color orangeColor: {orangeColor = Utility.getAppHexColor("orange")}
                        property color redColor: {redColor = "red"}
                        nibColor: value > 45.0 ? redColor : (value > 25.0 ? orangeColor: blueColor)
                        Text {
                            id: consumValLabel
                            color: {color = Utility.getAppHexColor("lightText")}
                            text: "0"
                            font.pixelSize: gaugeSize2*0.15
                            anchors.verticalCenterOffset: 0.265*gaugeSize2
                            verticalAlignment: Text.AlignVCenter
                            anchors.centerIn: parent
                            anchors.margins: 10
                            font.family:  "Roboto"
                            Text {
                                id: avgLabel
                                color: {color = Utility.getAppHexColor("lightText")}
                                text: "AVG"
                                font.pixelSize: gaugeSize2*0.06
                                anchors.verticalCenterOffset: 0.135*gaugeSize2
                                verticalAlignment: Text.AlignVCenter
                                anchors.centerIn: parent
                                anchors.margins: 10
                                font.family:  "Roboto"
                            }
                        }
                        Behavior on nibColor {
                            ColorAnimation {
                                duration: 100;
                                easing.type: Easing.InOutSine
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            id: textRect
            color: "transparent"
            Layout.fillWidth: true
            Layout.preferredHeight:  gaugeSize2*0.26
            Layout.alignment: Qt.AlignBottom
            Layout.rowSpan: 1
            Layout.bottomMargin: 0
            Text {
                id: odoLabel
                color: {color = Utility.getAppHexColor("lightText")}
                text: "ODOMETER"
                anchors.horizontalCenterOffset:  gaugeSize2*-2/3
                font.pixelSize: gaugeSize2/18.0
                verticalAlignment: Text.AlignVCenter
                anchors.centerIn: parent
                anchors.verticalCenterOffset: - gaugeSize2*0.12
                anchors.margins: 10
                font.family:  "Roboto"
            }
            Text {
                id: timeLabel
                color: {color = Utility.getAppHexColor("lightText")}
                text: "UP-TIME"
                anchors.horizontalCenterOffset:  gaugeSize2*2/3
                font.pixelSize: gaugeSize2/18.0
                verticalAlignment: Text.AlignVCenter
                anchors.centerIn: parent
                anchors.verticalCenterOffset: - gaugeSize2*0.12
                anchors.margins: 10
                font.family:  "Roboto"
            }
            Text {
                id: tripLabel
                color: {color = Utility.getAppHexColor("lightText")}
                text: "TRIP"
                anchors.horizontalCenterOffset:  0
                font.pixelSize: gaugeSize2/18.0
                verticalAlignment: Text.AlignVCenter
                anchors.centerIn: parent
                anchors.verticalCenterOffset: - gaugeSize2*0.12
                anchors.margins: 10
                font.family:  "Roboto"
            }
            Rectangle {
                id:clockRect
                width:2*gaugeSize2
                height: rideTime.implicitHeight + gaugeSize2*0.025
                anchors.centerIn: parent
                color: {color = Utility.getAppHexColor("darkBackground")}
                anchors.verticalCenterOffset: gaugeSize2*0.005
                border.color: {border.color = Utility.getAppHexColor("lightestBackground")}
                border.width: 1
                radius: gaugeSize2*0.03
                Text{
                    id: rideTime
                    color: {color = Utility.getAppHexColor("lightText")}
                    anchors.horizontalCenterOffset: gaugeSize2*2/3
                    text: "00:00:00"
                    font.pixelSize: gaugeSize2/10.0
                    verticalAlignment: Text.AlignVCenter
                    font.letterSpacing: gaugeSize2*0.001
                    anchors.centerIn: parent
                    anchors.margins: 10
                    font.family:  "Exan"
                }
                Glow{
                    anchors.fill: rideTime
                    radius: 0
                    samples: 9
                    color: "#55ffffff"
                    source: rideTime
                }
                Text{
                    id: odometer
                    color: {color = Utility.getAppHexColor("lightText")}
                    anchors.horizontalCenterOffset:  gaugeSize2*-2/3
                    text: "0.0"
                    font.pixelSize: gaugeSize2/10.0
                    verticalAlignment: Text.AlignVCenter
                    font.letterSpacing: gaugeSize2*0.001
                    anchors.centerIn: parent
                    anchors.margins: 10
                    font.family:  "Exan"
                }
                Glow{
                    anchors.fill: odometer
                    radius: 0
                    samples: 9
                    color: "#55ffffff"
                    source: odometer
                }
                Text{
                    id: trip
                    color: {color = Utility.getAppHexColor("lightText")}
                    anchors.horizontalCenterOffset: 0
                    text: "0.0"
                    font.pixelSize: gaugeSize2/10.0
                    verticalAlignment: Text.AlignVCenter
                    font.letterSpacing: gaugeSize2*0.001
                    anchors.centerIn: parent
                    anchors.margins: 10
                    font.family:  "Exan"
                }
                Glow{
                    anchors.fill: trip
                    radius: 0
                    samples: 9
                    color: "#55ffffff"
                    source: trip
                }
            }
        }
    } // <<< TUTAJ WLEJ CAŁY SWÓJ STARY GRIDLAYOUT (wszystko co właśnie usunąłeś) >>>
            // (od Rectangle { Layout.alignment... aż do końca Rectangle { id: textRect ... } )

        }
    }

    // === EKRAN 2 – kalibracja + tabela SOC ===
    Item {
        Rectangle {
            anchors.fill: parent
            color: Utility.getAppHexColor("darkBackground")
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15

Label {
    text: "Kalibracja i tabela SOC"
    font.pixelSize: 22
    color: Utility.getAppHexColor("lightText")
    Layout.alignment: Qt.AlignHCenter
}
GroupBox {
    title: "Mnożnik kalibracji napięcia"
    Layout.fillWidth: true

    RowLayout {
        spacing: 8
        Button {
            text: "−"
            Layout.preferredWidth: 56
            Layout.preferredHeight: 48
            font.pixelSize: 22
            onClicked: {
                var v = Math.round(voltageCalibMultiplier * 10000) - 10
                voltageCalibMultiplier = Math.max(0.9000, v / 10000.0)
                voltCalibField.text = voltageCalibMultiplier.toFixed(4)
            }
        }
        TextField {
            id: voltCalibField
            text: voltageCalibMultiplier.toFixed(4)
            validator: DoubleValidator { bottom: 0.9000; top: 1.2000; decimals: 4 }
            onEditingFinished: {
                if (acceptableInput) voltageCalibMultiplier = parseFloat(text)
                text = voltageCalibMultiplier.toFixed(4)
            }
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            font.pixelSize: 18
            horizontalAlignment: Text.AlignHCenter
        }
        Button {
            text: "+"
            Layout.preferredWidth: 56
            Layout.preferredHeight: 48
            font.pixelSize: 22
            onClicked: {
                var v = Math.round(voltageCalibMultiplier * 10000) + 10
                voltageCalibMultiplier = Math.min(1.2000, v / 10000.0)
                voltCalibField.text = voltageCalibMultiplier.toFixed(4)
            }
        }
    }
}

GroupBox {
    title: "Tabela poziomu naładowania"
    Layout.fillWidth: true
    Layout.fillHeight: true

    Flickable {
        id: socFlickable
        anchors.fill: parent
        clip: true
        contentWidth: width
        contentHeight: socGrid.implicitHeight
        flickableDirection: Flickable.VerticalFlick

        GridLayout {
            id: socGrid
            width: socFlickable.width
            columns: 6
            columnSpacing: 4
            rowSpacing: 4

                    // row 100% / 45%
                    Label {
                        Layout.preferredWidth: 44; Layout.preferredHeight: 46
                        text: "100%"; color: Utility.getAppHexColor("lightText")
                        font.pixelSize: 17; horizontalAlignment: Text.AlignRight; verticalAlignment: Text.AlignVCenter
                    }
                    TextField {
                        property int mi: 20
                        Layout.fillWidth: true; Layout.preferredHeight: 46
                        text: socTableModel.count > 20 ? parseFloat(socTableModel.get(20).voltage).toFixed(3) : "0.000"
                        font.pixelSize: 17; horizontalAlignment: Text.AlignHCenter
                        validator: DoubleValidator { bottom: 2.500; top: 4.500; decimals: 3 }
                        onEditingFinished: {
                            if (acceptableInput && socTableModel.count > mi)
                                socTableModel.setProperty(mi, "voltage", parseFloat(text))
                            if (socTableModel.count > mi)
                                text = parseFloat(socTableModel.get(mi).voltage).toFixed(3)
                        }
                    }
                    Label {
                        Layout.preferredWidth: 14; Layout.preferredHeight: 46
                        text: "V"; color: Utility.getAppHexColor("disabledText")
                        font.pixelSize: 15; verticalAlignment: Text.AlignVCenter
                    }
                    Label {
                        Layout.preferredWidth: 44; Layout.preferredHeight: 46
                        text: "45%"; color: Utility.getAppHexColor("lightText")
                        font.pixelSize: 17; horizontalAlignment: Text.AlignRight; verticalAlignment: Text.AlignVCenter
                    }
                    TextField {
                        property int mi: 9
                        Layout.fillWidth: true; Layout.preferredHeight: 46
                        visible: true
                        text: socTableModel.count > 9 ? parseFloat(socTableModel.get(9).voltage).toFixed(3) : ""
                        font.pixelSize: 17; horizontalAlignment: Text.AlignHCenter
                        validator: DoubleValidator { bottom: 2.500; top: 4.500; decimals: 3 }
                        onEditingFinished: {
                            if (9 >= 0 && acceptableInput && socTableModel.count > 9)
                                socTableModel.setProperty(9, "voltage", parseFloat(text))
                            if (9 >= 0 && socTableModel.count > 9)
                                text = parseFloat(socTableModel.get(9).voltage).toFixed(3)
                        }
                    }
                    Label {
                        Layout.preferredWidth: 14; Layout.preferredHeight: 46
                        text: "V"; color: Utility.getAppHexColor("disabledText")
                        font.pixelSize: 15; verticalAlignment: Text.AlignVCenter
                    }
                    // row 95% / 40%
                    Label {
                        Layout.preferredWidth: 44; Layout.preferredHeight: 46
                        text: "95%"; color: Utility.getAppHexColor("lightText")
                        font.pixelSize: 17; horizontalAlignment: Text.AlignRight; verticalAlignment: Text.AlignVCenter
                    }
                    TextField {
                        property int mi: 19
                        Layout.fillWidth: true; Layout.preferredHeight: 46
                        text: socTableModel.count > 19 ? parseFloat(socTableModel.get(19).voltage).toFixed(3) : "0.000"
                        font.pixelSize: 17; horizontalAlignment: Text.AlignHCenter
                        validator: DoubleValidator { bottom: 2.500; top: 4.500; decimals: 3 }
                        onEditingFinished: {
                            if (acceptableInput && socTableModel.count > mi)
                                socTableModel.setProperty(mi, "voltage", parseFloat(text))
                            if (socTableModel.count > mi)
                                text = parseFloat(socTableModel.get(mi).voltage).toFixed(3)
                        }
                    }
                    Label {
                        Layout.preferredWidth: 14; Layout.preferredHeight: 46
                        text: "V"; color: Utility.getAppHexColor("disabledText")
                        font.pixelSize: 15; verticalAlignment: Text.AlignVCenter
                    }
                    Label {
                        Layout.preferredWidth: 44; Layout.preferredHeight: 46
                        text: "40%"; color: Utility.getAppHexColor("lightText")
                        font.pixelSize: 17; horizontalAlignment: Text.AlignRight; verticalAlignment: Text.AlignVCenter
                    }
                    TextField {
                        property int mi: 8
                        Layout.fillWidth: true; Layout.preferredHeight: 46
                        visible: true
                        text: socTableModel.count > 8 ? parseFloat(socTableModel.get(8).voltage).toFixed(3) : ""
                        font.pixelSize: 17; horizontalAlignment: Text.AlignHCenter
                        validator: DoubleValidator { bottom: 2.500; top: 4.500; decimals: 3 }
                        onEditingFinished: {
                            if (8 >= 0 && acceptableInput && socTableModel.count > 8)
                                socTableModel.setProperty(8, "voltage", parseFloat(text))
                            if (8 >= 0 && socTableModel.count > 8)
                                text = parseFloat(socTableModel.get(8).voltage).toFixed(3)
                        }
                    }
                    Label {
                        Layout.preferredWidth: 14; Layout.preferredHeight: 46
                        text: "V"; color: Utility.getAppHexColor("disabledText")
                        font.pixelSize: 15; verticalAlignment: Text.AlignVCenter
                    }
                    // row 90% / 35%
                    Label {
                        Layout.preferredWidth: 44; Layout.preferredHeight: 46
                        text: "90%"; color: Utility.getAppHexColor("lightText")
                        font.pixelSize: 17; horizontalAlignment: Text.AlignRight; verticalAlignment: Text.AlignVCenter
                    }
                    TextField {
                        property int mi: 18
                        Layout.fillWidth: true; Layout.preferredHeight: 46
                        text: socTableModel.count > 18 ? parseFloat(socTableModel.get(18).voltage).toFixed(3) : "0.000"
                        font.pixelSize: 17; horizontalAlignment: Text.AlignHCenter
                        validator: DoubleValidator { bottom: 2.500; top: 4.500; decimals: 3 }
                        onEditingFinished: {
                            if (acceptableInput && socTableModel.count > mi)
                                socTableModel.setProperty(mi, "voltage", parseFloat(text))
                            if (socTableModel.count > mi)
                                text = parseFloat(socTableModel.get(mi).voltage).toFixed(3)
                        }
                    }
                    Label {
                        Layout.preferredWidth: 14; Layout.preferredHeight: 46
                        text: "V"; color: Utility.getAppHexColor("disabledText")
                        font.pixelSize: 15; verticalAlignment: Text.AlignVCenter
                    }
                    Label {
                        Layout.preferredWidth: 44; Layout.preferredHeight: 46
                        text: "35%"; color: Utility.getAppHexColor("lightText")
                        font.pixelSize: 17; horizontalAlignment: Text.AlignRight; verticalAlignment: Text.AlignVCenter
                    }
                    TextField {
                        property int mi: 7
                        Layout.fillWidth: true; Layout.preferredHeight: 46
                        visible: true
                        text: socTableModel.count > 7 ? parseFloat(socTableModel.get(7).voltage).toFixed(3) : ""
                        font.pixelSize: 17; horizontalAlignment: Text.AlignHCenter
                        validator: DoubleValidator { bottom: 2.500; top: 4.500; decimals: 3 }
                        onEditingFinished: {
                            if (7 >= 0 && acceptableInput && socTableModel.count > 7)
                                socTableModel.setProperty(7, "voltage", parseFloat(text))
                            if (7 >= 0 && socTableModel.count > 7)
                                text = parseFloat(socTableModel.get(7).voltage).toFixed(3)
                        }
                    }
                    Label {
                        Layout.preferredWidth: 14; Layout.preferredHeight: 46
                        text: "V"; color: Utility.getAppHexColor("disabledText")
                        font.pixelSize: 15; verticalAlignment: Text.AlignVCenter
                    }
                    // row 85% / 30%
                    Label {
                        Layout.preferredWidth: 44; Layout.preferredHeight: 46
                        text: "85%"; color: Utility.getAppHexColor("lightText")
                        font.pixelSize: 17; horizontalAlignment: Text.AlignRight; verticalAlignment: Text.AlignVCenter
                    }
                    TextField {
                        property int mi: 17
                        Layout.fillWidth: true; Layout.preferredHeight: 46
                        text: socTableModel.count > 17 ? parseFloat(socTableModel.get(17).voltage).toFixed(3) : "0.000"
                        font.pixelSize: 17; horizontalAlignment: Text.AlignHCenter
                        validator: DoubleValidator { bottom: 2.500; top: 4.500; decimals: 3 }
                        onEditingFinished: {
                            if (acceptableInput && socTableModel.count > mi)
                                socTableModel.setProperty(mi, "voltage", parseFloat(text))
                            if (socTableModel.count > mi)
                                text = parseFloat(socTableModel.get(mi).voltage).toFixed(3)
                        }
                    }
                    Label {
                        Layout.preferredWidth: 14; Layout.preferredHeight: 46
                        text: "V"; color: Utility.getAppHexColor("disabledText")
                        font.pixelSize: 15; verticalAlignment: Text.AlignVCenter
                    }
                    Label {
                        Layout.preferredWidth: 44; Layout.preferredHeight: 46
                        text: "30%"; color: Utility.getAppHexColor("lightText")
                        font.pixelSize: 17; horizontalAlignment: Text.AlignRight; verticalAlignment: Text.AlignVCenter
                    }
                    TextField {
                        property int mi: 6
                        Layout.fillWidth: true; Layout.preferredHeight: 46
                        visible: true
                        text: socTableModel.count > 6 ? parseFloat(socTableModel.get(6).voltage).toFixed(3) : ""
                        font.pixelSize: 17; horizontalAlignment: Text.AlignHCenter
                        validator: DoubleValidator { bottom: 2.500; top: 4.500; decimals: 3 }
                        onEditingFinished: {
                            if (6 >= 0 && acceptableInput && socTableModel.count > 6)
                                socTableModel.setProperty(6, "voltage", parseFloat(text))
                            if (6 >= 0 && socTableModel.count > 6)
                                text = parseFloat(socTableModel.get(6).voltage).toFixed(3)
                        }
                    }
                    Label {
                        Layout.preferredWidth: 14; Layout.preferredHeight: 46
                        text: "V"; color: Utility.getAppHexColor("disabledText")
                        font.pixelSize: 15; verticalAlignment: Text.AlignVCenter
                    }
                    // row 80% / 25%
                    Label {
                        Layout.preferredWidth: 44; Layout.preferredHeight: 46
                        text: "80%"; color: Utility.getAppHexColor("lightText")
                        font.pixelSize: 17; horizontalAlignment: Text.AlignRight; verticalAlignment: Text.AlignVCenter
                    }
                    TextField {
                        property int mi: 16
                        Layout.fillWidth: true; Layout.preferredHeight: 46
                        text: socTableModel.count > 16 ? parseFloat(socTableModel.get(16).voltage).toFixed(3) : "0.000"
                        font.pixelSize: 17; horizontalAlignment: Text.AlignHCenter
                        validator: DoubleValidator { bottom: 2.500; top: 4.500; decimals: 3 }
                        onEditingFinished: {
                            if (acceptableInput && socTableModel.count > mi)
                                socTableModel.setProperty(mi, "voltage", parseFloat(text))
                            if (socTableModel.count > mi)
                                text = parseFloat(socTableModel.get(mi).voltage).toFixed(3)
                        }
                    }
                    Label {
                        Layout.preferredWidth: 14; Layout.preferredHeight: 46
                        text: "V"; color: Utility.getAppHexColor("disabledText")
                        font.pixelSize: 15; verticalAlignment: Text.AlignVCenter
                    }
                    Label {
                        Layout.preferredWidth: 44; Layout.preferredHeight: 46
                        text: "25%"; color: Utility.getAppHexColor("lightText")
                        font.pixelSize: 17; horizontalAlignment: Text.AlignRight; verticalAlignment: Text.AlignVCenter
                    }
                    TextField {
                        property int mi: 5
                        Layout.fillWidth: true; Layout.preferredHeight: 46
                        visible: true
                        text: socTableModel.count > 5 ? parseFloat(socTableModel.get(5).voltage).toFixed(3) : ""
                        font.pixelSize: 17; horizontalAlignment: Text.AlignHCenter
                        validator: DoubleValidator { bottom: 2.500; top: 4.500; decimals: 3 }
                        onEditingFinished: {
                            if (5 >= 0 && acceptableInput && socTableModel.count > 5)
                                socTableModel.setProperty(5, "voltage", parseFloat(text))
                            if (5 >= 0 && socTableModel.count > 5)
                                text = parseFloat(socTableModel.get(5).voltage).toFixed(3)
                        }
                    }
                    Label {
                        Layout.preferredWidth: 14; Layout.preferredHeight: 46
                        text: "V"; color: Utility.getAppHexColor("disabledText")
                        font.pixelSize: 15; verticalAlignment: Text.AlignVCenter
                    }
                    // row 75% / 20%
                    Label {
                        Layout.preferredWidth: 44; Layout.preferredHeight: 46
                        text: "75%"; color: Utility.getAppHexColor("lightText")
                        font.pixelSize: 17; horizontalAlignment: Text.AlignRight; verticalAlignment: Text.AlignVCenter
                    }
                    TextField {
                        property int mi: 15
                        Layout.fillWidth: true; Layout.preferredHeight: 46
                        text: socTableModel.count > 15 ? parseFloat(socTableModel.get(15).voltage).toFixed(3) : "0.000"
                        font.pixelSize: 17; horizontalAlignment: Text.AlignHCenter
                        validator: DoubleValidator { bottom: 2.500; top: 4.500; decimals: 3 }
                        onEditingFinished: {
                            if (acceptableInput && socTableModel.count > mi)
                                socTableModel.setProperty(mi, "voltage", parseFloat(text))
                            if (socTableModel.count > mi)
                                text = parseFloat(socTableModel.get(mi).voltage).toFixed(3)
                        }
                    }
                    Label {
                        Layout.preferredWidth: 14; Layout.preferredHeight: 46
                        text: "V"; color: Utility.getAppHexColor("disabledText")
                        font.pixelSize: 15; verticalAlignment: Text.AlignVCenter
                    }
                    Label {
                        Layout.preferredWidth: 44; Layout.preferredHeight: 46
                        text: "20%"; color: Utility.getAppHexColor("lightText")
                        font.pixelSize: 17; horizontalAlignment: Text.AlignRight; verticalAlignment: Text.AlignVCenter
                    }
                    TextField {
                        property int mi: 4
                        Layout.fillWidth: true; Layout.preferredHeight: 46
                        visible: true
                        text: socTableModel.count > 4 ? parseFloat(socTableModel.get(4).voltage).toFixed(3) : ""
                        font.pixelSize: 17; horizontalAlignment: Text.AlignHCenter
                        validator: DoubleValidator { bottom: 2.500; top: 4.500; decimals: 3 }
                        onEditingFinished: {
                            if (4 >= 0 && acceptableInput && socTableModel.count > 4)
                                socTableModel.setProperty(4, "voltage", parseFloat(text))
                            if (4 >= 0 && socTableModel.count > 4)
                                text = parseFloat(socTableModel.get(4).voltage).toFixed(3)
                        }
                    }
                    Label {
                        Layout.preferredWidth: 14; Layout.preferredHeight: 46
                        text: "V"; color: Utility.getAppHexColor("disabledText")
                        font.pixelSize: 15; verticalAlignment: Text.AlignVCenter
                    }
                    // row 70% / 15%
                    Label {
                        Layout.preferredWidth: 44; Layout.preferredHeight: 46
                        text: "70%"; color: Utility.getAppHexColor("lightText")
                        font.pixelSize: 17; horizontalAlignment: Text.AlignRight; verticalAlignment: Text.AlignVCenter
                    }
                    TextField {
                        property int mi: 14
                        Layout.fillWidth: true; Layout.preferredHeight: 46
                        text: socTableModel.count > 14 ? parseFloat(socTableModel.get(14).voltage).toFixed(3) : "0.000"
                        font.pixelSize: 17; horizontalAlignment: Text.AlignHCenter
                        validator: DoubleValidator { bottom: 2.500; top: 4.500; decimals: 3 }
                        onEditingFinished: {
                            if (acceptableInput && socTableModel.count > mi)
                                socTableModel.setProperty(mi, "voltage", parseFloat(text))
                            if (socTableModel.count > mi)
                                text = parseFloat(socTableModel.get(mi).voltage).toFixed(3)
                        }
                    }
                    Label {
                        Layout.preferredWidth: 14; Layout.preferredHeight: 46
                        text: "V"; color: Utility.getAppHexColor("disabledText")
                        font.pixelSize: 15; verticalAlignment: Text.AlignVCenter
                    }
                    Label {
                        Layout.preferredWidth: 44; Layout.preferredHeight: 46
                        text: "15%"; color: Utility.getAppHexColor("lightText")
                        font.pixelSize: 17; horizontalAlignment: Text.AlignRight; verticalAlignment: Text.AlignVCenter
                    }
                    TextField {
                        property int mi: 3
                        Layout.fillWidth: true; Layout.preferredHeight: 46
                        visible: true
                        text: socTableModel.count > 3 ? parseFloat(socTableModel.get(3).voltage).toFixed(3) : ""
                        font.pixelSize: 17; horizontalAlignment: Text.AlignHCenter
                        validator: DoubleValidator { bottom: 2.500; top: 4.500; decimals: 3 }
                        onEditingFinished: {
                            if (3 >= 0 && acceptableInput && socTableModel.count > 3)
                                socTableModel.setProperty(3, "voltage", parseFloat(text))
                            if (3 >= 0 && socTableModel.count > 3)
                                text = parseFloat(socTableModel.get(3).voltage).toFixed(3)
                        }
                    }
                    Label {
                        Layout.preferredWidth: 14; Layout.preferredHeight: 46
                        text: "V"; color: Utility.getAppHexColor("disabledText")
                        font.pixelSize: 15; verticalAlignment: Text.AlignVCenter
                    }
                    // row 65% / 10%
                    Label {
                        Layout.preferredWidth: 44; Layout.preferredHeight: 46
                        text: "65%"; color: Utility.getAppHexColor("lightText")
                        font.pixelSize: 17; horizontalAlignment: Text.AlignRight; verticalAlignment: Text.AlignVCenter
                    }
                    TextField {
                        property int mi: 13
                        Layout.fillWidth: true; Layout.preferredHeight: 46
                        text: socTableModel.count > 13 ? parseFloat(socTableModel.get(13).voltage).toFixed(3) : "0.000"
                        font.pixelSize: 17; horizontalAlignment: Text.AlignHCenter
                        validator: DoubleValidator { bottom: 2.500; top: 4.500; decimals: 3 }
                        onEditingFinished: {
                            if (acceptableInput && socTableModel.count > mi)
                                socTableModel.setProperty(mi, "voltage", parseFloat(text))
                            if (socTableModel.count > mi)
                                text = parseFloat(socTableModel.get(mi).voltage).toFixed(3)
                        }
                    }
                    Label {
                        Layout.preferredWidth: 14; Layout.preferredHeight: 46
                        text: "V"; color: Utility.getAppHexColor("disabledText")
                        font.pixelSize: 15; verticalAlignment: Text.AlignVCenter
                    }
                    Label {
                        Layout.preferredWidth: 44; Layout.preferredHeight: 46
                        text: "10%"; color: Utility.getAppHexColor("lightText")
                        font.pixelSize: 17; horizontalAlignment: Text.AlignRight; verticalAlignment: Text.AlignVCenter
                    }
                    TextField {
                        property int mi: 2
                        Layout.fillWidth: true; Layout.preferredHeight: 46
                        visible: true
                        text: socTableModel.count > 2 ? parseFloat(socTableModel.get(2).voltage).toFixed(3) : ""
                        font.pixelSize: 17; horizontalAlignment: Text.AlignHCenter
                        validator: DoubleValidator { bottom: 2.500; top: 4.500; decimals: 3 }
                        onEditingFinished: {
                            if (2 >= 0 && acceptableInput && socTableModel.count > 2)
                                socTableModel.setProperty(2, "voltage", parseFloat(text))
                            if (2 >= 0 && socTableModel.count > 2)
                                text = parseFloat(socTableModel.get(2).voltage).toFixed(3)
                        }
                    }
                    Label {
                        Layout.preferredWidth: 14; Layout.preferredHeight: 46
                        text: "V"; color: Utility.getAppHexColor("disabledText")
                        font.pixelSize: 15; verticalAlignment: Text.AlignVCenter
                    }
                    // row 60% / 5%
                    Label {
                        Layout.preferredWidth: 44; Layout.preferredHeight: 46
                        text: "60%"; color: Utility.getAppHexColor("lightText")
                        font.pixelSize: 17; horizontalAlignment: Text.AlignRight; verticalAlignment: Text.AlignVCenter
                    }
                    TextField {
                        property int mi: 12
                        Layout.fillWidth: true; Layout.preferredHeight: 46
                        text: socTableModel.count > 12 ? parseFloat(socTableModel.get(12).voltage).toFixed(3) : "0.000"
                        font.pixelSize: 17; horizontalAlignment: Text.AlignHCenter
                        validator: DoubleValidator { bottom: 2.500; top: 4.500; decimals: 3 }
                        onEditingFinished: {
                            if (acceptableInput && socTableModel.count > mi)
                                socTableModel.setProperty(mi, "voltage", parseFloat(text))
                            if (socTableModel.count > mi)
                                text = parseFloat(socTableModel.get(mi).voltage).toFixed(3)
                        }
                    }
                    Label {
                        Layout.preferredWidth: 14; Layout.preferredHeight: 46
                        text: "V"; color: Utility.getAppHexColor("disabledText")
                        font.pixelSize: 15; verticalAlignment: Text.AlignVCenter
                    }
                    Label {
                        Layout.preferredWidth: 44; Layout.preferredHeight: 46
                        text: "5%"; color: Utility.getAppHexColor("lightText")
                        font.pixelSize: 17; horizontalAlignment: Text.AlignRight; verticalAlignment: Text.AlignVCenter
                    }
                    TextField {
                        property int mi: 1
                        Layout.fillWidth: true; Layout.preferredHeight: 46
                        visible: true
                        text: socTableModel.count > 1 ? parseFloat(socTableModel.get(1).voltage).toFixed(3) : ""
                        font.pixelSize: 17; horizontalAlignment: Text.AlignHCenter
                        validator: DoubleValidator { bottom: 2.500; top: 4.500; decimals: 3 }
                        onEditingFinished: {
                            if (1 >= 0 && acceptableInput && socTableModel.count > 1)
                                socTableModel.setProperty(1, "voltage", parseFloat(text))
                            if (1 >= 0 && socTableModel.count > 1)
                                text = parseFloat(socTableModel.get(1).voltage).toFixed(3)
                        }
                    }
                    Label {
                        Layout.preferredWidth: 14; Layout.preferredHeight: 46
                        text: "V"; color: Utility.getAppHexColor("disabledText")
                        font.pixelSize: 15; verticalAlignment: Text.AlignVCenter
                    }
                    // row 55% / 0%
                    Label {
                        Layout.preferredWidth: 44; Layout.preferredHeight: 46
                        text: "55%"; color: Utility.getAppHexColor("lightText")
                        font.pixelSize: 17; horizontalAlignment: Text.AlignRight; verticalAlignment: Text.AlignVCenter
                    }
                    TextField {
                        property int mi: 11
                        Layout.fillWidth: true; Layout.preferredHeight: 46
                        text: socTableModel.count > 11 ? parseFloat(socTableModel.get(11).voltage).toFixed(3) : "0.000"
                        font.pixelSize: 17; horizontalAlignment: Text.AlignHCenter
                        validator: DoubleValidator { bottom: 2.500; top: 4.500; decimals: 3 }
                        onEditingFinished: {
                            if (acceptableInput && socTableModel.count > mi)
                                socTableModel.setProperty(mi, "voltage", parseFloat(text))
                            if (socTableModel.count > mi)
                                text = parseFloat(socTableModel.get(mi).voltage).toFixed(3)
                        }
                    }
                    Label {
                        Layout.preferredWidth: 14; Layout.preferredHeight: 46
                        text: "V"; color: Utility.getAppHexColor("disabledText")
                        font.pixelSize: 15; verticalAlignment: Text.AlignVCenter
                    }
                    Label {
                        Layout.preferredWidth: 44; Layout.preferredHeight: 46
                        text: "0%"; color: Utility.getAppHexColor("lightText")
                        font.pixelSize: 17; horizontalAlignment: Text.AlignRight; verticalAlignment: Text.AlignVCenter
                    }
                    TextField {
                        property int mi: 0
                        Layout.fillWidth: true; Layout.preferredHeight: 46
                        visible: true
                        text: socTableModel.count > 0 ? parseFloat(socTableModel.get(0).voltage).toFixed(3) : ""
                        font.pixelSize: 17; horizontalAlignment: Text.AlignHCenter
                        validator: DoubleValidator { bottom: 2.500; top: 4.500; decimals: 3 }
                        onEditingFinished: {
                            if (0 >= 0 && acceptableInput && socTableModel.count > 0)
                                socTableModel.setProperty(0, "voltage", parseFloat(text))
                            if (0 >= 0 && socTableModel.count > 0)
                                text = parseFloat(socTableModel.get(0).voltage).toFixed(3)
                        }
                    }
                    Label {
                        Layout.preferredWidth: 14; Layout.preferredHeight: 46
                        text: "V"; color: Utility.getAppHexColor("disabledText")
                        font.pixelSize: 15; verticalAlignment: Text.AlignVCenter
                    }
                    // row 50% / None%
                    Label {
                        Layout.preferredWidth: 44; Layout.preferredHeight: 46
                        text: "50%"; color: Utility.getAppHexColor("lightText")
                        font.pixelSize: 17; horizontalAlignment: Text.AlignRight; verticalAlignment: Text.AlignVCenter
                    }
                    TextField {
                        property int mi: 10
                        Layout.fillWidth: true; Layout.preferredHeight: 46
                        text: socTableModel.count > 10 ? parseFloat(socTableModel.get(10).voltage).toFixed(3) : "0.000"
                        font.pixelSize: 17; horizontalAlignment: Text.AlignHCenter
                        validator: DoubleValidator { bottom: 2.500; top: 4.500; decimals: 3 }
                        onEditingFinished: {
                            if (acceptableInput && socTableModel.count > mi)
                                socTableModel.setProperty(mi, "voltage", parseFloat(text))
                            if (socTableModel.count > mi)
                                text = parseFloat(socTableModel.get(mi).voltage).toFixed(3)
                        }
                    }
                    Label {
                        Layout.preferredWidth: 14; Layout.preferredHeight: 46
                        text: "V"; color: Utility.getAppHexColor("disabledText")
                        font.pixelSize: 15; verticalAlignment: Text.AlignVCenter
                    }
                    Label {
                        Layout.preferredWidth: 44; Layout.preferredHeight: 46
                        text: ""; color: Utility.getAppHexColor("lightText")
                        font.pixelSize: 17; horizontalAlignment: Text.AlignRight; verticalAlignment: Text.AlignVCenter
                    }
                    TextField {
                        property int mi: -1
                        Layout.fillWidth: true; Layout.preferredHeight: 46
                        visible: false
                        text: ""
                        font.pixelSize: 17; horizontalAlignment: Text.AlignHCenter
                        validator: DoubleValidator { bottom: 2.500; top: 4.500; decimals: 3 }
                        onEditingFinished: {
                            
                        }
                    }
                    Label {
                        Layout.preferredWidth: 14; Layout.preferredHeight: 46
                        text: ""; color: Utility.getAppHexColor("disabledText")
                        font.pixelSize: 15; verticalAlignment: Text.AlignVCenter
                    }
        }
    }
}
            Button {
                text: "Przelicz tabelę do 1% i zastosuj"
                Layout.fillWidth: true
                onClicked: {
                    updateInterpolatedTable()
                    VescIf.emitStatusMessage("Tabela przeliczona do 1%", true)
                }
            }

            Label {
                text: "↓ Przesuń palcem z góry na dół aby wrócić do wskaźników"
                font.pixelSize: 14
                color: Utility.getAppHexColor("disabledText")
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }
}

// Wskaźnik stron (kropki na dole)
PageIndicator {
    anchors.bottom: parent.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    count: swipeView.count
    currentIndex: swipeView.currentIndex
}
Timer {
    id: updateTimer
    interval: 20          // 50 Hz – w zupełności wystarczy
    running: true         // lub running: updateData jeśli chcesz zachować sterowanie
    repeat: true
    onTriggered: {
        mCommands.getValuesSetup()
        // mCommands.getValuesImu()  // odkomentuj tylko jeśli używasz incline (teraz zakomentowane)
    }
}
    Connections {
        id: commandsUpdate
        target: mCommands

        property string lastFault: ""

        // onValuesImuReceived disabled - inclineCanvas removed
        // function onValuesImuReceived(values, mask) { inclineCanvas.incline = Math.tan(values.pitch) * 100 }

        function onValuesSetupReceived(values, mask) {
            var currentMaxRound = Math.ceil(mMcConf.getParamDouble("l_current_max") / 5) * 5 * values.num_vescs
            var currentMinRound = Math.floor(mMcConf.getParamDouble("l_current_min") / 5) * 5 * values.num_vescs

            if (currentMaxRound > currentGauge.maximumValue || currentMaxRound < (currentGauge.maximumValue * 0.7)) {
                currentGauge.maximumValue = currentMaxRound
                currentGauge.minimumValue = currentMinRound
            }

            currentGauge.labelStep = Math.ceil((currentMaxRound - currentMinRound) / 40) * 5
            currentGauge.value = values.current_motor
            batCurrentGauge.value = values.current_in

            // Zakres battery current: baza z ustawień mastera × num_vescs,
            // auto-rozszerzany gdy slave'y w CAN mają wyższe limity (values.current_in to już suma ze wszystkich VESC)
            var batCurrentMaxConf = Math.ceil(mMcConf.getParamDouble("l_in_current_max") / 5) * 5 * values.num_vescs
            var batCurrentMinConf = Math.floor(mMcConf.getParamDouble("l_in_current_min") / 5) * 5 * values.num_vescs

            // Auto-rozszerzanie na podstawie zmierzonego prądu (obsługuje slave'y z różnymi limitami)
            var measuredMax = Math.ceil(Math.max(values.current_in, batCurrentMaxConf) / 5) * 5
            var measuredMin = Math.floor(Math.min(values.current_in, batCurrentMinConf) / 5) * 5

            // Aktualizuj zakres gdy konfiguracja jest dostępna (> 0) lub zmierzony prąd wychodzi za zakres
            if (batCurrentMaxConf > 0) {
                var newMax = measuredMax
                var newMin = measuredMin

                // Zmniejszaj zakres tylko gdy konfiguracja jest znacznie mniejsza (hystereza 0.7×)
                if (newMax < batCurrentGauge.maximumValue * 0.7 && newMax <= batCurrentMaxConf) {
                    newMax = batCurrentMaxConf
                } else {
                    newMax = Math.max(newMax, batCurrentMaxConf)
                }
                if (newMin > batCurrentGauge.minimumValue * 0.7 && newMin >= batCurrentMinConf) {
                    newMin = batCurrentMinConf
                } else {
                    newMin = Math.min(newMin, batCurrentMinConf)
                }

                batCurrentGauge.maximumValue = newMax
                batCurrentGauge.minimumValue = newMin
                batCurrentGauge.labelStep = Math.ceil((newMax - newMin) / 40) * 5
            } else if (values.current_in > batCurrentGauge.maximumValue || values.current_in < batCurrentGauge.minimumValue) {
                // Brak konfiguracji ale prąd wychodzi poza zakres – rozszerz dynamicznie
                batCurrentGauge.maximumValue = Math.max(batCurrentGauge.maximumValue, Math.ceil(values.current_in / 5) * 5)
                batCurrentGauge.minimumValue = Math.min(batCurrentGauge.minimumValue, Math.floor(values.current_in / 5) * 5)
                batCurrentGauge.labelStep = Math.ceil((batCurrentGauge.maximumValue - batCurrentGauge.minimumValue) / 40) * 5
            }
//            voltageGauge.value = values.v_in
            var cellsFromVesc = mMcConf.getParamInt("si_battery_cells")
            if (cellsFromVesc > 0 && cellsFromVesc !== batterySeriesCells) {
                batterySeriesCells = cellsFromVesc
                updateInterpolatedTable()
            }
            var effectiveVin = values.v_in * voltageCalibMultiplier
            calibratedVoltage = effectiveVin
            var customSoc = getCustomSoc(effectiveVin)
            batteryGauge.value = customSoc

            var useImperial = VescIf.useImperialUnits()
            var useNegativeSpeedValues = VescIf.speedGaugeUseNegativeValues()

            var fl = mMcConf.getParamDouble("foc_motor_flux_linkage")
            var rpmMax = (values.v_in * 60.0) / (Math.sqrt(3.0) * 2.0 * Math.PI * fl)
            var speedFact = ((mMcConf.getParamInt("si_motor_poles") / 2.0) * 60.0 *
                             mMcConf.getParamDouble("si_gear_ratio")) /
                    (mMcConf.getParamDouble("si_wheel_diameter") * Math.PI)

            if (speedFact < 1e-3) {
                speedFact = 1e-3
            }

            var speedMax = 3.6 * rpmMax / speedFact
            var impFact = useImperial ? 0.621371192 : 1.0
            var speedMaxRound = Math.ceil((speedMax * impFact) / 10.0) * 10.0

            var dist = values.tachometer_abs / 1000.0
            var wh_consume = values.watt_hours - values.watt_hours_charged
            var wh_km_total = wh_consume / Math.max(dist , 1e-10)

            if (speedMaxRound > speedGauge.maximumValue || speedMaxRound < (speedGauge.maximumValue * 0.6) ||
                    useNegativeSpeedValues !== speedGauge.minimumValue < 0) {
                var labelStep = Math.ceil(speedMaxRound / 100) * 10

                if ((speedMaxRound / labelStep) > 30) {
                    labelStep = speedMaxRound / 30
                }

                speedGauge.labelStep = labelStep
                speedGauge.maximumValue = speedMaxRound
                speedGauge.minimumValue = useNegativeSpeedValues ? -speedMaxRound : 0
            }

            var speedNow = values.speed * 3.6 * impFact
            speedGauge.value = useNegativeSpeedValues ? speedNow : Math.abs(speedNow)

            speedGauge.unitText = useImperial ? "mph" : "km/h"

            var powerMax = Math.min(values.v_in * Math.min(mMcConf.getParamDouble("l_in_current_max"),
                                                           mMcConf.getParamDouble("l_current_max")),
                                    mMcConf.getParamDouble("l_watt_max")) * values.num_vescs
            var powerMin = Math.max(values.v_in * Math.max(mMcConf.getParamDouble("l_in_current_min"),
                                                           mMcConf.getParamDouble("l_current_min")),
                                    mMcConf.getParamDouble("l_watt_min")) * values.num_vescs
            var powerMaxRound = (Math.ceil(powerMax / 1000.0) * 1000.0)
            var powerMinRound = (Math.floor(powerMin / 1000.0) * 1000.0)

            if (powerMaxRound > powerGauge.maximumValue || powerMaxRound < (powerGauge.maximumValue * 0.6)) {
                powerGauge.maximumValue = powerMaxRound
                powerGauge.minimumValue = powerMinRound
            }

            powerGauge.value = (values.current_in * values.v_in)
            powerGauge.labelStep = Math.ceil((powerMaxRound - powerMinRound)/5000.0) * 1000.0
            var alpha = 0.05
            var efficiencyNow = Math.max( Math.min(values.current_in * values.v_in/Math.max(Math.abs(values.speed * 3.6 * impFact), 1e-6) , 60) , -60)
            efficiency_lpf = (1.0 - alpha) * efficiency_lpf + alpha *  efficiencyNow
            efficiencyGauge.value = efficiency_lpf
            efficiencyGauge.unitText = useImperial ? "WH/MI" : "WH/KM"
            if( (wh_km_total / impFact) < 999.0) {
                consumValLabel.text = parseFloat(wh_km_total / impFact).toFixed(1)
            } else {
                consumValLabel.text = "∞"
            }

            odometerValue = values.odometer
            batteryGauge.unitText = parseFloat(wh_km_total / impFact).toFixed(1) + "%"
            rangeLabel.text = useImperial ? "MI\nRANGE" : "KM\nRANGE"

            var firmwareLevel = values.battery_level
            var totalWh = (firmwareLevel > 0.001) ? (values.battery_wh / firmwareLevel) : 5000.0
            var customRemainingWh = totalWh * (customSoc / 100.0)

            if (customRemainingWh / (wh_km_total / impFact) < 999.0) {
                rangeValLabel.text = parseFloat(customRemainingWh / (wh_km_total / impFact)).toFixed(1)
            } else {
                rangeValLabel.text = "∞"
            }
            rideTime.text = new Date(values.uptime_ms).toISOString().substr(11, 8)
            odometer.text = parseFloat((values.odometer * impFact) / 1000.0).toFixed(1)
            trip.text = parseFloat((values.tachometer_abs * impFact) / 1000.0).toFixed(1)

            escTempGauge.value = values.temp_mos
            escTempGauge.maximumValue = Math.ceil(mMcConf.getParamDouble("l_temp_fet_end") / 5) * 5
            escTempGauge.throttleStartValue = Math.ceil(mMcConf.getParamDouble("l_temp_fet_start") / 5) * 5
            escTempGauge.labelStep = Math.ceil(escTempGauge.maximumValue/ 50) * 5
            motTempGauge.value = values.temp_motor
            motTempGauge.labelStep = Math.ceil(motTempGauge.maximumValue/ 50) * 5
            motTempGauge.maximumValue = Math.ceil(mMcConf.getParamDouble("l_temp_motor_end") / 5) * 5
            motTempGauge.throttleStartValue = Math.ceil(mMcConf.getParamDouble("l_temp_motor_start") / 5) * 5

            if (lastFault !== values.fault_str && values.fault_str !== "FAULT_CODE_NONE") {
                VescIf.emitStatusMessage(values.fault_str, false)
            }

            lastFault = values.fault_str
        }
    }
}