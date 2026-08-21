.PHONY: prepare train exp mlflow test help

PYTHON = .venv/bin/python

help:
	@echo "Các lệnh Make khả dụng:"
	@echo "  make prepare  - Tải và chia tập dữ liệu (train_batch1, holdout, train_batch2)"
	@echo "  make exp      - Tự động chạy 3 thí nghiệm MLflow & chọn thông số tối ưu"
	@echo "  make train    - Huấn luyện mô hình với siêu tham số hiện tại trong params.yaml"
	@echo "  make mlflow   - Khởi động MLflow UI (http://localhost:5000)"
	@echo "  make test     - Chạy unit test mô hình"

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
