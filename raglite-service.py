#!/usr/bin/env python3
"""
PandaWiki RAG Service
简单的RAG服务HTTP接口
"""

import json
import logging
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
import uuid
from datetime import datetime

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# 内存中存储模型配置
models_storage = []

class RAGHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        """处理GET请求"""
        path = urlparse(self.path).path
        
        if path == '/health' or path == '/':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            response = {'status': 'ok', 'service': 'PandaWiki RAG Service'}
            self.wfile.write(json.dumps(response).encode())
        elif path == '/api/v1/models':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            response = {
                'code': 0,
                'data': models_storage,
                'message': 'success'
            }
            self.wfile.write(json.dumps(response).encode())
        else:
            self.send_response(404)
            self.end_headers()
    
    def do_POST(self):
        """处理POST请求"""
        path = urlparse(self.path).path
        content_length = int(self.headers.get('Content-Length', 0))
        
        if path == '/api/v1/models':
            if content_length > 0:
                post_data = self.rfile.read(content_length)
                try:
                    data = json.loads(post_data.decode())
                    logger.info(f"Adding model: {data}")
                    
                    # 创建新的模型配置
                    model_id = str(uuid.uuid4())
                    model_config = {
                        'id': model_id,
                        'provider': data.get('provider', 'openai-compatible-api'),
                        'name': data.get('name', ''),
                        'task_type': data.get('task_type', ''),
                        'api_base': data.get('api_base', ''),
                        'api_key': data.get('api_key', ''),
                        'max_tokens': data.get('max_tokens', 8192),
                        'is_default': data.get('is_default', False),
                        'enabled': data.get('enabled', True),
                        'config': data.get('config', {}),
                        'description': data.get('description', ''),
                        'version': data.get('version', ''),
                        'timeout': data.get('timeout', 30),
                        'create_time': int(datetime.now().timestamp()),
                        'update_time': int(datetime.now().timestamp()),
                        'owner': data.get('owner', ''),
                        'quota_limit': data.get('quota_limit', 0)
                    }
                    
                    models_storage.append(model_config)
                    
                    response = {
                        'code': 0,
                        'data': model_config,
                        'message': 'success'
                    }
                    
                    self.send_response(200)
                    self.send_header('Content-type', 'application/json')
                    self.end_headers()
                    self.wfile.write(json.dumps(response).encode())
                    
                except json.JSONDecodeError:
                    self.send_response(400)
                    self.send_header('Content-type', 'application/json')
                    self.end_headers()
                    error_response = {'code': -1, 'message': 'Invalid JSON'}
                    self.wfile.write(json.dumps(error_response).encode())
            else:
                self.send_response(400)
                self.end_headers()
        elif content_length > 0:
            # 其他POST请求的默认处理
            post_data = self.rfile.read(content_length)
            try:
                data = json.loads(post_data.decode())
                logger.info(f"Received RAG request: {data}")
                
                # 简单的响应
                response = {
                    'status': 'success',
                    'result': 'RAG service is running, but not fully implemented yet.'
                }
                
                self.send_response(200)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps(response).encode())
                
            except json.JSONDecodeError:
                self.send_response(400)
                self.end_headers()
        else:
            self.send_response(400)
            self.end_headers()
    
    def do_DELETE(self):
        """处理DELETE请求"""
        path = urlparse(self.path).path
        
        if path == '/api/v1/models':
            content_length = int(self.headers.get('Content-Length', 0))
            if content_length > 0:
                post_data = self.rfile.read(content_length)
                try:
                    data = json.loads(post_data.decode())
                    logger.info(f"Deleting models: {data}")
                    
                    # 根据models字段删除模型
                    models_to_delete = data.get('models', [])
                    for model_to_delete in models_to_delete:
                        models_storage[:] = [m for m in models_storage 
                                           if not (m.get('name') == model_to_delete.get('name') and 
                                                  m.get('api_base') == model_to_delete.get('api_base'))]
                    
                    response = {
                        'code': 0,
                        'message': 'Models deleted successfully'
                    }
                    
                    self.send_response(200)
                    self.send_header('Content-type', 'application/json')
                    self.end_headers()
                    self.wfile.write(json.dumps(response).encode())
                    
                except json.JSONDecodeError:
                    self.send_response(400)
                    self.send_header('Content-type', 'application/json')
                    self.end_headers()
                    error_response = {'code': -1, 'message': 'Invalid JSON'}
                    self.wfile.write(json.dumps(error_response).encode())
            else:
                self.send_response(400)
                self.end_headers()
        else:
            self.send_response(404)
            self.end_headers()

def run_server():
    server_address = ('', 8080)
    httpd = HTTPServer(server_address, RAGHandler)
    logger.info("RAG Service started on http://localhost:8080")
    logger.info("Health check: http://localhost:8080/health")
    logger.info("Models API: http://localhost:8080/api/v1/models")
    
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        logger.info("Shutting down RAG service...")
        httpd.shutdown()

if __name__ == '__main__':
    run_server() 