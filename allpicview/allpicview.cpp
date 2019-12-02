#include "allpicview.h"
#include <QMimeData>
#include "utils/snifferimageformat.h"

namespace {
const int VIEW_IMPORT = 0;
const int VIEW_ALLPICS = 1;
const int VIEW_SEARCH = 2;
const int VIEW_MAINWINDOW_ALLPIC = 0;
}  //namespace

AllPicView::AllPicView()
{
    setAcceptDrops(true);

    m_pStackedWidget = new DStackedWidget(this);
    m_pImportView = new ImportView();
    m_pThumbnailListView = new ThumbnailListView();
    m_pSearchView = new SearchView();
    m_pStackedWidget->addWidget(m_pImportView);
    m_pStackedWidget->addWidget(m_pThumbnailListView);
    m_pStackedWidget->addWidget(m_pSearchView);
    m_pStatusBar = new StatusBar();
    m_pStatusBar->setParent(this);
    QVBoxLayout* pVBoxLayout = new QVBoxLayout();
    pVBoxLayout->setContentsMargins(0,0,0,0);
    pVBoxLayout->addWidget(m_pStackedWidget);
    pVBoxLayout->addWidget(m_pStatusBar);
    setLayout(pVBoxLayout);
//    updateStackedWidget();
    initConnections();

//    m_spinner = new DSpinner(this);
//    m_spinner->setFixedSize(40, 40);
//    m_spinner->hide();

//    if (0 < DBManager::instance()->getImgsCount())
//    {
//        m_spinner->show();
//        m_spinner->start();
//    }
    updatePicsIntoThumbnailView();
}

void AllPicView::initConnections()
{
    connect(dApp->signalM, &SignalManager::imagesInserted, this, &AllPicView::updatePicsIntoThumbnailView);
    connect(dApp->signalM, &SignalManager::imagesRemoved, this, &AllPicView::updatePicsIntoThumbnailView);
    connect(dApp, &Application::sigFinishLoad, this, [=] {
        m_pThumbnailListView->update();
    });

    connect(m_pThumbnailListView,&ThumbnailListView::openImage,this,[=](int index){
        SignalManager::ViewInfo info;
        info.album = "";
        info.lastPanel = nullptr;
        auto imagelist = DBManager::instance()->getAllInfos();
        if(imagelist.size()>1)
        {
            for(auto image : imagelist)
            {
                info.paths<<image.filePath;
            }
        }
        else
        {
          info.paths.clear();
        }
        info.path = imagelist[index].filePath;
        info.viewType = utils::common::VIEW_ALLPIC_SRN;
        info.viewMainWindowID = VIEW_MAINWINDOW_ALLPIC;
        emit dApp->signalM->viewImage(info);
        emit dApp->signalM->showImageView(VIEW_MAINWINDOW_ALLPIC);
    });
    connect(m_pThumbnailListView,&ThumbnailListView::menuOpenImage,this,[=](QString path,QStringList paths,bool isFullScreen, bool isSlideShow){
        SignalManager::ViewInfo info;
        info.album = "";
        info.lastPanel = nullptr;
        auto imagelist = DBManager::instance()->getAllInfos();
        if(paths.size()>1)
        {
            info.paths = paths;
        }
        else
        {
            if(imagelist.size()>1)
            {
                for(auto image : imagelist)
                {
                    info.paths<<image.filePath;
                }
            }
            else
            {
              info.paths.clear();
            }
        }
        info.path = path;
        info.fullScreen = isFullScreen;
        info.slideShow = isSlideShow;
        info.viewType = utils::common::VIEW_ALLPIC_SRN;
        info.viewMainWindowID = VIEW_MAINWINDOW_ALLPIC;
        if(info.slideShow)
        {
            if(imagelist.count() == 1)
            {
                info.paths = paths;
            }

            emit dApp->signalM->startSlideShow(info);
            emit dApp->signalM->showSlidePanel(VIEW_MAINWINDOW_ALLPIC);
        }
        else {
            emit dApp->signalM->viewImage(info);
            emit dApp->signalM->showImageView(VIEW_MAINWINDOW_ALLPIC);
        }
    });
    connect(dApp->signalM, &SignalManager::sigUpdateImageLoader, this, &AllPicView::updatePicsIntoThumbnailView);
    connect(m_pStatusBar->m_pSlider, &DSlider::valueChanged, dApp->signalM, &SignalManager::sigMainwindowSliderValueChg);
    connect(m_pThumbnailListView, &ThumbnailListView::sigMouseRelease, this, &AllPicView::updatePicNum);
    connect(m_pThumbnailListView, &ThumbnailListView::customContextMenuRequested, this, &AllPicView::updatePicNum);
    connect(m_pSearchView->m_pThumbnailListView, &ThumbnailListView::sigMouseRelease, this, &AllPicView::updatePicNum);
    connect(m_pSearchView->m_pThumbnailListView, &ThumbnailListView::customContextMenuRequested, this, &AllPicView::updatePicNum);

    connect(m_pImportView->m_pImportBtn, &DPushButton::clicked, this, [=]{
        m_pStackedWidget->setCurrentIndex(VIEW_ALLPICS);
        m_pImportView->onImprotBtnClicked();
    });
    connect(m_pImportView, &ImportView::importFailedToView, this, [=]{
        updateStackedWidget();
    });
}

void AllPicView::updateStackedWidget()
{
    if (0 < DBManager::instance()->getImgsCount())
    {
        m_pStackedWidget->setCurrentIndex(VIEW_ALLPICS);
    }
    else
    {
        m_pStackedWidget->setCurrentIndex(VIEW_IMPORT);
    }
}

void AllPicView::updatePicsIntoThumbnailView()
{
    using namespace utils::image;
//    m_spinner->hide();
    QList<ThumbnailListView::ItemInfo> thumbnaiItemList;

    auto infos = DBManager::instance()->getAllInfos();
    for(auto info : infos)
    {
        ThumbnailListView::ItemInfo vi;
        vi.name = info.fileName;
        vi.path = info.filePath;
//        vi.image = dApp->m_imagemap.value(info.filePath);
        if (dApp->m_imagemap.value(info.filePath).isNull())
        {
            QSize imageSize = getImageQSize(vi.path);

            vi.width = imageSize.width();
            vi.height = imageSize.height();
        }
        else
        {
            vi.width = dApp->m_imagemap.value(info.filePath).width();
            vi.height = dApp->m_imagemap.value(info.filePath).height();
        }

        thumbnaiItemList<<vi;
    }

    m_pThumbnailListView->insertThumbnails(thumbnaiItemList);

    if(VIEW_SEARCH == m_pStackedWidget->currentIndex())
    {
        //donothing
    }
    else
    {
        updateStackedWidget();
    }

    restorePicNum();
}

void AllPicView::dragEnterEvent(QDragEnterEvent *e)
{
    e->setDropAction(Qt::CopyAction);
    e->accept();
}

void AllPicView::dropEvent(QDropEvent *event)
{
    QList<QUrl> urls = event->mimeData()->urls();
    if (urls.isEmpty()) {
        return;
    }

    using namespace utils::image;
    QStringList paths;
    for (QUrl url : urls) {
        const QString path = url.toLocalFile();
        if (QFileInfo(path).isDir()) {
            auto finfos =  getImagesInfo(path, false);
            for (auto finfo : finfos) {
                if (imageSupportRead(finfo.absoluteFilePath())) {
                    paths << finfo.absoluteFilePath();
                }
            }
        } else if (imageSupportRead(path)) {
            paths << path;
        }
    }

    if (paths.isEmpty())
    {
        return;
    }

    DBImgInfoList dbInfos;

    using namespace utils::image;

    for (auto path : paths)
    {
        if (! imageSupportRead(path)) {
            continue;
        }

//        // Generate thumbnail and storage into cache dir
//        if (! utils::image::thumbnailExist(path)) {
//            // Generate thumbnail failed, do not insert into DB
//            if (! utils::image::generateThumbnail(path)) {
//                continue;
//            }
//        }

        QFileInfo fi(path);
        DBImgInfo dbi;
        dbi.fileName = fi.fileName();
        dbi.filePath = path;
        dbi.dirHash = utils::base::hash(QString());
        dbi.time = fi.birthTime();
        dbi.changeTime = QDateTime::currentDateTime();

        dbInfos << dbi;
    }

    if (! dbInfos.isEmpty())
    {
        dApp->m_imageloader->ImportImageLoader(dbInfos);
    }
    else
    {
        emit dApp->signalM->ImportFailed();
    }

    event->accept();
}

void AllPicView::dragMoveEvent(QDragMoveEvent *event)
{
    event->accept();
}

void AllPicView::dragLeaveEvent(QDragLeaveEvent *e)
{

}

void AllPicView::resizeEvent(QResizeEvent *e)
{
//    m_spinner->move(width()/2 - 20, (height()-50)/2 - 20);
}

void AllPicView::updatePicNum()
{
    QString str = tr("%1 photo(s) selected");
    int selPicNum = 0;

    if(VIEW_ALLPICS == m_pStackedWidget->currentIndex())
    {
        QStringList paths = m_pThumbnailListView->selectedPaths();
        selPicNum = paths.length();

    }
    else if(VIEW_SEARCH == m_pStackedWidget->currentIndex())
    {
        QStringList paths = m_pSearchView->m_pThumbnailListView->selectedPaths();
        selPicNum = paths.length();
    }

    if (0 < selPicNum)
    {
        m_pStatusBar->m_pAllPicNumLabel->setText(str.arg(QString::number(selPicNum)));
    }
    else
    {
        restorePicNum();
    }
}

void AllPicView::restorePicNum()
{
    QString str = tr("%1 photo(s)");
    int selPicNum = 0;

    if(VIEW_ALLPICS == m_pStackedWidget->currentIndex())
    {
        selPicNum = DBManager::instance()->getImgsCount();
    }
    else if(VIEW_SEARCH == m_pStackedWidget->currentIndex())
    {
        selPicNum = m_pSearchView->m_searchPicNum;
    }

    m_pStatusBar->m_pAllPicNumLabel->setText(str.arg(QString::number(selPicNum)));
}
