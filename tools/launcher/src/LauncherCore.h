#ifndef LAUNCHERCORE_H
#define LAUNCHERCORE_H

#include <QObject>
#include <QString>
#include <QSettings>
#include "DownloadManager.h"

class LauncherCore : public QObject
{
    Q_OBJECT

public:
    explicit LauncherCore(QObject *parent = nullptr);
    ~LauncherCore();
    
    // Configuration
    QString getGamePath() const;
    void setGamePath(const QString &path);
    
    QString getServerUrl() const;
    void setServerUrl(const QString &url);
    
    // Game status
    bool isGameInstalled() const;
    QString getPatchVersion() const;
    QString detectGameLanguage() const; // Detect client language (enUS, enGB, esES, frFR, etc.)
    bool needsFullInstall() const; // Check if full install needed or just patches
    
    // Actions
    void checkForUpdates();
    void launchGame();
    void installGame();
    void downloadGameFromFolder();
    void downloadPatchesOnly(); // Download only patches for existing installation

signals:
    void progressUpdated(int percentage, const QString &status);
    void statusUpdated(const QString &status);
    void errorOccurred(const QString &error);
    void gameLaunched();

private slots:
    void onDownloadProgress(qint64 bytesReceived, qint64 bytesTotal);
    void onDownloadFinished(const QString &filePath);
    void onDownloadError(const QString &error);

private:
    void setupConnections();
    void loadConfig();
    void saveConfig();
    QString getLocalPatchVersion() const;
    QString getServerPatchVersion() const;
    bool checkMissingFiles() const;
    
    QSettings *m_settings;
    DownloadManager *m_downloadManager;
    
    QString m_gamePath;
    QString m_serverUrl;
    QString m_gameZipUrl;
    QString m_patchVersionUrl;
    QString m_patchDownloadUrl;
    
    bool m_isDownloading;
    QString m_currentDownload;
};

#endif // LAUNCHERCORE_H

