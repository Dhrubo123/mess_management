<?php

namespace App\Services;

use App\Models\Mess;
use App\Models\MessMonth;

class MessSummaryService
{
    public function calculate(Mess $mess, MessMonth $messMonth): array
    {
        $members = $mess->activeMembers()->with('user:id,name,phone,email')->get();
        $memberCount = max($members->count(), 1);

        $meals = $messMonth->meals()->get();
        $bazars = $messMonth->bazars()->get();
        $deposits = $messMonth->deposits()->get();
        $fixedBills = $messMonth->fixedBills()->get();

        $totalBazar = round((float) $bazars->sum('amount'), 2);
        $totalMeals = round((float) $meals->sum(fn ($m) => $m->breakfast + $m->lunch + $m->dinner + $m->guest_meals), 2);
        $mealRate = $totalMeals > 0 ? round($totalBazar / $totalMeals, 2) : 0.0;

        $totalFixedBills = round((float) $fixedBills->sum('total_amount'), 2);
        $perMemberFixedShare = round($totalFixedBills / $memberCount, 2);

        $totalMealDeposits = round((float) $deposits->where('deposit_type', 'meal')->sum('amount'), 2);
        $totalFixedDeposits = round((float) $deposits->where('deposit_type', 'fixed_bill')->sum('amount'), 2);
        $totalDeposits = round($totalMealDeposits + $totalFixedDeposits, 2);

        $memberBreakdowns = $members->map(function ($membership) use (
            $meals,
            $deposits,
            $mealRate,
            $perMemberFixedShare
        ) {
            $userId = $membership->user_id;
            $userMeals = $meals->where('user_id', $userId);
            $mealCount = round((float) $userMeals->sum(fn ($m) => $m->breakfast + $m->lunch + $m->dinner + $m->guest_meals), 2);
            $mealCost = round($mealCount * $mealRate, 2);

            $seatRent = round((float) $membership->monthly_seat_rent, 2);
            $fixedCost = round($seatRent + $perMemberFixedShare, 2);
            $totalCost = round($mealCost + $fixedCost, 2);

            $mealDeposit = round((float) $deposits->where('user_id', $userId)->where('deposit_type', 'meal')->sum('amount'), 2);
            $fixedDeposit = round((float) $deposits->where('user_id', $userId)->where('deposit_type', 'fixed_bill')->sum('amount'), 2);
            $totalPaid = round($mealDeposit + $fixedDeposit, 2);

            // Positive balance = refundable / extra paid; Negative = due to pay
            $mealBalance = round($mealDeposit - $mealCost, 2);
            $netBalance = round($totalPaid - $totalCost, 2);

            return [
                'user_id' => $userId,
                'name' => $membership->user?->name ?? 'Unknown',
                'phone' => $membership->user?->phone,
                'role' => $membership->role,
                'room_label' => $membership->room_label,
                'total_meals' => $mealCount,
                'meal_cost' => $mealCost,
                'seat_rent' => $seatRent,
                'fixed_bill_share' => $perMemberFixedShare,
                'total_cost' => $totalCost,
                'meal_deposit' => $mealDeposit,
                'fixed_deposit' => $fixedDeposit,
                'total_paid' => $totalPaid,
                'meal_balance' => $mealBalance,
                'net_balance' => $netBalance,
            ];
        })->values()->all();

        $todayStr = now()->toDateString();
        $todayMeals = $meals->filter(fn ($m) => $m->meal_date?->toDateString() === $todayStr);

        return [
            'mess' => [
                'id' => $mess->id,
                'name' => $mess->name,
                'invite_code' => $mess->invite_code,
                'area' => $mess->area,
                'city' => $mess->city,
                'meal_cutoff_time' => $mess->meal_cutoff_time,
                'has_breakfast' => (bool) $mess->has_breakfast,
                'is_pro' => $mess->is_pro,
            ],
            'today_kitchen' => [
                'date' => $todayStr,
                'breakfast' => round((float) $todayMeals->sum('breakfast'), 1),
                'lunch' => round((float) $todayMeals->sum('lunch'), 1),
                'dinner' => round((float) $todayMeals->sum('dinner'), 1),
                'guest_meals' => round((float) $todayMeals->sum('guest_meals'), 1),
            ],
            'month' => [
                'id' => $messMonth->id,
                'year' => $messMonth->year,
                'month' => $messMonth->month,
                'label' => date('F Y', mktime(0, 0, 0, $messMonth->month, 1, $messMonth->year)),
                'status' => $messMonth->status,
                'manager_id' => $messMonth->manager_id,
            ],
            'totals' => [
                'member_count' => $members->count(),
                'total_meals' => $totalMeals,
                'total_bazar' => $totalBazar,
                'meal_rate' => $mealRate,
                'total_fixed_bills' => $totalFixedBills,
                'per_member_fixed_share' => $perMemberFixedShare,
                'total_meal_deposits' => $totalMealDeposits,
                'total_fixed_deposits' => $totalFixedDeposits,
                'total_deposits' => $totalDeposits,
                'cash_in_hand' => round($totalMealDeposits - $totalBazar, 2),
            ],
            'members' => $memberBreakdowns,
        ];
    }

    public function buildShareText(array $summary, string $locale = 'en'): string
    {
        $messName = $summary['mess']['name'];
        $monthLabel = $summary['month']['label'];
        $t = $summary['totals'];

        if ($locale === 'bn') {
            $lines = [
                "🏠 {$messName} — {$monthLabel}",
                "━━━━━━━━━━━━━━━━",
                "🍛 মোট মিল: {$t['total_meals']}",
                "🛒 মোট বাজার: ৳{$t['total_bazar']}",
                "📊 মিল রেট: ৳{$t['meal_rate']}",
                "💡 ফিক্সড বিল (প্রতি জন): ৳{$t['per_member_fixed_share']}",
                "💵 হাতে আছে (মিল ফান্ড): ৳{$t['cash_in_hand']}",
                "━━━━━━━━━━━━━━━━",
                "সদস্যদের হিসাব:",
            ];

            foreach ($summary['members'] as $m) {
                $status = $m['net_balance'] >= 0
                    ? "পাবে ৳" . number_format($m['net_balance'], 0)
                    : "বাকি ৳" . number_format(abs($m['net_balance']), 0);
                $lines[] = "• {$m['name']}: {$m['total_meals']} মিল | খরচ ৳{$m['total_cost']} | জমা ৳{$m['total_paid']} ({$status})";
            }

            $lines[] = "━━━━━━━━━━━━━━━━";
            $lines[] = "MessMate BD অ্যাপ দিয়ে তৈরি";

            return implode("\n", $lines);
        }

        $lines = [
            "🏠 {$messName} — {$monthLabel}",
            "━━━━━━━━━━━━━━━━",
            "🍛 Total Meals: {$t['total_meals']}",
            "🛒 Total Bazar: ৳{$t['total_bazar']}",
            "📊 Meal Rate: ৳{$t['meal_rate']}",
            "💡 Fixed Bills / Member: ৳{$t['per_member_fixed_share']}",
            "💵 Meal Cash in Hand: ৳{$t['cash_in_hand']}",
            "━━━━━━━━━━━━━━━━",
            "Member Breakdown:",
        ];

        foreach ($summary['members'] as $m) {
            $status = $m['net_balance'] >= 0
                ? "Refund ৳" . number_format($m['net_balance'], 0)
                : "Due ৳" . number_format(abs($m['net_balance']), 0);
            $lines[] = "• {$m['name']}: {$m['total_meals']} meals | Cost ৳{$m['total_cost']} | Paid ৳{$m['total_paid']} ({$status})";
        }

        $lines[] = "━━━━━━━━━━━━━━━━";
        $lines[] = "Generated by MessMate BD";

        return implode("\n", $lines);
    }
}
