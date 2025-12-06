#ifndef SETTINGSDIALOG_H
#define SETTINGSDIALOG_H

#include <QDialog>
#include <QLineEdit>
#include <QPushButton>
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QLabel>
#include <QGroupBox>

class SettingsDialog : public QDialog
{
    Q_OBJECT

public:
    explicit SettingsDialog(QWidget *parent = nullptr);
    
    QString getGamePath() const;
    QString getServerUrl() const;
    QString getGameZipUrl() const;
    QString getPatchVersionUrl() const;
    QString getPatchDownloadUrl() const;
    
    void setGamePath(const QString &path);
    void setServerUrl(const QString &url);
    void setGameZipUrl(const QString &url);
    void setPatchVersionUrl(const QString &url);
    void setPatchDownloadUrl(const QString &url);

private slots:
    void onBrowseGamePath();
    void onSave();
    void onCancel();

private:
    void setupUI();
    
    QLineEdit *m_gamePathEdit;
    QLineEdit *m_serverUrlEdit;
    QLineEdit *m_gameZipUrlEdit;
    QLineEdit *m_patchVersionUrlEdit;
    QLineEdit *m_patchDownloadUrlEdit;
    
    QPushButton *m_browseButton;
    QPushButton *m_saveButton;
    QPushButton *m_cancelButton;
};

#endif // SETTINGSDIALOG_H

