/****************************************************************************
 * config_model.hpp : Staged VLC configuration for QML preferences
 ****************************************************************************/
#ifndef VLC_QT_PREFERENCES_CONFIG_MODEL_HPP
#define VLC_QT_PREFERENCES_CONFIG_MODEL_HPP

#include <QAbstractListModel>
#include <QPointer>
#include <QStringList>
#include <QVariantList>
#include <QVector>

class MainCtx;
Q_MOC_INCLUDE("maininterface/mainctx.hpp")

class ConfigModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(MainCtx *ctx READ ctx WRITE setCtx NOTIFY ctxChanged)
    Q_PROPERTY(QString category READ category WRITE setCategory NOTIFY categoryChanged)
    Q_PROPERTY(QString search READ search WRITE setSearch NOTIFY searchChanged)
    Q_PROPERTY(bool dirty READ dirty NOTIFY dirtyChanged)
    Q_PROPERTY(QString error READ error NOTIFY errorChanged)
    Q_PROPERTY(QStringList categories READ categories NOTIFY categoriesChanged)

public:
    enum Role {
        KeyRole = Qt::UserRole + 1, CategoryRole, LabelRole, HelpRole,
        TypeRole, ValueRole, CurrentRole, DefaultRole, MinimumRole,
        MaximumRole, ChoicesRole, DirtyRole
    };
    Q_ENUM(Role)

    explicit ConfigModel(QObject *parent = nullptr);
    MainCtx *ctx() const;
    void setCtx(MainCtx *ctx);
    QString category() const { return m_category; }
    void setCategory(const QString &category);
    QString search() const { return m_search; }
    void setSearch(const QString &search);
    bool dirty() const;
    QString error() const { return m_error; }
    QStringList categories() const;

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE bool setValue(const QString &key, const QVariant &value);
    Q_INVOKABLE bool apply();
    Q_INVOKABLE void cancel();
    Q_INVOKABLE void resetCategory();
    Q_INVOKABLE void reload();

signals:
    void ctxChanged();
    void categoryChanged();
    void searchChanged();
    void dirtyChanged();
    void errorChanged();
    void categoriesChanged();

private:
    struct Entry {
        QString key, category, label, help, type;
        QVariant current, staged, original, minimum, maximum;
        QVariantList choices;
        bool bounded = false;
    };

    bool visible(const Entry &entry) const;
    void rebuildRows();
    void setError(const QString &error);
    void notifyEntry(int entryIndex);
    static bool normalize(const Entry &entry, const QVariant &value, QVariant *normalized);
    static QVariant readValue(const Entry &entry);
    static void putValue(const Entry &entry, const QVariant &value);

    QPointer<MainCtx> m_ctx;
    QString m_category, m_search, m_error;
    QVector<Entry> m_entries;
    QVector<int> m_rows;
};

#endif
