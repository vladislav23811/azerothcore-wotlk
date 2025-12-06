#include "LauncherCore.h"
#include <QDir>
#include <QFileInfo>
#include <QProcess>
#include <QStandardPaths>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonParseError>
#include <QMessageBox>
#include <QDebug>
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QEventLoop>
#include <QZipReader>
#include <QDirIterator>

LauncherCore::LauncherCore(QObject *parent)
    : QObject(parent)
    , m_isDownloading(false)
{
    m_settings = new QSettings("ProgressiveSystems", "WoWLauncher", this);
    m_downloadManager = new DownloadManager(this);
    
    loadConfig();
    setupConnections();
}

void LauncherCore::setupConnections()
{
    connect(m_downloadManager, &DownloadManager::downloadProgress, 
            this, &LauncherCore::onDownloadProgress);
    connect(m_downloadManager, &DownloadManager::downloadFinished, 
            this, &LauncherCore::onDownloadFinished);
    connect(m_downloadManager, &DownloadManager::downloadError, 
            this, &LauncherCore::onDownloadError);
}

LauncherCore::~LauncherCore()
{
}

void LauncherCore::loadConfig()
{
    // Try to load from JSON config file first
    QFile configFile("launcher_config.json");
    if (configFile.open(QIODevice::ReadOnly)) {
        QByteArray data = configFile.readAll();
        QJsonParseError error;
        QJsonDocument doc = QJsonDocument::fromJson(data, &error);
        
        if (error.error == QJsonParseError::NoError && doc.isObject()) {
            QJsonObject obj = doc.object();
            m_gamePath = obj["wow_path"].toString();
            m_serverUrl = obj["server_url"].toString();
            m_gameZipUrl = obj["game_zip_url"].toString();
            m_patchVersionUrl = obj["patch_version_url"].toString();
            m_patchDownloadUrl = obj["patch_download_url"].toString();
            configFile.close();
            return;
        }
    }
    
    // Fallback to QSettings or defaults
    m_gamePath = m_settings->value("gamePath", "C:/WoW").toString();
    m_serverUrl = m_settings->value("serverUrl", "http://localhost").toString();
    // Game is now in extracted folder, not ZIP
    m_gameZipUrl = m_settings->value("gameZipUrl", m_serverUrl + "/WoW/").toString();
    m_patchVersionUrl = m_settings->value("patchVersionUrl", m_serverUrl + "/patches/version.txt").toString();
    m_patchDownloadUrl = m_settings->value("patchDownloadUrl", m_serverUrl + "/patches/latest/patch-Z.MPQ").toString();
}

void LauncherCore::saveConfig()
{
    QJsonObject obj;
    obj["wow_path"] = m_gamePath;
    obj["server_url"] = m_serverUrl;
    obj["game_zip_url"] = m_gameZipUrl;
    obj["patch_version_url"] = m_patchVersionUrl;
    obj["patch_download_url"] = m_patchDownloadUrl;
    
    QJsonDocument doc(obj);
    QFile configFile("launcher_config.json");
    if (configFile.open(QIODevice::WriteOnly)) {
        configFile.write(doc.toJson());
        configFile.close();
    }
    
    // Also save to QSettings
    m_settings->setValue("gamePath", m_gamePath);
    m_settings->setValue("serverUrl", m_serverUrl);
}

QString LauncherCore::getGamePath() const
{
    return m_gamePath;
}

void LauncherCore::setGamePath(const QString &path)
{
    m_gamePath = path;
    saveConfig();
}

QString LauncherCore::getServerUrl() const
{
    return m_serverUrl;
}

void LauncherCore::setServerUrl(const QString &url)
{
    m_serverUrl = url;
    saveConfig();
}

bool LauncherCore::isGameInstalled() const
{
    if (m_gamePath.isEmpty())
        return false;
    
    QFileInfo wowExe(m_gamePath + "/Wow.exe");
    return wowExe.exists();
}

QString LauncherCore::getPatchVersion() const
{
    return getLocalPatchVersion();
}

QString LauncherCore::getLocalPatchVersion() const
{
    QString patchFile = m_gamePath + "/Data/patch-Z.MPQ";
    QFileInfo fileInfo(patchFile);
    
    if (fileInfo.exists()) {
        // Use file modification time as version
        return QString::number(fileInfo.lastModified().toSecsSinceEpoch());
    }
    
    return "0";
}

QString LauncherCore::getServerPatchVersion() const
{
    // Make synchronous HTTP request (in real app, use async)
    QNetworkAccessManager manager;
    QNetworkRequest request(QUrl(m_patchVersionUrl));
    QNetworkReply *reply = manager.get(request);
    
    QEventLoop loop;
    connect(reply, &QNetworkReply::finished, &loop, &QEventLoop::quit);
    loop.exec();
    
    if (reply->error() == QNetworkReply::NoError) {
        QString version = QString::fromUtf8(reply->readAll()).trimmed();
        reply->deleteLater();
        return version;
    }
    
    reply->deleteLater();
    return "";
}

void LauncherCore::checkForUpdates()
{
    emit statusUpdated("Checking for updates...");
    
    // Check if game is installed
    if (!isGameInstalled()) {
        emit statusUpdated("Game not installed. Please install first.");
        return;
    }
    
    // Check for patch updates
    QString localVersion = getLocalPatchVersion();
    emit statusUpdated(QString("Local patch version: %1").arg(localVersion));
    
    // Get server version
    QString serverVersion = getServerPatchVersion();
    if (serverVersion.isEmpty()) {
        emit statusUpdated("Could not connect to server. Check server URL in settings.");
        return;
    }
    
    emit statusUpdated(QString("Server patch version: %1").arg(serverVersion));
    
    // Compare versions
    bool needsUpdate = false;
    if (localVersion == "0") {
        needsUpdate = true;
    } else {
        // Compare timestamps (server version should be timestamp)
        qint64 local = localVersion.toLongLong();
        qint64 server = serverVersion.toLongLong();
        needsUpdate = server > local;
    }
    
    if (needsUpdate) {
        emit statusUpdated("New patch available! Downloading...");
        QString patchPath = m_gamePath + "/Data/patch-Z.MPQ";
        
        // Create Data directory if needed
        QDir dataDir(m_gamePath + "/Data");
        if (!dataDir.exists()) {
            dataDir.mkpath(".");
        }
        
        m_isDownloading = true;
        m_currentDownload = "patch";
        m_downloadManager->downloadFile(m_patchDownloadUrl, patchPath);
    } else {
        emit statusUpdated("Patch is up to date.");
        emit progressUpdated(100, "Ready");
    }
}

void LauncherCore::launchGame()
{
    if (!isGameInstalled()) {
        emit errorOccurred("Game is not installed!");
        return;
    }
    
    QString wowExe = m_gamePath + "/Wow.exe";
    QFileInfo exeInfo(wowExe);
    
    if (!exeInfo.exists()) {
        emit errorOccurred("WoW executable not found: " + wowExe);
        return;
    }
    
    emit statusUpdated("Launching WoW...");
    
    QProcess *process = new QProcess(this);
    process->setWorkingDirectory(m_gamePath);
    process->start(wowExe);
    
    if (process->waitForStarted(3000)) {
        emit statusUpdated("WoW launched successfully!");
        emit gameLaunched();
    } else {
        emit errorOccurred("Failed to launch WoW: " + process->errorString());
    }
}

void LauncherCore::installGame()
{
    emit statusUpdated("Starting game installation...");
    
    // Download from extracted folder on server
    // Server should have game extracted at: http://server/WoW/
    QString gameFolderUrl = m_serverUrl;
    if (!gameFolderUrl.endsWith("/")) {
        gameFolderUrl += "/";
    }
    gameFolderUrl += "WoW/";
    
    emit statusUpdated("Downloading game files from server...");
    emit progressUpdated(0, "Preparing download...");
    
    // Download game files from extracted folder
    downloadGameFromFolder(gameFolderUrl);
}

void LauncherCore::downloadGameFromFolder(const QString &baseUrl)
{
    // Create game directory
    QDir gameDir(m_gamePath);
    if (!gameDir.exists()) {
        gameDir.mkpath(".");
    }
    
    emit statusUpdated("Downloading game files...");
    
    // List of critical files to download
    // In a real implementation, you'd get a file list from server
    // For now, we'll download key files
    QStringList criticalFiles = {
        "Wow.exe",
        "Data/enUS/patch-enUS.MPQ",
        "Data/patch.MPQ"
    };
    
    // For simplicity, we'll download files one by one
    // In production, you'd want to:
    // 1. Get file list from server (filelist.txt or similar)
    // 2. Download files in parallel
    // 3. Show progress
    
    m_isDownloading = true;
    m_currentDownload = "game";
    
    // Download critical files
    int totalFiles = criticalFiles.size();
    int downloaded = 0;
    
    for (const QString &file : criticalFiles) {
        QString fileUrl = baseUrl + file;
        QString localPath = m_gamePath + "/" + file;
        
        // Create directory if needed
        QFileInfo fileInfo(localPath);
        QDir dir = fileInfo.absoluteDir();
        if (!dir.exists()) {
            dir.mkpath(".");
        }
        
        emit statusUpdated(QString("Downloading: %1").arg(file));
        
        // Download file (synchronous for simplicity)
        QNetworkAccessManager manager;
        QNetworkRequest request(QUrl(fileUrl));
        QNetworkReply *reply = manager.get(request);
        
        QEventLoop loop;
        connect(reply, &QNetworkReply::finished, &loop, &QEventLoop::quit);
        loop.exec();
        
        if (reply->error() == QNetworkReply::NoError) {
            QFile outputFile(localPath);
            if (outputFile.open(QIODevice::WriteOnly)) {
                outputFile.write(reply->readAll());
                outputFile.close();
                downloaded++;
                emit progressUpdated((downloaded * 100) / totalFiles, 
                    QString("Downloaded %1/%2 files").arg(downloaded).arg(totalFiles));
            }
        } else {
            emit errorOccurred(QString("Failed to download %1: %2").arg(file, reply->errorString()));
        }
        
        reply->deleteLater();
    }
    
    m_isDownloading = false;
    
    if (downloaded == totalFiles) {
        emit statusUpdated("Game installation complete!");
        emit progressUpdated(100, "Installation complete");
    } else {
        emit errorOccurred(QString("Only downloaded %1/%2 files").arg(downloaded).arg(totalFiles));
    }
}

void LauncherCore::onDownloadProgress(qint64 bytesReceived, qint64 bytesTotal)
{
    if (bytesTotal > 0) {
        int percentage = (bytesReceived * 100) / bytesTotal;
        QString status = QString("Downloading: %1/%2 MB")
            .arg(bytesReceived / 1024 / 1024)
            .arg(bytesTotal / 1024 / 1024);
        emit progressUpdated(percentage, status);
    }
}

void LauncherCore::onDownloadFinished(const QString &filePath)
{
    m_isDownloading = false;
    emit statusUpdated("Download complete: " + filePath);
    emit progressUpdated(100, "Download complete");
    
    // If we were downloading the patch
    if (m_currentDownload == "patch") {
        emit statusUpdated("Patch installed successfully!");
    }
    
    m_currentDownload = "";
}

void LauncherCore::onDownloadError(const QString &error)
{
    m_isDownloading = false;
    emit errorOccurred("Download failed: " + error);
}

