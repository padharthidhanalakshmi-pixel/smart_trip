import 'package:flutter/material.dart';

/// Which place categories match each interest.
const interestCategories = <String, Set<String>>{
  'Nature': {'Park', 'Nature', 'Viewpoint'},
  'History': {'Historic', 'Museum'},
  'Food': {'Restaurant', 'Cafe'},
  'Shopping': {'Shopping'},
  'Adventure': {'Adventure', 'Nature'},
  'Culture': {'Museum', 'Culture', 'Historic'},
  'Photography': {'Viewpoint', 'Historic', 'Park'},
  'Nightlife': {'Nightlife'},
};

/// Good choices when rain is likely.
const indoorCategories = {'Museum', 'Culture', 'Shopping', 'Restaurant', 'Cafe', 'Nightlife'};

/// Usually free or low-cost to visit.
const freeCategories = {'Park', 'Nature', 'Viewpoint', 'Historic', 'Attraction'};

/// Not used for daytime sightseeing slots.
const nonSightCategories = {'Restaurant', 'Cafe', 'Nightlife', 'Shopping'};

IconData categoryIcon(String category) {
  switch (category) {
    case 'Museum':
      return Icons.museum_outlined;
    case 'Historic':
      return Icons.account_balance_outlined;
    case 'Park':
      return Icons.park_outlined;
    case 'Nature':
      return Icons.terrain;
    case 'Viewpoint':
      return Icons.landscape_outlined;
    case 'Adventure':
      return Icons.attractions_outlined;
    case 'Culture':
      return Icons.theater_comedy_outlined;
    case 'Restaurant':
      return Icons.restaurant_outlined;
    case 'Cafe':
      return Icons.local_cafe_outlined;
    case 'Shopping':
      return Icons.shopping_bag_outlined;
    case 'Nightlife':
      return Icons.nightlife_outlined;
    default:
      return Icons.place_outlined;
  }
}
