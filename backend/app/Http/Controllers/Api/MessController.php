<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\InteractsWithMess;
use App\Http\Controllers\Controller;
use App\Models\FixedBill;
use App\Models\Mess;
use App\Models\MessMember;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class MessController extends Controller
{
    use InteractsWithMess;

    public function index(Request $request): JsonResponse
    {
        $messes = $request->user()
            ->messes()
            ->wherePivot('is_active', true)
            ->withCount(['activeMembers'])
            ->get();

        return response()->json(['messes' => $messes]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:120'],
            'city' => ['nullable', 'string', 'max:60'],
            'area' => ['required', 'string', 'max:100'],
            'address' => ['nullable', 'string', 'max:255'],
            'meal_cutoff_time' => ['nullable', 'regex:/^\d{2}:\d{2}$/'],
            'has_breakfast' => ['nullable', 'boolean'],
            'facilities' => ['nullable', 'array'],
            'facilities.*' => ['string', 'max:40'],
            'food_mode' => ['nullable', 'in:meal_rate,fixed_food'],
            'monthly_seat_rent' => ['nullable', 'numeric', 'min:0'],
            'wifi_bill' => ['nullable', 'numeric', 'min:0'],
            'bua_bill' => ['nullable', 'numeric', 'min:0'],
            'electricity_bill' => ['nullable', 'numeric', 'min:0'],
        ]);

        $user = $request->user();

        $mess = DB::transaction(function () use ($validated, $user) {
            $mess = Mess::create([
                'name' => $validated['name'],
                'invite_code' => Mess::generateInviteCode(),
                'city' => $validated['city'] ?? 'Chattogram',
                'area' => $validated['area'],
                'address' => $validated['address'] ?? null,
                'meal_cutoff_time' => $validated['meal_cutoff_time'] ?? '22:00',
                'has_breakfast' => $validated['has_breakfast'] ?? false,
                'facilities' => $validated['facilities'] ?? ['Wi-Fi', 'Bua', 'Electricity', 'Gas'],
                'food_mode' => $validated['food_mode'] ?? 'meal_rate',
                'created_by' => $user->id,
            ]);

            MessMember::create([
                'mess_id' => $mess->id,
                'user_id' => $user->id,
                'role' => 'manager',
                'monthly_seat_rent' => $validated['monthly_seat_rent'] ?? 0,
                'is_active' => true,
            ]);

            $month = $mess->currentMonth();

            $initialBills = [
                ['key' => 'wifi_bill', 'title' => 'Wi-Fi Bill', 'category' => 'wifi'],
                ['key' => 'bua_bill', 'title' => 'Bua (Cook & Cleaning)', 'category' => 'bua'],
                ['key' => 'electricity_bill', 'title' => 'Electricity & Gas', 'category' => 'electricity'],
            ];
            foreach ($initialBills as $b) {
                $amt = (float) ($validated[$b['key']] ?? 0);
                if ($amt > 0) {
                    FixedBill::create([
                        'mess_month_id' => $month->id,
                        'title' => $b['title'],
                        'category' => $b['category'],
                        'total_amount' => $amt,
                        'split_type' => 'equal',
                        'created_by' => $user->id,
                    ]);
                }
            }

            return $mess;
        });

        return response()->json([
            'mess' => $mess->loadCount('activeMembers'),
        ], 201);
    }

    public function join(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'invite_code' => ['required', 'string', 'max:10'],
            'room_label' => ['nullable', 'string', 'max:60'],
            'monthly_seat_rent' => ['nullable', 'numeric', 'min:0'],
        ]);

        $mess = Mess::where('invite_code', strtoupper(trim($validated['invite_code'])))->first();

        if (! $mess) {
            return response()->json(['message' => 'Invalid invite code.'], 404);
        }

        $membership = MessMember::updateOrCreate(
            ['mess_id' => $mess->id, 'user_id' => $request->user()->id],
            [
                'is_active' => true,
                'left_at' => null,
                'room_label' => $validated['room_label'] ?? null,
                'monthly_seat_rent' => $validated['monthly_seat_rent'] ?? 0,
            ]
        );

        return response()->json([
            'message' => 'Joined mess successfully.',
            'mess' => $mess->loadCount('activeMembers'),
            'membership' => $membership,
        ]);
    }

    public function show(Request $request, Mess $mess): JsonResponse
    {
        $membership = $this->requireMembership($request, $mess);

        $mess->load([
            'activeMembers.user:id,name,phone,email',
        ]);

        return response()->json([
            'mess' => $mess,
            'my_role' => $membership->role,
            'current_month' => $mess->currentMonth(),
        ]);
    }

    public function updateSettings(Request $request, Mess $mess): JsonResponse
    {
        $this->requireManager($request, $mess);

        $validated = $request->validate([
            'name' => ['sometimes', 'string', 'max:120'],
            'area' => ['sometimes', 'string', 'max:100'],
            'address' => ['nullable', 'string', 'max:255'],
            'meal_cutoff_time' => ['sometimes', 'regex:/^\d{2}:\d{2}$/'],
            'has_breakfast' => ['sometimes', 'boolean'],
            'facilities' => ['sometimes', 'array'],
            'facilities.*' => ['string', 'max:40'],
            'food_mode' => ['sometimes', 'in:meal_rate,fixed_food'],
            'default_breakfast' => ['sometimes', 'numeric', 'min:0', 'max:5'],
            'default_lunch' => ['sometimes', 'numeric', 'min:0', 'max:5'],
            'default_dinner' => ['sometimes', 'numeric', 'min:0', 'max:5'],
        ]);

        $mess->update($validated);

        return response()->json(['mess' => $mess->fresh()]);
    }

    public function handoverManager(Request $request, Mess $mess): JsonResponse
    {
        $currentManager = $this->requireManager($request, $mess);

        $validated = $request->validate([
            'new_manager_user_id' => ['required', 'integer'],
        ]);

        $nextManager = $mess->activeMembers()
            ->where('user_id', $validated['new_manager_user_id'])
            ->first();

        if (! $nextManager) {
            return response()->json(['message' => 'Selected user is not an active member of this mess.'], 422);
        }

        DB::transaction(function () use ($mess, $currentManager, $nextManager) {
            $currentManager->update(['role' => 'member']);
            $nextManager->update(['role' => 'manager']);

            $month = $mess->currentMonth();
            $month->update(['manager_id' => $nextManager->user_id]);
        });

        return response()->json([
            'message' => 'Manager role handed over successfully.',
            'new_manager_user_id' => $nextManager->user_id,
        ]);
    }
}
