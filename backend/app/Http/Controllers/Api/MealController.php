<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\InteractsWithMess;
use App\Http\Controllers\Controller;
use App\Models\Meal;
use App\Models\Mess;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MealController extends Controller
{
    use InteractsWithMess;

    public function index(Request $request, Mess $mess): JsonResponse
    {
        $this->requireMembership($request, $mess);
        $messMonth = $this->resolveMessMonth($request, $mess);

        $query = $messMonth->meals()->with('user:id,name,phone');

        if ($request->filled('date')) {
            $query->whereDate('meal_date', $request->query('date'));
        }

        if ($request->filled('user_id')) {
            $query->where('user_id', (int) $request->query('user_id'));
        }

        $meals = $query->orderByDesc('meal_date')->get();

        return response()->json([
            'mess_month' => $messMonth,
            'meals' => $meals,
        ]);
    }

    public function upsert(Request $request, Mess $mess): JsonResponse
    {
        $membership = $this->requireMembership($request, $mess);

        $validated = $request->validate([
            'user_id' => ['nullable', 'integer'],
            'meal_date' => ['required', 'date'],
            'breakfast' => ['nullable', 'numeric', 'min:0', 'max:10'],
            'lunch' => ['required', 'numeric', 'min:0', 'max:10'],
            'dinner' => ['required', 'numeric', 'min:0', 'max:10'],
            'guest_meals' => ['nullable', 'numeric', 'min:0', 'max:20'],
        ]);

        $targetUserId = $validated['user_id'] ?? $request->user()->id;

        if ($targetUserId !== $request->user()->id && $membership->role !== 'manager') {
            return response()->json(['message' => 'Only the mess manager can edit another member\'s meals.'], 403);
        }

        $mealDate = \Carbon\Carbon::parse($validated['meal_date']);
        $messMonth = $mess->months()->firstOrCreate(
            ['year' => (int) $mealDate->year, 'month' => (int) $mealDate->month],
            [
                'manager_id' => $mess->activeMembers()->where('role', 'manager')->value('user_id') ?? $mess->created_by,
                'status' => 'open',
            ]
        );
        $this->ensureMonthOpen($messMonth);

        $meal = Meal::updateOrCreate(
            [
                'mess_month_id' => $messMonth->id,
                'user_id' => $targetUserId,
                'meal_date' => $mealDate->toDateString(),
            ],
            [
                'breakfast' => $mess->has_breakfast ? ($validated['breakfast'] ?? 0) : 0,
                'lunch' => $validated['lunch'],
                'dinner' => $validated['dinner'],
                'guest_meals' => $validated['guest_meals'] ?? 0,
                'updated_by' => $request->user()->id,
            ]
        );

        return response()->json([
            'meal' => $meal->load('user:id,name,phone'),
        ]);
    }

    public function bulkUpsert(Request $request, Mess $mess): JsonResponse
    {
        $this->requireManager($request, $mess);

        $validated = $request->validate([
            'meal_date' => ['required', 'date'],
            'entries' => ['required', 'array', 'min:1'],
            'entries.*.user_id' => ['required', 'integer'],
            'entries.*.breakfast' => ['nullable', 'numeric', 'min:0', 'max:10'],
            'entries.*.lunch' => ['required', 'numeric', 'min:0', 'max:10'],
            'entries.*.dinner' => ['required', 'numeric', 'min:0', 'max:10'],
            'entries.*.guest_meals' => ['nullable', 'numeric', 'min:0', 'max:20'],
        ]);

        $mealDate = \Carbon\Carbon::parse($validated['meal_date']);
        $messMonth = $mess->months()->firstOrCreate(
            ['year' => (int) $mealDate->year, 'month' => (int) $mealDate->month],
            [
                'manager_id' => $request->user()->id,
                'status' => 'open',
            ]
        );
        $this->ensureMonthOpen($messMonth);

        $saved = [];
        \Illuminate\Support\Facades\DB::transaction(function () use ($validated, $mess, $messMonth, $mealDate, $request, &$saved) {
            foreach ($validated['entries'] as $entry) {
                $saved[] = Meal::updateOrCreate(
                    [
                        'mess_month_id' => $messMonth->id,
                        'user_id' => $entry['user_id'],
                        'meal_date' => $mealDate->toDateString(),
                    ],
                    [
                        'breakfast' => $mess->has_breakfast ? ($entry['breakfast'] ?? 0) : 0,
                        'lunch' => $entry['lunch'],
                        'dinner' => $entry['dinner'],
                        'guest_meals' => $entry['guest_meals'] ?? 0,
                        'updated_by' => $request->user()->id,
                    ]
                );
            }
        });

        return response()->json([
            'message' => 'All member meals updated.',
            'count' => count($saved),
        ]);
    }
}
