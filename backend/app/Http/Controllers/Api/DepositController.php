<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\InteractsWithMess;
use App\Http\Controllers\Controller;
use App\Models\Deposit;
use App\Models\Mess;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DepositController extends Controller
{
    use InteractsWithMess;

    public function index(Request $request, Mess $mess): JsonResponse
    {
        $this->requireMembership($request, $mess);
        $messMonth = $this->resolveMessMonth($request, $mess);

        $deposits = $messMonth->deposits()
            ->with(['user:id,name,phone', 'recorder:id,name'])
            ->orderByDesc('deposit_date')
            ->orderByDesc('id')
            ->get();

        return response()->json([
            'mess_month' => $messMonth,
            'total_amount' => round((float) $deposits->sum('amount'), 2),
            'deposits' => $deposits,
        ]);
    }

    public function store(Request $request, Mess $mess): JsonResponse
    {
        $this->requireManager($request, $mess);

        $validated = $request->validate([
            'user_id' => ['required', 'integer'],
            'amount' => ['required', 'numeric', 'min:1'],
            'deposit_type' => ['nullable', 'in:meal,fixed_bill'],
            'payment_method' => ['nullable', 'in:cash,bkash,nagad,bank'],
            'reference' => ['nullable', 'string', 'max:100'],
            'deposit_date' => ['required', 'date'],
        ]);

        $depositDate = \Carbon\Carbon::parse($validated['deposit_date']);
        $messMonth = $mess->months()->firstOrCreate(
            ['year' => (int) $depositDate->year, 'month' => (int) $depositDate->month],
            [
                'manager_id' => $request->user()->id,
                'status' => 'open',
            ]
        );
        $this->ensureMonthOpen($messMonth);

        $deposit = Deposit::create([
            'mess_month_id' => $messMonth->id,
            'user_id' => $validated['user_id'],
            'amount' => $validated['amount'],
            'deposit_type' => $validated['deposit_type'] ?? 'meal',
            'payment_method' => $validated['payment_method'] ?? 'cash',
            'reference' => $validated['reference'] ?? null,
            'deposit_date' => $depositDate->toDateString(),
            'recorded_by' => $request->user()->id,
        ]);

        return response()->json([
            'deposit' => $deposit->load('user:id,name,phone'),
        ], 201);
    }

    public function destroy(Request $request, Mess $mess, Deposit $deposit): JsonResponse
    {
        $this->requireManager($request, $mess);
        abort_if($deposit->messMonth->mess_id !== $mess->id, 404);
        $this->ensureMonthOpen($deposit->messMonth);

        $deposit->delete();

        return response()->json(['message' => 'Deposit deleted.']);
    }
}
