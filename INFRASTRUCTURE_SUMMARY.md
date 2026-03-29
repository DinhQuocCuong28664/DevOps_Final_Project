# Tổng kết Quá trình Xây dựng Hạ tầng AWS & EKS

Dưới đây là tổng hợp các bước tiếp cận và cấu hình hạ tầng đã thực hiện, giúp hệ thống đạt chuẩn tối đa cho đồ án:

## 1. Định hình Kiến trúc (Đạt chuẩn Tier 5)
- Quyết định bỏ qua các thao tác cấu hình thủ công để tiến thẳng tới **Kubernetes (Amazon EKS)** - tiêu chuẩn quản lý container hàng đầu hiện nay.
- Lựa chọn kiến trúc hiện đại này giúp "mở khóa" mức điểm tối đa (2.5 điểm) cho phần Kiến trúc dự án.

## 2. Chuẩn bị Công cụ và Bảo mật (DevSecOps)
- Đã cài đặt thành công bộ 3 công cụ cốt lõi làm "vũ khí" trên Windows:
  - `aws-cli`: Để giao tiếp và xác thực với AWS.
  - `terraform`: Để tự động hóa xây dựng hạ tầng (IaC).
  - `kubectl`: Để điều khiển và tương tác với cụm Kubernetes sau này.
- **Điểm cộng DevSecOps (Bảo mật):** Thay vì sử dụng tài khoản Root mang nhiều rủi ro, dự án đã khởi tạo một **IAM User** riêng biệt (`devops-admin`). User này được cấp quyền vừa đủ, cấu hình an toàn qua `aws configure` và file `accessKeys.csv` đã được cất giấu cẩn thận để tránh lộ lọt thông tin nhạy cảm lên GitHub. Tư duy bảo mật từ đầu này là một điểm cộng rất lớn.

## 3. Viết Code Hạ tầng (Infrastructure as Code)
Thay vì tiêu tốn thời gian click chuột trên giao diện web AWS (Console), toàn bộ hệ thống phân tán được triển khai tự động, minh bạch và có thể tái sử dụng thông qua 3 file code Terraform:

- **`provider.tf`**: Khai báo khu vực địa lý (Region) vững chãi để xây dựng dự án là Sydney (`ap-southeast-2`).
- **`vpc.tf`**: "Đào móng" hệ thống mạng. Khởi tạo Mạng riêng ảo (VPC), phân chia logic thành khu vực tiếp đón luồng truy cập bên ngoài (Public Subnets) và khu vực an toàn nội bộ (Private Subnets). Đồng thời, cấu hình NAT Gateway để các máy chủ bên trong (Worker nodes) có thể kết nối Internet tải image một cách an toàn.
- **`eks.tf`**: Xây dựng "bộ não" điều phối là Kubernetes Control Plane. Bên cạnh đó, thiết lập một nhóm máy chủ (Worker Node Group) gồm 2 máy ảo `t3.medium` đặt an toàn trong vùng Private Subnet, sẵn sàng gánh tải ứng dụng.

## 4. Khởi tạo và Xây dựng Dòng lệnh (`init` & `apply`)
Quá trình tự động hóa được thực thi mượt mà qua các lệnh Terraform:
- Chạy `terraform init` để chuẩn bị môi trường, tải các "bản vẽ kỹ thuật" (modules) cần thiết từ HashiCorp.
- Chạy `terraform apply` để ra lệnh cho AWS tiến hành xây dựng toàn bộ hệ thống thực tế trên đám mây, tuân thủ chính xác theo những gì đã được định nghĩa trong code.
