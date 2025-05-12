# Let's learn Assembly Language
Đây là nội dung khóa học ngôn ngữ Assembly AMD64 trên Linux.

## Yêu cầu đầu vào:
- Biết Linux và terminal cơ bản
- Có ý thích tìm hiểu về kiến trúc máy tính
- Không yêu cầu kiến thức Assembly trước đó

## Mục tiêu
Học viên sau khi học xong sẽ nắm được kiến thức về các phần sau:

- Kiến trúc cơ bản của trong máy tính
- Tổ chức bộ nhớ
- Thanh ghi và phân loại thanh ghi
- Các lệnh assembly cơ bản
- Tổ chức mã nguồn, include và link
- Cách chương trình được thực thi
- Giao tiếp với hệ điều hành Linux thông qua syscall
- Hiểu cách gọi ngắt, hàm, stack và quy ước System V AMD64 ABI
- Sử dụng lệnh nhảy và lặp
- Quản lý bộ nhớ
- Debugging với gdb
- Sử dụng các hàm libc từ Assembly

## Danh sách bài học (dự kiến)
- Cài đặt môi trường
- Hello World!
- Các thành phần trong một chương trình Assembly
- Bit và các hệ cơ số
- Làm quen với gdb
- Section (segment)
	- Tổ chức bộ nhớ của một chương trình
	- Code segment
	- Data segment
	- Stack segment
	- Heap
- Thanh ghi (giới thiệu, hi/lo)
  - Các thanh ghi dữ liệu 
  - Các thanh ghi địa chỉ/con trỏ
  - Các thanh ghi index
  - Các thanh ghi segment (segment trong các chế độ 16/32/64 bit)
  - Thanh ghi cờ
- Gọi các lệnh hệ thống Linux (syscall/int 80h)
- Kernel/User mode
- Các chế độ địa chỉ
- Khai báo biến/const và các kiểu dữ liệu
- Array
- Bảng mã ASCII
- Các lệnh cơ bản
  - Lệnh gán và các lệnh số học
  - Lệnh logic và dịch bit
  - Lệnh rẽ nhánh (có và không có điều kiện)
  - Vòng lặp
- Khai báo và gọi thủ tục (call/ret)
- System V AMD64 ABI
- Tổ chức mã nguồn với include và link
- Macro
- Quản lý bộ nhớ
- Làm việc với hệ thống file

# Tài liệu tham khảo
- [Intel® 64 and IA-32 Architectures Software Developer's Manual Volume 1: Basic Architecture](https://www.intel.com/content/www/us/en/developer/articles/technical/intel-sdm.html)
- [NASM manual](https://www.nasm.us/xdoc/2.16.03/html/nasmdoc0.html)
- [Linux System Call Table - Chromium OS](https://www.chromium.org/chromium-os/developer-library/reference/linux-constants/syscalls/)
- [Assembly Programming Tutorial - tutorialspoint](https://www.tutorialspoint.com/assembly_programming/index.htm)
- [Debugging with gdb](https://www.eecs.umich.edu/courses/eecs373/readings/Debugger.pdf)
- [System V Application Binary Interface AMD64 Architecture Processor Supplement](https://cs61.seas.harvard.edu/site/2022/pdf/x86-64-abi-20210928.pdf)
- [System V ABI - OSDev](https://wiki.osdev.org/System_V_ABI)
