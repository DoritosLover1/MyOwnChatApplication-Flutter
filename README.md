# 💬 MyOwnChatApplication - Flutter

Modern, güvenli ve gerçek zamanlı bir mesajlaşma uygulaması. Bu proje; Flutter'ın gücü, **Supabase**'in kimlik doğrulama altyapısı ve **Sendbird**'ün anlık mesajlaşma yetenekleri birleştirilerek geliştirilmiştir.

## 🚀 Özellikler

- 🔐 **Güvenli Kimlik Doğrulama:** Supabase üzerinden şifreli Email/Şifre ile kayıt olma ve giriş yapma.
- ⚡ **Hızlı Giriş (Quick Login):** Yerel hesapları güvenle saklayarak (Secure Storage & Sqflite) hesaplar arası tek tıkla geçiş yapabilme.
- 💬 **Gerçek Zamanlı Sohbet:** Sendbird Chat SDK kullanılarak anlık birebir ve grup mesajlaşma yeteneği.
- 🎨 **Modern ve Şık Arayüz:** Kullanıcı dostu, animasyonlu ve "vivid" renk paletine sahip özel tasarım.
- 🛡️ **Güvenlik Odaklı:** Hassas API anahtarları `.env` üzerinden yönetilir ve Git geçmişine sızması engellenir.

---

## 🛠️ Kullanılan Teknolojiler

- **[Flutter](https://flutter.dev/):** Çapraz platform arayüz geliştirme çerçevesi.
- **[Supabase](https://supabase.com/):** Açık kaynak Firebase alternatifi (Backend ve Kimlik Doğrulama).
- **[Sendbird](https://sendbird.com/):** Gelişmiş In-App Chat SDK.
- **Güvenlik & Yerel Depolama:** `flutter_secure_storage`, `sqflite`, `flutter_dotenv`

---

## ⚙️ Kurulum ve Çalıştırma

Projeyi kendi bilgisayarınızda çalıştırmak için aşağıdaki adımları izleyin:

### 1. Depoyu Klonlayın
```bash
git clone https://github.com/DoritosLover1/MyOwnChatApplication-Flutter.git
cd MyOwnChatApplication-Flutter
```

### 2. Bağımlılıkları Yükleyin
```bash
flutter pub get
```

### 3. Çevre Değişkenlerini (Environment Variables) Ayarlayın
Ana dizinde (`lib` klasörüyle aynı dizinde) bir `.env` dosyası oluşturun ve içerisine API anahtarlarınızı ekleyin:
```env
SUPABASE_URL=https://sizin_supabase_url_adresiniz.supabase.co
SUPABASE_ANON_KEY=sizin_supabase_anon_key_degeriniz
SENDBIRD_APP_ID=sizin_sendbird_app_id_degeriniz
```

### 4. Uygulamayı Çalıştırın
```bash
flutter run
```

---

## 🤝 Katkıda Bulunma

Bu proje geliştirilmeye açıktır. Herhangi bir hata bulursanız veya özellik eklemek isterseniz, lütfen bir **Pull Request (PR)** açmaktan veya **Issue** oluşturmaktan çekinmeyin!

⭐ Bu projeyi beğendiyseniz yıldız (star) vermeyi unutmayın!
