# Báo Cáo Lab Day 21 - CI/CD cho AI Systems

| | |
|---|---|
| Họ và tên | Đỗ Thành Đạt |
| MSSV | 2A202601278 |
| Lớp / Khóa | K4 |
| Repo GitHub | https://github.com/Datdt03/Track2-Day21-DoThanhDat-2A202601278 |
| Ngày nộp | 22/08/2026 |

---

## 1. Bộ Siêu Tham Số Đã Chọn và Lý Do

| Lần chạy | n_estimators | learning_rate | max_depth | f1_score | accuracy |
|---|---|---|---|---|---|
| 1 | 150 | 0.1 | 4 | 0.7156 | 0.876 |
| 2 | 100 | 0.1 | 3 | 0.7109 | 0.878 |
| 3 | 50 | 0.05 | 2 | 0.6051 | 0.846 |

**Bộ siêu tham số đã chọn:** n_estimators = 150, learning_rate = 0.1, max_depth = 4.

**Lý do:** Em chọn bộ tham số này vì đạt chỉ số F1 cao nhất trong các lần thử nghiệm. Lần chạy thứ hai có accuracy cao hơn một chút nhưng F1 lại thấp hơn, cho thấy mô hình chưa phân loại thực sự tốt lớp thu nhập cao. Khi em tăng số cây kết hợp độ sâu hợp lý, mô hình học được các đặc trưng tốt hơn mà không bị quá khớp.

---

## 2. Vì Sao Ngưỡng Chất Lượng Đặt Trên F1 Chứ Không Phải Accuracy

Tập dữ liệu có sự chênh lệch lớn khi nhóm thu nhập thấp chiếm khoảng 75%. Nếu một mô hình dự đoán tất cả là thu nhập thấp thì điểm accuracy vẫn đạt 0.75 nhưng hoàn toàn không học được gì. Chỉ số F1 đo lường cân bằng giữa độ chính xác và độ bao phủ của nhóm thu nhập cao, giúp phản ánh đúng năng lực mô hình. Việc đánh giá trực tiếp trên lớp dương giúp theo dõi chính xác mục tiêu thay vì bị làm mờ bởi tỷ lệ đa số.

---

## 3. Khó Khăn Gặp Phải và Cách Giải Quyết

| Khó khăn | Nguyên nhân | Cách giải quyết |
|---|---|---|
| Pipeline CI CD bị lỗi khi tải dữ liệu từ cloud | Môi trường thiếu thư viện dvc s3 và chưa có thông tin xác thực AWS | Em bổ sung dependency và thiết lập GitHub Secrets đầy đủ |
| Cổng dịch vụ API trên máy chủ không phản hồi | Nhóm bảo mật Security Group chưa cho phép lưu thông cổng 8080 | Em cập nhật lại quy tắc inbound trên AWS EC2 để mở cổng 8080 |

---

## 4. So Sánh Bước 2 và Bước 3

| | f1_score | accuracy |
|---|---|---|
| Bước 2 (chỉ train_batch1) | 0.7156 | 0.876 |
| Bước 3 (thêm train_batch2) | 0.7156 | 0.876 |

**Nhận xét:** Khi bổ sung thêm dữ liệu mới, kết quả dự báo không thay đổi so với trước. Điều này phản ánh tập dữ liệu mới có cùng phân phối và không mang lại thêm thông tin hữu ích cho mô hình. Tuy vậy, kết quả vẫn vượt ngưỡng 0.65 nên quy trình tự động hóa vẫn hoàn tất việc đóng gói và triển khai bình thường.
