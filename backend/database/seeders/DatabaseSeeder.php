<?php

namespace Database\Seeders;

use App\Models\Bazar;
use App\Models\BoostRequest;
use App\Models\Deposit;
use App\Models\FixedBill;
use App\Models\Meal;
use App\Models\Mess;
use App\Models\MessMember;
use App\Models\SeatListing;
use App\Models\SponsorBanner;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $manager = User::firstOrCreate(
            ['phone' => '01711000001'],
            [
                'name' => 'Tanvir Ahmed',
                'email' => 'tanvir@messmate.bd',
                'password' => Hash::make('123456'),
                'locale' => 'en',
            ]
        );

        $roommatesData = [
            ['name' => 'Rakib Hasan', 'phone' => '01711000002', 'email' => 'rakib@messmate.bd', 'room' => 'Room 1 - Seat B', 'rent' => 3000],
            ['name' => 'Nayeem Islam', 'phone' => '01711000003', 'email' => 'nayeem@messmate.bd', 'room' => 'Room 2 - Seat A', 'rent' => 3000],
            ['name' => 'Sabbir Hossain', 'phone' => '01711000004', 'email' => 'sabbir@messmate.bd', 'room' => 'Room 2 - Seat B', 'rent' => 2800],
            ['name' => 'Mehedi Karim', 'phone' => '01711000005', 'email' => 'mehedi@messmate.bd', 'room' => 'Room 3 - Single', 'rent' => 5000],
        ];

        $mess = Mess::firstOrCreate(
            ['invite_code' => 'CTG100'],
            [
                'name' => 'Chawk Bazar Bachelor Mess',
                'city' => 'Chattogram',
                'area' => 'Chawk Bazar',
                'address' => 'Kapasgola Road, Chawk Bazar, Chattogram',
                'meal_cutoff_time' => '22:00',
                'has_breakfast' => false,
                'is_pro' => true,
                'created_by' => $manager->id,
            ]
        );

        MessMember::firstOrCreate(
            ['mess_id' => $mess->id, 'user_id' => $manager->id],
            ['role' => 'manager', 'room_label' => 'Room 1 - Seat A', 'monthly_seat_rent' => 3000, 'is_active' => true]
        );

        $allMembers = [$manager];
        foreach ($roommatesData as $r) {
            $user = User::firstOrCreate(
                ['phone' => $r['phone']],
                [
                    'name' => $r['name'],
                    'email' => $r['email'],
                    'password' => Hash::make('123456'),
                    'locale' => 'en',
                ]
            );

            MessMember::firstOrCreate(
                ['mess_id' => $mess->id, 'user_id' => $user->id],
                ['role' => 'member', 'room_label' => $r['room'], 'monthly_seat_rent' => $r['rent'], 'is_active' => true]
            );
            $allMembers[] = $user;
        }

        $month = $mess->currentMonth();

        // Seed recent days including today (2-meal mode: Lunch + Dinner)
        $today = now();
        $startDay = max(1, $today->day - 9);
        for ($day = $startDay; $day <= $today->day; $day++) {
            $date = $today->copy()->day($day)->toDateString();
            foreach ($allMembers as $idx => $member) {
                Meal::firstOrCreate(
                    ['mess_month_id' => $month->id, 'user_id' => $member->id, 'meal_date' => $date],
                    [
                        'breakfast' => 0,
                        'lunch' => ($day === $today->day && $idx === 3) ? 0 : 1,
                        'dinner' => 1,
                        'guest_meals' => ($day === $startDay + 2 && $idx === 0) ? 2 : 0,
                        'updated_by' => $manager->id,
                    ]
                );
            }
        }

        if ($month->bazars()->count() === 0) {
            Bazar::create([
                'mess_month_id' => $month->id,
                'bought_by' => $manager->id,
                'bazar_date' => $today->copy()->day(1)->toDateString(),
                'amount' => 3650,
                'items_note' => 'Khatunganj rice 25kg, Soybean oil 5L, Masoor dal, Onions, Potatoes',
                'created_by' => $manager->id,
            ]);
            Bazar::create([
                'mess_month_id' => $month->id,
                'bought_by' => $allMembers[1]->id,
                'bazar_date' => $today->copy()->day(4)->toDateString(),
                'amount' => 2300,
                'items_note' => 'Broiler chicken 5kg, Eggs 4 dozen, Chawk Bazar fresh vegetables',
                'created_by' => $manager->id,
            ]);
            Bazar::create([
                'mess_month_id' => $month->id,
                'bought_by' => $allMembers[2]->id,
                'bazar_date' => $today->copy()->day(7)->toDateString(),
                'amount' => 2100,
                'items_note' => 'Loitta & Rui fish, Eggplant, Tomatoes, Spices',
                'created_by' => $manager->id,
            ]);
        }

        if ($month->deposits()->count() === 0) {
            foreach ($allMembers as $idx => $member) {
                Deposit::create([
                    'mess_month_id' => $month->id,
                    'user_id' => $member->id,
                    'amount' => $idx === 3 ? 2000 : 3000,
                    'deposit_type' => 'meal',
                    'payment_method' => $idx % 2 === 0 ? 'bkash' : 'cash',
                    'reference' => $idx % 2 === 0 ? 'CTG9283' . $idx : null,
                    'deposit_date' => $today->copy()->day(2)->toDateString(),
                    'recorded_by' => $manager->id,
                ]);
            }
        }

        if ($month->fixedBills()->count() === 0) {
            $bills = [
                ['title' => 'Broadband Wi-Fi (30 Mbps)', 'category' => 'wifi', 'total_amount' => 1000],
                ['title' => 'Bua (Cooking & Cleaning)', 'category' => 'bua', 'total_amount' => 3000],
                ['title' => 'Gas + Electricity + Water', 'category' => 'electricity', 'total_amount' => 2500],
            ];
            foreach ($bills as $b) {
                FixedBill::create([
                    'mess_month_id' => $month->id,
                    'title' => $b['title'],
                    'category' => $b['category'],
                    'total_amount' => $b['total_amount'],
                    'split_type' => 'equal',
                    'created_by' => $manager->id,
                ]);
            }
        }

        // Seed Chattogram Bachelor Seat / To-Let Finder listings
        if (SeatListing::count() === 0) {
            SeatListing::create([
                'mess_id' => $mess->id,
                'posted_by' => $manager->id,
                'title' => '1 Seat Available near Chawk Bazar Coaching Hub & Chittagong College',
                'city' => 'Chattogram',
                'area' => 'Chawk Bazar',
                'address_hint' => 'Kapasgola Road, 3 min walk from Chawk Bazar Moor',
                'seat_type' => 'shared_seat',
                'gender_preference' => 'male',
                'seats_available' => 1,
                'monthly_rent' => 3000,
                'avg_meal_cost' => 2600,
                'available_from' => $today->copy()->addMonth()->startOfMonth()->toDateString(),
                'facilities' => ['Wi-Fi', 'Fridge', 'Bua', 'Filter Water', '24/7 Security'],
                'contact_phone' => '01711000001',
                'description' => 'Quiet study-friendly mess for Chittagong College / Mohsin College / coaching students. Transparent meals tracked on MessMate BD.',
                'is_featured' => true,
                'status' => 'active',
            ]);

            SeatListing::create([
                'mess_id' => null,
                'posted_by' => $allMembers[1]->id,
                'title' => '2 Seats for CU Students (5 Min Walk to Sholoshahar Shuttle Station)',
                'city' => 'Chattogram',
                'area' => '2 No. Gate',
                'address_hint' => 'Near 2 No. Gate / Sholoshahar Railway Station',
                'seat_type' => 'shared_seat',
                'gender_preference' => 'male',
                'seats_available' => 2,
                'monthly_rent' => 3200,
                'avg_meal_cost' => 2700,
                'available_from' => $today->copy()->addMonth()->startOfMonth()->toDateString(),
                'facilities' => ['Wi-Fi', 'Bua', 'Filter Water', 'Balcony'],
                'contact_phone' => '01711000002',
                'description' => 'Ideal for Chittagong University students who take the morning shuttle train.',
                'is_featured' => true,
                'status' => 'active',
            ]);

            SeatListing::create([
                'mess_id' => null,
                'posted_by' => $allMembers[2]->id,
                'title' => 'Sunny Single Room for Job Holder / Private Uni Student at GEC Circle',
                'city' => 'Chattogram',
                'area' => 'GEC Circle',
                'address_hint' => 'OR Nizam Road, behind GEC Convention Hall',
                'seat_type' => 'single_room',
                'gender_preference' => 'male',
                'seats_available' => 1,
                'monthly_rent' => 6000,
                'avg_meal_cost' => 3100,
                'available_from' => $today->copy()->addMonth()->startOfMonth()->toDateString(),
                'facilities' => ['Wi-Fi', 'Attached Bath', 'Lift', 'Generator', 'Bua'],
                'contact_phone' => '01711000003',
                'description' => 'Clean tiles floor, lift & IPS backup, walking distance to GEC Moor & Premier University.',
                'is_featured' => false,
                'status' => 'active',
            ]);

            SeatListing::create([
                'mess_id' => null,
                'posted_by' => $allMembers[3]->id,
                'title' => 'Shared Seat in Corporate Bachelor Mess (Agrabad C/A)',
                'city' => 'Chattogram',
                'area' => 'Agrabad',
                'address_hint' => 'CDA Residential Area, near Agrabad Access Road',
                'seat_type' => 'shared_seat',
                'gender_preference' => 'male',
                'seats_available' => 1,
                'monthly_rent' => 3800,
                'avg_meal_cost' => 3000,
                'available_from' => $today->copy()->addDays(10)->toDateString(),
                'facilities' => ['Wi-Fi', 'Fridge', 'Bua', 'Generator'],
                'contact_phone' => '01711000004',
                'description' => 'Quiet environment for bank, port, and corporate office employees working in Agrabad.',
                'is_featured' => false,
                'status' => 'active',
            ]);
        }

        // Seed Company Admin Account
        User::firstOrCreate(
            ['email' => 'admin@messmate.bd'],
            [
                'name' => 'MessMate CTG Admin',
                'phone' => '01800000000',
                'password' => Hash::make('admin123'),
                'locale' => 'en',
                'is_admin' => true,
            ]
        );

        // Seed Sample Local CTG Sponsor Banner
        if (SponsorBanner::count() === 0) {
            SponsorBanner::create([
                'sponsor_name' => 'Chawk Bazar IELTS & BCS Care',
                'headline' => '20% Discount for MessMate BD Students in Chattogram!',
                'subtitle' => 'New batch starting next week near Chawk Bazar Moor. Free mock test included.',
                'cta_label' => 'Call Now',
                'cta_value' => '01819000123',
                'target_area' => null,
                'badge_text' => 'CTG SPONSOR',
                'is_active' => true,
            ]);
        }

        // Seed 1 Sample Pending Boost Request so Admin can test 1-click Approval
        $unfeaturedListing = SeatListing::where('is_featured', false)->first();
        if ($unfeaturedListing && BoostRequest::count() === 0) {
            BoostRequest::create([
                'seat_listing_id' => $unfeaturedListing->id,
                'user_id' => $unfeaturedListing->posted_by,
                'amount' => 99,
                'payment_method' => 'bkash',
                'sender_phone' => '01711000003',
                'trx_id' => 'BK99CTG842',
                'duration_days' => 7,
                'status' => 'pending',
            ]);
        }
    }
}
