/****************************************************************************
 * shortcuts_model.hpp : Staged VLC keyboard shortcuts for QML
 ****************************************************************************/
#ifndef VLC_QT_PREFERENCES_SHORTCUTS_MODEL_HPP
#define VLC_QT_PREFERENCES_SHORTCUTS_MODEL_HPP

#include <QAbstractListModel>
#include <QPointer>
#include <QVariantMap>
#include <QVector>

class MainCtx;
Q_MOC_INCLUDE("maininterface/mainctx.hpp")

class ShortcutsModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(MainCtx *ctx READ ctx WRITE setCtx NOTIFY ctxChanged)
    Q_PROPERTY(QString search READ search WRITE setSearch NOTIFY searchChanged)
    Q_PROPERTY(QString searchField READ searchField WRITE setSearchField NOTIFY searchFieldChanged)
    Q_PROPERTY(bool dirty READ dirty NOTIFY dirtyChanged)
    Q_PROPERTY(QString error READ error NOTIFY errorChanged)

public:
    enum Role { KeyRole = Qt::UserRole + 1, ActionRole, GroupRole,
                HotkeyRole, GlobalHotkeyRole, DirtyRole };
    Q_ENUM(Role)

    explicit ShortcutsModel(QObject *parent = nullptr);
    MainCtx *ctx() const;
    void setCtx(MainCtx *ctx);
    QString search() const { return m_search; }
    void setSearch(const QString &search);
    QString searchField() const { return m_searchField; }
    void setSearchField(const QString &field);
    bool dirty() const;
    QString error() const { return m_error; }

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE void reload();
    Q_INVOKABLE void cancel();
    Q_INVOKABLE void resetAll();
    Q_INVOKABLE bool apply();
    Q_INVOKABLE QVariantMap stageKey(const QString &option, bool global,
                                    int qtKey, int modifiers, bool replaceConflict = false);
    Q_INVOKABLE bool clearKey(const QString &option, bool global);

signals:
    void ctxChanged();
    void searchChanged();
    void searchFieldChanged();
    void dirtyChanged();
    void errorChanged();

private:
    struct Entry {
        QString key, globalKey, action, group;
        QString current, staged, defaults, globalCurrent, globalStaged, globalDefaults;
    };
    struct Change { QString key, before, after; };

    bool visible(const Entry &entry) const;
    void rebuildRows();
    void notifyEntry(int entryIndex);
    void setError(const QString &error);
    int findEntry(const QString &key) const;
    static QString readKey(const QString &key);
    static void putKey(const QString &key, const QString &value);
    static QString groupFor(const QString &key);
    static int groupOrder(const QString &group);

    QPointer<MainCtx> m_ctx;
    QString m_search, m_searchField = QStringLiteral("all"), m_error;
    QVector<Entry> m_entries;
    QVector<int> m_rows;
};

#endif
