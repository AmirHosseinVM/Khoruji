# OneSpeed — راهنمای ساخت APK

## روش سریع (بدون هیچ سروری) — GitHub Actions

چون الان سروری در دسترس ندارید، این پروژه یه ورک‌فلوی آماده داره
(`.github/workflows/build-apk.yml`) که خودش، رایگان، روی سرورهای گیت‌هاب:
فونت فارسی رو دانلود می‌کنه، پروژه اندروید رو می‌سازه، آیکون/تنظیمات امنیتی
رو اعمال می‌کنه، و در آخر یه APK واقعی و قابل‌نصب بهتون میده — بدون اینکه
شما هیچ سروری داشته باشید.

### مراحل (۵ دقیقه):

1. یه ریپوی رایگان گیت‌هاب بسازید (اگه اکانت ندارید، `github.com` رجیستر کنید — رایگانه)
2. محتوای این زیپ رو توش push کنید:
   ```bash
   cd onespeed_app
   git init
   git add .
   git commit -m "OneSpeed v1"
   git branch -M main
   git remote add origin https://github.com/USERNAME/onespeed.git
   git push -u origin main
   ```
3. برید تب **Actions** توی صفحه‌ی ریپو — یه اجرا به اسم "Build OneSpeed APK"
   خودش شروع میشه (چون push به `main` تریگرشه). اگه شروع نشد، دستی از همون
   تب دکمه‌ی **Run workflow** رو بزنید.
4. صبر کنید (اولین بار ~۸-۱۲ دقیقه، چون Flutter SDK رو خودش دانلود می‌کنه)
5. وقتی سبز شد، پایین صفحه‌ی همون اجرا، بخش **Artifacts** رو باز کنید —
   `onespeed-apk` رو دانلود کنید، زیپشو باز کنید، `app-release.apk` رو
   بریزید رو گوشی و نصب کنید.

**این APK فعلاً با کلید موقت (debug) امضا شده** — یعنی قابل‌نصب و تست کاملاً
واقعیه (اتصال واقعی VPN، پینگ واقعی و غیره)، فقط برای انتشار نهایی بین
مشتری‌ها باید با کلید release واقعی امضا بشه (مرحله بعد).

### برای امضای واقعی (وقتی آماده انتشار بودید)

روی هر سیستمی با `keytool` (حتی خود گیت‌هاب Codespaces رایگان):
```bash
keytool -genkey -v -keystore onespeed-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias onespeed
base64 -w0 onespeed-release.jks > keystore.b64   # لینوکس/مک: بدون -w0 هم کار می‌کنه
```
بعد توی ریپوی گیت‌هاب: **Settings → Secrets and variables → Actions** این
۴ تا secret رو بسازید:
- `ONESPEED_KEYSTORE_BASE64` → محتوای `keystore.b64`
- `ONESPEED_KEYSTORE_PASSWORD`
- `ONESPEED_KEY_ALIAS` → `onespeed`
- `ONESPEED_KEY_PASSWORD`

دفعه بعد که push کنید، APK با همین کلید واقعی امضا میشه. **این فایل jks رو
جای امنی نگه دارید** — هر آپدیت بعدی باید با همین کلید امضا بشه.

---

## روش جایگزین — روی سرور اوبونتوی خودتون (وقتی سرور گرفتید)

اگه بعداً سرور گرفتید و خواستید مستقیم اونجا build بگیرید:

```bash
cd ~
flutter create --platforms=android --org com.onespeed --project-name onespeed onespeed_scaffold
cd onespeed_scaffold
rm -rf lib && cp -r ~/onespeed_delivery/lib .
cp ~/onespeed_delivery/pubspec.yaml .
mkdir -p assets/fonts assets/splash
cp ~/onespeed_delivery/assets/splash/splash_logo.png assets/splash/
# فونت‌ها رو دستی از fonts.google.com/specimen/Vazirmatn بگیرید و بریزید تو assets/fonts/
cp -rf ~/onespeed_delivery/android_overrides/app/src/main/res/mipmap-* android/app/src/main/res/
cp -rf ~/onespeed_delivery/android_overrides/app/src/main/res/drawable-* android/app/src/main/res/
cp -f ~/onespeed_delivery/android_overrides/AndroidManifest.xml android/app/src/main/AndroidManifest.xml
mkdir -p android/app/src/main/res/xml
cp -f ~/onespeed_delivery/android_overrides/network_security_config.xml android/app/src/main/res/xml/
cp -f ~/onespeed_delivery/android_overrides/proguard-rules.pro android/app/
cp -f ~/onespeed_delivery/android_overrides/app_build.gradle android/app/build.gradle

flutter pub get
flutter build apk --release   # بدون کلید هم کار می‌کنه (debug fallback)
```

خروجی: `build/app/outputs/flutter-apk/app-release.apk`

---

## نکات مهم

0. **این نسخه چند باگ جدی قبلی رو فیکس کرده:**
   - قطع نشدن اتصال: یه باگ در تشخیص وضعیت بود (`"DISCONNECTED".contains("CONNECTED")` که همیشه true بود!) — الان با تطبیق دقیق رشته درست شده، بعلاوه یه fallback timeout که اگه هسته جواب نده دکمه گیر نمی‌کنه
   - فرمت ساب: پنل بسته به توکن، گاهی JSON کامل و گاهی لیست ساده‌ی لینک (`vless://`, `ss://`) برمی‌گردونه — الان هر دو حالت پشتیبانی میشه
   - اتصال‌نشدن سرورها: به‌جای ساخت دستی JSON، از تابع خود پلاگین (`FlutterV2ray.parseFromURL`) برای ساخت کانفیگ صحیح Xray استفاده می‌کنیم — **حتماً `flutter pub upgrade flutter_v2ray` بزنید** تا آخرین نسخه (با پشتیبانی کامل REALITY/xhttp) بیاد، وگرنه سرورهای reality همچنان وصل نمیشن
   - پینگ الان واقعیه: از طریق خود پروتکل به `https://www.google.com/gen_204` (نه فقط تست TCP خام) — هم موقع اتصال به «بهترین سرور» خودکار میره، هم با تپ روی هر سرور توی لیست دستی قابل تست‌کردنه
   - نوتیفیکیشن اتصال: اسم سرور (remark) و دکمه‌ی «قطع اتصال» رو پاس میده؛ آیکون نوتیف تک‌رنگ هم اضافه شده (`drawable-*/ic_notification.png`) — اگه پلاگین شما resource دیگه‌ای برای آیکون نوتیف می‌خواد (اسمش بین نسخه‌ها فرق داره)، توی مستندات پلاگین چک کنید

1. **`lib/services/api_service.dart`** → `gatewayBase` از قبل روی
   `https://devfull.sbs/app` تنظیمه (همونی که تست کردیم).
2. **`lib/screens/dashboard_screen.dart`** → `telegramUrl` رو با کانال
   واقعی‌تون عوض کنید.
3. **`lib/services/vpn_service.dart`** → اگه نسخه‌ی نصب‌شده‌ی
   `flutter_v2ray` اسم متدها فرق داشت (مخصوصاً `notificationDisconnectButtonName`
   که ممکنه اسمش فرق کنه یا اصلاً نباشه)، اولین جایی که چک کنید همینجاست.
4. بک‌اند PHP (پوشه‌ی `backend-php/`) رو اگه هنوز آپلود نکردید، طبق راهنمای
   قبلی روی هاستتون بذارید.
5. اگه build توی GitHub Actions قرمز (fail) شد یا باز هم روی گوشی مشکلی
   دیدید، دقیقاً پیام خطا/رفتار رو برام بفرستید — خط‌به‌خط درستش می‌کنم.
