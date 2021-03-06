#!/usr/bin/env python
# coding:utf-8
# author:luodi date:2015/1/29
# description: use this script to update hxbns area servers
# version:v1.0 mtime:2014/1/29

'''
	hxbns Batch Manager program,"stop|start" 
'''

import os
import sys
import time

from modules.logs import *


class BatchManager:

	def __init__(self):
		self.dir = '/data/server/'
		self.script={'start':'start.sh','stop':'stop.sh'}
		self.hxserverstop=['loginserver','gameserver','commonserver','funcell','dbserver']
		self.hxserverstart=['dbserver','funcell','commonserver','loginserver','gameserver']

	def helpinfo(self):
		print "\033[32mUsage:python BatchManager.py 3d_CN_Area10 gametype {stop|start}\033[0m"


	#List Server dir name and input packge name
	def input(self):
		if len(sys.argv) < 2:
			self.helpinfo()
			dirs = os.listdir(self.dir)
			for i in dirs:
				print i
			sys.exit(1)

		elif len(sys.argv) < 3:
			self.helpinfo()
			dirs = os.listdir(self.dir +"/"+ sys.argv[2])
			for i in dirs:
				print i
			sys.exit(1)
		elif len(sys.argv) < 4:
			self.helpinfo()
			infolist=['stop','start']
			for info in infolist:
				print info
			sys.exit(1)
		return sys.argv[1],sys.argv[2],sys.argv[3]

	
	def Manager(self,dirname,opername,line,oper):
		if oper == 'start' and line == "gameserver":
			time.sleep(60)
		dirinfo = os.path.join(dirname,line,'script')	
		cmdlist='cd %s && erl -make && /bin/sh %s' %(dirinfo,opername)
		value = os.popen(cmdlist).readlines()
		for li in value:
			print "\033[32m%s\033[0m" %li.strip('\n')
			logging.info("result:%s" %li)
		
	def RunCmd(self):
		servername,line,oper = self.input()
		dirname = os.path.join(self.dir,servername)
		opername = self.script[oper]
		logging.info("operation server is  %s" %servername)
		self.Manager(dirname,opername,line,oper)
		logging.info("Are performing operations %s" %oper)

	#running functions	
	def run(self):
		self.input()
		self.RunCmd()

try:
	update=BatchManager()
	update.run()

except KeyboardInterrupt:
	print "Program Non-normal exit!!"
	sys.exit(1)

