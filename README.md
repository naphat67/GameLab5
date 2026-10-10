# Skybound Trails

เกมแพลตฟอร์ม 3D low-poly สำหรับ Godot 4.7.2 มี 2 ด่าน ด่านละ 5 เกาะขนาดใหญ่ เก็บแสง หลบกับดัก และเข้าประตูเพื่อผ่านด่าน

## วิธีเล่น

- เดินหน้า/ถอยหลังด้วย `W` / `S` หรือปุ่มลูกศรขึ้น/ลง
- เคลื่อนซ้าย/ขวาด้วย `A` / `D` หรือปุ่มลูกศรซ้าย/ขวา
- กระโดดด้วย `Space` เท่านั้น
- ปุ่ม `WASD` อ่านจากตำแหน่งปุ่มจริง จึงใช้ได้แม้เปลี่ยนภาษาแป้นพิมพ์
- เก็บแสงให้ครบก่อนเข้าประตู
- ตกจากเกาะหรือโดนกับดักจะกลับไปจุดเริ่มของด่าน
- เมื่อจบเกม กด `R` เพื่อเริ่มใหม่

## แหล่งที่มา

- ใช้ฉากต้นแบบและ prefab แพลตฟอร์มจาก [3D Platformer Starter Kit](https://store.godotengine.org/asset/the-silver-demons/platformer-3d-starter-kit/) โดยนำมาจัดวางเส้นทางใหม่สำหรับทั้งสองด่าน
- ตัวละคร **Animated Platformer Character** โดย Quaternius จาก [Poly Pizza](https://poly.pizza/m/kKtL4zvS3n) (CC0) พร้อมแอนิเมชัน Idle, Run และ Jump
- เส้นทางและตำแหน่งอุปสรรคของด่านจัดทำขึ้นสำหรับโปรเจกต์นี้ โดยใช้ prefab จาก Starter Kit

## เปิดโปรเจกต์

เปิด `project.godot` ด้วย Godot 4.7.2 หรือใหม่กว่า แล้วกด Run Project

## เล่นบนเว็บผ่าน GitHub Pages

เว็บเกมอยู่ในโฟลเดอร์ `docs/` ให้คงไฟล์ `index.html`, `.js`, `.wasm`, `.pck` และไฟล์ประกอบอื่น ๆ ไว้ด้วยกัน ห้ามเปลี่ยนชื่อไฟล์ที่ Godot ส่งออก

หลังอัปโหลดโปรเจกต์ขึ้น branch `main` แล้ว ตั้งค่า GitHub Pages ดังนี้:

1. เปิด `Settings` ของ repository
2. เลือก `Pages`
3. ตั้ง `Deploy from a branch` → branch `main` → folder `/docs` แล้วกด `Save`
4. เปิดเกมที่ `https://naphat67.github.io/GameLab5/`

## ส่งออกเว็บใหม่

ใช้ Godot 4.7.2 พร้อม Web export templates แล้วเลือก preset `Web` จากเมนู Export เพื่อสร้างไฟล์ใหม่ใน `docs/` จากนั้น commit และ push การเปลี่ยนแปลงขึ้น `main`.
