<p align="center">
  <img src="assets/images/app_icon.png" width="110" alt="CG Core Logo" />
</p>

<h1 align="center">CG Core – Küçük İşletme Yönetim Sistemi (SaaS)</h1>

<p align="center">
  Küçük ve orta ölçekli işletmelerin günlük personel, araç, gider ve finansal raporlama süreçlerini tek bir mobil platformda birleştiren çok kiracılı (Multi-Tenant) Flutter & Firebase SaaS uygulaması.
</p>

---

## Özellikler

- **Multi-Tenant SaaS Mimarisi:** Her işletme (`businesses/{businessId}`) kendi verileriyle tamamen izole edilir. Sıkı `firestore.rules` kuralları ile rol bazlı erişim kontrolü sağlanır.
- **Kimlik Doğrulama & İşletme Kurulumu:** E-posta/Şifre ve Google Sign-In desteği; yeni işletme kaydında otomatik şube ve 13 varsayılan gider kategorisi oluşturma.
- **Dashboard (Özet Paneli):** Aylık toplam gider, personel/araç/genel gider kırılımları, yaklaşan sigorta/kasko/muayene uyarıları ve son hareketler.
- **Personel Yönetimi:** Personel kartları, geçmiş ayları etkilemeyen maaş değişiklik tarihçesi, avans/maaş/prim/kesinti kayıtları, 30 günlük kurala göre ücretsiz izin kesintisi ve aylık hakediş hesap özeti.
- **Araç Yönetimi:** Plaka bazlı araç kartları, yakıt/bakım/tamir/sigorta/kasko/muayene giderleri, otomatik kilometre güncelleme ve km başına maliyet analizi.
- **İşletme Giderleri:** Özelleştirilebilir ikon ve renkli gider kategorileri, kamera/galeriden fiş fotoğrafı yükleme (Firebase Storage) ve ay/kategori bazlı filtreleme.
- **Raporlama ve Dışa Aktarım:** Son 6 aylık gider karşılaştırma sütun grafiği, kategori dağılım pasta grafiği (`fl_chart`), personel/araç maliyet raporları, Türkçe PDF (`pdf` / `printing`) ve çok sayfalı `.xlsx` Excel (`excel` / `share_plus`) çıktısı.
- **Kuruş Hassasiyetli Finansal Mimari:** Kayan nokta (floating-point) hatalarını önlemek için tüm parasal alanlar integer kuruş (`amountCents`) olarak saklanır ve canlı Türkçe para formatıyla (`1.500,50 ₺`) girilir.

---

## Teknoloji Yığını

- **Framework:** Flutter (Material 3) & Dart
- **State Management, DI & Routing:** GetX (`GetxController`, `Bindings`, `GetxService`)
- **Mimari:** Clean Architecture + Repository Pattern
- **Backend & Altyapı:** Firebase Authentication, Cloud Firestore, Firebase Storage

---

## Proje Klasör Yapısı

```text
lib/
├── core/               # Tema, rotalar, sabitler, servisler (Auth, Tenant, Storage), formatlayıcılar ve ortak widgetlar
├── data/               # Global modeller (User, Business) ve repository sınıfları
└── modules/
    ├── splash/         # Açılış ve oturum/tenant kontrolü
    ├── auth/           # Giriş ve işletme kayıt (onboarding)
    ├── shell/          # 5 sekmeli ana navigasyon kabuğu
    ├── dashboard/      # Özet gösterge paneli
    ├── employees/      # Personel, maaş geçmişi, hareketler ve izinler
    ├── vehicles/       # Araçlar, bakım ve kilometre maliyet takibi
    ├── expenses/       # İşletme giderleri, kategoriler ve fiş yükleme
    └── reports/        # Grafikler, maliyet raporları ve PDF/Excel dışa aktarım
```

---

## Kurulum (Getting Started)

1. **Depoyu klonlayın ve bağımlılıkları yükleyin:**
   ```bash
   git clone https://github.com/<KULLANICI_ADINIZ>/cg-core.git
   cd cg-core
   flutter pub get
   ```

2. **Firebase projenizi bağlayın:**
   - [Firebase Console](https://console.firebase.google.com/) üzerinden bir proje oluşturun.
   - **Authentication** (Email/Password ve Google), **Cloud Firestore** ve **Firebase Storage** servislerini aktif edin.
   - FlutterFire CLI ile kendi Firebase yapılandırmanızı oluşturun:
     ```bash
     flutterfire configure
     ```
   - Güvenlik kurallarını ve indeksleri yayınlayın:
     ```bash
     npx -y firebase-tools@latest deploy --only firestore:rules,firestore:indexes
     ```

3. **Uygulamayı çalıştırın:**
   ```bash
   flutter run
   ```

4. **Testleri çalıştırın:**
   ```bash
   flutter test
   ```

---

## Lisans

Bu proje [MIT Lisansı](LICENSE) altında açık kaynak olarak lisanslanmıştır.
