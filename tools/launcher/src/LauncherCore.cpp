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

LauncherCore::LauncherCore(QObject *parent)
    : QObject(parent)
    , m_isDownloading(false)
{
    m_settings = new QSettings("ProgressiveSystems", "WoWLauncher", this);
    m_downloadManager = new DownloadManager(this);
    
    loadConfig();
    setupConnections();
}

LauncherCore::~LauncherCore()
{
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
    m_gameZipUrl = m_settings->value("gameZipUrl", m_serverUrl + "/WOTLKHD.zip").toString();
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
    // This would make an HTTP request - simplified for now
    // In real implementation, use QNetworkAccessManager
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
    
    // TODO: Get server version and compare
    // For now, just check if patch exists
    QString patchPath = m_gamePath + "/Data/patch-Z.MPQ";
    if (!QFileInfo::exists(patchPath)) {
        emit statusUpdated("Patch not found. Downloading...");
        m_isDownloading = true;
        m_currentDownload = "patch";
        m_downloadManager->downloadFile(m_patchDownloadUrl, patchPath);
    } else {
        emit statusUpdated("Patch is up to date.");
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
    // TODO: Implement game installation from ZIP
    emit statusUpdated("Game installation not yet implemented.");
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
}

void LauncherCore::onDownloadError(const QString &error)
{
    m_isDownloading = false;
    emit errorOccurred("Download failed: " + error);
}

