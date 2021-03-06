﻿#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QtQml>

#include <QThread>
#include <QDir>

#include "src/DBop.h"
#include "src/IOContextManager.h"
#include "src/MessageManager.h"
#include "src/UserManager.h"
#include "src/NetStructureManager.h"
#include "src/AdminManager.h"
#include "src/SessionManager.h"
#include "src/UserReuqestManager.h"
#include "src/TaskManager.h"
#include "src/HomeworkManager.h"

#include <QQuickWindow>

int main(int argc, char *argv[])
{
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QGuiApplication app(argc, argv);
    QQmlApplicationEngine engine;

    DBOP::getInstance();
    auto networkThread = QThread::create([](){
		QDir().mkdir(tmpDir.c_str());
		QDir().mkdir(groupDir.c_str());
        auto msgm = MessageManager::getInstance();
        msgm->run();

        auto iom = IOContextManager::getInstance();
        iom->init();
        iom->run();

        NetStructureManager::getInstance()->buildNetStructure(1);
        iom->wait();
        qDebug() << "thread stop";
    });
	networkThread->start();

    engine.rootContext()->setContextProperty("UserManager", UserManager::getInstance());
    engine.rootContext()->setContextProperty("AdminManager", AdminManager::getInstance());
    engine.rootContext()->setContextProperty("SessionManager", SessionManager::getInstance());
    engine.rootContext()->setContextProperty("UserReuqestManager", UserReuqestManager::getInstance());
    engine.rootContext()->setContextProperty("TaskManager", TaskManager::getInstance());
    engine.rootContext()->setContextProperty("HomeworkManager", HomeworkManager::getInstance());
	engine.rootContext()->setContextProperty("DBOP", DBOP::getInstance());

    QObject::connect(&engine, &QQmlApplicationEngine::quit, [&](){
        IOContextManager::getInstance()->stop();
    });

    QObject::connect(networkThread, &QThread::finished, [&](){
        qDebug() << "network thread finished";
		app.quit();
    });

    engine.addImportPath(":/imports");
    engine.load(QUrl(QStringLiteral("qrc:/MainWindow.qml")));
	QObject *topLevel = engine.rootObjects().value(0);
	QQuickWindow *window = qobject_cast<QQuickWindow *>(topLevel);
	window->setColor(QColor(Qt::transparent));

	app.exec();
    abort();

    return 0;
}
