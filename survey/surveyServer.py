from os import curdir
from os.path import join as pjoin

from BaseHTTPServer import BaseHTTPRequestHandler, HTTPServer

import json
import urlparse
import subprocess
import cgi
import urllib
import time

class StoreHandler(BaseHTTPRequestHandler):

	#Handler for the GET requests
	def do_GET(self):
		if self.path=="/":
			self.path="/survey.html"

		try:
			#Check the file extension required and
			#set the right mime type

			sendReply = False
			if self.path.endswith(".html"):
				mimetype='text/html'
				sendReply = True
			if self.path.endswith(".jpg"):
				mimetype='image/jpg'
				sendReply = True
			if self.path.endswith(".gif"):
				mimetype='image/gif'
				sendReply = True
			if self.path.endswith(".js"):
				mimetype='application/javascript'
				sendReply = True
			if self.path.endswith(".css"):
				mimetype='text/css'
				sendReply = True

			if sendReply == True:
				#Open the static file requested and send it
				f = open(curdir + "/" + self.path) 
				self.send_response(200)
				self.send_header('Content-type',mimetype)
				self.end_headers()
				self.wfile.write(f.read())
				f.close()
			return

		except IOError:
			self.send_error(404,'File Not Found: %s' % self.path)


	def do_POST(self):
		if self.path == '/surveyresponse':
                        
                        data = self.rfile.read(int(self.headers['Content-Length']))
                        decoded = json.loads(urllib.unquote(data).decode('utf8'))
                        entitiesArray =  decoded["entities"]
                        isProgrammer = decoded["programmer"]

                        userId = time.time() # this server is single threaded, so this is ok


                        programmerData = pjoin(curdir, 'programmerData.csv')
                        entityData = pjoin(curdir, 'entityData.csv')
                        
                        pd = open(programmerData, "a")
                        pd.write(str(userId) + "," +  str(isProgrammer) + "\n")
                        pd.close()

                        ed = open(entityData, "a")
                        for entity in entitiesArray:
                                entityRecord = [entity["name"], entity["index"], entity["time"], entity["clickedLink"], "\"" + str(entity["selected"])+"\""]
                                entityRecord = [str(i) for i in entityRecord]
                                ed.write(str(userId) + "," +  ",".join(entityRecord) + "\n")
                        ed.close()
                        
			self.send_response(200)


server = HTTPServer(('', 8081), StoreHandler)
server.serve_forever()







