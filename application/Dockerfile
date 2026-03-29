# ==========================================
# Stage 1: Cài đặt dependencies
# ==========================================
FROM node:18-alpine AS builder

WORKDIR /app

# Copy file khai báo dependencies trước để tận dụng Docker cache
COPY package.json package-lock.json ./

# Cài đặt chỉ production dependencies (không cài devDependencies như nodemon)
RUN npm ci --only=production

# ==========================================
# Stage 2: Chạy ứng dụng (Image nhẹ nhất)
# ==========================================
FROM node:18-alpine

WORKDIR /app

# Tạo user riêng thay vì chạy bằng root (Bảo mật - DevSecOps)
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copy dependencies đã cài từ stage trước
COPY --from=builder /app/node_modules ./node_modules

# Copy toàn bộ source code ứng dụng
COPY . .

# Chuyển sang user không có quyền root
USER appuser

# Khai báo cổng mà ứng dụng Express lắng nghe
EXPOSE 3000

# Lệnh khởi chạy ứng dụng
CMD ["node", "main.js"]
