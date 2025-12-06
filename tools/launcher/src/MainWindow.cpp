#include "MainWindow.h"
#include <QMessageBox>
#include <QFileDialog>
#include <QSettings>
#include <QTimer>

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
    , m_isUpdating(false)
    , m_isLaunching(false)
{
    setWindowTitle("WoW Launcher - Progressive Systems");
    setMinimumSize(600, 500);
    resize(800, 600);
    
    // Initialize launcher core
    m_launcherCore = new LauncherCore(this);
    
    setupUI();
    setupConnections();
    updateUI();
    
    // Check for updates on startup
    QTimer::singleShot(1000, this, [this]() {
        m_launcherCore->checkForUpdates();
    });
}

MainWindow::~MainWindow()
{
}

void MainWindow::setupUI()
{
    m_centralWidget = new QWidget(this);
    setCentralWidget(m_centralWidget);
    
    m_mainLayout = new QVBoxLayout(m_centralWidget);
    m_mainLayout->setSpacing(10);
    m_mainLayout->setContentsMargins(15, 15, 15, 15);
    
    // Header
    m_titleLabel = new QLabel("World of Warcraft", this);
    m_titleLabel->setStyleSheet("font-size: 24px; font-weight: bold; color: #FFD700;");
    m_titleLabel->setAlignment(Qt::AlignCenter);
    
    m_versionLabel = new QLabel("Progressive Systems Launcher v1.0", this);
    m_versionLabel->setStyleSheet("font-size: 12px; color: #888;");
    m_versionLabel->setAlignment(Qt::AlignCenter);
    
    m_mainLayout->addWidget(m_titleLabel);
    m_mainLayout->addWidget(m_versionLabel);
    m_mainLayout->addSpacing(10);
    
    // Status Group
    m_statusGroup = new QGroupBox("Status", this);
    QVBoxLayout *statusLayout = new QVBoxLayout(m_statusGroup);
    
    m_statusLabel = new QLabel("Ready", this);
    m_statusLabel->setStyleSheet("font-size: 14px;");
    
    m_progressBar = new QProgressBar(this);
    m_progressBar->setRange(0, 100);
    m_progressBar->setValue(0);
    m_progressBar->setTextVisible(true);
    
    m_logText = new QTextEdit(this);
    m_logText->setReadOnly(true);
    m_logText->setMaximumHeight(150);
    m_logText->setStyleSheet("background-color: #1e1e1e; color: #d4d4d4; font-family: 'Consolas', monospace;");
    
    statusLayout->addWidget(m_statusLabel);
    statusLayout->addWidget(m_progressBar);
    statusLayout->addWidget(m_logText);
    
    m_mainLayout->addWidget(m_statusGroup);
    
    // Game Info Group
    m_gameInfoGroup = new QGroupBox("Game Information", this);
    QVBoxLayout *gameInfoLayout = new QVBoxLayout(m_gameInfoGroup);
    
    m_gamePathLabel = new QLabel("Game Path: Not set", this);
    m_patchVersionLabel = new QLabel("Patch Version: Unknown", this);
    m_gameStatusLabel = new QLabel("Status: Checking...", this);
    
    gameInfoLayout->addWidget(m_gamePathLabel);
    gameInfoLayout->addWidget(m_patchVersionLabel);
    gameInfoLayout->addWidget(m_gameStatusLabel);
    
    m_mainLayout->addWidget(m_gameInfoGroup);
    
    // Buttons
    QHBoxLayout *buttonLayout = new QHBoxLayout();
    
    m_checkUpdatesButton = new QPushButton("Check for Updates", this);
    m_checkUpdatesButton->setStyleSheet(
        "QPushButton { background-color: #2d89ef; color: white; padding: 8px; border-radius: 4px; }"
        "QPushButton:hover { background-color: #1e6bc7; }"
        "QPushButton:pressed { background-color: #155a9e; }"
    );
    
    m_settingsButton = new QPushButton("Settings", this);
    m_settingsButton->setStyleSheet(
        "QPushButton { background-color: #666; color: white; padding: 8px; border-radius: 4px; }"
        "QPushButton:hover { background-color: #555; }"
    );
    
    m_launchButton = new QPushButton("Launch WoW", this);
    m_launchButton->setStyleSheet(
        "QPushButton { background-color: #28a745; color: white; padding: 12px; font-size: 14px; font-weight: bold; border-radius: 4px; }"
        "QPushButton:hover { background-color: #218838; }"
        "QPushButton:pressed { background-color: #1e7e34; }"
        "QPushButton:disabled { background-color: #555; color: #888; }"
    );
    m_launchButton->setMinimumHeight(50);
    
    buttonLayout->addWidget(m_checkUpdatesButton);
    buttonLayout->addWidget(m_settingsButton);
    buttonLayout->addStretch();
    buttonLayout->addWidget(m_launchButton);
    
    m_mainLayout->addLayout(buttonLayout);
    m_mainLayout->addStretch();
}

void MainWindow::setupConnections()
{
    connect(m_launchButton, &QPushButton::clicked, this, &MainWindow::onLaunchClicked);
    connect(m_checkUpdatesButton, &QPushButton::clicked, this, &MainWindow::onCheckUpdatesClicked);
    connect(m_settingsButton, &QPushButton::clicked, this, &MainWindow::onSettingsClicked);
    
    connect(m_launcherCore, &LauncherCore::progressUpdated, this, &MainWindow::onProgressUpdated);
    connect(m_launcherCore, &LauncherCore::statusUpdated, this, &MainWindow::onStatusUpdated);
    connect(m_launcherCore, &LauncherCore::errorOccurred, this, &MainWindow::onErrorOccurred);
    connect(m_launcherCore, &LauncherCore::gameLaunched, this, &MainWindow::onGameLaunched);
}

void MainWindow::updateUI()
{
    // Update game path
    QString gamePath = m_launcherCore->getGamePath();
    m_gamePathLabel->setText("Game Path: " + (gamePath.isEmpty() ? "Not set" : gamePath));
    
    // Update patch version
    QString patchVersion = m_launcherCore->getPatchVersion();
    m_patchVersionLabel->setText("Patch Version: " + (patchVersion.isEmpty() ? "Unknown" : patchVersion));
    
    // Update game status
    bool gameInstalled = m_launcherCore->isGameInstalled();
    m_gameStatusLabel->setText("Status: " + (gameInstalled ? "Installed" : "Not Installed"));
    
    // Update launch button
    m_launchButton->setEnabled(gameInstalled && !m_isUpdating && !m_isLaunching);
}

void MainWindow::onLaunchClicked()
{
    if (!m_launcherCore->isGameInstalled()) {
        QMessageBox::warning(this, "Game Not Installed", 
            "WoW is not installed. Please install the game first.");
        return;
    }
    
    m_isLaunching = true;
    m_launchButton->setEnabled(false);
    m_launchButton->setText("Launching...");
    
    m_launcherCore->launchGame();
}

void MainWindow::onCheckUpdatesClicked()
{
    m_isUpdating = true;
    m_checkUpdatesButton->setEnabled(false);
    m_launchButton->setEnabled(false);
    
    m_launcherCore->checkForUpdates();
}

void MainWindow::onSettingsClicked()
{
    QMessageBox::information(this, "Settings", 
        "Settings dialog coming soon!\n\n"
        "You can edit launcher_config.json manually for now.");
}

void MainWindow::onProgressUpdated(int percentage, const QString &status)
{
    m_progressBar->setValue(percentage);
    m_statusLabel->setText(status);
    
    if (!status.isEmpty()) {
        m_logText->append(QString("[%1] %2").arg(QTime::currentTime().toString("hh:mm:ss"), status));
    }
}

void MainWindow::onStatusUpdated(const QString &status)
{
    m_statusLabel->setText(status);
    m_logText->append(QString("[%1] %2").arg(QTime::currentTime().toString("hh:mm:ss"), status));
    
    // Reset update state if status indicates completion
    if (status.contains("complete", Qt::CaseInsensitive) || 
        status.contains("ready", Qt::CaseInsensitive)) {
        m_isUpdating = false;
        m_checkUpdatesButton->setEnabled(true);
        updateUI();
    }
}

void MainWindow::onErrorOccurred(const QString &error)
{
    QMessageBox::critical(this, "Error", error);
    m_logText->append(QString("[ERROR] %1").arg(error));
    
    m_isUpdating = false;
    m_isLaunching = false;
    m_checkUpdatesButton->setEnabled(true);
    updateUI();
}

void MainWindow::onGameLaunched()
{
    m_isLaunching = false;
    m_launchButton->setText("Launch WoW");
    m_launchButton->setEnabled(true);
    
    // Optionally close launcher after launching
    // close();
}

