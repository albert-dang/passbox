import os
import sys
from azure.storage.blob import BlobServiceClient

def upload_files_to_container(connection_string, container_name, source_folder):
    try:
        blob_service_client = BlobServiceClient.from_connection_string(connection_string)
        container_client = blob_service_client.get_container_client(container_name)
        
        for root, dirs, files in os.walk(source_folder):
            for file in files:
                file_path = os.path.join(root, file)
                blob_path = os.path.relpath(file_path, start=source_folder)
                blob_client = container_client.get_blob_client(blob_path)
                
                print(f"Uploading {file_path} to blob {blob_path} ...")
                with open(file_path, "rb") as data:
                    blob_client.upload_blob(data, overwrite=True)
                    
        print("Upload completed successfully.")
    except Exception as e:
        print(f"An error occurred: {e}")
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: upload_static.py <STORAGE_CONNECTION_STRING>")
        sys.exit(1)
    
    connection_string = sys.argv[1]
    container_name = "static"
    source_folder = "./static"
    
    upload_files_to_container(connection_string, container_name, source_folder)