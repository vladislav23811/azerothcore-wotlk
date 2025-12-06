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
#include <QTimer>
#include <QStringList>
#include <QUrl>

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
    QObject::connect(m_downloadManager, &DownloadManager::downloadProgress, 
            this, &LauncherCore::onDownloadProgress);
    QObject::connect(m_downloadManager, &DownloadManager::downloadFinished, 
            this, &LauncherCore::onDownloadFinished);
    QObject::connect(m_downloadManager, &DownloadManager::downloadError, 
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
            // Support both old "game_zip_url" and new "game_folder_url"
            m_gameZipUrl = obj["game_folder_url"].toString();
            if (m_gameZipUrl.isEmpty()) {
                m_gameZipUrl = obj["game_zip_url"].toString(); // Legacy support
            }
            m_patchVersionUrl = obj["patch_version_url"].toString();
            m_patchDownloadUrl = obj["patch_download_url"].toString();
            configFile.close();
            return;
        }
    }
    
    // Fallback to QSettings or defaults
    m_gamePath = m_settings->value("gamePath", "C:/WoW").toString();
    m_serverUrl = m_settings->value("serverUrl", "http://myclubgames.com").toString();
    // Game folder URL (extracted game files)
    m_gameZipUrl = m_settings->value("gameFolderUrl", m_serverUrl + "/WoW/").toString();
    m_patchVersionUrl = m_settings->value("patchVersionUrl", m_serverUrl + "/patches/version.txt").toString();
    m_patchDownloadUrl = m_settings->value("patchDownloadUrl", m_serverUrl + "/patches/latest/patch-Z.MPQ").toString();
}

void LauncherCore::saveConfig()
{
    QJsonObject obj;
    obj["wow_path"] = m_gamePath;
    obj["server_url"] = m_serverUrl;
    obj["game_folder_url"] = m_gameZipUrl; // Now it's folder URL, not ZIP
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

QString LauncherCore::detectGameLanguage() const
{
    if (m_gamePath.isEmpty())
        return "enUS"; // Default
    
    // Check Data folder for language subfolders
    QDir dataDir(m_gamePath + "/Data");
    if (!dataDir.exists())
        return "enUS";
    
    // Common language codes
    QStringList languages = {"enUS", "enGB", "esES", "esMX", "frFR", "deDE", "ruRU", "koKR", "zhCN", "zhTW"};
    
    for (const QString &lang : languages) {
        QDir langDir(dataDir.absoluteFilePath(lang));
        if (langDir.exists()) {
            // Check if it has MPQ files
            QFileInfoList files = langDir.entryInfoList(QStringList() << "*.MPQ", QDir::Files);
            if (!files.isEmpty()) {
                return lang;
            }
        }
    }
    
    // Fallback: check locale.wtf or realmlist.wtf
    QFile localeFile(m_gamePath + "/Data/locale.wtf");
    if (localeFile.open(QIODevice::ReadOnly)) {
        QByteArray data = localeFile.readAll();
        for (const QString &lang : languages) {
            if (data.contains(lang.toUtf8())) {
                return lang;
            }
        }
    }
    
    return "enUS"; // Default fallback
}

bool LauncherCore::needsFullInstall() const
{
    if (!isGameInstalled())
        return true;
    
    // Check for critical files
    QStringList criticalFiles = {
        "/Wow.exe",
        "/Data/patch.MPQ",
        "/Data/patch-2.MPQ"
    };
    
    int missingCount = 0;
    for (const QString &file : criticalFiles) {
        if (!QFileInfo::exists(m_gamePath + file)) {
            missingCount++;
        }
    }
    
    // If more than 1 critical file missing, suggest full install
    // Otherwise, just patches needed
    return missingCount > 1;
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
    // Make synchronous HTTP request to get patch version
    QNetworkAccessManager manager;
    QUrl url(m_patchVersionUrl);
    QNetworkRequest request(url);
    request.setRawHeader("User-Agent", "WoW-Launcher/1.0");
    
    QNetworkReply *reply = manager.get(request);
    
    QEventLoop loop;
    connect(reply, &QNetworkReply::finished, &loop, &QEventLoop::quit);
    
    // 5 second timeout
    QTimer::singleShot(5000, &loop, &QEventLoop::quit);
    loop.exec();
    
    QString version = "";
    if (reply->error() == QNetworkReply::NoError) {
        version = QString::fromUtf8(reply->readAll()).trimmed();
    }
    
    reply->deleteLater();
    return version;
}

void LauncherCore::checkForUpdates()
{
    emit statusUpdated("Checking for updates...");
    
    // Check if game is installed
    if (!isGameInstalled()) {
        emit statusUpdated("Game not installed. Please install first.");
        emit progressUpdated(0, "Game not installed");
        return;
    }
    
    // Detect language
    QString language = detectGameLanguage();
    emit statusUpdated(QString("Detected game language: %1").arg(language));
    
    // Check for patch updates
    QString localVersion = getLocalPatchVersion();
    emit statusUpdated(QString("Local patch version: %1").arg(localVersion.isEmpty() ? "None" : localVersion));
    
    // Get server version
    QString serverVersion = getServerPatchVersion();
    if (serverVersion.isEmpty()) {
        emit statusUpdated("Could not connect to server. Check server URL in settings.");
        emit progressUpdated(0, "Connection failed");
        return;
    }
    
    emit statusUpdated(QString("Server patch version: %1").arg(serverVersion));
    
    // Compare versions
    bool needsUpdate = false;
    if (localVersion == "0" || localVersion.isEmpty()) {
        needsUpdate = true;
        emit statusUpdated("No local patch found. Downloading...");
    } else {
        // Compare timestamps (server version should be timestamp)
        bool ok1, ok2;
        qint64 local = localVersion.toLongLong(&ok1);
        qint64 server = serverVersion.toLongLong(&ok2);
        
        if (ok1 && ok2) {
            needsUpdate = server > local;
            if (needsUpdate) {
                emit statusUpdated("New patch available! Downloading...");
            } else {
                emit statusUpdated("Patch is up to date.");
                emit progressUpdated(100, "Up to date");
                return;
            }
        } else {
            // String comparison fallback
            needsUpdate = serverVersion != localVersion;
            if (needsUpdate) {
                emit statusUpdated("New patch available! Downloading...");
            } else {
                emit statusUpdated("Patch is up to date.");
                emit progressUpdated(100, "Up to date");
                return;
            }
        }
    }
    
    if (needsUpdate) {
        QString patchPath = m_gamePath + "/Data/patch-Z.MPQ";
        
        // Create Data directory if needed
        QDir dataDir(m_gamePath + "/Data");
        if (!dataDir.exists()) {
            dataDir.mkpath(".");
        }
        
        m_isDownloading = true;
        m_currentDownload = "patch";
        m_downloadManager->downloadFile(m_patchDownloadUrl, patchPath);
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
    emit statusUpdated("Starting game installation from server folder...");
    
    // Check if game is partially installed
    if (isGameInstalled() && !needsFullInstall()) {
        // Just download patches
        emit statusUpdated("Game detected. Downloading patches only...");
        downloadPatchesOnly();
    } else {
        // Full install
        downloadGameFromFolder();
    }
}

void LauncherCore::downloadPatchesOnly()
{
    // Get game folder URL
    QString gameFolderUrl = m_gameZipUrl;
    if (!gameFolderUrl.endsWith("/")) {
        gameFolderUrl += "/";
    }
    
    // Detect language
    QString language = detectGameLanguage();
    emit statusUpdated(QString("Detected language: %1").arg(language));
    emit statusUpdated("Downloading patches only...");
    
    // List of patch files to download
    QStringList patchFiles = {
        QString("Data/%1/patch-%1.MPQ").arg(language),
        QString("Data/%1/patch-%1-2.MPQ").arg(language),
        QString("Data/%1/patch-%1-3.MPQ").arg(language),
        "Data/patch.MPQ",
        "Data/patch-2.MPQ",
        "Data/patch-3.MPQ",
        "Data/patch-Z.MPQ" // Custom patch
    };
    
    // Filter to only missing files
    QStringList filesToDownload;
    for (const QString &file : patchFiles) {
        QString localPath = m_gamePath + "/" + file;
        if (!QFileInfo::exists(localPath)) {
            filesToDownload.append(file);
        }
    }
    
    if (filesToDownload.isEmpty()) {
        emit statusUpdated("All patches are up to date!");
        emit progressUpdated(100, "Up to date");
        return;
    }
    
    emit statusUpdated(QString("Found %1 missing patches").arg(filesToDownload.size()));
    
    m_isDownloading = true;
    m_currentDownload = "patches";
    
    QNetworkAccessManager manager;
    int totalFiles = filesToDownload.size();
    int downloaded = 0;
    int failed = 0;
    
    for (const QString &file : filesToDownload) {
        QString fileUrl = gameFolderUrl + file;
        QString localPath = m_gamePath + "/" + file;
        
        // Create directory if needed
        QFileInfo fileInfo(localPath);
        QDir dir = fileInfo.absoluteDir();
        if (!dir.exists()) {
            dir.mkpath(".");
        }
        
        emit statusUpdated(QString("Downloading patch: %1").arg(file));
        
        // Download file
        QUrl fileUrlObj(fileUrl);
        QNetworkRequest fileRequest(fileUrlObj);
        fileRequest.setRawHeader("User-Agent", "WoW-Launcher/1.0");
        QNetworkReply *fileReply = manager.get(fileRequest);
        
        QEventLoop fileLoop;
        QObject::connect(fileReply, &QNetworkReply::finished, &fileLoop, &QEventLoop::quit);
        fileLoop.exec();
        
        if (fileReply->error() == QNetworkReply::NoError) {
            QFile outputFile(localPath);
            if (outputFile.open(QIODevice::WriteOnly)) {
                outputFile.write(fileReply->readAll());
                outputFile.close();
                downloaded++;
                emit progressUpdated((downloaded * 100) / totalFiles, 
                    QString("Downloaded %1/%2 patches").arg(downloaded).arg(totalFiles));
            } else {
                emit errorOccurred(QString("Cannot write file: %1").arg(localPath));
                failed++;
            }
        } else {
            emit errorOccurred(QString("Failed to download %1: %2").arg(file, fileReply->errorString()));
            failed++;
        }
        
        fileReply->deleteLater();
    }
    
    m_isDownloading = false;
    
    if (downloaded > 0) {
        emit statusUpdated(QString("Downloaded %1/%2 patches successfully").arg(downloaded).arg(totalFiles));
        if (failed > 0) {
            emit statusUpdated(QString("Warning: %1 patches failed to download").arg(failed));
        }
        emit progressUpdated(100, "Patches installed");
    } else {
        emit errorOccurred("No patches were downloaded!");
    }
}

void LauncherCore::downloadGameFromFolder()
{
    // Get game folder URL
    QString gameFolderUrl = m_gameZipUrl;
    if (!gameFolderUrl.endsWith("/")) {
        gameFolderUrl += "/";
    }
    
    emit statusUpdated(QString("Downloading game from: %1").arg(gameFolderUrl));
    emit progressUpdated(0, "Preparing download...");
    
    // Create game directory
    QDir gameDir(m_gamePath);
    if (!gameDir.exists()) {
        gameDir.mkpath(".");
        emit statusUpdated(QString("Created game directory: %1").arg(m_gamePath));
    }
    
    // Detect language if game partially installed
    QString language = detectGameLanguage();
    emit statusUpdated(QString("Using language: %1").arg(language));
    
    // First, try to get file list from server
    QString fileListUrl = gameFolderUrl + "filelist.txt";
    QNetworkAccessManager manager;
    QUrl fileListUrlObj(fileListUrl);
    QNetworkRequest request(fileListUrlObj);
    request.setRawHeader("User-Agent", "WoW-Launcher/1.0");
    
    QNetworkReply *reply = manager.get(request);
    QEventLoop loop;
    QObject::connect(reply, &QNetworkReply::finished, &loop, &QEventLoop::quit);
    QTimer::singleShot(10000, &loop, &QEventLoop::quit); // 10 second timeout
    loop.exec();
    
    QStringList filesToDownload;
    
    if (reply->error() == QNetworkReply::NoError) {
        // Got file list from server
        QString fileList = QString::fromUtf8(reply->readAll());
        QStringList allFiles = fileList.split("\n", Qt::SkipEmptyParts);
        
        // Filter files based on what's missing
        for (const QString &file : allFiles) {
            QString localPath = m_gamePath + "/" + file;
            if (!QFileInfo::exists(localPath)) {
                filesToDownload.append(file);
            }
        }
        
        emit statusUpdated(QString("Found %1 missing files to download").arg(filesToDownload.size()));
    } else {
        // No file list, download critical files only
        emit statusUpdated("No file list found, downloading critical files only...");
        QStringList criticalFiles = {
            "Wow.exe",
            QString("Data/%1/patch-%1.MPQ").arg(language),
            QString("Data/%1/patch-%1-2.MPQ").arg(language),
            QString("Data/%1/patch-%1-3.MPQ").arg(language),
            "Data/patch.MPQ",
            "Data/patch-2.MPQ",
            "Data/patch-3.MPQ"
        };
        
        // Only add files that don't exist
        for (const QString &file : criticalFiles) {
            if (!QFileInfo::exists(m_gamePath + "/" + file)) {
                filesToDownload.append(file);
            }
        }
    }
    reply->deleteLater();
    
    if (filesToDownload.isEmpty()) {
        emit errorOccurred("No files to download!");
        return;
    }
    
    m_isDownloading = true;
    m_currentDownload = "game";
    
    int totalFiles = filesToDownload.size();
    int downloaded = 0;
    int failed = 0;
    
    for (const QString &file : filesToDownload) {
        QString fileUrl = gameFolderUrl + file;
        QString localPath = m_gamePath + "/" + file;
        
        // Create directory if needed
        QFileInfo fileInfo(localPath);
        QDir dir = fileInfo.absoluteDir();
        if (!dir.exists()) {
            dir.mkpath(".");
        }
        
        // Skip if file already exists (we already filtered, but double-check)
        if (QFileInfo::exists(localPath)) {
            // Check file size - if 0 bytes or very small, re-download
            QFileInfo fileInfo(localPath);
            if (fileInfo.size() > 100) { // File exists and has content
                emit statusUpdated(QString("Skipping existing file: %1").arg(file));
                downloaded++;
                emit progressUpdated((downloaded * 100) / totalFiles, 
                    QString("Downloaded %1/%2 files").arg(downloaded).arg(totalFiles));
                continue;
            }
        }
        
        emit statusUpdated(QString("Downloading: %1").arg(file));
        
        // Download file
        QUrl fileUrlObj(fileUrl);
        QNetworkRequest fileRequest(fileUrlObj);
        fileRequest.setRawHeader("User-Agent", "WoW-Launcher/1.0");
        QNetworkReply *fileReply = manager.get(fileRequest);
        
        QEventLoop fileLoop;
        QObject::connect(fileReply, &QNetworkReply::finished, &fileLoop, &QEventLoop::quit);
        fileLoop.exec();
        
        if (fileReply->error() == QNetworkReply::NoError) {
            QFile outputFile(localPath);
            if (outputFile.open(QIODevice::WriteOnly)) {
                outputFile.write(fileReply->readAll());
                outputFile.close();
                downloaded++;
                emit progressUpdated((downloaded * 100) / totalFiles, 
                    QString("Downloaded %1/%2 files").arg(downloaded).arg(totalFiles));
            } else {
                emit errorOccurred(QString("Cannot write file: %1").arg(localPath));
                failed++;
            }
        } else {
            emit errorOccurred(QString("Failed to download %1: %2").arg(file, fileReply->errorString()));
            failed++;
        }
        
        fileReply->deleteLater();
    }
    
    m_isDownloading = false;
    
    if (downloaded > 0) {
        emit statusUpdated(QString("Downloaded %1/%2 files successfully").arg(downloaded).arg(totalFiles));
        if (failed > 0) {
            emit statusUpdated(QString("Warning: %1 files failed to download").arg(failed));
        }
        emit progressUpdated(100, "Installation complete");
    } else {
        emit errorOccurred("No files were downloaded!");
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
        // Update UI to show new version
        QString newVersion = getLocalPatchVersion();
        emit statusUpdated(QString("Patch version updated to: %1").arg(newVersion));
    } else if (m_currentDownload == "game") {
        emit statusUpdated("Game installation complete!");
        emit statusUpdated("You can now launch the game.");
    }
    
    m_currentDownload = "";
}

void LauncherCore::onDownloadError(const QString &error)
{
    m_isDownloading = false;
    emit errorOccurred("Download failed: " + error);
}

