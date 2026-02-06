import 'package:flutter_test/flutter_test.dart';
import 'package:gud_app/models/statistics.dart';

void main() {
  group('Statistics', () {
    final periodStart = DateTime(2024, 1, 1);
    final periodEnd = DateTime(2024, 1, 31);
    
    test('constructor creates valid Statistics', () {
      final stats = Statistics(
        totalRevenue: 50000.0,
        totalExpenses: 15000.0,
        netProfit: 35000.0,
        totalLoads: 100,
        deliveredLoads: 95,
        totalMiles: 10000.0,
        averageRate: 500.0,
        ratePerMile: 5.0,
        periodStart: periodStart,
        periodEnd: periodEnd,
        driverStats: {
          'driver1': {'loads': 50, 'revenue': 25000.0},
          'driver2': {'loads': 45, 'revenue': 22500.0},
        },
      );

      expect(stats.totalRevenue, 50000.0);
      expect(stats.totalExpenses, 15000.0);
      expect(stats.netProfit, 35000.0);
      expect(stats.totalLoads, 100);
      expect(stats.deliveredLoads, 95);
      expect(stats.totalMiles, 10000.0);
      expect(stats.averageRate, 500.0);
      expect(stats.ratePerMile, 5.0);
      expect(stats.periodStart, periodStart);
      expect(stats.periodEnd, periodEnd);
      expect(stats.driverStats, isNotNull);
      expect(stats.driverStats.length, 2);
    });

    test('constructor uses empty map for null driverStats', () {
      final stats = Statistics(
        totalRevenue: 10000.0,
        totalExpenses: 3000.0,
        netProfit: 7000.0,
        totalLoads: 20,
        deliveredLoads: 18,
        totalMiles: 2000.0,
        averageRate: 500.0,
        ratePerMile: 5.0,
        periodStart: periodStart,
        periodEnd: periodEnd,
      );

      expect(stats.driverStats, isNotNull);
      expect(stats.driverStats.isEmpty, true);
    });

    test('toMap serializes Statistics correctly', () {
      final stats = Statistics(
        totalRevenue: 50000.0,
        totalExpenses: 15000.0,
        netProfit: 35000.0,
        totalLoads: 100,
        deliveredLoads: 95,
        totalMiles: 10000.0,
        averageRate: 500.0,
        ratePerMile: 5.0,
        periodStart: periodStart,
        periodEnd: periodEnd,
        driverStats: {'driver1': {'loads': 50}},
      );

      final map = stats.toMap();

      expect(map['totalRevenue'], 50000.0);
      expect(map['totalExpenses'], 15000.0);
      expect(map['netProfit'], 35000.0);
      expect(map['totalLoads'], 100);
      expect(map['deliveredLoads'], 95);
      expect(map['totalMiles'], 10000.0);
      expect(map['averageRate'], 500.0);
      expect(map['ratePerMile'], 5.0);
      expect(map['periodStart'], periodStart.toIso8601String());
      expect(map['periodEnd'], periodEnd.toIso8601String());
      expect(map['driverStats'], isA<Map>());
    });

    test('fromMap deserializes Statistics correctly', () {
      final map = {
        'totalRevenue': 50000.0,
        'totalExpenses': 15000.0,
        'netProfit': 35000.0,
        'totalLoads': 100,
        'deliveredLoads': 95,
        'totalMiles': 10000.0,
        'averageRate': 500.0,
        'ratePerMile': 5.0,
        'periodStart': periodStart.toIso8601String(),
        'periodEnd': periodEnd.toIso8601String(),
        'driverStats': {
          'driver1': {'loads': 50, 'revenue': 25000.0},
        },
      };

      final stats = Statistics.fromMap(map);

      expect(stats.totalRevenue, 50000.0);
      expect(stats.totalExpenses, 15000.0);
      expect(stats.netProfit, 35000.0);
      expect(stats.totalLoads, 100);
      expect(stats.deliveredLoads, 95);
      expect(stats.totalMiles, 10000.0);
      expect(stats.averageRate, 500.0);
      expect(stats.ratePerMile, 5.0);
      expect(stats.periodStart, periodStart);
      expect(stats.periodEnd, periodEnd);
      expect(stats.driverStats['driver1']['loads'], 50);
    });

    test('fromMap uses default values for missing fields', () {
      final map = {
        'periodStart': periodStart.toIso8601String(),
        'periodEnd': periodEnd.toIso8601String(),
      };

      final stats = Statistics.fromMap(map);

      expect(stats.totalRevenue, 0.0);
      expect(stats.totalExpenses, 0.0);
      expect(stats.netProfit, 0.0);
      expect(stats.totalLoads, 0);
      expect(stats.deliveredLoads, 0);
      expect(stats.totalMiles, 0.0);
      expect(stats.averageRate, 0.0);
      expect(stats.ratePerMile, 0.0);
      expect(stats.driverStats.isEmpty, true);
    });

    test('serialization roundtrip maintains data integrity', () {
      final original = Statistics(
        totalRevenue: 75000.0,
        totalExpenses: 20000.0,
        netProfit: 55000.0,
        totalLoads: 150,
        deliveredLoads: 145,
        totalMiles: 15000.0,
        averageRate: 500.0,
        ratePerMile: 5.0,
        periodStart: periodStart,
        periodEnd: periodEnd,
        driverStats: {
          'driver1': {'loads': 80, 'revenue': 40000.0},
          'driver2': {'loads': 70, 'revenue': 35000.0},
        },
      );

      final map = original.toMap();
      final deserialized = Statistics.fromMap(map);

      expect(deserialized.totalRevenue, original.totalRevenue);
      expect(deserialized.totalExpenses, original.totalExpenses);
      expect(deserialized.netProfit, original.netProfit);
      expect(deserialized.totalLoads, original.totalLoads);
      expect(deserialized.deliveredLoads, original.deliveredLoads);
      expect(deserialized.totalMiles, original.totalMiles);
      expect(deserialized.averageRate, original.averageRate);
      expect(deserialized.ratePerMile, original.ratePerMile);
      expect(deserialized.periodStart, original.periodStart);
      expect(deserialized.periodEnd, original.periodEnd);
      expect(deserialized.driverStats.length, original.driverStats.length);
    });

    test('calculates profit margin correctly', () {
      final stats = Statistics(
        totalRevenue: 100000.0,
        totalExpenses: 25000.0,
        netProfit: 75000.0,
        totalLoads: 200,
        deliveredLoads: 190,
        totalMiles: 20000.0,
        averageRate: 500.0,
        ratePerMile: 5.0,
        periodStart: periodStart,
        periodEnd: periodEnd,
      );

      // Manual calculation: (netProfit / totalRevenue) * 100
      final profitMargin = (stats.netProfit / stats.totalRevenue) * 100;
      expect(profitMargin, 75.0);
    });

    test('calculates delivery completion rate correctly', () {
      final stats = Statistics(
        totalRevenue: 50000.0,
        totalExpenses: 15000.0,
        netProfit: 35000.0,
        totalLoads: 100,
        deliveredLoads: 95,
        totalMiles: 10000.0,
        averageRate: 500.0,
        ratePerMile: 5.0,
        periodStart: periodStart,
        periodEnd: periodEnd,
      );

      // Manual calculation: (deliveredLoads / totalLoads) * 100
      final completionRate = (stats.deliveredLoads / stats.totalLoads) * 100;
      expect(completionRate, 95.0);
    });

    test('handles zero values correctly', () {
      final stats = Statistics(
        totalRevenue: 0.0,
        totalExpenses: 0.0,
        netProfit: 0.0,
        totalLoads: 0,
        deliveredLoads: 0,
        totalMiles: 0.0,
        averageRate: 0.0,
        ratePerMile: 0.0,
        periodStart: periodStart,
        periodEnd: periodEnd,
      );

      expect(stats.totalRevenue, 0.0);
      expect(stats.totalLoads, 0);
      
      final map = stats.toMap();
      final deserialized = Statistics.fromMap(map);
      
      expect(deserialized.totalRevenue, 0.0);
      expect(deserialized.totalLoads, 0);
    });

    test('handles numeric type conversions correctly', () {
      final map = {
        'totalRevenue': 50000, // int instead of double
        'totalExpenses': 15000,
        'netProfit': 35000,
        'totalLoads': 100,
        'deliveredLoads': 95,
        'totalMiles': 10000,
        'averageRate': 500,
        'ratePerMile': 5,
        'periodStart': periodStart.toIso8601String(),
        'periodEnd': periodEnd.toIso8601String(),
      };

      final stats = Statistics.fromMap(map);

      expect(stats.totalRevenue, 50000.0);
      expect(stats.totalRevenue, isA<double>());
      expect(stats.totalMiles, isA<double>());
    });

    test('handles complex driver statistics', () {
      final driverStats = {
        'driver1': {
          'loads': 50,
          'revenue': 25000.0,
          'miles': 5000.0,
          'expenses': 7500.0,
        },
        'driver2': {
          'loads': 45,
          'revenue': 22500.0,
          'miles': 4500.0,
          'expenses': 6750.0,
        },
        'driver3': {
          'loads': 5,
          'revenue': 2500.0,
          'miles': 500.0,
          'expenses': 750.0,
        },
      };

      final stats = Statistics(
        totalRevenue: 50000.0,
        totalExpenses: 15000.0,
        netProfit: 35000.0,
        totalLoads: 100,
        deliveredLoads: 100,
        totalMiles: 10000.0,
        averageRate: 500.0,
        ratePerMile: 5.0,
        periodStart: periodStart,
        periodEnd: periodEnd,
        driverStats: driverStats,
      );

      expect(stats.driverStats.length, 3);
      expect(stats.driverStats['driver1']['loads'], 50);
      expect(stats.driverStats['driver2']['revenue'], 22500.0);
      expect(stats.driverStats['driver3']['miles'], 500.0);
    });

    test('handles date ranges correctly', () {
      final start = DateTime(2024, 1, 1);
      final end = DateTime(2024, 12, 31);
      
      final stats = Statistics(
        totalRevenue: 100000.0,
        totalExpenses: 30000.0,
        netProfit: 70000.0,
        totalLoads: 200,
        deliveredLoads: 195,
        totalMiles: 20000.0,
        averageRate: 500.0,
        ratePerMile: 5.0,
        periodStart: start,
        periodEnd: end,
      );

      expect(stats.periodStart, start);
      expect(stats.periodEnd, end);
      expect(stats.periodEnd.isAfter(stats.periodStart), true);
      
      // Calculate period duration
      final duration = stats.periodEnd.difference(stats.periodStart);
      expect(duration.inDays, greaterThan(300)); // about a year
    });
  });
}
