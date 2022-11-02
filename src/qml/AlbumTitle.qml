import QtQuick 2.11
import QtQuick.Window 2.11
import QtQuick.Layouts 1.11
import QtQuick.Controls 2.4
import QtQuick.Dialogs 1.3
import Qt.labs.folderlistmodel 2.11
import org.deepin.dtk 1.0

import "./Control"

Rectangle {

    anchors.top : root.top
    anchors.left : parent.left
    anchors.leftMargin: 0
    width:  root.width
    height: 50

    TitleBar {
        id : title
        anchors.fill: parent
        width: parent.width
        menu: Menu {
               x: 0; y: 0
               Action {
                   id: equalizerControl
                   text: qsTr("New album")
                   onTriggered: {
                       var x = parent.mapToGlobal(0, 0).x + parent.width / 2 - 190
                       var y = parent.mapToGlobal(0, 0).y + parent.height / 2 - 89
                       newAlbum.setX(x)
                       newAlbum.setY(y)
                       newAlbum.setNormalEdit()
                       newAlbum.show()

                   }
               }
               MenuItem {
                   id: settingsControl
                   text: qsTr("Import folders")
                   onTriggered: {
                       albumControl.createNewCustomAutoImportAlbum()
                   }
               }
               MenuSeparator { }
               ThemeMenu { }
               MenuSeparator { }
               HelpAction { }
               AboutAction {
                   aboutDialog: AboutDialog {
                       maximumWidth: 360
                       maximumHeight: 362
                       minimumWidth: 360
                       minimumHeight: 362
                       productName: qsTr("Album")
                       productIcon: "deepin-album"
                       version: qsTr("Version:") + "%1".arg(Qt.application.version)
                       description: qsTr("Album is a stylish management tool for viewing and organizing photos and videos.")
                       websiteName: DTK.deepinWebsiteName
                       websiteLink: DTK.deepinWebsiteLink
                       license: qsTr("%1 is released under %2").arg(productName).arg("GPLV3")
                   }
               }
               QuitAction { }
           }
        ActionButton {
            id: appTitleIcon
            anchors.top: parent.top
            anchors.topMargin: 0
            anchors.left: parent.left
            anchors.leftMargin: 0
            width :  50
            height : 50
            icon {
                name: "deepin-album"
                width: 36
                height: 36
            }
        }

        ToolButton {
            id: showHideleftSidebarButton
            anchors.top: parent.top
            anchors.topMargin: 0
            anchors.left: appTitleIcon.right
            anchors.leftMargin: 0
            width :   50
            height : 50
            icon {
                name: "topleft"
                width: 36
                height: 36
            }
            ToolTip.visible: hovered
            ToolTip.text: leftSidebar.x !== 0 ? qsTr("Show side pane") : qsTr("Hide side pane")
            onClicked :{
                if(leftSidebar.x !== 0 ){
                    showSliderAnimation.start()
                }
                else{
                    hideSliderAnimation.start()
                }
            }
        }

        ToolButton {
            id: range1Button
            anchors.top: parent.top
            anchors.topMargin: 0
            anchors.left: showHideleftSidebarButton.right
            anchors.leftMargin: 0/*- leftSidebar.x/2*/
            enabled: global.statusBarNumText !== ""
            width:50
            height:50
            ToolTip.visible: hovered
            ToolTip.text: icon.name === "range1" ? qsTr("Original ratio") : qsTr("Square thumbnails")
            icon { 
                name: asynImageProvider.getLoadMode() == 0 ? "range1" : "range2"
                width: 36
                height: 36
            }
            onClicked: {
                //1.图片推送器切换
                asynImageProvider.switchLoadMode()

                //切换图标
                if(icon.name === "range1"){
                    icon.name = "range2"
                }else{
                    icon.name = "range1"
                }

                //2.发送全局信号，所有的缩略图强制刷新
                global.sigThumbnailStateChange()
            }
        }

        ButtonBox {
            id: collectionBtnBox
            anchors.top: parent.top
            anchors.topMargin: 7
            anchors.left: range1Button.right
            anchors.leftMargin: 0
            height: 36
            property bool refreshVisilbe: false
            visible: global.currentViewIndex === GlobalVar.ThumbnailViewType.Collecttion && albumControl.getYears(refreshVisilbe).length !== 0

            ToolButton {
                id:yButton
                Layout.preferredHeight: parent.height
                checkable: true
                text: qsTr("Y")
                checked: true
                onClicked: {
                    thumbnailImage.setCollecttionViewIndex(0)
                }
            }
            ToolButton {
                id:mButton
                Layout.preferredHeight: parent.height
                checkable: true
                text: qsTr("M")
                onClicked: {
                    thumbnailImage.setCollecttionViewIndex(1)
                }
            }
            ToolButton {
                id:dButton
                Layout.preferredHeight: parent.height
                checkable: true
                text: qsTr("D")
                onClicked: {
                    thumbnailImage.setCollecttionViewIndex(2)
                }
            }
            ToolButton {
                id:allButton
                Layout.preferredHeight: parent.height
                checkable: true
                text: qsTr("All")
                onClicked: {
                    thumbnailImage.setCollecttionViewIndex(3)
                }
            }

            function setChecked(index) {
                switch (index) {
                case 0:
                    yButton.checked = true
                    break
                case 1:
                    mButton.checked = true
                    break
                case 2:
                    dButton.checked = true
                    break
                case 3:
                    allButton.checked = true
                    break
                }
            }

            Component.onCompleted: {
                global.sigCollectionViewIndexChanged.connect(setChecked)
            }
        }

        Connections {
            target: global
            onSigFlushSearchView: {
                searchEdit.executeSearch(true)
            }
        }

        Connections {
            target: albumControl
            onSigRefreshAllCollection: {
                if (global.currentViewIndex === GlobalVar.ThumbnailViewType.Collecttion) {
                    collectionBtnBox.refreshVisilbe = !collectionBtnBox.refreshVisilbe
                }
            }
        }

        SearchEdit{
            id: searchEdit
            placeholder: qsTr("Search")
            width: 240
            anchors.top: parent.top
            anchors.topMargin: 7
            anchors.left: parent.left
            anchors.leftMargin: ( parent.width - width )/2
            text: global.searchEditText

            property string searchKey: ""
            property int   beforeView: -1

            //先用这个顶上吧，以前的returnPressed不支持
            onAccepted: {
                executeSearch(false)
            }

            function executeSearch(bForce) {
                if(global.currentViewIndex !== GlobalVar.ThumbnailViewType.SearchResult) {
                    beforeView = global.currentViewIndex
                }

                //判重
                if(text == searchKey && global.currentViewIndex === GlobalVar.ThumbnailViewType.SearchResult && !bForce) {
                    return
                }
                searchKey = text

                //空白的时候执行退出
                if(text == "") {
                    global.currentViewIndex = beforeView
                    return
                }

                //执行搜索并切出画面
                //1.搜索
                var UID = -1
                switch(beforeView) {
                default: //搜索全库
                    break
                case 4: //搜索我的收藏
                    UID = 0
                    break
                case 5: //搜索最近删除
                    UID = -2
                    break
                case 6: //搜索指定相册
                    UID = global.currentCustomAlbumUId
                    break;
                }
                global.sigRunSearch(UID, text)

                //2.切出画面
                global.currentViewIndex = GlobalVar.ThumbnailViewType.SearchResult
            }
        }

        ToolButton {

            visible: global.selectedPaths.length === 0
            id: titleImportBtn
            anchors.top: parent.top
            anchors.topMargin: 0
            anchors.right: parent.right
            anchors.rightMargin: 4 * parent.height
            width: 50
            height: 50
            icon {
                name: "import"
                width: 36
                height: 36
            }
            onClicked :{
                importDialog.open()
            }

            Shortcut {
                enabled: global.stackControlCurrent === 0
                autoRepeat: false
                sequence : "Ctrl+O"
                onActivated : {
                   importDialog.open()
                }
            }
        }
        ToolButton {
            id: titleCollectionBtn
            property bool canFavorite: albumControl.canFavorite(global.selectedPaths,global.bRefreshFavoriteIconFlag)
            visible: !titleImportBtn.visible && global.currentViewIndex !== GlobalVar.ThumbnailViewType.Device
            anchors.top: parent.top
            anchors.topMargin: 0
            anchors.right: titleRotateBtn.left
            anchors.rightMargin: 0
            width: 50
            height: 50
            ToolTip.delay: 500
            ToolTip.timeout: 5000
            ToolTip.visible: hovered
            ToolTip.text: canFavorite ? qsTr("Favorite") : qsTr("Unfavorite")
            DciIcon.mode: DTK.ControlState.HoveredState
            icon {
                name: canFavorite ? "toolbar-collection" : "toolbar-collection2"
                width: 36
                height: 36
            }
            onClicked: {
                if (canFavorite)
                    albumControl.insertIntoAlbum(0, global.selectedPaths)
                else {
                    albumControl.removeFromAlbum(0, global.selectedPaths)
                    // 当前处于我的收藏视图，点击图片操作-取消收藏，需要重载我的收藏列表内容
                    if (global.currentViewIndex === GlobalVar.ThumbnailViewType.Favorite && global.currentCustomAlbumUId === 0) {
                        global.sigFlushCustomAlbumView(global.currentCustomAlbumUId)
                    }
                }

                global.bRefreshFavoriteIconFlag = !global.bRefreshFavoriteIconFlag
            }
        }

        ToolButton {
            id: titleRotateBtn
            visible: (titleImportBtn.visible ? false : true)
            enabled: fileControl.isRotatable(global.selectedPaths)
            ColorSelector.disabled: !fileControl.isRotatable(global.selectedPaths)
            anchors.top: parent.top
            anchors.topMargin: 0
            anchors.right:  titleTrashBtn.left
            anchors.rightMargin: 0
            width: 50
            height: 50
            ToolTip.delay: 500
            ToolTip.timeout: 5000
            ToolTip.visible: hovered
            ToolTip.text: qsTr("Rotate")
            icon {
                name: "felete"
                width: 36
                height: 36
            }
            onClicked: {
                fileControl.rotateFile(global.selectedPaths, -90)
            }
        }
        ToolButton {
            id: titleTrashBtn
            visible: (titleImportBtn.visible ? false : true)
            enabled: fileControl.isCanDelete(global.selectedPaths)
            ColorSelector.disabled: !fileControl.isCanDelete(global.selectedPaths)
            anchors.top: parent.top
            anchors.topMargin: 0
            anchors.right: parent.right
            anchors.rightMargin: 4 * parent.height
            width: 50
            height: 50
            ToolTip.delay: 500
            ToolTip.timeout: 5000
            ToolTip.visible: hovered
            ToolTip.text: qsTr("Delete")
            icon {
                name: "delete"
                width: 36
                height: 36
            }
            onClicked: {
                deleteDialog.setDisplay(GlobalVar.FileDeleteType.TrashSel, global.selectedPaths.length)
                deleteDialog.show()
            }
        }
    }

}
