#include "SessionManager.h"
#include "DBop.h"
#include "ConnectionManager.h"
#include "NetStructureManager.h"
#include "UserReuqestManager.h"
#include "TaskManager.h"
#include "HomeworkManager.h"

#include "QtCore\qfileinfo.h"
#include "QtCore\quuid.h"

const StringType sessionFamilyStr("SeesionManage");
const StringType transferStrActionStr("TransferStr");
const StringType transferPicActionStr("TransferPic");
const StringType transferFileActionStr("TransferFile");

SessionManager::SessionManager(QObject *parent)
    :QObject(parent)
{
    ConnectionManager::getInstance()->registerFamilyHandler(sessionFamilyStr, std::bind(&SessionManager::actionParse, this, _1, _2));

	registerActionHandler(transferStrActionStr, std::bind(&SessionManager::handleRecvChatMsg, this, _1, _2));
    registerActionHandler(transferPicActionStr, std::bind(&SessionManager::handleRecvPicMsg, this, _1, _2));
}

SessionManager::~SessionManager()
{
}

SessionManager * SessionManager::getInstance()
{
	static SessionManager instance;
    return &instance;
}

int SessionManager::createSession(int type, const QString & duuid)
{
    QString suid = NetStructureManager::getInstance()->getLocalUuid().c_str();
	return DBOP::createSession(SessionInfo(type, suid, duuid));
}

int SessionManager::deleteSession(int sid)
{
	return DBOP::deleteSession(sid);
}

QVariantList SessionManager::listSessions()
{
	return DBOP::listSessions();
}

QString SessionManager::getSeesionIdByUuid(const QString& uuid, int type) 
{
	auto result = DBOP::getSession(type, -1, uuid);
	return result.empty() ? QString() : result["sid"].toString();
}

QVariantList SessionManager::getChatMsgs(int sid, const QString& duuid)
{
	return DBOP::listSessionMessages(sid, duuid);
}

void SessionManager::sendChatMsg(int sid, int stype, const QString & duuid, const QString & msg)
{
	MessageInfo msgInfo(sid, int(ChatMsgType::ChatText), msg);
	DBOP::createMessage(msgInfo, true);
    notifyModelAppendMsg(msgInfo);

	JsonObjType datas;
	datas["type"] = msgInfo.mtype;
    datas["source"] = NetStructureManager::getInstance()->getLocalUuid().c_str();
	datas["dest"] = duuid.toStdString().c_str();
	datas["data"] = msgInfo.mdata.toUtf8().toStdString().c_str();
	datas["date"] = msgInfo.mdate;

	if (SessionType::UserSession == SessionType(stype))
        ConnectionManager::getInstance()->sendActionMsg(TransferMode::Single, sessionFamilyStr, transferStrActionStr, datas);
	else if (SessionType::GroupSession == SessionType(stype))
        ConnectionManager::getInstance()->sendActionMsg(TransferMode::Group, sessionFamilyStr, transferStrActionStr, datas);
}

void SessionManager::sendPic(int sid, int stype, const QString & duuid, const QUrl & picPath, bool isAnimation)
{
    MessageInfo msgInfo(sid, int(isAnimation ? ChatMsgType::ChatAnimation : ChatMsgType::ChatPic), picPath.toString());
	DBOP::createMessage(msgInfo, true);

	JsonObjType datas;
	datas["type"] = msgInfo.mtype;
	datas["source"] = NetStructureManager::getInstance()->getLocalUuid().c_str();
	datas["dest"] = duuid.toStdString().c_str();
	datas["date"] = msgInfo.mdate;
    QFileInfo picInfo(picPath.toString().split("///")[1]);
	datas["picStoreName"] = QUuid::createUuid().toString() + "." + picInfo.completeSuffix();

	if (SessionType::UserSession == SessionType(stype)) {
		ConnectionManager::getInstance()->sendActionMsg(TransferMode::Single, sessionFamilyStr, transferPicActionStr, datas);

		QVariantHash taskData;
        taskData["picRealName"] = picInfo.absoluteFilePath();
		taskData["picStoreName"] = datas["picStoreName"].toString();
		TaskManager::getInstance()->createSendPicSingleTask(duuid, taskData);
	}
	else if (SessionType::GroupSession == SessionType(stype)) {
		ConnectionManager::getInstance()->sendActionMsg(TransferMode::Group, sessionFamilyStr, transferPicActionStr, datas);
		//����ͼƬ���޸�·��
	}
}

void SessionManager::sendFile(int sid, int stype, const QString & duuid, const QUrl & filePath)
{
    UserReuqestManager::getInstance()->sendFileTrangferReq(duuid, filePath.toString().split("///")[1]);
}

void SessionManager::publishHomework(const QString & duuid, const QVariantList & hwInfo)
{
    HomeworkManager::getInstance()->publishHomework();
}

QString SessionManager::getLocalUuid()
{
	return  NetStructureManager::getInstance()->getLocalUuid().c_str();
}

void SessionManager::handleRecvChatMsg(JsonObjType & msg, ConnPtr conn)
{
	qDebug() << "RECV CHAT MSG: " << msg;
	auto data = msg["data"].toObject();
	MessageInfo msgInfo(data["dest"].toString(), data["type"].toInt(), data["data"].toString(), data["date"].toString());
	DBOP::createMessage(msgInfo, false);
    notifyModelAppendMsg(msgInfo);
}

void SessionManager::handleRecvPicMsg(JsonObjType & msg, ConnPtr conn)
{
	qDebug() << "RECV PIC MSG: " << msg;
    auto data = msg["data"].toObject();
	QUrl fileUrl = QUrl::fromLocalFile(tmpDir.c_str() + data["picStoreName"].toString());
    MessageInfo msgInfo(data["dest"].toString(), data["type"].toInt(), fileUrl.toString(), data["date"].toString());
    DBOP::createMessage(msgInfo, false);
    notifyModelAppendMsg(msgInfo);
}

void SessionManager::notifyModelAppendMsg(const MessageInfo& msgInfo)
{
    QVariantList recvMsg;
    recvMsg.append(msgInfo.mid);
    recvMsg.append(msgInfo.sid);
    recvMsg.append(msgInfo.mduuid);
    recvMsg.append(msgInfo.mtype);
    recvMsg.append(msgInfo.mdata);
    recvMsg.append(msgInfo.mdate);
    sessionMsgRecv(recvMsg);
}
