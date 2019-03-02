-- Creating a new database for ACIS 5504: Project 2
USE [master]
GO

CREATE DATABASE [GeneralDataPRD]
ON PRIMARY
	(NAME='GeneralData',
	FILENAME = 
		'C:\Users\Work1\Desktop\Portfolio_Stuff\SQL\General_Database.mdf',
	SIZE = 10MB,
	MAXSIZE = 100MB,
	FILEGROWTH=10%)
LOG ON
	(NAME = 'GeneralData_Log',
	FILENAME = 
		'C:\Users\Work1\Desktop\Portfolio_Stuff\SQL\General_Database_Log.ldf',
	SIZE = 4MB,
	MAXSIZE = 45MB,
	FILEGROWTH = 10%)

GO