part of 'pico_color_data.dart';

@immutable
class PicoVaccineColor {
  const PicoVaccineColor._({
    required this.public,
    required this.elderly,
    required this.teenager,
    required this.main,
    required this.healthWorker,
    required this.publicWorker,
  });

  factory PicoVaccineColor.light() => PicoVaccineColor._(
         public: PicoColors.vaccinePublic,
        elderly: PicoColors.vaccineElderly,
        teenager: PicoColors.vaccineTeenager,
        main: PicoColors.vaccineAll,
        healthWorker: PicoColors.vaccineHealthWorker,
        publicWorker: PicoColors.vaccinePublicWorker,
      );
  factory PicoVaccineColor.dark() => PicoVaccineColor._(
       public: PicoColors.vaccinePublicDark,
        elderly: PicoColors.vaccineElderlyDark,
        teenager: PicoColors.vaccineTeenagerDark,
        main: PicoColors.vaccineAllDark,
        healthWorker: PicoColors.vaccineHealthWorkerDark,
        publicWorker: PicoColors.vaccinePublicWorkerDark,
      );


  final Color public;
  final Color elderly;
  final Color teenager;
  final Color main;
  final Color healthWorker;
  final Color publicWorker;

  PicoVaccineColor copyWith({
    Color? public,
    Color? elderly,
    Color? teenager,
    Color? main,
    Color? healthWorker,
    Color? publicWorker,
  }) {
    return PicoVaccineColor._(
      public: public ?? this.public,
      elderly: elderly ?? this.elderly,
      teenager: teenager ?? this.teenager,
      main: main ?? this.main,
      healthWorker: healthWorker ?? this.healthWorker,
      publicWorker: publicWorker ?? this.publicWorker,
    );
  }

  PicoVaccineColor lerp({
    required double t,
    required Color publicVariant,
    required Color elderlyVariant,
    required Color teenagerVariant,
    required Color mainVariant,
    required Color healthWorkerVariant,
    required Color publicWorkerVariant,
  }) =>
      PicoVaccineColor._(
        public: Color.lerp(public, publicVariant, t) ?? public,
        elderly: Color.lerp(elderly, elderlyVariant, t) ?? elderly,
        teenager: Color.lerp(teenager, teenagerVariant, t) ?? teenager,
        main: Color.lerp(main, mainVariant, t) ?? main,
        healthWorker:
            Color.lerp(healthWorker, healthWorkerVariant, t) ?? healthWorker,
        publicWorker:
            Color.lerp(publicWorker, publicWorkerVariant, t) ?? publicWorker,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PicoVaccineColor &&
        other.public == public &&
        other.elderly == elderly &&
        other.teenager == teenager &&
        other.main == main &&
        other.healthWorker == healthWorker &&
        other.publicWorker == publicWorker;
  }

  @override
  int get hashCode {
    return public.hashCode ^
        elderly.hashCode ^
        teenager.hashCode ^
        main.hashCode ^
        healthWorker.hashCode ^
        publicWorker.hashCode;
  }
}
