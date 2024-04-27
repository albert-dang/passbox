from flask import Flask, jsonify, make_response, request, session
from azure.storage.blob import BlobServiceClient
from functools import wraps
import json, os, secrets

app = Flask(__name__)
app.secret_key = secrets.token_hex(16)
connect_str = os.environ.get('STORAGE_CONNECTION_STRING')
blob_service_client = BlobServiceClient.from_connection_string(connect_str)
static_container_client = blob_service_client.get_container_client('static')
uploads_container_client = blob_service_client.get_container_client('uploads')

def login_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'user' not in session:
            return jsonify({'message': 'Authentication required'}), 401
        return f(*args, **kwargs)
    return decorated_function

@app.route('/login', methods=['POST'])
def login():
    try:
        credentials = request.json
        email = credentials.get('email')
        password = credentials.get('password')
        
        blob_client = static_container_client.get_blob_client('users.json')
        download_stream = blob_client.download_blob()
        users_data = download_stream.readall()
        users = json.loads(users_data)
        
        user = users.get(email)
        if user and user['password'] == password:
            session['user'] = email
            return jsonify({'message': 'Login successful'}), 200
        else:
            return jsonify({'message': 'Invalid credentials'}), 401
    except Exception as e:
        return jsonify({'message': 'An error occurred during login', 'error': str(e)})

@app.route('/', methods=['GET'])
def index():
    blob_client = static_container_client.get_blob_client('index.html')
    download_stream = blob_client.download_blob()
    html_content = download_stream.readall()
    response = make_response(html_content, 200)
    response.mimetype = 'text/html'
    return response

@app.route('/files', methods=['GET'])
@login_required
def list_files():
    blob_list = uploads_container_client.list_blobs()
    files = [blob.name for blob in blob_list]
    return jsonify(files)

@app.route('/download', methods=['GET'])
@login_required
def download_file():
    selected_file_name = request.args.get('filename')
    if not selected_file_name:
        return jsonify({"error": "No file selected or available for download."}), 400

    blob_client = uploads_container_client.get_blob_client(selected_file_name)
    
    try:
        download_stream = blob_client.download_blob()
        file_data = download_stream.readall()
        blob_client.delete_blob()

        response = make_response(file_data)
        response.headers['Content-Disposition'] = f'attachment; filename={selected_file_name}'
        response.mimetype = 'application/octet-stream'
        return response
    except Exception as e:
        return jsonify({"error": str(e)}), 404

@app.route('/upload', methods=['POST'])
@login_required
def upload_file():
    if 'file' not in request.files:
        return jsonify({'error': 'No file part'}), 400
    
    file = request.files['file']
    if file.filename == '':
        return jsonify({'error': 'No selected file'}), 400
    
    if file:
        blob_client = uploads_container_client.get_blob_client(file.filename)
        blob_client.upload_blob(file, overwrite=True)
        return jsonify({'message': 'File successfully uploaded'}), 200

@app.route('/select_file', methods=['POST'])
@login_required
def select_file():
    selected_file = request.json.get('filename')
    if not selected_file:
        return jsonify({'message': 'Filename is required'}), 400

    session['selected_file_name'] = selected_file
    return jsonify({'message': f'File {selected_file} selected'}), 200

if __name__ == '__main__':
    app.run()