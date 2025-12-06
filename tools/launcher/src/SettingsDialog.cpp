#include "SettingsDialog.h"
#include <QFileDialog>
#include <QMessageBox>

SettingsDialog::SettingsDialog(QWidget *parent)
    : QDialog(parent)
{
    setWindowTitle("Launcher Settings");
    setMinimumSize(500, 400);
    resize(600, 450);
    
    setupUI();
}

void SettingsDialog::setupUI()
{
    QVBoxLayout *mainLayout = new QVBoxLayout(this);
    
    // Game Path Group
    QGroupBox *gamePathGroup = new QGroupBox("Game Installation", this);
    QVBoxLayout *gamePathLayout = new QVBoxLayout(gamePathGroup);
    
    QHBoxLayout *pathLayout = new QHBoxLayout();
    m_gamePathEdit = new QLineEdit(this);
    m_browseButton = new QPushButton("Browse...", this);
    pathLayout->addWidget(m_gamePathEdit);
    pathLayout->addWidget(m_browseButton);
    
    gamePathLayout->addLayout(pathLayout);
    mainLayout->addWidget(gamePathGroup);
    
    // Server Settings Group
    QGroupBox *serverGroup = new QGroupBox("Server Settings", this);
    QVBoxLayout *serverLayout = new QVBoxLayout(serverGroup);
    
    serverLayout->addWidget(new QLabel("Server URL:", this));
    m_serverUrlEdit = new QLineEdit(this);
    m_serverUrlEdit->setPlaceholderText("http://localhost");
    serverLayout->addWidget(m_serverUrlEdit);
    
    serverLayout->addWidget(new QLabel("Game ZIP URL:", this));
    m_gameZipUrlEdit = new QLineEdit(this);
    m_gameZipUrlEdit->setPlaceholderText("http://localhost/WOTLKHD.zip");
    serverLayout->addWidget(m_gameZipUrlEdit);
    
    serverLayout->addWidget(new QLabel("Patch Version URL:", this));
    m_patchVersionUrlEdit = new QLineEdit(this);
    m_patchVersionUrlEdit->setPlaceholderText("http://localhost/patches/version.txt");
    serverLayout->addWidget(m_patchVersionUrlEdit);
    
    serverLayout->addWidget(new QLabel("Patch Download URL:", this));
    m_patchDownloadUrlEdit = new QLineEdit(this);
    m_patchDownloadUrlEdit->setPlaceholderText("http://localhost/patches/latest/patch-Z.MPQ");
    serverLayout->addWidget(m_patchDownloadUrlEdit);
    
    mainLayout->addWidget(serverGroup);
    
    // Buttons
    QHBoxLayout *buttonLayout = new QHBoxLayout();
    buttonLayout->addStretch();
    
    m_okButton = new QPushButton("OK", this);
    m_okButton->setDefault(true);
    m_cancelButton = new QPushButton("Cancel", this);
    
    buttonLayout->addWidget(m_okButton);
    buttonLayout->addWidget(m_cancelButton);
    
    mainLayout->addLayout(buttonLayout);
    
    // Connections
    connect(m_browseButton, &QPushButton::clicked, this, &SettingsDialog::onBrowseGamePath);
    connect(m_serverUrlEdit, &QLineEdit::textChanged, this, &SettingsDialog::onServerUrlChanged);
    connect(m_okButton, &QPushButton::clicked, this, &QDialog::accept);
    connect(m_cancelButton, &QPushButton::clicked, this, &QDialog::reject);
}

void SettingsDialog::onBrowseGamePath()
{
    QString path = QFileDialog::getExistingDirectory(this, "Select WoW Installation Directory", m_gamePathEdit->text());
    if (!path.isEmpty()) {
        m_gamePathEdit->setText(path);
    }
}

void SettingsDialog::onServerUrlChanged()
{
    QString serverUrl = m_serverUrlEdit->text();
    if (serverUrl.isEmpty()) {
        serverUrl = "http://localhost";
    }
    
    // Auto-update URLs based on server URL
    if (m_gameZipUrlEdit->text().isEmpty() || m_gameZipUrlEdit->text().contains("localhost")) {
        m_gameZipUrlEdit->setText(serverUrl + "/WOTLKHD.zip");
    }
    if (m_patchVersionUrlEdit->text().isEmpty() || m_patchVersionUrlEdit->text().contains("localhost")) {
        m_patchVersionUrlEdit->setText(serverUrl + "/patches/version.txt");
    }
    if (m_patchDownloadUrlEdit->text().isEmpty() || m_patchDownloadUrlEdit->text().contains("localhost")) {
        m_patchDownloadUrlEdit->setText(serverUrl + "/patches/latest/patch-Z.MPQ");
    }
}

QString SettingsDialog::getGamePath() const
{
    return m_gamePathEdit->text();
}

void SettingsDialog::setGamePath(const QString &path)
{
    m_gamePathEdit->setText(path);
}

QString SettingsDialog::getServerUrl() const
{
    return m_serverUrlEdit->text();
}

void SettingsDialog::setServerUrl(const QString &url)
{
    m_serverUrlEdit->setText(url);
    onServerUrlChanged();
}

QString SettingsDialog::getGameZipUrl() const
{
    return m_gameZipUrlEdit->text();
}

void SettingsDialog::setGameZipUrl(const QString &url)
{
    m_gameZipUrlEdit->setText(url);
}

QString SettingsDialog::getPatchVersionUrl() const
{
    return m_patchVersionUrlEdit->text();
}

void SettingsDialog::setPatchVersionUrl(const QString &url)
{
    m_patchVersionUrlEdit->setText(url);
}

QString SettingsDialog::getPatchDownloadUrl() const
{
    return m_patchDownloadUrlEdit->text();
}

void SettingsDialog::setPatchDownloadUrl(const QString &url)
{
    m_patchDownloadUrlEdit->setText(url);
}

