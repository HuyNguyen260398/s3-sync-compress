import os
import boto3
import json
import zipfile
import subprocess
import sys
from pathlib import Path
from datetime import datetime
import logging
from fastapi import FastAPI
from fastapi.responses import JSONResponse
import uvicorn

logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

TRIGGER_FILE = "/tmp/trigger_sync"

# FastAPI application
app = FastAPI(title="S3 Sync API", version="1.0.0")


@app.post("/api/start-sync")
async def start_sync():
    """Trigger S3 sync and compression process"""
    try:
        Path(TRIGGER_FILE).touch()
        return JSONResponse(
            status_code=200,
            content={
                "status": "sync triggered",
                "message": "Sync process will start shortly",
            },
        )
    except Exception as e:
        logger.error(f"Failed to trigger sync: {e}")
        return JSONResponse(
            status_code=500,
            content={"error": "Failed to trigger sync", "message": str(e)},
        )


@app.get("/api/health")
async def health_check():
    """Health check endpoint"""
    return JSONResponse(
        status_code=200,
        content={"status": "healthy", "message": "API server is running"},
    )


def start_api_server():
    """Start the FastAPI server on port 8001"""
    logger.info("Starting API server on port 8001")
    uvicorn.run(
        app, host="127.0.0.1", port=8001, log_level="critical"  # Suppress uvicorn logs
    )


class S3SyncCompress:
    def __init__(self):
        try:
            # Verify AWS credentials first
            self.verify_aws_credentials()

            self.s3 = boto3.client("s3")
            self.local_dir = Path("/app/data")
            self.output_dir = Path("/app/output")
            self.local_dir.mkdir(exist_ok=True)
            self.output_dir.mkdir(exist_ok=True)
            logger.info("S3SyncCompress initialized successfully")
        except Exception as e:
            logger.error(f"Failed to initialize S3SyncCompress: {e}")
            self.update_status("error", message=str(e))
            raise

    def verify_aws_credentials(self):
        """Verify AWS credentials are available and valid"""
        if not os.getenv("AWS_ACCESS_KEY_ID") or not os.getenv("AWS_SECRET_ACCESS_KEY"):
            raise ValueError("AWS credentials not provided")

        try:
            subprocess.run(
                ["aws", "sts", "get-caller-identity"],
                capture_output=True,
                check=True,
                timeout=10,
            )
            logger.info("AWS credentials verified successfully")
        except Exception as e:
            raise ValueError(f"AWS connection failed: {e}")

    def update_status(
        self, status, files_synced=0, files_compressed=0, message="", download_url=""
    ):
        """Update status file with current progress"""
        status_data = {
            "status": status,
            "files_synced": files_synced,
            "files_compressed": files_compressed,
            "timestamp": datetime.now().isoformat(),
            "message": message,
            "download_url": download_url,
        }

        try:
            with open("/app/output/status.json", "w") as f:
                json.dump(status_data, f, indent=2)
            logger.info(f"Status updated: {status} - {message}")
        except Exception as e:
            logger.error(f"Failed to update status: {e}")

    def sync_from_s3(self, bucket, prefix=""):
        """Download files from S3 bucket"""
        logger.info(f"Starting sync from s3://{bucket}/{prefix}")
        self.update_status(
            "syncing", message=f"Downloading from s3://{bucket}/{prefix}"
        )

        try:
            # List objects with pagination support
            paginator = self.s3.get_paginator("list_objects_v2")
            page_iterator = paginator.paginate(Bucket=bucket, Prefix=prefix)

            files = []
            total_objects = 0

            for page in page_iterator:
                if "Contents" not in page:
                    continue

                for obj in page["Contents"]:
                    # Skip folders (objects ending with /)
                    if obj["Key"].endswith("/"):
                        continue

                    total_objects += 1
                    logger.info(f"Downloading: {obj['Key']} ({obj['Size']} bytes)")

                    local_path = self.local_dir / obj["Key"]
                    local_path.parent.mkdir(parents=True, exist_ok=True)

                    try:
                        self.s3.download_file(bucket, obj["Key"], str(local_path))
                        files.append(local_path)

                        # Update status periodically
                        if len(files) % 5 == 0:
                            self.update_status(
                                "syncing",
                                files_synced=len(files),
                                message=f"Downloaded {len(files)} files...",
                            )
                    except Exception as e:
                        logger.error(f"Failed to download {obj['Key']}: {e}")
                        continue

            if not files:
                logger.warning(f"No files found in s3://{bucket}/{prefix}")
                self.update_status(
                    "completed",
                    files_synced=0,
                    files_compressed=0,
                    message=f"No files found in s3://{bucket}/{prefix}",
                )
            else:
                logger.info(f"Successfully downloaded {len(files)} files")
                self.update_status(
                    "compressing",
                    files_synced=len(files),
                    message=f"Downloaded {len(files)} files, starting compression",
                )

            return files

        except Exception as e:
            logger.error(f"S3 sync error: {e}")
            self.update_status("error", message=f"S3 sync failed: {str(e)}")
            return []

    def create_zip_file(self, files):
        """Create a single zip file with timestamp from all downloaded files"""
        if not files:
            return None

        logger.info(f"Starting compression of {len(files)} files into single zip")

        # Create zip filename with timestamp
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        zip_filename = f"s3_sync_{timestamp}.zip"
        zip_path = self.output_dir / zip_filename

        try:
            with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zipf:
                for i, file_path in enumerate(files):
                    try:
                        # Archive name preserves the relative structure
                        arcname = file_path.relative_to(self.local_dir)
                        logger.info(f"Adding to zip: {file_path.name}")
                        zipf.write(file_path, arcname=str(arcname))

                        # Update status periodically
                        if (i + 1) % 5 == 0 or (i + 1) == len(files):
                            self.update_status(
                                "compressing",
                                files_synced=len(files),
                                files_compressed=i + 1,
                                message=f"Compressing files {i + 1}/{len(files)} into zip",
                            )
                    except Exception as e:
                        logger.error(f"Failed to add {file_path} to zip: {e}")
                        continue

            logger.info(f"Zip file created successfully: {zip_path}")
            logger.info(f"Zip file size: {zip_path.stat().st_size} bytes")
            return zip_path

        except Exception as e:
            logger.error(f"Failed to create zip file: {e}")
            self.update_status("error", message=f"Failed to create zip file: {str(e)}")
            return None

    def upload_zip_to_s3(self, zip_path, target_bucket, prefix=""):
        """Upload zip file to second S3 bucket"""
        if not zip_path or not zip_path.exists():
            logger.error(f"Zip file not found: {zip_path}")
            return None

        try:
            # Determine S3 key
            s3_key = f"{prefix}/{zip_path.name}" if prefix else zip_path.name
            s3_key = s3_key.lstrip("/")  # Remove leading slash if any

            logger.info(f"Uploading zip to s3://{target_bucket}/{s3_key}")
            self.update_status(
                "uploading",
                files_synced=0,
                files_compressed=0,
                message=f"Uploading zip file to s3://{target_bucket}",
            )

            # Upload file
            self.s3.upload_file(str(zip_path), target_bucket, s3_key)

            # Generate download URL (valid for 24 hours)
            download_url = self.s3.generate_presigned_url(
                "get_object",
                Params={"Bucket": target_bucket, "Key": s3_key},
                ExpiresIn=86400,  # 24 hours
            )

            logger.info(f"Zip file uploaded successfully")
            logger.info(f"Download URL: {download_url}")

            return {
                "bucket": target_bucket,
                "key": s3_key,
                "url": download_url,
                "filename": zip_path.name,
                "size": zip_path.stat().st_size,
            }

        except Exception as e:
            logger.error(f"Failed to upload zip to S3: {e}")
            self.update_status("error", message=f"Failed to upload zip to S3: {str(e)}")
            return None

    def run(self):
        """Main operation"""
        try:
            bucket = os.getenv("S3_BUCKET", "test-bucket")
            prefix = os.getenv("S3_PREFIX", "")
            output_bucket = os.getenv("S3_OUTPUT_BUCKET", "")
            output_prefix = os.getenv("S3_OUTPUT_PREFIX", "synced-files")

            # Check if output bucket is provided
            if not output_bucket:
                logger.error("S3_OUTPUT_BUCKET environment variable not set")
                self.update_status(
                    "error", message="S3_OUTPUT_BUCKET environment variable not set"
                )
                return {
                    "files_synced": 0,
                    "files_compressed": 0,
                    "status": "error",
                    "message": "Output S3 bucket not configured",
                }

            logger.info("=" * 50)
            logger.info("S3 Sync & Compress Service Starting")
            logger.info("=" * 50)
            logger.info(f"Source Bucket: {bucket}")
            logger.info(f"Source Prefix: {prefix}")
            logger.info(f"Output Bucket: {output_bucket}")
            logger.info(f"Output Prefix: {output_prefix}")

            # Sync files from S3
            files = self.sync_from_s3(bucket, prefix)

            if not files:
                logger.warning("No files to compress")
                self.update_status(
                    "completed",
                    files_synced=0,
                    files_compressed=0,
                    message="No files found to process",
                )
                return {
                    "files_synced": 0,
                    "files_compressed": 0,
                    "status": "completed",
                    "message": "No files found to process",
                }

            # Create single zip file with timestamp
            zip_path = self.create_zip_file(files)

            if not zip_path:
                logger.error("Failed to create zip file")
                self.update_status("error", message="Failed to create zip file")
                return {
                    "files_synced": len(files),
                    "files_compressed": 0,
                    "status": "error",
                    "message": "Failed to create zip file",
                }

            # Upload zip to output bucket
            upload_result = self.upload_zip_to_s3(
                zip_path, output_bucket, output_prefix
            )

            if not upload_result:
                logger.error("Failed to upload zip to S3")
                self.update_status("error", message="Failed to upload zip to S3")
                return {
                    "files_synced": len(files),
                    "files_compressed": 1,
                    "status": "error",
                    "message": "Failed to upload zip to S3",
                }

            # Create final status
            status = {
                "files_synced": len(files),
                "files_compressed": 1,
                "status": "completed",
                "timestamp": datetime.now().isoformat(),
                "message": f"Successfully processed {len(files)} files, created and uploaded zip file",
                "zip_info": {
                    "filename": upload_result["filename"],
                    "bucket": upload_result["bucket"],
                    "key": upload_result["key"],
                    "size": upload_result["size"],
                    "download_url": upload_result["url"],
                },
            }

            # Write final status
            with open("/app/output/status.json", "w") as f:
                json.dump(status, f, indent=2)

            logger.info("=" * 50)
            logger.info("Operation completed successfully!")
            logger.info(f"Files synced: {len(files)}")
            logger.info(f"Zip file: {upload_result['filename']}")
            logger.info(f"Download URL: {upload_result['url']}")
            logger.info("=" * 50)

            return status

        except Exception as e:
            logger.error(f"Critical error in main operation: {e}")
            error_status = {
                "files_synced": 0,
                "files_compressed": 0,
                "status": "error",
                "timestamp": datetime.now().isoformat(),
                "message": f"Critical error: {str(e)}",
            }

            with open("/app/output/status.json", "w") as f:
                json.dump(error_status, f, indent=2)

            raise


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "api-server":
        start_api_server()
    else:
        try:
            service = S3SyncCompress()
            service.run()
            sys.exit(0)
        except Exception as e:
            logger.error(f"Service failed: {e}")
            sys.exit(1)
