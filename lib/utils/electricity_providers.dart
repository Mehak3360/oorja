class TariffSlab {
  final double upTo; // upper limit of this slab (units), use double.infinity for unlimited
  final double rate; // rate per unit in this slab

  const TariffSlab({required this.upTo, required this.rate});
}

class ElectricityProvider {
  final String name;
  final String state;
  final List<TariffSlab> slabs;

  const ElectricityProvider({
    required this.name,
    required this.state,
    required this.slabs,
  });
}

class ElectricityProviders {
  // Representative/illustrative slab structures for major Indian state electricity boards.
  // Note: real tariffs change periodically and vary by connection type (domestic/commercial),
  // season, and subsidy schemes. These are approximate values for demonstration purposes.
  static const List<ElectricityProvider> all = [
    ElectricityProvider(
      name: 'PSPCL',
      state: 'Punjab',
      slabs: [
        TariffSlab(upTo: 100, rate: 3.49),
        TariffSlab(upTo: 300, rate: 5.44),
        TariffSlab(upTo: 500, rate: 6.59),
        TariffSlab(upTo: double.infinity, rate: 7.31),
      ],
    ),
    ElectricityProvider(
      name: 'BSES Rajdhani',
      state: 'Delhi',
      slabs: [
        TariffSlab(upTo: 200, rate: 3.00),
        TariffSlab(upTo: 400, rate: 4.50),
        TariffSlab(upTo: 800, rate: 6.50),
        TariffSlab(upTo: double.infinity, rate: 8.00),
      ],
    ),
    ElectricityProvider(
      name: 'MSEDCL',
      state: 'Maharashtra',
      slabs: [
        TariffSlab(upTo: 100, rate: 4.71),
        TariffSlab(upTo: 300, rate: 8.32),
        TariffSlab(upTo: 500, rate: 11.09),
        TariffSlab(upTo: double.infinity, rate: 12.36),
      ],
    ),
    ElectricityProvider(
      name: 'BESCOM',
      state: 'Karnataka',
      slabs: [
        TariffSlab(upTo: 100, rate: 4.15),
        TariffSlab(upTo: 200, rate: 5.60),
        TariffSlab(upTo: 400, rate: 7.15),
        TariffSlab(upTo: double.infinity, rate: 8.20),
      ],
    ),
    ElectricityProvider(
      name: 'TNEB',
      state: 'Tamil Nadu',
      slabs: [
        TariffSlab(upTo: 100, rate: 0.0), // first 100 units free under TN scheme (illustrative)
        TariffSlab(upTo: 200, rate: 2.35),
        TariffSlab(upTo: 500, rate: 4.70),
        TariffSlab(upTo: double.infinity, rate: 6.35),
      ],
    ),
    ElectricityProvider(
      name: 'Other / Custom',
      state: '',
      slabs: [], // user enters flat tariff manually
    ),
  ];

  static List<String> get names => all.map((p) => p.name).toList();

  static ElectricityProvider? getByName(String name) {
    try {
      return all.firstWhere((p) => p.name == name);
    } catch (_) {
      return null;
    }
  }

  // Calculates total cost using slab-based (telescopic) billing
  static double calculateSlabCost(ElectricityProvider provider, double totalUnits) {
    if (provider.slabs.isEmpty) return 0; // "Other/Custom" — caller should use flat tariff instead

    double remaining = totalUnits;
    double previousLimit = 0;
    double totalCost = 0;

    for (final slab in provider.slabs) {
      if (remaining <= 0) break;
      final slabSize = slab.upTo - previousLimit;
      final unitsInThisSlab = remaining < slabSize ? remaining : slabSize;
      totalCost += unitsInThisSlab * slab.rate;
      remaining -= unitsInThisSlab;
      previousLimit = slab.upTo;
    }

    return totalCost;
  }
}