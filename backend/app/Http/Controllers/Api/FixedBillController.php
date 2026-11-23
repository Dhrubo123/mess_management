<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\InteractsWithMess;
use App\Http\Controllers\Controller;
use App\Models\FixedBill;
use App\Models\Mess;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class FixedBillController extends Controller
{
    use InteractsWithMess;

    public function index(Request $request, Mess $mess): JsonResponse
    {
        $this->requireMembership($request, $mess);
        $messMonth = $this->resolveMessMonth($request, $mess);

        $bills = $messMonth->fixedBills()->orderByDesc('id')->get();

        return response()->json([
            'mess_month' => $messMonth,
            'total_amount' => round((float) $bills->sum('total_amount'), 2),
            'fixed_bills' => $bills,
        ]);
    }

    public function store(Request $request, Mess $mess): JsonResponse
    {
        $this->requireManager($request, $mess);

        $validated = $request->validate([
            'title' => ['required', 'string', 'max:100'],
            'category' => ['nullable', 'in:rent,wifi,bua,gas,electricity,water,other'],
            'total_amount' => ['required', 'numeric', 'min:1'],
            'notes' => ['nullable', 'string', 'max:255'],
            'year' => ['nullable', 'integer'],
            'month' => ['nullable', 'integer', 'min:1', 'max:12'],
        ]);

        $messMonth = $this->resolveMessMonth($request, $mess);
        $this->ensureMonthOpen($messMonth);

        $bill = FixedBill::create([
            'mess_month_id' => $messMonth->id,
            'title' => $validated['title'],
            'category' => $validated['category'] ?? 'other',
            'total_amount' => $validated['total_amount'],
            'split_type' => 'equal',
            'notes' => $validated['notes'] ?? null,
            'created_by' => $request->user()->id,
        ]);

        return response()->json(['fixed_bill' => $bill], 201);
    }

    public function copyPrevious(Request $request, Mess $mess): JsonResponse
    {
        $this->requireManager($request, $mess);
        $currentMonth = $this->resolveMessMonth($request, $mess);
        $this->ensureMonthOpen($currentMonth);

        $prevDate = \Carbon\Carbon::create($currentMonth->year, $currentMonth->month, 1)->subMonth();
        $prevMonth = $mess->months()
            ->where('year', (int) $prevDate->year)
            ->where('month', (int) $prevDate->month)
            ->first();

        if (! $prevMonth) {
            return response()->json(['message' => 'No bills found in previous month.'], 404);
        }

        $prevBills = $prevMonth->fixedBills()->get();
        if ($prevBills->isEmpty()) {
            return response()->json(['message' => 'No bills found in previous month.'], 404);
        }

        $copied = 0;
        foreach ($prevBills as $b) {
            $exists = $currentMonth->fixedBills()
                ->where('title', $b->title)
                ->where('category', $b->category)
                ->exists();
            if (! $exists) {
                FixedBill::create([
                    'mess_month_id' => $currentMonth->id,
                    'title' => $b->title,
                    'category' => $b->category,
                    'total_amount' => $b->total_amount,
                    'split_type' => $b->split_type,
                    'notes' => $b->notes,
                    'created_by' => $request->user()->id,
                ]);
                $copied++;
            }
        }

        return response()->json([
            'message' => $copied > 0 ? "Copied {$copied} bills from last month." : 'All bills from last month already exist.',
            'copied_count' => $copied,
        ]);
    }

    public function destroy(Request $request, Mess $mess, FixedBill $fixedBill): JsonResponse
    {
        $this->requireManager($request, $mess);
        abort_if($fixedBill->messMonth->mess_id !== $mess->id, 404);
        $this->ensureMonthOpen($fixedBill->messMonth);

        $fixedBill->delete();

        return response()->json(['message' => 'Fixed bill deleted.']);
    }
}
