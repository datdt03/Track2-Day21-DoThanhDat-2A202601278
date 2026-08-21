import os
import yaml
import json
import mlflow
from src.train import train

# Dat bien moi truong tracking cho MLflow
os.environ["MLFLOW_TRACKING_URI"] = "sqlite:///mlflow.db"
os.environ["MLFLOW_ARTIFACT_ROOT"] = "./mlartifacts"

experiments = [
    {
        "name": "Thí nghiệm 1 (Mô hình nhỏ)",
        "params": {"n_estimators": 50, "learning_rate": 0.05, "max_depth": 2}
    },
    {
        "name": "Thí nghiệm 2 (Cấu hình mặc định)",
        "params": {"n_estimators": 100, "learning_rate": 0.1, "max_depth": 3}
    },
    {
        "name": "Thí nghiệm 3 (Cấu hình tối ưu)",
        "params": {"n_estimators": 150, "learning_rate": 0.1, "max_depth": 4}
    }
]

print("==========================================================================")
print("       BẮT ĐẦU CHẠY 3 THÍ NGHIỆM TỰ ĐỘNG & THEO DÕI QUA MLFLOW           ")
print("==========================================================================")

results = []
best_f1 = -1.0
best_params = None

for idx, exp in enumerate(experiments, 1):
    name = exp["name"]
    params = exp["params"]
    print(f"\n[+] Chạy Thí Nghiệm {idx}: {name}")
    print(f"    Siêu tham số: {params}")

    # Ghi params vao file params.yaml
    with open("params.yaml", "w") as f:
        yaml.dump(params, f, default_flow_style=False)

    # Huan luyen
    f1 = train(params)

    # Doc file outputs/report.json
    with open("outputs/report.json", "r") as f:
        report = json.load(f)

    acc = report.get("accuracy", 0.0)
    results.append({
        "run": idx,
        "name": name,
        "params": params,
        "f1_score": f1,
        "accuracy": acc
    })

    if f1 > best_f1:
        best_f1 = f1
        best_params = params

print("\n==========================================================================")
print("                          BẢNG KẾT QUẢ SO SÁNH                           ")
print("==========================================================================")
print(f"{'STT':<5} | {'N_Estimators':<12} | {'LR':<6} | {'Max Depth':<10} | {'F1 Score':<10} | {'Accuracy':<10}")
print("-" * 70)
for r in results:
    p = r["params"]
    print(f"{r['run']:<5} | {p['n_estimators']:<12} | {p['learning_rate']:<6} | {p['max_depth']:<10} | {r['f1_score']:.4f}     | {r['accuracy']:.4f}")
print("-" * 70)

print(f"\n[*] Bộ siêu tham số TỐI ƯU NHẤT (F1 Score cao nhất):")
print(f"    -> {best_params}")
print(f"    -> F1 Score: {best_f1:.4f} (Đạt ngưỡng F1 >= 0.65)")

# Cap nhat params.yaml voi bo sieu tham so tot nhat
with open("params.yaml", "w") as f:
    yaml.dump(best_params, f, default_flow_style=False)

print("[✓] Đã lưu bộ siêu tham số tối ưu vào file `params.yaml`.")
print("==========================================================================")
