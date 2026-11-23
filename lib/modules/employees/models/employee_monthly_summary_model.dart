class EmployeeMonthlySummaryModel {
  final int year;
  final int month;
  final int baseSalaryCents;
  final int earnedSalaryCents; // Hakediş (ücretsiz izin düşüldükten sonra)
  final int bonusCents;        // Ek Ödeme & Prim
  final int advanceCents;      // Avans
  final int salaryPaymentCents;// Yapılan Maaş Ödemesi
  final int deductionCents;    // Kesinti
  final int unpaidLeaveDays;   // Ücretsiz izin / mazeretsiz devamsızlık gün sayısı
  final int paidLeaveDays;     // Ücretli / mazeretli izin gün sayısı

  EmployeeMonthlySummaryModel({
    required this.year,
    required this.month,
    required this.baseSalaryCents,
    required this.earnedSalaryCents,
    required this.bonusCents,
    required this.advanceCents,
    required this.salaryPaymentCents,
    required this.deductionCents,
    required this.unpaidLeaveDays,
    required this.paidLeaveDays,
  });

  /// Hakediş + Ek Ödeme - Avans - Yapılan Ödeme - Kesinti = Kalan Tutar
  int get remainingBalanceCents =>
      earnedSalaryCents + bonusCents - advanceCents - salaryPaymentCents - deductionCents;

  int get totalPaidCents => advanceCents + salaryPaymentCents;
}
