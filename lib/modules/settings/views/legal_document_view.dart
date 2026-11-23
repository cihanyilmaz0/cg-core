import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

enum LegalDocumentType { privacyPolicy, termsOfUse }

class LegalDocumentView extends StatelessWidget {
  final LegalDocumentType type;

  const LegalDocumentView({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final isPrivacy = type == LegalDocumentType.privacyPolicy;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(isPrivacy ? 'Gizlilik Politikası' : 'Kullanım Koşulları'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: isPrivacy ? _buildPrivacySections() : _buildTermsSections(),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPrivacySections() {
    return [
      _header('CG Core Gizlilik Politikası ve KVKK Aydınlatma Metni'),
      _updatedDate('Son Güncelleme: 23 Kasım 2026'),
      _section(
        '1. Veri Sorumlusu',
        'CG Core mobil uygulaması ("Uygulama"), küçük ve orta ölçekli işletmelerin günlük personel, araç ve gider operasyonlarını yönetmesine yardımcı olan bir SaaS platformudur. Gizlilik ve veri güvenliği ile ilgili her türlü sorunuz için cihan_00by@hotmail.com adresinden iletişime geçebilirsiniz.',
      ),
      _section(
        '2. Toplanan ve İşlenen Veriler',
        '• Kimlik ve Hesap Bilgileri: Ad soyad, e-posta adresi ve kimlik doğrulama bilgileri (E-posta/Şifre veya Google ile Giriş).\n'
        '• İşletme Verileri: İşletme adı, faaliyet sektörü, vergi numarası (isteğe bağlı) ve şube bilgileri.\n'
        '• Operasyonel Kayıtlar: Uygulama içerisine girdiğiniz personel kartları, maaş/avans/izin kayıtları, araç plakaları, bakım/yakıt giderleri ve genel işletme giderleri.\n'
        '• Medya ve Kamera/Galeri Erişimi: Yalnızca fiş ve fatura fotoğrafı yüklemek istediğinizde açık izninizle kamera veya galerinize erişilir. Seçilen görseller şifreli olarak bulut depolamaya yüklenir.',
      ),
      _section(
        '3. Verilerin Saklanması ve Güvenliği',
        'Tüm verileriniz Google Cloud / Firebase altyapısı (Firebase Authentication, Cloud Firestore ve Firebase Storage) üzerinde şifreli bağlantı (HTTPS/TLS) ile saklanır. Çok kiracılı (multi-tenant) mimari sayesinde her işletmenin verileri birbirinden tamamen izole edilir; başka bir işletme veya üçüncü şahıs verilerinize erişemez.',
      ),
      _section(
        '4. Verilerin Üçüncü Taraflarla Paylaşımı',
        'CG Core; kişisel veya ticari verilerinizi reklam amaçlı kullanmaz, üçüncü taraflara satmaz veya kiralamaz. Veriler yalnızca uygulamanın teknik altyapısını sağlayan Google Firebase servislerinde barındırılır.',
      ),
      _section(
        '5. Hesap Silme ve Kullanıcı Hakları',
        'Uygulama içerisindeki Ayarlar > "Hesabımı Kalıcı Olarak Sil" seçeneğini kullanarak kullanıcı hesabınızı ve profil erişiminizi istediğiniz zaman kalıcı olarak silebilirsiniz. Silinen hesaplar geri döndürülemez.',
      ),
    ];
  }

  List<Widget> _buildTermsSections() {
    return [
      _header('CG Core Kullanım Koşulları (Kullanıcı Sözleşmesi)'),
      _updatedDate('Son Güncelleme: 23 Kasım 2026'),
      _section(
        '1. Hizmetin Kapsamı',
        'CG Core; işletmelerin personel, araç, genel gider ve finansal hareketlerini pratik bir şekilde takip edebilmesi amacıyla sunulan bir yönetim yazılımıdır. Uygulamayı kullanarak bu koşulları kabul etmiş sayılırsınız.',
      ),
      _section(
        '2. Resmî Muhasebe ve Bordro Uyarısı',
        'CG Core bir resmî muhasebe, e-fatura veya SGK/bordro yazılımı değildir. Uygulama içerisinde hesaplanan personel hakediş, avans, kesinti ve gider raporları yalnızca işletme içi ön takip ve bilgilendirme amaçlıdır. Resmî beyanname ve bordro işlemleri için yetkili mali müşavirinize başvurunuz.',
      ),
      _section(
        '3. Kullanıcı Sorumlulukları',
        '• Hesap güvenliğiniz ve şifrenizin gizliliğinden siz sorumlusunuz.\n'
        '• Sisteme girdiğiniz personel ve müşteri bilgilerinin doğruluğu ve yasal izinleri işletme sahibinin sorumluluğundadır.\n'
        '• Uygulamanın güvenliğini ihlal edecek veya sistem bütünlüğünü bozacak girişimlerde bulunulamaz.',
      ),
      _section(
        '4. Hizmet Sürekliliği ve Değişiklikler',
        'CG Core, hizmet kalitesini artırmak amacıyla uygulama özelliklerinde güncelleme yapma hakkını saklı tutar. Veri kaybını önlemek için düzenli bulut yedekleme standartları uygulanır; ancak kritik finansal raporlarınızı PDF veya Excel olarak dışa aktararak yedeklemeniz önerilir.',
      ),
      _section(
        '5. İletişim',
        'Sözleşme ve destek talepleriniz için: cihan_00by@hotmail.com',
      ),
    ];
  }

  Widget _header(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }

  Widget _updatedDate(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 16),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: AppColors.textMutedLight),
      ),
    );
  }

  Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
