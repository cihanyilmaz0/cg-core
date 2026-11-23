enum UserRole {
  owner,
  manager;

  static UserRole fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'owner':
        return UserRole.owner;
      case 'manager':
        return UserRole.manager;
      default:
        return UserRole.owner;
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.owner:
        return 'İşletme Sahibi';
      case UserRole.manager:
        return 'Yönetici';
    }
  }
}

enum SalaryType {
  monthly,
  daily;

  static SalaryType fromString(String? value) {
    return value?.toLowerCase() == 'daily' ? SalaryType.daily : SalaryType.monthly;
  }

  String get displayName {
    switch (this) {
      case SalaryType.monthly:
        return 'Aylık';
      case SalaryType.daily:
        return 'Günlük';
    }
  }
}

enum EmployeeTransactionType {
  advance,
  salaryPayment,
  bonus,
  deduction,
  otherPayment;

  static EmployeeTransactionType fromString(String? value) {
    switch (value) {
      case 'Advance':
        return EmployeeTransactionType.advance;
      case 'SalaryPayment':
        return EmployeeTransactionType.salaryPayment;
      case 'Bonus':
        return EmployeeTransactionType.bonus;
      case 'Deduction':
        return EmployeeTransactionType.deduction;
      case 'OtherPayment':
      default:
        return EmployeeTransactionType.otherPayment;
    }
  }

  String get firestoreKey {
    switch (this) {
      case EmployeeTransactionType.advance:
        return 'Advance';
      case EmployeeTransactionType.salaryPayment:
        return 'SalaryPayment';
      case EmployeeTransactionType.bonus:
        return 'Bonus';
      case EmployeeTransactionType.deduction:
        return 'Deduction';
      case EmployeeTransactionType.otherPayment:
        return 'OtherPayment';
    }
  }

  String get displayName {
    switch (this) {
      case EmployeeTransactionType.advance:
        return 'Avans';
      case EmployeeTransactionType.salaryPayment:
        return 'Maaş Ödemesi';
      case EmployeeTransactionType.bonus:
        return 'Prim / Ek Ödeme';
      case EmployeeTransactionType.deduction:
        return 'Kesinti';
      case EmployeeTransactionType.otherPayment:
        return 'Diğer Ödeme';
    }
  }
}

enum LeaveType {
  paidLeave,
  unpaidLeave,
  excusedAbsence,
  unexcusedAbsence;

  static LeaveType fromString(String? value) {
    switch (value) {
      case 'PaidLeave':
        return LeaveType.paidLeave;
      case 'UnpaidLeave':
        return LeaveType.unpaidLeave;
      case 'ExcusedAbsence':
        return LeaveType.excusedAbsence;
      case 'UnexcusedAbsence':
      default:
        return LeaveType.unexcusedAbsence;
    }
  }

  String get firestoreKey {
    switch (this) {
      case LeaveType.paidLeave:
        return 'PaidLeave';
      case LeaveType.unpaidLeave:
        return 'UnpaidLeave';
      case LeaveType.excusedAbsence:
        return 'ExcusedAbsence';
      case LeaveType.unexcusedAbsence:
        return 'UnexcusedAbsence';
    }
  }

  String get displayName {
    switch (this) {
      case LeaveType.paidLeave:
        return 'Ücretli İzin';
      case LeaveType.unpaidLeave:
        return 'Ücretsiz İzin';
      case LeaveType.excusedAbsence:
        return 'Mazeretli Devamsızlık';
      case LeaveType.unexcusedAbsence:
        return 'Mazeretsiz Devamsızlık';
    }
  }
}

enum VehicleExpenseType {
  fuel,
  maintenance,
  repair,
  tire,
  insurance,
  casco,
  inspection,
  parking,
  hgs,
  other;

  static VehicleExpenseType fromString(String? value) {
    switch (value) {
      case 'Fuel':
        return VehicleExpenseType.fuel;
      case 'Maintenance':
        return VehicleExpenseType.maintenance;
      case 'Repair':
        return VehicleExpenseType.repair;
      case 'Tire':
        return VehicleExpenseType.tire;
      case 'Insurance':
        return VehicleExpenseType.insurance;
      case 'Casco':
        return VehicleExpenseType.casco;
      case 'Inspection':
        return VehicleExpenseType.inspection;
      case 'Parking':
        return VehicleExpenseType.parking;
      case 'HGS':
        return VehicleExpenseType.hgs;
      case 'Other':
      default:
        return VehicleExpenseType.other;
    }
  }

  String get firestoreKey {
    switch (this) {
      case VehicleExpenseType.fuel:
        return 'Fuel';
      case VehicleExpenseType.maintenance:
        return 'Maintenance';
      case VehicleExpenseType.repair:
        return 'Repair';
      case VehicleExpenseType.tire:
        return 'Tire';
      case VehicleExpenseType.insurance:
        return 'Insurance';
      case VehicleExpenseType.casco:
        return 'Casco';
      case VehicleExpenseType.inspection:
        return 'Inspection';
      case VehicleExpenseType.parking:
        return 'Parking';
      case VehicleExpenseType.hgs:
        return 'HGS';
      case VehicleExpenseType.other:
        return 'Other';
    }
  }

  String get displayName {
    switch (this) {
      case VehicleExpenseType.fuel:
        return 'Yakıt';
      case VehicleExpenseType.maintenance:
        return 'Periyodik Bakım';
      case VehicleExpenseType.repair:
        return 'Tamir & Onarım';
      case VehicleExpenseType.tire:
        return 'Lastik';
      case VehicleExpenseType.insurance:
        return 'Trafik Sigortası';
      case VehicleExpenseType.casco:
        return 'Kasko';
      case VehicleExpenseType.inspection:
        return 'Muayene';
      case VehicleExpenseType.parking:
        return 'Otopark';
      case VehicleExpenseType.hgs:
        return 'HGS / OGS Geçiş';
      case VehicleExpenseType.other:
        return 'Diğer';
    }
  }
}

enum FuelType {
  diesel,
  gasoline,
  lpg,
  electric,
  hybrid;

  static FuelType fromString(String? value) {
    switch (value) {
      case 'Diesel':
        return FuelType.diesel;
      case 'Gasoline':
        return FuelType.gasoline;
      case 'LPG':
        return FuelType.lpg;
      case 'Electric':
        return FuelType.electric;
      case 'Hybrid':
        return FuelType.hybrid;
      default:
        return FuelType.diesel;
    }
  }

  String get firestoreKey {
    switch (this) {
      case FuelType.diesel:
        return 'Diesel';
      case FuelType.gasoline:
        return 'Gasoline';
      case FuelType.lpg:
        return 'LPG';
      case FuelType.electric:
        return 'Electric';
      case FuelType.hybrid:
        return 'Hybrid';
    }
  }

  String get displayName {
    switch (this) {
      case FuelType.diesel:
        return 'Dizel';
      case FuelType.gasoline:
        return 'Benzin';
      case FuelType.lpg:
        return 'Benzin / LPG';
      case FuelType.electric:
        return 'Elektrik';
      case FuelType.hybrid:
        return 'Hibrit';
    }
  }
}

enum PaymentMethod {
  cash,
  creditCard,
  bankTransfer;

  static PaymentMethod fromString(String? value) {
    switch (value) {
      case 'CreditCard':
        return PaymentMethod.creditCard;
      case 'BankTransfer':
        return PaymentMethod.bankTransfer;
      case 'Cash':
      default:
        return PaymentMethod.cash;
    }
  }

  String get firestoreKey {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.creditCard:
        return 'CreditCard';
      case PaymentMethod.bankTransfer:
        return 'BankTransfer';
    }
  }

  String get displayName {
    switch (this) {
      case PaymentMethod.cash:
        return 'Nakit';
      case PaymentMethod.creditCard:
        return 'Kredi / Banka Kartı';
      case PaymentMethod.bankTransfer:
        return 'Havale / EFT';
    }
  }
}
