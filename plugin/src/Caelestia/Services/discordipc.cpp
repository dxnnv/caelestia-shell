#include "discordipc.hpp"

#include <qcoreapplication.h>
#include <qdatastream.h>
#include <qdatetime.h>
#include <qdebug.h>
#include <qdir.h>
#include <qfileinfo.h>
#include <qiodevice.h>
#include <qjsondocument.h>
#include <qset.h>
#include <qstandardpaths.h>
#include <qtenvironmentvariables.h>

#include <cstdint>

namespace {

enum class Opcode : std::uint8_t {
    Handshake = 0,
    Frame = 1,
    Close = 2,
    Ping = 3,
    Pong = 4
};

} // namespace

namespace caelestia::services {

using Qt::StringLiterals::operator""_s;

DiscordIpc::DiscordIpc(QObject* parent)
    : QObject(parent)
    , m_socket(new QLocalSocket(this))
    , m_reconnectTimer(new QTimer(this))
    , m_connected(false) {
    connect(m_socket, &QLocalSocket::connected, this, &DiscordIpc::onSocketConnected);
    connect(m_socket, &QLocalSocket::disconnected, this, &DiscordIpc::onSocketDisconnected);
    connect(m_socket, &QLocalSocket::readyRead, this, &DiscordIpc::onReadyRead);
    connect(m_socket, &QLocalSocket::errorOccurred, this, &DiscordIpc::onError);

    m_reconnectTimer->setInterval(5000);
    connect(m_reconnectTimer, &QTimer::timeout, this, &DiscordIpc::checkReconnect);
}

DiscordIpc::~DiscordIpc() {
    disconnectIpc();
}

bool DiscordIpc::connected() const {
    return m_connected;
}

void DiscordIpc::connectIpc(const QString& clientId) {
    m_clientId = clientId;
    if (m_socket->state() != QLocalSocket::UnconnectedState) {
        m_socket->abort();
    }
    checkReconnect();
    m_reconnectTimer->start();
}

void DiscordIpc::disconnectIpc() {
    m_reconnectTimer->stop();
    m_clientId.clear();
    m_socket->abort();
    if (m_connected) {
        m_connected = false;
        emit connectedChanged();
    }
}

void DiscordIpc::checkReconnect() {
    if (m_clientId.isEmpty())
        return;
    if (m_socket->state() == QLocalSocket::ConnectedState || m_socket->state() == QLocalSocket::ConnectingState)
        return;

    QSet<QString> runtimeDirs;
    runtimeDirs.insert(QStandardPaths::writableLocation(QStandardPaths::RuntimeLocation));
    runtimeDirs.insert(qEnvironmentVariable("XDG_RUNTIME_DIR"));
    runtimeDirs.insert(QDir::tempPath());

    for (const auto& runtimeDir : runtimeDirs) {
        if (runtimeDir.isEmpty())
            continue;

        for (int index = 0; index < 10; ++index) {
            const auto pipePath = QDir(runtimeDir).filePath(u"discord-ipc-%1"_s).arg(index);
            if (!QFileInfo::exists(pipePath))
                continue;

            m_socket->connectToServer(pipePath);
            return;
        }
    }
}

void DiscordIpc::onSocketConnected() {
    // Send Handshake
    QJsonObject payload;
    payload[u"v"_s] = 1;
    payload[u"client_id"_s] = m_clientId;
    sendFrame(static_cast<int>(Opcode::Handshake), payload);
}

void DiscordIpc::onSocketDisconnected() {
    m_buffer.clear();
    if (m_connected) {
        m_connected = false;
        emit connectedChanged();
    }
}

void DiscordIpc::onError(QLocalSocket::LocalSocketError socketError) {
    Q_UNUSED(socketError);

    emit errorOccurred(m_socket->errorString());
    onSocketDisconnected();
}

void DiscordIpc::onReadyRead() {
    m_buffer.append(m_socket->readAll());

    while (m_buffer.size() >= 8) {
        QDataStream stream(m_buffer);
        stream.setByteOrder(QDataStream::LittleEndian);

        int32_t opcode;
        int32_t length;
        stream >> opcode >> length;

        if (m_buffer.size() < 8 + length) {
            break; // Wait for more data
        }

        const QByteArray payloadData = m_buffer.mid(8, length);
        m_buffer.remove(0, 8 + length);

        const QJsonDocument doc = QJsonDocument::fromJson(payloadData);
        if (doc.isObject()) {
            processPayload(opcode, doc.object());
        }
    }
}

void DiscordIpc::processPayload(int opcode, const QJsonObject& payload) {
    if (opcode == static_cast<int>(Opcode::Close)) {
        m_socket->abort();
        return;
    }

    if (opcode != static_cast<int>(Opcode::Frame)) {
        return;
    }

    if (payload.value(u"cmd"_s).toString() == u"DISPATCH"_s && payload.value(u"evt"_s).toString() == u"READY"_s) {
        m_connected = true;
        emit connectedChanged();
    }
}

void DiscordIpc::sendFrame(int opcode, const QJsonObject& payload) {
    if (m_socket->state() != QLocalSocket::ConnectedState)
        return;

    const QJsonDocument doc(payload);
    const QByteArray data = doc.toJson(QJsonDocument::Compact);

    QByteArray header;
    QDataStream stream(&header, QIODevice::WriteOnly);
    stream.setByteOrder(QDataStream::LittleEndian);
    stream << static_cast<int32_t>(opcode) << static_cast<int32_t>(data.size());

    m_socket->write(header);
    m_socket->write(data);
    m_socket->flush();
}

void DiscordIpc::sendActivity(const QJsonObject& activity) {
    if (!m_connected)
        return;

    const QJsonObject args{
        { u"pid"_s, QCoreApplication::applicationPid() },
        { u"activity"_s, activity },
    };

    const QJsonObject payload{
        { u"cmd"_s, u"SET_ACTIVITY"_s },
        { u"args"_s, args },
        { u"nonce"_s, QString::number(QDateTime::currentMSecsSinceEpoch()) },
    };

    sendFrame(static_cast<int>(Opcode::Frame), payload);
}

void DiscordIpc::clearActivity() {
    if (!m_connected)
        return;

    const QJsonObject args{
        { u"pid"_s, QCoreApplication::applicationPid() },
    };

    const QJsonObject payload{
        { u"cmd"_s, u"SET_ACTIVITY"_s },
        { u"args"_s, args },
        { u"nonce"_s, QString::number(QDateTime::currentMSecsSinceEpoch()) },
    };

    sendFrame(static_cast<int>(Opcode::Frame), payload);
}

} // namespace caelestia::services
