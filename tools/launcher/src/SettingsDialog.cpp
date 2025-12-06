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
    QGroupBox *gamePathGroup = new QGroupBox("Game Installation Path", this);
    QHBoxLayout *gamePathLayout = new QHBoxLayout(gamePathGroup);
    m_gamePathEdit = new QLineEdit(this);
    m_browseButton = new QPushButton("Browse...", this);
    gamePathLayout->addWidget(m_gamePathEdit);
    gamePathLayout->addWidget(m_browseButton);
    mainLayout->addWidget(gamePathGroup);
    
    connect(m_browseButton, &QPushButton::clicked, this, &SettingsDialog::onBrowseGamePath);
    
    // Server URLs Group
    QGroupBox *serverGroup = new QGroupBox("Server Configuration", this);
    QVBoxLayout *serverLayout = new QVBoxLayout(serverGroup);
    
    QLabel *serverUrlLabel = new QLabel("Server URL:", this);
    m_serverUrlEdit = new QLineEdit(this);
    m_serverUrlEdit->setPlaceholderText("http://localhost or http://your-server-ip");
    serverLayout->addWidget(serverUrlLabel);
    serverLayout->addWidget(m_serverUrlEdit);
    
    QLabel *gameZipLabel = new QLabel("Game ZIP URL:", this);
    m_gameZipUrlEdit = new QLineEdit(this);
    m_gameZipUrlEdit->setPlaceholderText("http://localhost/WOTLKHD.zip");
    serverLayout->addWidget(gameZipLabel);
    serverLayout->addWidget(m_gameZipUrlEdit);
    
    QLabel *patchVersionLabel = new QLabel("Patch Version URL:", this);
    m_patchVersionUrlEdit = new QLineEdit(this);
    m_patchVersionUrlEdit->setPlaceholderText("http://localhost/patches/version.txt");
    serverLayout->addWidget(patchVersionLabel);
    serverLayout->addWidget(m_patchVersionUrlEdit);
    
    QLabel *patchDownloadLabel = new QLabel("Patch Download URL:", this);
    m_patchDownloadUrlEdit = new QLineEdit(this);
    m_patchDownloadUrlEdit->setPlaceholderText("http://localhost/patches/latest/patch-Z.MPQ");
    serverLayout->addWidget(patchDownloadLabel);
    serverLayout->addWidget(m_patchDownloadUrlEdit);
    
    mainLayout->addWidget(serverGroup);
    
    // Buttons
    QHBoxLayout *buttonLayout = new QHBoxLayout();
    buttonLayout->addStretch();
    
    m_saveButton = new QPushButton("Save", this);
    m_saveButton->setStyleSheet(
        "QPushButton { background-color: #28a745; color: white; padding: 8px 20px; border-radius: 4px; }"
        "QPushButton:hover { background-color: #218838; }"
    );
    
    m_cancelButton = new QPushButton("Cancel", this);
    m_cancelButton->setStyleSheet(
        "QPushButton { background-color: #666; color: white; padding: 8px 20px; border-radius: 4px; }"
        "QPushButton:hover { background-color: #555; }"
    );
    
    buttonLayout->addWidget(m_saveButton);
    buttonLayout->addWidget(m_cancelButton);
    mainLayout->addLayout(buttonLayout);
    
    connect(m_saveButton, &QPushButton::clicked, this, &SettingsDialog::onSave);
    connect(m_cancelButton, &QPushButton::clicked, this, &SettingsDialog::onCancel);
}

QString SettingsDialog::getGamePath() const
{
    return m_gamePathEdit->text();
}

QString SettingsDialog::getServerUrl() const
{
    return m_serverUrlEdit->text();
}

QString SettingsDialog::getGameZipUrl() const
{
    return m_gameZipUrlEdit->text();
}

QString SettingsDialog::getPatchVersionUrl() const
{
    return m_patchVersionUrlEdit->text();
}

QString SettingsDialog::getPatchDownloadUrl() const
{
    return m_patchDownloadUrlEdit->text();
}

void SettingsDialog::setGamePath(const QString &path)
{
    m_gamePathEdit->setText(path);
}

void SettingsDialog::setServerUrl(const QString &url)
{
    m_serverUrlEdit->setText(url);
}

void SettingsDialog::setGameZipUrl(const QString &url)
{
    m_gameZipUrlEdit->setText(url);
}

void SettingsDialog::setPatchVersionUrl(const QString &url)
{
    m_patchVersionUrlEdit->setText(url);
}

void SettingsDialog::setPatchDownloadUrl(const QString &url)
{
    m_patchDownloadUrlEdit->setText(url);
}

void SettingsDialog::onBrowseGamePath()
{
    QString path = QFileDialog::getExistingDirectory(this, "Select WoW Installation Directory", m_gamePathEdit->text());
    if (!path.isEmpty()) {
        m_gamePathEdit->setText(path);
    }
}

void SettingsDialog::onSave()
{
    if (m_gamePathEdit->text().isEmpty()) {
        QMessageBox::warning(this, "Invalid Settings", "Game path cannot be empty!");
        return;
    }
    
    if (m_serverUrlEdit->text().isEmpty()) {
        QMessageBox::warning(this, "Invalid Settings", "Server URL cannot be empty!");
        return;
    }
    
    accept();
}

void SettingsDialog::onCancel()
{
    reject();
}

