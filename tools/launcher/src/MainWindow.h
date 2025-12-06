#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include <QProgressBar>
#include <QLabel>
#include <QPushButton>
#include <QTextEdit>
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QGroupBox>
#include <QLineEdit>
#include <QCheckBox>
#include "LauncherCore.h"

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    explicit MainWindow(QWidget *parent = nullptr);
    ~MainWindow();

private slots:
    void onLaunchClicked();
    void onCheckUpdatesClicked();
    void onSettingsClicked();
    void onProgressUpdated(int percentage, const QString &status);
    void onStatusUpdated(const QString &status);
    void onErrorOccurred(const QString &error);
    void onGameLaunched();

private:
    void setupUI();
    void setupConnections();
    void updateUI();
    
    // UI Components
    QWidget *m_centralWidget;
    QVBoxLayout *m_mainLayout;
    
    // Header
    QLabel *m_titleLabel;
    QLabel *m_versionLabel;
    
    // Status Section
    QGroupBox *m_statusGroup;
    QLabel *m_statusLabel;
    QProgressBar *m_progressBar;
    QTextEdit *m_logText;
    
    // Game Info Section
    QGroupBox *m_gameInfoGroup;
    QLabel *m_gamePathLabel;
    QLabel *m_patchVersionLabel;
    QLabel *m_gameStatusLabel;
    
    // Buttons
    QPushButton *m_launchButton;
    QPushButton *m_checkUpdatesButton;
    QPushButton *m_settingsButton;
    
    // Core launcher logic
    LauncherCore *m_launcherCore;
    
    // State
    bool m_isUpdating;
    bool m_isLaunching;
};

#endif // MAINWINDOW_H

