#include "DownloadManager.h"
#include <QNetworkRequest>
#include <QDir>
#include <QDebug>

DownloadManager::DownloadManager(QObject *parent)
    : QObject(parent)
    , m_networkManager(new QNetworkAccessManager(this))
    , m_currentReply(nullptr)
    , m_outputFile(nullptr)
{
}

DownloadManager::~DownloadManager()
{
    if (m_outputFile) {
        m_outputFile->close();
        delete m_outputFile;
    }
}

void DownloadManager::downloadFile(const QString &url, const QString &destination)
{
    // Close previous download if any
    if (m_currentReply) {
        m_currentReply->abort();
        m_currentReply->deleteLater();
    }
    
    if (m_outputFile) {
        m_outputFile->close();
        delete m_outputFile;
    }
    
    // Create destination directory if needed
    QFileInfo fileInfo(destination);
    QDir dir = fileInfo.absoluteDir();
    if (!dir.exists()) {
        dir.mkpath(".");
    }
    
    // Open file for writing
    m_outputFile = new QFile(destination, this);
    if (!m_outputFile->open(QIODevice::WriteOnly)) {
        emit downloadError("Cannot open file for writing: " + destination);
        return;
    }
    
    m_currentDestination = destination;
    
    // Create network request
    QUrl urlObj(url);
    QNetworkRequest request(urlObj);
    request.setRawHeader("User-Agent", "WoW-Launcher/1.0");
    
    // Start download
    m_currentReply = m_networkManager->get(request);
    
    QObject::connect(m_currentReply, &QNetworkReply::downloadProgress, 
            this, &DownloadManager::onDownloadProgress);
    QObject::connect(m_currentReply, &QNetworkReply::finished, 
            this, &DownloadManager::onDownloadFinished);
    QObject::connect(m_currentReply, QOverload<QNetworkReply::NetworkError>::of(&QNetworkReply::error),
            this, &DownloadManager::onDownloadError);
    QObject::connect(m_currentReply, &QNetworkReply::readyRead, 
            this, [this]() {
                if (m_outputFile && m_currentReply) {
                    m_outputFile->write(m_currentReply->readAll());
                }
            });
}

void DownloadManager::onDownloadProgress(qint64 bytesReceived, qint64 bytesTotal)
{
    emit downloadProgress(bytesReceived, bytesTotal);
}

void DownloadManager::onDownloadFinished()
{
    if (m_currentReply->error() == QNetworkReply::NoError) {
        // Write any remaining data
        if (m_outputFile && m_currentReply) {
            m_outputFile->write(m_currentReply->readAll());
        }
        
        if (m_outputFile) {
            m_outputFile->close();
        }
        
        emit downloadFinished(m_currentDestination);
    } else {
        emit downloadError(m_currentReply->errorString());
    }
    
    m_currentReply->deleteLater();
    m_currentReply = nullptr;
    
    if (m_outputFile) {
        delete m_outputFile;
        m_outputFile = nullptr;
    }
}

void DownloadManager::onDownloadError(QNetworkReply::NetworkError error)
{
    Q_UNUSED(error);
    emit downloadError(m_currentReply->errorString());
    
    if (m_outputFile) {
        m_outputFile->close();
        delete m_outputFile;
        m_outputFile = nullptr;
    }
    
    m_currentReply->deleteLater();
    m_currentReply = nullptr;
}

