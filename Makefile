.PHONY: prepare train exp mlflow test help dispose-aws dispose-ec2 dispose-s3 dispose-sg dispose-keypair

PYTHON = .venv/bin/python
AWS_REGION ?= us-east-1
S3_BUCKET ?= datdt-income-bucket-2026
KEY_PAIR_NAME ?= income_deploy
SG_NAME ?= income-api-sg

help:
	@echo "Các lệnh Make khả dụng:"
	@echo "  make prepare      - Tải và chia tập dữ liệu (train_batch1, holdout, train_batch2)"
	@echo "  make exp          - Tự động chạy 3 thí nghiệm MLflow & chọn thông số tối ưu"
	@echo "  make train        - Huấn luyện mô hình với siêu tham số hiện tại trong params.yaml"
	@echo "  make mlflow       - Khởi động MLflow UI (http://localhost:5000)"
	@echo "  make test         - Chạy unit test mô hình"
	@echo "  make dispose-aws  - Hủy/Xóa tất cả tài nguyên AWS (EC2, SG, Key Pair, S3 Bucket)"
	@echo "  make dispose-ec2  - Hủy các EC2 Instances liên quan (*income*)"
	@echo "  make dispose-s3   - Làm rỗng và xóa S3 Bucket ($(S3_BUCKET))"
	@echo "  make dispose-sg   - Xóa Security Group (*income*)"
	@echo "  make dispose-keypair - Xóa Key Pair (*income*)"

prepare:
	$(PYTHON) prepare_data.py

exp:
	@export MLFLOW_TRACKING_URI=sqlite:///mlflow.db && \
	export MLFLOW_ARTIFACT_ROOT=./mlartifacts && \
	$(PYTHON) run_experiments.py

train:
	@export MLFLOW_TRACKING_URI=sqlite:///mlflow.db && \
	export MLFLOW_ARTIFACT_ROOT=./mlartifacts && \
	$(PYTHON) src/train.py

mlflow:
	@export MLFLOW_TRACKING_URI=sqlite:///mlflow.db && \
	mlflow ui --backend-store-uri sqlite:///mlflow.db --port 5000

test:
	$(PYTHON) -m pytest tests/

# ==============================================================================
# AWS DISPOSAL / CLEANUP TARGETS
# ==============================================================================

dispose-aws: dispose-ec2 dispose-sg dispose-keypair dispose-s3
	@echo "=== Toàn bộ tài nguyên AWS liên quan đã được dọn dẹp (disposed) thành công ==="

dispose-ec2:
	@echo "--- 1. Đang dừng và xóa (terminate) các EC2 Instance ---"
	@INST_IDS=$$(aws ec2 describe-instances --region $(AWS_REGION) \
		--filters "Name=tag:Name,Values=*income*" "Name=instance-state-name,Values=pending,running,stopping,stopped" \
		--query "Reservations[].Instances[].InstanceId" --output text 2>/dev/null); \
	if [ -n "$$INST_IDS" ]; then \
		echo "Tìm thấy Instance ID(s): $$INST_IDS"; \
		aws ec2 terminate-instances --region $(AWS_REGION) --instance-ids $$INST_IDS; \
		echo "Đang chờ EC2 Instance dừng hoàn toàn..."; \
		aws ec2 wait instance-terminated --region $(AWS_REGION) --instance-ids $$INST_IDS; \
		echo "EC2 Instance đã bị hủy (terminated)."; \
	else \
		echo "Không tìm thấy EC2 Instance nào trùng khớp."; \
	fi

dispose-sg:
	@echo "--- 2. Đang xóa Security Group ($(SG_NAME)) ---"
	@SG_IDS=$$(aws ec2 describe-security-groups --region $(AWS_REGION) \
		--filters "Name=group-name,Values=*income*" \
		--query "SecurityGroups[].GroupId" --output text 2>/dev/null); \
	if [ -n "$$SG_IDS" ]; then \
		for sg in $$SG_IDS; do \
			echo "Đang xóa Security Group: $$sg"; \
			aws ec2 delete-security-group --region $(AWS_REGION) --group-id $$sg || echo "Cảnh báo: Chưa xóa được $$sg (có thể cần chờ EC2 giải phóng hoàn toàn)."; \
		done; \
	else \
		echo "Không tìm thấy Security Group nào trùng khớp."; \
	fi

dispose-keypair:
	@echo "--- 3. Đang xóa Key Pair ($(KEY_PAIR_NAME)) ---"
	@KEY_NAMES=$$(aws ec2 describe-key-pairs --region $(AWS_REGION) \
		--query "KeyPairs[?contains(KeyName, 'income')].KeyName" --output text 2>/dev/null); \
	if [ -n "$$KEY_NAMES" ]; then \
		for k in $$KEY_NAMES; do \
			echo "Đang xóa Key Pair: $$k"; \
			aws ec2 delete-key-pair --region $(AWS_REGION) --key-name $$k; \
		done; \
	else \
		echo "Không tìm thấy Key Pair nào trùng khớp."; \
	fi

dispose-s3:
	@echo "--- 4. Đang làm rỗng và xóa S3 Bucket ($(S3_BUCKET)) ---"
	@if aws s3api head-bucket --bucket $(S3_BUCKET) --region $(AWS_REGION) 2>/dev/null; then \
		echo "Đang xóa dữ liệu và bucket $(S3_BUCKET)..."; \
		aws s3 rb s3://$(S3_BUCKET) --force; \
		echo "S3 Bucket $(S3_BUCKET) đã được xóa."; \
	else \
		echo "S3 Bucket $(S3_BUCKET) không tồn tại hoặc không thể truy cập."; \
	fi

