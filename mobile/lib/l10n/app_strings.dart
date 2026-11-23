import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLocale {
  static const _key = 'app_locale';
  static final ValueNotifier<String> current = ValueNotifier<String>('en');

  static bool get isBn => current.value == 'bn';

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    current.value = prefs.getString(_key) ?? 'en';
  }

  static Future<void> setLocale(String locale) async {
    final normalized = locale == 'bn' ? 'bn' : 'en';
    current.value = normalized;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, normalized);
  }

  static Future<void> toggle() async {
    await setLocale(isBn ? 'en' : 'bn');
  }
}

class S {
  static String t(String key) {
    final map = AppLocale.isBn ? _bn : _en;
    return map[key] ?? _en[key] ?? key;
  }

  static const Map<String, String> _en = {
    // Auth
    'tagline': 'Bachelor Mess & Seat Manager',
    'hero_headline': 'Transparent meals, bazar & bachelor seats in one place.',
    'sign_in': 'Sign In',
    'create_account': 'Create Account',
    'full_name': 'Full Name',
    'mobile_number': 'Mobile Number',
    'password': 'Password',
    'sign_in_btn': 'Sign In to MessMate',
    'register_btn': 'Create Free Account',
    'demo_login': 'Quick Demo Login (Tanvir • Chawk Bazar, CTG)',

    // Nav tabs
    'tab_home': 'Home',
    'tab_ledger': 'Ledger',
    'tab_tolet': 'To-Let',
    'tab_profile': 'Profile',

    // Dashboard
    'current_meal_rate': 'Current Meal Rate',
    'per_meal': '/ meal',
    'members': 'Members',
    'total_meals': 'Total Meals',
    'total_bazar': 'Total Bazar',
    'cash_in_hand': 'Cash in Hand',
    'fixed_per_person': 'Fixed / Person',
    'log_meal': 'Log Meal',
    'add_bazar': 'Add Bazar',
    'deposit': 'Deposit',
    'share_summary': 'Share',
    'member_balances': 'Member Balances',
    'cutoff': 'Cutoff',
    'manager': 'Manager',
    'refund': 'Refund',
    'due': 'Due',
    'meals': 'meals',
    'cost': 'Cost',
    'paid': 'Paid',
    'no_mess_title': 'No Active Mess Yet',
    'no_mess_desc': 'Create your bachelor mess or join an existing one with a 6-character invite code.',
    'create_or_join': 'Create or Join Mess',

    // Ledger
    'bazar': 'Bazar',
    'deposits': 'Deposits',
    'fixed_bills': 'Fixed Bills',
    'meals_tab': 'Meals',
    'add_deposit': 'Add Deposit',
    'add_bill': 'Add Bill',
    'no_bazar': 'No bazar entries yet',
    'no_deposits': 'No deposits recorded yet',
    'no_bills': 'No fixed bills added yet',
    'no_meals': 'No meals logged yet',
    'meal_fund': 'Meal Fund',
    'fixed_bill': 'Fixed Bill',
    'equal_split': 'Equal split',

    // To-Let
    'search_area_hint': 'Search CTG area (Chawk Bazar, GEC, Agrabad...)',
    'all': 'All',
    'post_seat': 'Post Seat',
    'featured': 'FEATURED',
    'verified_mess': 'VERIFIED MESS',
    'per_month': '/mo',
    'available_from': 'From',
    'avg_meal_cost': 'Avg Meal Cost',
    'copy': 'Copy',
    'no_seats': 'No bachelor seats found for this area',

    // Profile
    'invite_code_title': 'Mess Invite Code',
    'invite_code_desc': 'Share this code so roommates can join.',
    'handover_title': 'Handover Manager Role',
    'handover_desc': 'Pass next month\'s management to a roommate',
    'language_title': 'App Language',
    'language_desc': 'Switch between English & বাংলা',
    'switch_mess': 'Switch Active Mess',
    'sign_out': 'Sign Out',

    // Sheets
    'sheet_log_meal_title': 'Log Today\'s Meals',
    'breakfast': 'Breakfast',
    'lunch': 'Lunch',
    'dinner': 'Dinner',
    'guest_meals': 'Guest Meals',
    'save_meals': 'Save Meals',
    'sheet_bazar_title': 'Add Bazar Expense',
    'sheet_bazar_sub': 'Record daily grocery or market spend for the mess.',
    'total_spent': 'Total Spent (BDT)',
    'items_bought': 'Items Bought',
    'save_bazar': 'Save Bazar Entry',
    'sheet_deposit_title': 'Record Member Deposit',
    'sheet_deposit_sub': 'Log cash, bKash, or Nagad money received from a roommate.',
    'save_deposit': 'Save Deposit',
    'sheet_bill_title': 'Add Fixed Monthly Bill',
    'sheet_bill_sub': 'Automatically split equally among all active mess members.',
    'save_bill': 'Add Fixed Bill',
    'sheet_seat_title': 'Post Vacant Bachelor Seat',
    'publish_seat': 'Publish Seat Listing',
    'month_closed': 'CLOSED',
    'close_month': 'Close Month',
    'reopen_month': 'Reopen Month',
    'month_locked_banner': 'This month is closed and locked for edits.',
    'today_kitchen': 'Today\'s Kitchen',
    'manage_all': 'Manage All',
    'include_breakfast': 'Include Breakfast',
    'include_breakfast_desc': 'Off by default (Lunch + Dinner only)',
  };

  static const Map<String, String> _bn = {
    // Auth
    'tagline': 'ব্যাচেলর মেস ও সিট ম্যানেজার',
    'hero_headline': 'মেসের মিল, বাজার, বিল ও ব্যাচেলর সিট—সব এক অ্যাপে।',
    'sign_in': 'লগইন',
    'create_account': 'নতুন একাউন্ট',
    'full_name': 'পূর্ণ নাম',
    'mobile_number': 'মোবাইল নম্বর',
    'password': 'পাসওয়ার্ড',
    'sign_in_btn': 'লগইন করুন',
    'register_btn': 'ফ্রি একাউন্ট খুলুন',
    'demo_login': 'ডেমো লগইন (তানভীর • চকবাজার, চট্টগ্রাম)',

    // Nav tabs
    'tab_home': 'হোম',
    'tab_ledger': 'হিসাব',
    'tab_tolet': 'টু-লেট',
    'tab_profile': 'প্রোফাইল',

    // Dashboard
    'current_meal_rate': 'চলতি মিল রেট',
    'per_meal': '/ মিল',
    'members': 'সদস্য',
    'total_meals': 'মোট মিল',
    'total_bazar': 'মোট বাজার',
    'cash_in_hand': 'হাতে আছে',
    'fixed_per_person': 'ফিক্সড / জন',
    'log_meal': 'মিল দিন',
    'add_bazar': 'বাজার যোগ',
    'deposit': 'জমা দিন',
    'share_summary': 'শেয়ার করুন',
    'member_balances': 'সদস্যদের হিসাব',
    'cutoff': 'কাটঅফ',
    'manager': 'ম্যানেজার',
    'refund': 'পাবে',
    'due': 'বাকি',
    'meals': 'মিল',
    'cost': 'খরচ',
    'paid': 'জমা',
    'no_mess_title': 'কোনো মেস যুক্ত নেই',
    'no_mess_desc': 'নতুন ব্যাচেলর মেস তৈরি করুন অথবা ইনভাইট কোড দিয়ে মেসে যুক্ত হোন।',
    'create_or_join': 'মেস তৈরি বা যুক্ত হোন',

    // Ledger
    'bazar': 'বাজার',
    'deposits': 'জমা',
    'fixed_bills': 'ফিক্সড বিল',
    'meals_tab': 'মিল তালিকা',
    'add_deposit': 'জমা যোগ',
    'add_bill': 'বিল যোগ',
    'no_bazar': 'এখনো কোনো বাজার যুক্ত হয়নি',
    'no_deposits': 'এখনো কোনো জমা যুক্ত হয়নি',
    'no_bills': 'এখনো কোনো ফিক্সড বিল নেই',
    'no_meals': 'এখনো কোনো মিল এন্ট্রি হয়নি',
    'meal_fund': 'মিল ফান্ড',
    'fixed_bill': 'ফিক্সড বিল',
    'equal_split': 'সমান ভাগ',

    // To-Let
    'search_area_hint': 'চট্টগ্রামের এলাকা খুঁজুন (চকবাজার, জিইসি, আগ্রাবাদ...)',
    'all': 'সব',
    'post_seat': 'সিট পোস্ট',
    'featured': 'ফিচার্ড',
    'verified_mess': 'ভেরিফায়েড মেস',
    'per_month': '/মাস',
    'available_from': 'শুরু',
    'avg_meal_cost': 'গড় মিল খরচ',
    'copy': 'কপি',
    'no_seats': 'এই এলাকায় কোনো খালি সিট পাওয়া যায়নি',

    // Profile
    'invite_code_title': 'মেস ইনভাইট কোড',
    'invite_code_desc': 'রুমমেটদের মেসে যুক্ত করতে কোডটি শেয়ার করুন।',
    'handover_title': 'ম্যানেজার পরিবর্তন',
    'handover_desc': 'পরের মাসের ম্যানেজার দায়িত্ব হস্তান্তর করুন',
    'language_title': 'অ্যাপের ভাষা',
    'language_desc': 'English এবং বাংলা পরিবর্তন করুন',
    'switch_mess': 'মেস পরিবর্তন করুন',
    'sign_out': 'লগআউট',

    // Sheets
    'sheet_log_meal_title': 'আজকের মিল দিন',
    'breakfast': 'সকালের নাস্তা',
    'lunch': 'দুপুরের খাবার',
    'dinner': 'রাতের খাবার',
    'guest_meals': 'গেস্ট মিল',
    'save_meals': 'মিল সেভ করুন',
    'sheet_bazar_title': 'বাজার খরচ যুক্ত করুন',
    'sheet_bazar_sub': 'মেসের দৈনিক বাজারের হিসাব লিখুন।',
    'total_spent': 'মোট খরচ (টাকা)',
    'items_bought': 'কী কী কেনা হয়েছে',
    'save_bazar': 'বাজার সেভ করুন',
    'sheet_deposit_title': 'সদস্যের জমা লিখুন',
    'sheet_deposit_sub': 'ক্যাশ, বিকাশ বা নগদে প্রাপ্ত টাকা যুক্ত করুন।',
    'save_deposit': 'জমা সেভ করুন',
    'sheet_bill_title': 'মাসিক ফিক্সড বিল যোগ',
    'sheet_bill_sub': 'সব সদস্যের মাঝে সমানভাবে ভাগ হবে।',
    'save_bill': 'বিল সেভ করুন',
    'sheet_seat_title': 'খালি ব্যাচেলর সিট পোস্ট করুন',
    'publish_seat': 'পোস্ট পাবলিশ করুন',
    'month_closed': 'ক্লোজড',
    'close_month': 'মাস ক্লোজ করুন',
    'reopen_month': 'পুনরায় খুলুন',
    'month_locked_banner': 'এই মাসের হিসাব ক্লোজ করা আছে (এডিট লক)।',
    'today_kitchen': 'আজকের রান্নার হিসাব',
    'manage_all': 'সবাইকে এডিট',
    'include_breakfast': 'সকালের নাস্তা চালু',
    'include_breakfast_desc': 'ডিফল্ট বন্ধ (শুধু দুপুর ও রাত)',
  };
}
