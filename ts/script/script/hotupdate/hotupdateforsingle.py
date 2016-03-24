#!/usr/bin/env python
#coding:utf-8
# author:luodi date:2014/11/18
# description:use this script to hotupdate hxbns area servers
# version:v1.3 mtime:2015/03/25

#version 1.2 add the frist update  module function,use method is 
#exec this program add modules name in end .The moduls Can be a lists

'''
	Modify the hot  update script , add hot update modules function
	I test is Successful in local server
'''

#verion 1.3 delete menu function,and add filename is version id 

import os
import sys
import tarfile
import bz2
import shutil
import time

from modules.ftpconnect import *
from modules.logs import *

class hotupdate:
	def __init__(self):
		self.dir = '/data/server/'
		self.ftpdir = 'server/'
		self.backup = '/data/server/bak/Probackup/'
	def helpinfo(self):
		print "\033[32mUsage:python hotupdate.py 3d_CN_Area10 gameserver 58906 base.beam\033[0m"
	
	#列出选择的目录
	def input(self):
		if len(sys.argv) < 2:
			cmd =  'find %s -maxdepth 1 -type d ' %self.dir
			self.helpinfo()
			print "\033[32mSERVERS LIST:\033[0m"
			for i in os.popen(cmd).readlines():
				print os.path.basename(i).strip()
			logging.error("input error,program is exit")  
			sys.exit(1)

		elif len(sys.argv) < 3:
			inputdir = os.path.join(self.dir,sys.argv[1])
			dir = os.listdir(inputdir)
			for info in dir:
				print info
			sys.exit(1)

		elif len(sys.argv) < 4:
			print "\033[31m Please input HotUpdate Packge version from Ftp Server!!\033[0m"
			sys.exit(1)

		servertype = sys.argv[2]
		packgeversion = sys.argv[3]
		return servertype,packgeversion

	#确认用户输入
	def TestInput(self):
		while True:
			try:
				checkinput = raw_input("Please make sure the to HotUpdate hxbns server(Y/N):")
				if checkinput == "Y" or checkinput == "y":
					break
				elif checkinput == "N" or checkinput == "n":
					sys.exit(1)
				else:
					continue
			except KeyboardInterrupt:
				print "\n Program is exit!!"
				sys.exit(1)


	#Download File
	def download(self,filename,servertype):
		while True:
			filename = self.ftpdir +  'HotUpdate/' + filename + "_" + servertype + "_" + "hotUpdate.tar.bz2"
			code,name=download_files(filename)
			if code == "1":
				logging.warning("Download Package Error from FTP!!")
				sys.exit(1)
			else:
				return name

	#Backup destinations file list in the packges 
	def BackupDesFile(self,desfilename):
		if not os.path.exists(self.backup):
			os.makedirs(self.backup)
		desname = self.backup  + time.strftime("%Y%m%d%H", time.localtime())
		if not os.path.isdir(desname):
			os.makedirs(desname)
		shutil.copy2(desfilename,desname)


	#Hotupdate function
	def hotupdate(self,type,filename,desdir,fristmodule):
		'''
			decompression the package  use bz2 module	
		'''
		try:
			target_path = os.path.dirname(filename)
			tar = tarfile.open(filename, "r:bz2")
			file_names = tar.getnames()
			for file_name in file_names:
				tar.extract(file_name, target_path)	
			tar.close()
		except Exception, e:
			raise Exception, e

		dirname = filename.replace('.tar.bz2','')

		testdir = dirname + '/' + type
		if not os.path.exists(testdir):
			print "\033[31m[Error]:The input package not %s directory,please check!!\033[0m" %type
			logging.error("The input package not %s directory" %type )
			sys.exit(1)

		#Get hotupdate files list from  packages 	
		listdirname = "ls %s/%s/ebin/" %(dirname,type)
		#save hotupdate modules list
		ModulesList = []
		for i in os.popen(listdirname).readlines():
			try:
				SRCfile = dirname  + '/' + type + '/' + 'ebin/' + i
				SRCfile = SRCfile.strip('\n')
				filelist = desdir + '/ebin/' + i
				Newfile = os.path.dirname(filelist.strip('\n'))
				self.BackupDesFile(filelist.strip('\n'))
			except IOError,e:
				logging.warning("backup %s" %e)
				continue
			finally:
				i = i.strip('\n')
				ModulesList.append(i)
				shutil.copy2(SRCfile,Newfile)


		#exec  reload script , the script is reload ebin/  modules
		count=0
		fristmodule.reverse()
		for i in fristmodule:
			if i not in ModulesList:
				print "\033[31m this module  %s  dose not exsits!! \033[0m" %i
				count+=1
			else:
				ModulesList.remove(i)
				ModulesList.insert(0,i)

		if count > 0:
			sys.exit(1)

		Modules=' '.join(ModulesList)
		ModulesList= Modules.replace('.beam',' ')
		ModulesList = ModulesList.replace('\n','')
		print ModulesList
		execcmd = 'cd %s/script/ && erl -make && /bin/sh reload.sh "%s"' %(os.path.dirname(Newfile),ModulesList)
		result = os.popen(execcmd).readlines()
		print "Hotupdate Result:"
		for list in result:
			print "\033[32m%s\033[0m" %list.strip('\n')
			logging.info("hotupdate 3D module %s " %list.strip('\n'))
				

	#Hotupdate program main function
	def main(self):
		SERVER = sys.argv[1]
		modulelists = sys.argv[4:]
		SERVERdir = self.dir + SERVER
		if not os.path.isdir(SERVERdir):
			print "\033[31m You input Server name dose not exsit!!,plese check!!\033[0m"
			sys.exit(1)
			logging.info("input 1,ServerName is not Exsit!!")
		else:
			input_select,packge = self.input()
			filename = self.download(packge,input_select)
			Gsdir = os.path.join(self.dir,SERVER,input_select)
			if not os.path.isdir(Gsdir):       #interpretation directory If there is a. 
				print "\033[31m%s dose not exsits!!\033[0m" % Gsdir
				logging.error("%s does not exist on this server!!" %input_select) 

			logging.info("input 1,hotupdate %s:%s,Area Name:%s"%(input_select,filename,SERVER))  
			self.hotupdate(input_select,filename,Gsdir,modulelists)

	def run(self):
		self.input()
		self.main()

update=hotupdate()
update.run()

