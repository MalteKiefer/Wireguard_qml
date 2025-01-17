import QtQuick 2.0
import QtQuick.Layouts 1.12
import Qt.labs.settings 1.0
import Ubuntu.Components 1.3 as UITK
import io.thp.pyotherside 1.3

import "../components"

UITK.Page {
    property bool isEditing: false
    property string errorMsg
    property string profileName
    property string ipAddress
    property string privateKey
    property string extraRoutes
    property string interfaceName

    property variant peers: []

    Settings {
        id: settings
        property int interfaceNumber: 0
    }
    header: UITK.PageHeader {
        id: header
        title: isEditing ? "Edit profile " + profileName : "Create a new profile"
    }

    Flickable {
        id: flick
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.top: header.bottom
        anchors.topMargin: units.gu(2)
        contentHeight: col.height
        contentWidth: width

        Column {
            id: col
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.left: parent.left
            spacing: units.gu(1.5)

            Column {
                anchors.right: parent.right
                anchors.left: parent.left
                spacing: units.gu(1.5)
                MyTextField {
                    visible: !isEditing
                    title: i18n.ctr("download icon setting", "Profile name")
                    text: profileName
                    enabled: !isEditing
                    onChanged: {
                        errorMsg = ''
                        profileName = text
                    }
                }

                MyTextField {
                    id: privateKeyField
                    title: i18n.ctr("download icon setting", "Private Key")
                    placeholder: "a2VlcCB0aGlzIHNlY3JldAo="
                    text: privateKey
                    onChanged: {
                        errorMsg = ''
                        privateKey = text
                    }
                    control: RowLayout {
                        UITK.Button {
                            id: genKey
                            text: "Generate"
                            onClicked: {
                                privateKey = python.call_sync('vpn.genkey', [])
                            }
                        }
                        UITK.Button {
                            text: "Copy pubkey"
                            enabled: privateKey
                            onClicked: {
                                const pubkey = python.call_sync(
                                                 'vpn.genpubkey', [privateKey])
                                UITK.Clipboard.push(pubkey)
                                toast.show('Public key copied to clipboard')
                            }
                        }
                    }
                }
                MyTextField {
                    title: i18n.ctr("download icon setting",
                                    "IP address (with prefix length)")
                    text: ipAddress
                    placeholder: "10.0.0.14/24"
                    onChanged: {
                        errorMsg = ''
                        ipAddress = text
                    }
                }
                // TODO: Optional
                MyTextField {
                    title: i18n.ctr("download icon ", "Extra routes")
                    text: extraRoutes
                    placeholder: "10.0.0.14/24"
                    onChanged: {
                        errorMsg = ''
                        extraRoutes = text
                    }
                }
            }

            Repeater {
                model: ListModel {
                    id: listmodel
                    dynamicRoles: true
                }
                delegate: Column {
                    id: peerCol
                    spacing: units.gu(1.5)
                    anchors.left: parent.left
                    anchors.right: parent.right
                    RowLayout {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: units.gu(2)
                        anchors.rightMargin: units.gu(2.1)
                        UITK.Label {
                            Layout.fillWidth: true
                            text: 'Peer #' + (index + 1)
                        }
                        UITK.Icon {
                            name: "delete"
                            width: units.gu(2)
                            height: units.gu(2)
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    listmodel.remove(index)
                                }
                            }
                        }
                    }

                    MyTextField {
                        title: i18n.ctr("download icon setting", "Name")
                        text: name
                        onChanged: {
                            errorMsg = ''
                            name = text
                        }
                    }
                    MyTextField {
                        title: i18n.ctr("download icon setting", "Public key")
                        placeholder: "c29tZSBzaWxseSBzdHVmZgo="
                        text: key
                        onChanged: {
                            errorMsg = ''
                            key = text
                        }
                    }
                    MyTextField {
                        title: i18n.ctr("download icon setting",
                                        "Allowed IP prefixes")
                        text: allowedPrefixes
                        onChanged: {
                            errorMsg = ''
                            allowedPrefixes = text
                        }
                        placeholder: "10.0.0.1/32, 192.168.1.0/24"
                    }

                    MyTextField {
                        title: i18n.ctr("download icon setting",
                                        "Endpoint with port")
                        text: endpoint
                        onChanged: {
                            errorMsg = ''
                            endpoint = text
                        }
                        placeholder: "vpn.example.com:1234"
                    }
                }
            }

            UITK.Button {
                text: "Add peer"
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: units.gu(2)
                anchors.rightMargin: units.gu(2)
                onClicked: {
                    listmodel.append({
                                         "name": '',
                                         "key": '',
                                         "allowedPrefixes": '',
                                         "endpoint": ''
                                     })
                }
            }
            UITK.Label {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: units.gu(2)
                anchors.rightMargin: units.gu(2)
                wrapMode: Text.WordWrap
                visible: errorMsg
                text: errorMsg
                color: 'red'
            }

            UITK.Button {
                id: save
                text: "Save profile"
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottomMargin: units.gu(2)
                anchors.leftMargin: units.gu(2)
                anchors.rightMargin: units.gu(2)
                enabled: listmodel.count && profileName && ipAddress
                         && privateKey
                onClicked: {
                    errorMsg = ''
                    let _peers = []
                    for (var i = 0; i < listmodel.count; i++) {
                        const p = listmodel.get(i)
                        _peers.push({
                                        "name": p.name,
                                        "key": p.key,
                                        "allowed_prefixes": p.allowedPrefixes,
                                        "endpoint": p.endpoint
                                    })
                    }

                    python.call('vpn.save_profile',
                                [profileName, ipAddress, privateKey, interfaceName, extraRoutes, _peers],
                                function (error) {
                                    console.log(error)
                                    if (!error) {
                                        if (!isEditing) {
                                            settings.interfaceNumber = settings.interfaceNumber + 1
                                        }
                                        stack.clear()
                                        stack.push(Qt.resolvedUrl(
                                                       "PickProfilePage.qml"))
                                        return
                                    }
                                    errorMsg = error
                                })
                }
            }
        }
    }

    Component.onCompleted: {

        for (var i = 0; i < peers.count; i++) {
            const p = peers.get(i)
            listmodel.append({
                                 "name": p.name,
                                 "key": p.key,
                                 "allowedPrefixes": p.allowed_prefixes,
                                 "endpoint": p.endpoint
                             })
        }
    }

    Python {
        id: python
        Component.onCompleted: {
            addImportPath(Qt.resolvedUrl('../../src/'))
            importModule('vpn', function () {})
        }
    }
}
