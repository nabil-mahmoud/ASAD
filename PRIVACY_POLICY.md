# Privacy Policy for ASAD (نظام تسجيل الحضور الذكي)

**Last updated:** November 1, 2026

## 1. Introduction
This Privacy Policy describes how **ASAD** ("we", "our", or "the app"), with package name `com.asad.offline.attendance`, handles user information. ASAD is a dedicated offline university attendance management application designed for professors and academic institutions.

## 2. 100% Offline Architecture & Zero Data Collection
- **No Internet Required:** ASAD operates 100% locally on your device and does not require an active internet connection to perform its core functions.
- **No Data Collection:** We do not collect, transmit, store on external servers, monetize, or share any personal information, student records, academic IDs, course data, or usage analytics.
- **Local Storage:** All student rosters, session records, and attendance logs are stored exclusively in the local SQLite database on your device.

## 3. Device Permissions and How They Are Used
- **Camera (`CAMERA`):**
  - **Purpose:** Used strictly in real-time for optical scanning of linear barcodes (Code 128, Code 39, EAN-13) and QR codes from university student ID cards.
  - **Privacy Guarantee:** The camera feed is processed in real-time memory only. No photos, video recordings, or camera frames are ever saved, stored on disk, or uploaded to any server.
- **Flashlight (`FLASHLIGHT`):**
  - **Purpose:** Used optionally by the user to illuminate lecture halls or low-light environments during scanning.
- **Storage / File Sharing (`READ_MEDIA_DOCUMENTS` / File Export):**
  - **Purpose:** Used exclusively when the professor explicitly chooses to import student roster Excel files or export attendance sheets in Excel (`.xlsx`) or PDF format.

## 4. Third-Party Sharing
ASAD contains **no third-party SDKs, no advertising networks, no third-party analytics (e.g. Firebase or Google Analytics), and no cloud tracking**. No user or student data is ever shared with third parties.

## 5. Security of Your Data
Because all data is retained locally on your personal device, your data security is protected by your device's operating system security (passcode, biometric lock, and sandboxing). You retain full control over your data and can delete any course or session records directly from within the app at any time.

## 6. Children's Privacy
ASAD is intended for use by university faculty, academic staff, and higher-education students (ages 18 and older). We do not knowingly collect any data from children under the age of 13.

## 7. Contact Us
If you have any questions or feedback regarding this Privacy Policy, please contact:
- **Developer / Academic Supervisor:** Dr. Nabil Mahmoud Elshaer
- **Email:** nabilmahmoudelshaer@gmail.com
- **Repository:** https://github.com/nabil-mahmoud/ASAD

---

# سياسة الخصوصية لتطبيق ASAD (نظام تسجيل الحضور الذكي)

**تاريخ التحديث:** 1 نوفمبر 2026

## 1. المقدمة
توضح سياسة الخصوصية هذه كيفية تعامل تطبيق **ASAD** (حزمة `com.asad.offline.attendance`) مع بيانات المستخدمين. التطبيق مخصص لإدارة ورصد حضور وغياب الطلاب بالجامعات بطريقة أوفلاين ذكية ومستقلة.

## 2. العمل بدون إنترنت 100% وعدم جمع أي بيانات
- **بدون إنترنت:** يعمل التطبيق بشكل محلي كامل ولا يحتاج لأي اتصال بالإنترنت للقيام بمهامه.
- **عدم جمع البيانات:** نحن لا نجمع، ولا ننقل، ولا نشارك أي بيانات شخصية، أو أرقام جلوس/أكواد جامعية، أو كشوفات طلاب مع أي سيرفرات أو أطراف ثالثة نهائياً.
- **قاعدة بيانات محلية:** كافة بيانات الطلاب والمقررات والجلسات تُحفظ حصرياً داخل ذاكرة الهاتف المحلية (SQLite).

## 3. الصلاحيات المستخدمة
- **الكاميرا (Camera):** تُستخدم لحظياً وبشكل مباشر لمسح الباركود وQR كود بطاقات الطلاب الجامعية فقط. لا يتم حفظ أو تسجيل أي صور أو فيديوهات على الجهاز أو نقلها خارجياً.
- **الفلاش (Flashlight):** لتوفير إضاءة إضافية في المدرجات المظلمة أثناء المسح.
- **الملفات والمستندات:** لاستيراد شيت إكسيل الطلاب أو تصدير كشوفات الحضور كملفات إكسيل (`.xlsx`) و PDF بطلب مباشر من المستخدم.

## 4. التواصل
لأي استفسارات تتعلق بسياسة الخصوصية:
- **البريد الإلكتروني:** nabilmahmoudelshaer@gmail.com
